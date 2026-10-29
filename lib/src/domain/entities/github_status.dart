/// GitHub Actions workflow execution status
enum GithubWorkflowStatus {
  pending('PENDING'),
  running('RUNNING'),
  success('SUCCESS'),
  rejected('REJECTED'),
  failed('FAILED'),
  unknown('UNKNOWN');

  const GithubWorkflowStatus(this.value);
  final String value;

  static GithubWorkflowStatus fromString(String value) {
    return GithubWorkflowStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GithubWorkflowStatus.unknown,
    );
  }
}

/// Status file content from GitHub repository
class GithubStatus {
  final String workflowRunId;
  final GithubWorkflowStatus status;
  final String entityType; // 'branch', 'activity', 'record'
  final String entityId;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const GithubStatus({
    required this.workflowRunId,
    required this.status,
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.timestamp,
    this.details,
  });

  /// Creates a copy with updated fields
  GithubStatus copyWith({
    String? workflowRunId,
    GithubWorkflowStatus? status,
    String? entityType,
    String? entityId,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? details,
  }) {
    return GithubStatus(
      workflowRunId: workflowRunId ?? this.workflowRunId,
      status: status ?? this.status,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
    );
  }

  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'workflow_run_id': workflowRunId,
      'status': status.value,
      'entity_type': entityType,
      'entity_id': entityId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      if (details != null) 'details': details,
    };
  }

  /// Deserializes from JSON
  factory GithubStatus.fromJson(Map<String, dynamic> json) {
    return GithubStatus(
      workflowRunId: json['workflow_run_id'] as String,
      status: GithubWorkflowStatus.fromString(json['status'] as String),
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GithubStatus &&
          runtimeType == other.runtimeType &&
          workflowRunId == other.workflowRunId &&
          entityId == other.entityId;

  @override
  int get hashCode => Object.hash(workflowRunId, entityId);

  @override
  String toString() =>
      'GithubStatus(run: $workflowRunId, status: ${status.value}, entity: $entityType/$entityId)';
}