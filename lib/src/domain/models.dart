import 'dart:convert';

import 'quests.dart' show dateKey;

/// Field types a user can attach to an activity.
enum FieldType {
  number('number', 'Number'),
  duration('duration', 'Duration'),
  scale('scale', 'Scale 1-10'),
  yesNo('yesno', 'Yes / No'),
  text('text', 'Text');

  const FieldType(this.value, this.label);
  final String value;
  final String label;

  static FieldType parse(String? v) =>
      FieldType.values.firstWhere((e) => e.value == v, orElse: () => FieldType.number);
}

class ActivityField {
  final String id;
  final String name;
  final FieldType type;
  final String? unit;
  final bool required;

  const ActivityField({
    required this.id,
    required this.name,
    required this.type,
    this.unit,
    this.required = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.value,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        'required': required,
      };

  factory ActivityField.fromJson(Map<String, dynamic> j) => ActivityField(
        id: j['id'] as String,
        name: j['name'] as String,
        type: FieldType.parse(j['type'] as String?),
        unit: j['unit'] as String?,
        required: j['required'] as bool? ?? true,
      );
}

class Branch {
  final String id;
  final String name;
  final String description;
  final int color; // ARGB
  final int iconCodePoint;
  final DateTime createdAt;

  const Branch({
    required this.id,
    required this.name,
    this.description = '',
    required this.color,
    required this.iconCodePoint,
    required this.createdAt,
  });

  Branch copyWith({String? name, String? description, int? color, int? iconCodePoint}) => Branch(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'accent_color': color,
        'icon_code_point': iconCodePoint,
        'created_at': createdAt.toIso8601String(),
      };

  factory Branch.fromJson(Map<String, dynamic> j) => Branch(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        color: (j['accent_color'] as num).toInt(),
        iconCodePoint: (j['icon_code_point'] as num).toInt(),
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class Activity {
  final String id;
  final String branchId;
  final String name;
  final String description;
  final int color;
  final int iconCodePoint;
  final int baseXp;
  final List<ActivityField> fields;
  final double? goal;
  final String? goalFieldId;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.branchId,
    required this.name,
    this.description = '',
    required this.color,
    required this.iconCodePoint,
    this.baseXp = 10,
    this.fields = const [],
    this.goal,
    this.goalFieldId,
    required this.createdAt,
  });

