import 'dart:convert';

import 'package:dio/dio.dart';
import '../domain/models.dart';

class ConnectionReport {
  final bool ok;
  final String message;
  final bool workflowInstalled;
  final bool canWrite;
  final bool isPrivate;
  const ConnectionReport({
    required this.ok,
    required this.message,
    this.workflowInstalled = false,
    this.canWrite = false,
    this.isPrivate = false,
  });
}

/// Everything the app needs from the GitHub repository.
abstract class RemoteStore {
  /// Fires the workflow for [op]. Throws [RemoteException] when it can't be sent.
  Future<void> dispatch(Operation op);

  /// Fires the workflow once for all [ops] (at most 25 / ~48 KB; see [chunk]).
  /// Throws [RemoteException] when it can't be sent.
  Future<void> dispatchBatch(List<Operation> ops);

  /// Splits [ops] into ordered batches of at most [maxOps] operations and
  /// [maxBytes] serialized bytes. An operation over [maxBytes] goes alone.
  static List<List<Operation>> chunk(List<Operation> ops, {int maxOps = 25, int maxBytes = 48000}) {
    final batches = <List<Operation>>[];
    var current = <Operation>[];
    var bytes = 0;
    for (final op in ops) {
      final size = utf8.encode(jsonEncode(dispatchJson(op))).length;
      if (current.isNotEmpty && (current.length >= maxOps || bytes + size > maxBytes)) {
        batches.add(current);
        current = <Operation>[];
        bytes = 0;
      }
      current.add(op);
      bytes += size;
    }
    if (current.isNotEmpty) batches.add(current);
    return batches;
  }

  /// The wire form of one operation inside a dispatch payload.
  static Map<String, dynamic> dispatchJson(Operation op) => {
        'operation_id': op.id,
        'action': op.action.name,
        'entity_type': op.type.name,
        'entity_id': op.entityId,
        'payload': op.payload,
        'local_date': op.localDate,
      };

  /// Looks up the outcome of one operation. `pending` while the status file
  /// does not exist yet.
  Future<OpResult> status(String operationId);

  /// Reads branches.json / activities.json / records.json / quests.json.
  Future<Snapshot> pull();

  /// Verifies token, repository access and workflow installation.
  Future<ConnectionReport> check();
}

class RemoteException implements Exception {
  final String message;
  final bool retryable;
  RemoteException(this.message, {this.retryable = true});
  @override
  String toString() => message;
}

