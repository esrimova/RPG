/// Represents a single activity recording/completion
class Record {
  final String id;
  final String activityId;
  final String branchId;
  final DateTime timestamp;
  final Map<String, dynamic> fieldValues;
  final int xpEarned;
  final Map<String, int> statChanges;
  final String? notes;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  const Record({
    required this.id,
    required this.activityId,
    required this.branchId,
    required this.timestamp,
    required this.fieldValues,
    required this.xpEarned,
    this.statChanges = const {},
    this.notes,
    this.duration,
    this.metadata = const {},
  });

  /// Creates a copy with updated fields
  Record copyWith({
    String? id,
    String? activityId,
    String? branchId,
    DateTime? timestamp,
    Map<String, dynamic>? fieldValues,
    int? xpEarned,
    Map<String, int>? statChanges,
    String? notes,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    return Record(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      branchId: branchId ?? this.branchId,
      timestamp: timestamp ?? this.timestamp,
      fieldValues: fieldValues ?? this.fieldValues,
      xpEarned: xpEarned ?? this.xpEarned,
      statChanges: statChanges ?? this.statChanges,
      notes: notes ?? this.notes,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'branch_id': branchId,
      'timestamp': timestamp.toIso8601String(),
      'field_values': fieldValues,
      'xp_earned': xpEarned,
      'stat_changes': statChanges,
      if (notes != null) 'notes': notes,
      if (duration != null) 'duration_seconds': duration!.inSeconds,
      'metadata': metadata,
    };
  }

  /// Deserializes from JSON
  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      branchId: json['branch_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fieldValues: Map<String, dynamic>.from(json['field_values'] as Map),
      xpEarned: json['xp_earned'] as int,
      statChanges: Map<String, int>.from(json['stat_changes'] as Map? ?? {}),
      notes: json['notes'] as String?,
      duration: json['duration_seconds'] != null
          ? Duration(seconds: json['duration_seconds'] as int)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Record &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activityId == other.activityId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(id, activityId, timestamp);

  @override
  String toString() =>
      'Record(id: $id, activity: $activityId, xp: $xpEarned, time: $timestamp)';
}