  Activity copyWith({
    String? name,
    String? description,
    int? color,
    int? iconCodePoint,
    int? baseXp,
    List<ActivityField>? fields,
    double? goal,
    String? goalFieldId,
    bool clearGoal = false,
  }) =>
      Activity(
        id: id,
        branchId: branchId,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        baseXp: baseXp ?? this.baseXp,
        fields: fields ?? this.fields,
        goal: clearGoal ? null : (goal ?? this.goal),
        goalFieldId: clearGoal ? null : (goalFieldId ?? this.goalFieldId),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'branch_id': branchId,
        'name': name,
        'description': description,
        'accent_color': color,
        'icon_code_point': iconCodePoint,
        'base_xp': baseXp,
        'fields': fields.map((f) => f.toJson()).toList(),
        if (goal != null) 'goal': goal,
        if (goalFieldId != null) 'goal_field_id': goalFieldId,
        'created_at': createdAt.toIso8601String(),
      };

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        color: (j['accent_color'] as num).toInt(),
        iconCodePoint: (j['icon_code_point'] as num).toInt(),
        baseXp: (j['base_xp'] as num?)?.toInt() ?? 10,
        fields: ((j['fields'] as List?) ?? const [])
            .map((f) => ActivityField.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList(),
        goal: (j['goal'] as num?)?.toDouble(),
        goalFieldId: j['goal_field_id'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class Record {
  final String id;
  final String activityId;
  final String branchId;
  final DateTime timestamp;
  final Map<String, dynamic> values;
  final int xpEarned;
  final String? notes;
  final double? goal;

  const Record({
    required this.id,
    required this.activityId,
    required this.branchId,
    required this.timestamp,
    required this.values,
    required this.xpEarned,
    this.notes,
    this.goal,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'activity_id': activityId,
        'branch_id': branchId,
        'timestamp': timestamp.toIso8601String(),
        'field_values': values,
        'xp_earned': xpEarned,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (goal != null) 'goal': goal,
      };

  factory Record.fromJson(Map<String, dynamic> j) => Record(
        id: j['id'] as String,
        activityId: j['activity_id'] as String,
        branchId: j['branch_id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        values: Map<String, dynamic>.from((j['field_values'] as Map?) ?? const {}),
        xpEarned: (j['xp_earned'] as num?)?.toInt() ?? 0,
        notes: j['notes'] as String?,
        goal: (j['goal'] as num?)?.toDouble(),
      );
}

class QuestTask {
  final String id;
  final String name;
  final String date;
  final DateTime? doneAt;

  const QuestTask({required this.id, required this.name, required this.date, this.doneAt});

  QuestTask copyWith({String? name, String? date, DateTime? doneAt, bool clearDone = false}) => QuestTask(
        id: id,
        name: name ?? this.name,
        date: date ?? this.date,
        doneAt: clearDone ? null : (doneAt ?? this.doneAt),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date,
        if (doneAt != null) 'done_at': doneAt!.toIso8601String(),
      };

  factory QuestTask.fromJson(Map<String, dynamic> j) {
    final done = j['done_at'];
    return QuestTask(
      id: j['id'] as String,
      name: j['name'] as String,
      date: j['date'] as String,
      doneAt: done == null ? null : DateTime.parse(done as String),
    );
  }
}

/// How an auto quest spreads its tasks over the date range.
class QuestPattern {
  final String type; // every_n_days | weekdays
  final int n;
  final List<int> days; // 1=Mon..7=Sun

  const QuestPattern._(this.type, this.n, this.days);

  factory QuestPattern.everyNDays(int n) => QuestPattern._('every_n_days', n, const []);
  factory QuestPattern.weekdays(List<int> days) => QuestPattern._('weekdays', 0, List.unmodifiable(days));

  Map<String, dynamic> toJson() => type == 'weekdays' ? {'type': type, 'days': days} : {'type': type, 'n': n};

  factory QuestPattern.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String;
    if (type == 'every_n_days') return QuestPattern.everyNDays((j['n'] as num).toInt());
    if (type == 'weekdays') {
      return QuestPattern.weekdays((j['days'] as List).map((e) => (e as num).toInt()).toList());
    }
    throw FormatException('Unknown quest pattern $type');
  }
}

class Quest {
  final String id;
  final String name;
  final String description;
  final String startDate;
  final String endDate;
  final int totalXp;
  final bool auto;
  final QuestPattern? pattern;
  final List<QuestTask> tasks;
  final DateTime createdAt;

  const Quest({
    required this.id,
    required this.name,
    this.description = '',
    required this.startDate,
    required this.endDate,
    required this.totalXp,
    this.auto = false,
    this.pattern,
    this.tasks = const [],
    required this.createdAt,
  });

  Quest copyWith({
    String? name,
    String? description,
    String? startDate,
    String? endDate,
    int? totalXp,
    bool? auto,
    QuestPattern? pattern,
    bool clearPattern = false,
    List<QuestTask>? tasks,
  }) =>
      Quest(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        totalXp: totalXp ?? this.totalXp,
        auto: auto ?? this.auto,
        pattern: clearPattern ? null : (pattern ?? this.pattern),
        tasks: tasks ?? this.tasks,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
        'total_xp': totalXp,
        'distribution': auto ? 'auto' : 'manual',
        if (pattern != null) 'pattern': pattern!.toJson(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Quest.fromJson(Map<String, dynamic> j) => Quest(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        startDate: j['start_date'] as String,
        endDate: j['end_date'] as String,
        totalXp: (j['total_xp'] as num).toInt(),
        auto: j['distribution'] == 'auto',
        pattern: j['pattern'] == null ? null : QuestPattern.fromJson(Map<String, dynamic>.from(j['pattern'] as Map)),
        tasks: ((j['tasks'] as List?) ?? const [])
            .map((t) => QuestTask.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Everything the app knows about the user's world.
class Snapshot {
  final List<Branch> branches;
  final List<Activity> activities;
  final List<Record> records;
  final List<Quest> quests;

  const Snapshot({
    this.branches = const [],
    this.activities = const [],
    this.records = const [],
    this.quests = const [],
  });

  static const empty = Snapshot();

  Snapshot copyWith({
    List<Branch>? branches,
    List<Activity>? activities,
    List<Record>? records,
    List<Quest>? quests,
  }) =>
      Snapshot(
        branches: branches ?? this.branches,
        activities: activities ?? this.activities,
        records: records ?? this.records,
        quests: quests ?? this.quests,
      );

  List<Activity> activitiesOf(String branchId) => activities.where((a) => a.branchId == branchId).toList();
  List<Record> recordsOfActivity(String activityId) =>
      records.where((r) => r.activityId == activityId).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  Map<String, dynamic> toJson() => {
        'branches': branches.map((e) => e.toJson()).toList(),
        'activities': activities.map((e) => e.toJson()).toList(),
        'records': records.map((e) => e.toJson()).toList(),
        'quests': quests.map((e) => e.toJson()).toList(),
      };

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) f) {
    final out = <T>[];
    for (final e in (raw as List?) ?? const []) {
      try {
        out.add(f(Map<String, dynamic>.from(e as Map)));
      } catch (_) {
        // skip a malformed entity instead of losing the whole file
      }
    }
    return out;
  }

  factory Snapshot.fromJson(Map<String, dynamic> j) => Snapshot(
        branches: _list(j['branches'], Branch.fromJson),
        activities: _list(j['activities'], Activity.fromJson),
        records: _list(j['records'], Record.fromJson),
        quests: _list(j['quests'], Quest.fromJson),
      );

  factory Snapshot.fromLists(Object? branches, Object? activities, Object? records, [Object? quests]) => Snapshot(
        branches: _list(branches, Branch.fromJson),
        activities: _list(activities, Activity.fromJson),
        records: _list(records, Record.fromJson),
        quests: _list(quests, Quest.fromJson),
      );
}

enum OpAction { create, update, delete }

enum EntityType { branch, activity, record, quest }

/// One pending change that must reach the GitHub repository.
class Operation {
  final String id;
  final OpAction action;
  final EntityType type;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool dispatched;

  /// The user's local calendar date when the operation was made (`YYYY-MM-DD`).
  /// The validator uses this, never the runner clock.
  final String localDate;

  Operation({
    required this.id,
    required this.action,
    required this.type,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.dispatched = false,
    String? localDate,
  }) : localDate = localDate ?? dateKey(DateTime.now());

  Operation markDispatched() => Operation(
      id: id,
      action: action,
      type: type,
      entityId: entityId,
      payload: payload,
      createdAt: createdAt,
      dispatched: true,
      localDate: localDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.name,
        'entity_type': type.name,
        'entity_id': entityId,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'dispatched': dispatched,
        'local_date': localDate,
      };

  factory Operation.fromJson(Map<String, dynamic> j) => Operation(
        id: j['id'] as String,
        action: OpAction.values.byName(j['action'] as String),
        type: EntityType.values.byName(j['entity_type'] as String),
        entityId: j['entity_id'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map? ?? const {}),
        createdAt: DateTime.parse(j['created_at'] as String),
        dispatched: j['dispatched'] as bool? ?? false,
        localDate: j['local_date'] as String?,
      );

  static String encodeList(List<Operation> ops) => jsonEncode(ops.map((o) => o.toJson()).toList());
  static List<Operation> decodeList(String? s) {
    if (s == null || s.isEmpty) return [];
    try {
      return (jsonDecode(s) as List).map((e) => Operation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }
}

enum OpOutcome { success, rejected, failed, pending }

class OpResult {
  final OpOutcome outcome;
  final String message;
  const OpResult(this.outcome, this.message);
  bool get ok => outcome == OpOutcome.success;
}