class GithubRemoteStore implements RemoteStore {
  GithubRemoteStore({required this.repo, required String pat, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.github.com',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Authorization': 'Bearer $pat',
                'Accept': 'application/vnd.github+json',
                'X-GitHub-Api-Version': '2022-11-28',
              },
              validateStatus: (_) => true, // inspect status codes ourselves
            ));

  final String repo; // owner/name
  final Dio _dio;

  static bool isValidRepo(String s) => RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(s.trim());

  String _explain(Response r, String doing) {
    final api = r.data is Map ? (r.data['message'] as String?) : null;
    switch (r.statusCode) {
      case 401:
        return 'GitHub rejected the token (401). Check that it is valid and not expired.';
      case 403:
        return 'GitHub denied access (403) while $doing. ${api ?? ''}'.trim();
      case 404:
        return 'Repository "$repo" not found, or the token cannot see it (404).';
      default:
        return 'GitHub error ${r.statusCode} while $doing. ${api ?? ''}'.trim();
    }
  }

  Never _net(DioException e, String doing) =>
      throw RemoteException('No connection to GitHub while $doing (${e.type.name}).');

  @override
  Future<void> dispatch(Operation op) async {
    try {
      final r = await _dio.post('/repos/$repo/dispatches', data: {
        'event_type': 'rpg_operation',
        'client_payload': {
          'operation_id': op.id,
          'action': op.action.name,
          'entity_type': op.type.name,
          'entity_id': op.entityId,
          'payload': op.payload,
        },
      });
      if (r.statusCode != 204) {
        final retry = (r.statusCode ?? 500) >= 500;
        throw RemoteException(_explain(r, 'starting the sync'), retryable: retry);
      }
    } on DioException catch (e) {
      _net(e, 'starting the sync');
    }
  }

  @override
  Future<void> dispatchBatch(List<Operation> ops) async {
    try {
      final r = await _dio.post('/repos/$repo/dispatches', data: {
        'event_type': 'rpg_operation',
        'client_payload': {
          'operations': ops.map(RemoteStore.dispatchJson).toList(),
        },
      });
      if (r.statusCode != 204) {
        final retry = (r.statusCode ?? 500) >= 500;
        throw RemoteException(_explain(r, 'starting the sync'), retryable: retry);
      }
    } on DioException catch (e) {
      _net(e, 'starting the sync');
    }
  }

  @override
  Future<OpResult> status(String operationId) async {
    try {
      final r = await _dio.get('/repos/$repo/contents/status/$operationId.json',
          options: Options(headers: {'Accept': 'application/vnd.github.raw+json'}, responseType: ResponseType.json));
      if (r.statusCode == 404) return const OpResult(OpOutcome.pending, 'Waiting for GitHub Actions…');
      if (r.statusCode != 200) throw RemoteException(_explain(r, 'reading the result'));
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      final message = data['message'] as String? ?? '';
      switch (data['status']) {
        case 'SUCCESS':
          return OpResult(OpOutcome.success, message);
        case 'REJECTED':
          return OpResult(OpOutcome.rejected, message);
        case 'FAILED':
          return OpResult(OpOutcome.failed, message);
        default:
          return const OpResult(OpOutcome.pending, 'Waiting for GitHub Actions…');
      }
    } on DioException catch (e) {
      _net(e, 'reading the result');
    }
  }

  Future<Object?> _readJson(String file) async {
    final r = await _dio.get('/repos/$repo/contents/$file',
        options: Options(headers: {'Accept': 'application/vnd.github.raw+json'}, responseType: ResponseType.json));
    if (r.statusCode == 404) return const [];
    if (r.statusCode != 200) throw RemoteException(_explain(r, 'reading $file'));
    return r.data;
  }

  @override
  Future<Snapshot> pull() async {
    try {
      final b = await _readJson('branches.json');
      final a = await _readJson('activities.json');
      final rec = await _readJson('records.json');
      final q = await _readJson('quests.json');
      return Snapshot.fromLists(b, a, rec, q);
    } on DioException catch (e) {
      _net(e, 'downloading your data');
    }
  }

  @override
  Future<ConnectionReport> check() async {
    try {
      final u = await _dio.get('/user');
      if (u.statusCode != 200) return ConnectionReport(ok: false, message: _explain(u, 'checking the token'));
      final r = await _dio.get('/repos/$repo');
      if (r.statusCode != 200) return ConnectionReport(ok: false, message: _explain(r, 'opening the repository'));
      final perms = (r.data['permissions'] as Map?) ?? const {};
      final canWrite = perms['push'] == true;
      final priv = r.data['private'] == true;
      final wf = await _dio.get('/repos/$repo/contents/.github/workflows/create_entity.yml');
      final installed = wf.statusCode == 200;
      if (!canWrite) {
        return ConnectionReport(
            ok: false,
            message: 'Connected as ${u.data['login']}, but the token cannot write to $repo.',
            workflowInstalled: installed,
            isPrivate: priv);
      }
      if (!installed) {
        return ConnectionReport(
            ok: false,
            message: 'Connected, but the workflow file is missing in $repo. Push the .github folder first.',
            canWrite: true,
            isPrivate: priv);
      }
      return ConnectionReport(
          ok: true,
          message: 'Connected as ${u.data['login']} to $repo${priv ? ' (private)' : ' (PUBLIC - your data is visible)'}.',
          workflowInstalled: true,
          canWrite: true,
          isPrivate: priv);
    } on DioException catch (e) {
      return ConnectionReport(ok: false, message: 'No connection to GitHub (${e.type.name}).');
    }
  }
}
