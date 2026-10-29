import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/entities/github_status.dart';
import '../../core/constants/app_constants.dart';

/// GitHub API data source for workflow dispatch and status polling
class GithubApiDataSource {
  final Dio _dio;
  final String _pat;
  final String _repoOwner;
  final String _repoName;

  GithubApiDataSource({
    required Dio dio,
    required String pat,
    required String repoOwner,
    required String repoName,
  })  : _dio = dio,
        _pat = pat,
        _repoOwner = repoOwner,
        _repoName = repoName;

  /// Creates a Dio instance with GitHub authentication
  static Dio createDio(String pat) {
    return Dio(
      BaseOptions(
        baseUrl: AppConstants.githubApiBaseUrl,
        headers: {
          'Authorization': 'Bearer $pat',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Triggers a repository_dispatch workflow
  Future<GithubStatus> triggerWorkflow({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final workflowPayload = {
      'event_type': 'create_$entityType',
      'client_payload': {
        'entity_type': entityType,
        'entity_id': entityId,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    try {
      final response = await _dio.post(
        '/repos/$_repoOwner/$_repoName/dispatches',
        data: workflowPayload,
      );

      if (response.statusCode == 204) {
        // Workflow triggered successfully, now we need to poll for the run ID
        // For repository_dispatch, we get the run ID by polling workflow runs
        final runId = await _findWorkflowRun(entityType, entityId);
        
        return GithubStatus(
          workflowRunId: runId.toString(),
          status: GithubWorkflowStatus.running,
          entityType: entityType,
          entityId: entityId,
          message: 'Workflow triggered, polling for result...',
          timestamp: DateTime.now(),
        );
      } else {
        return GithubStatus(
          workflowRunId: '',
          status: GithubWorkflowStatus.failed,
          entityType: entityType,
          entityId: entityId,
          message: 'Failed to trigger workflow: ${response.statusCode}',
          timestamp: DateTime.now(),
        );
      }
    } on DioException catch (e) {
      return GithubStatus(
        workflowRunId: '',
        status: GithubWorkflowStatus.failed,
        entityType: entityType,
        entityId: entityId,
        message: 'Network error: ${e.message}',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Finds the workflow run ID for a recently triggered workflow
  Future<int> _findWorkflowRun(String entityType, String entityId) async {
    try {
      final response = await _dio.get(
        '/repos/$_repoOwner/$_repoName/actions/runs',
        queryParameters: {
          'event': 'repository_dispatch',
          'per_page': 10,
        },
      );

      if (response.statusCode == 200) {
        final runs = response.data['workflow_runs'] as List<dynamic>?;
        if (runs != null && runs.isNotEmpty) {
          // Find the run that matches our entity
          for (final run in runs) {
            final payload = run['head_commit']?['message'] as String? ?? '';
            if (payload.contains(entityType) && payload.contains(entityId)) {
              return run['id'] as int;
            }
          }
          // Return the most recent run
          return runs.first['id'] as int;
        }
      }
    } catch (e) {
      // Ignore errors, return a default
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Polls for workflow completion with exponential backoff
  Future<GithubStatus> pollWithBackoff({
    required String workflowRunId,
    required String entityType,
    required String entityId,
    int maxAttempts = AppConstants.maxPollAttempts,
  }) async {
    int attempt = 0;
    int delayMs = AppConstants.initialPollDelayMs;

    while (attempt < maxAttempts) {
      await Future.delayed(Duration(milliseconds: delayMs));
      
      final status = await getWorkflowStatus(workflowRunId);
      
      if (status.status == GithubWorkflowStatus.success ||
          status.status == GithubWorkflowStatus.rejected ||
          status.status == GithubWorkflowStatus.failed) {
        return status;
      }

      attempt++;
      delayMs = (delayMs * 2).clamp(AppConstants.initialPollDelayMs, AppConstants.maxPollDelayMs);
    }

    return GithubStatus(
      workflowRunId: workflowRunId,
      status: GithubWorkflowStatus.failed,
      entityType: entityType,
      entityId: entityId,
      message: 'Polling timeout after $maxAttempts attempts',
      timestamp: DateTime.now(),
    );
  }

  /// Gets the status of a specific workflow run
  Future<GithubStatus> getWorkflowStatus(String workflowRunId) async {
    try {
      final response = await _dio.get(
        '/repos/$_repoOwner/$_repoName/actions/runs/$workflowRunId',
      );

      if (response.statusCode == 200) {
        final run = response.data;
        final conclusion = run['conclusion'] as String?;
        final status = run['status'] as String?;

        GithubWorkflowStatus workflowStatus;
        String message;

        if (status == 'completed') {
          switch (conclusion) {
            case 'success':
              workflowStatus = GithubWorkflowStatus.success;
              message = 'Workflow completed successfully';
              break;
            case 'failure':
              workflowStatus = GithubWorkflowStatus.failed;
              message = 'Workflow failed';
              break;
            case 'cancelled':
              workflowStatus = GithubWorkflowStatus.failed;
              message = 'Workflow cancelled';
              break;
            default:
              workflowStatus = GithubWorkflowStatus.failed;
              message = 'Workflow ended with status: $conclusion';
          }
        } else if (status == 'in_progress' || status == 'queued') {
          workflowStatus = GithubWorkflowStatus.running;
          message = 'Workflow is running...';
        } else {
          workflowStatus = GithubWorkflowStatus.pending;
          message = 'Workflow is pending...';
        }

        return GithubStatus(
          workflowRunId: workflowRunId,
          status: workflowStatus,
          entityType: '',
          entityId: '',
          message: message,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      // Fall through to status file check
    }

    // Fallback: check the status file
    return getStatusFile();
  }

  /// Reads the .rpg_status.json file from the repository
  Future<GithubStatus> getStatusFile() async {
    try {
      final response = await _dio.get(
        '/repos/$_repoOwner/$_repoName/contents/${AppConstants.statusFilePath}',
        queryParameters: {'ref': 'main'},
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as String?;
        if (content != null) {
          final decoded = utf8.decode(base64Decode(content));
          final json = jsonDecode(decoded) as Map<String, dynamic>;
          return GithubStatus.fromJson(json);
        }
      }
    } catch (e) {
      // File not found or other error
    }

    return GithubStatus(
      workflowRunId: '',
      status: GithubWorkflowStatus.unknown,
      entityType: '',
      entityId: '',
      message: 'Status file not found',
      timestamp: DateTime.now(),
    );
  }

  /// Validates the PAT by making a test API call
  Future<bool> validatePat() async {
    try {
      final response = await _dio.get('/user');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}