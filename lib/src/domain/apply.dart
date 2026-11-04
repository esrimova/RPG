import 'goals.dart';
import 'models.dart';
import 'quests.dart';
import 'stats.dart';

/// Applies an operation to a snapshot with the same rules as
/// `.github/scripts/audit_entity.py`, so the local view matches what GitHub will
/// store. Returns an error message through [ApplyResult.error] when the
/// operation is invalid.
class ApplyResult {
  final Snapshot snapshot;
  final String? error;
  const ApplyResult(this.snapshot, [this.error]);
  bool get ok => error == null;
}

String _norm(String s) => s.trim().toLowerCase();

String? _goalError(Activity a) {
  if (a.goal == null && a.goalFieldId == null) return null;
  if (a.goal == null) return 'Goal field needs a goal';
  if (a.goal! <= 0) return 'Goal must be greater than 0';
  final f = a.fields.where((f) => f.id == a.goalFieldId).firstOrNull;
  if (f == null) return 'Goal needs a field to measure';
  if (f.type != FieldType.number && f.type != FieldType.duration) {
    return 'Goal field must be a number or duration field';
  }
  return null;
}

final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool _validDate(String d) {
  if (!_dateRe.hasMatch(d)) return false;
  final p = d.split('-').map(int.parse).toList();
  final t = DateTime.utc(p[0], p[1], p[2]);
  return t.year == p[0] && t.month == p[1] && t.day == p[2];
}

String? _questError(Quest q) {
  if (q.id.isEmpty) return 'Quest needs an id';
  if (q.name.trim().isEmpty) return 'Quest name is required';
  if (q.totalXp < 0) return 'Quest points cannot be negative';
  if (!_validDate(q.startDate) || !_validDate(q.endDate)) return 'Quest dates must be YYYY-MM-DD';
  if (q.startDate.compareTo(q.endDate) > 0) return 'Start date must not be after end date';
  if (q.auto) {
    final p = q.pattern;
    if (p == null) return 'Automatic quest needs a pattern';
    if (p.type == 'every_n_days' && p.n <= 0) return 'Pattern needs n greater than 0';
    if (p.type == 'weekdays' && (p.days.isEmpty || p.days.any((d) => d < 1 || d > 7))) {
      return 'Pattern needs weekdays 1-7';
    }
  }
  final ids = <String>{};
  for (final t in q.tasks) {
    if (t.id.isEmpty || !ids.add(t.id)) return 'Task ids must be unique';
    if (t.name.trim().isEmpty) return 'Task name is required';
    if (!_validDate(t.date)) return 'Task dates must be YYYY-MM-DD';
    if (t.date.compareTo(q.startDate) < 0 || t.date.compareTo(q.endDate) > 0) {
      return 'Task date is outside the quest range';
    }
  }
  return null;
}

ApplyResult applyOperation(Snapshot s, Operation op) {
  ApplyResult fail(String m) => ApplyResult(s, m);
  switch (op.type) {
    case EntityType.branch:
      final i = s.branches.indexWhere((b) => b.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Branch already exists');
      if (op.action != OpAction.create && i < 0) return fail('Branch does not exist');
      if (op.action == OpAction.delete) {
        final gone = s.activities.where((a) => a.branchId == op.entityId).map((a) => a.id).toSet();
        return ApplyResult(s.copyWith(
          branches: s.branches.where((b) => b.id != op.entityId).toList(),
          activities: s.activities.where((a) => a.branchId != op.entityId).toList(),
          records: s.records.where((r) => r.branchId != op.entityId && !gone.contains(r.activityId)).toList(),
        ));
      }
      final b = Branch.fromJson(op.payload);
      if (s.branches.any((o) => o.id != b.id && _norm(o.name) == _norm(b.name))) {
        return fail('A branch named "${b.name}" already exists');
      }
      final costsError = levelCostsError(b.levelCosts);
      if (costsError != null) return fail(costsError);
      final list = [...s.branches];
      if (i >= 0) {
        list[i] = b;
      } else {
        list.add(b);
      }
      return ApplyResult(s.copyWith(branches: list));
    case EntityType.activity:
      final i = s.activities.indexWhere((a) => a.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Activity already exists');
      if (op.action != OpAction.create && i < 0) return fail('Activity does not exist');
      if (op.action == OpAction.delete) {
        return ApplyResult(s.copyWith(
          activities: s.activities.where((a) => a.id != op.entityId).toList(),
          records: s.records.where((r) => r.activityId != op.entityId).toList(),
        ));
      }
      final a = Activity.fromJson(op.payload);
      if (!s.branches.any((b) => b.id == a.branchId)) return fail('Branch does not exist');
      if (s.activities.any((o) => o.id != a.id && o.branchId == a.branchId && _norm(o.name) == _norm(a.name))) {
        return fail('Activity "${a.name}" already exists in this branch');
      }
      final goalError = _goalError(a);
      if (goalError != null) return fail(goalError);
      final list = [...s.activities];
      if (i >= 0) {
        list[i] = a;
      } else {
        list.add(a);
      }
      return ApplyResult(s.copyWith(activities: list));
    case EntityType.record:
      final i = s.records.indexWhere((r) => r.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Record already exists');
      if (op.action != OpAction.create && i < 0) return fail('Record does not exist');
      if (op.action == OpAction.delete) {
        return ApplyResult(s.copyWith(
          records: s.records.where((r) => r.id != op.entityId).toList(),
        ));
      }
      final r = Record.fromJson(op.payload);
      final act = s.activities.where((a) => a.id == r.activityId).firstOrNull;
      if (act == null) return fail('Activity does not exist');
      for (final f in act.fields) {
        final v = r.values[f.id];
        if (f.required && (v == null || v == '')) return fail('Missing value for "${f.name}"');
      }
      if (op.action == OpAction.create && act.goal != null) {
        final gv = r.values[act.goalFieldId];
        if (gv is! num) return fail('Missing goal value');
        final effective = r.goal ?? act.goal!;
        if (effective <= 0) return fail('Goal must be greater than 0');
        if (r.xpEarned != goalXp(baseXp: act.baseXp, value: gv, goal: effective)) {
          return fail('Points do not match the goal');
        }
      }
      final list = [...s.records];
      if (i >= 0) {
        list[i] = r;
      } else {
        list.add(r);
      }
      return ApplyResult(s.copyWith(records: list));
    case EntityType.quest:
      final i = s.quests.indexWhere((q) => q.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Quest already exists');
      if (op.action != OpAction.create && i < 0) return fail('Quest does not exist');
      if (op.action == OpAction.delete) {
        return ApplyResult(s.copyWith(quests: s.quests.where((q) => q.id != op.entityId).toList()));
      }
      if (op.action == OpAction.update && questStatus(s.quests[i], op.localDate) != QuestStatus.active) {
        return fail('Quest is finished');
      }
      final Quest q;
      try {
        if (op.payload['distribution'] != 'auto' && op.payload['distribution'] != 'manual') {
          return fail('Distribution must be auto or manual');
        }
        q = Quest.fromJson(op.payload);
      } catch (_) {
        return fail('Invalid quest');
      }
      final qError = _questError(q);
      if (qError != null) return fail(qError);
      if (s.quests.any((o) => o.id != q.id && _norm(o.name) == _norm(q.name))) {
        return fail('A quest named "${q.name}" already exists');
      }
      if (i >= 0) {
        final old = s.quests[i];
        final kept = q.tasks.map((t) => t.id).toSet();
        final removed = old.tasks.any((t) => !kept.contains(t.id));
        if (removed && q.tasks.isNotEmpty && q.tasks.every((t) => t.doneAt != null)) {
          return fail('Cannot complete a quest by removing tasks');
        }
      }
      final list = [...s.quests];
      if (i >= 0) {
        list[i] = q;
      } else {
        list.add(q);
      }
      return ApplyResult(s.copyWith(quests: list));
    case EntityType.stat:
      final i = s.stats.indexWhere((e) => e.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Stat entry already exists');
      if (op.action != OpAction.create && i < 0) return fail('Stat entry does not exist');
      if (op.action == OpAction.update) return fail('Stat entries can only be added or deleted');
      if (op.action == OpAction.delete) {
        return ApplyResult(s.copyWith(stats: s.stats.where((e) => e.id != op.entityId).toList()));
      }
      final StatEntry e;
      try {
        e = StatEntry.fromJson(op.payload);
      } catch (_) {
        return fail('Invalid stat entry');
      }
      final eError = statError(e);
      if (eError != null) return fail(eError);
      return ApplyResult(s.copyWith(stats: [...s.stats, e]));
  }
}

/// Same rules as `level_costs_error` in the validator. Null when valid (or absent).
const maxLevelCosts = 200;

String? levelCostsError(List<int>? costs) {
  if (costs == null) return null;
  if (costs.isEmpty) return 'Level points must be a non-empty list';
  if (costs.length > maxLevelCosts) return 'At most $maxLevelCosts levels can be configured';
  if (costs.any((c) => c <= 0)) return 'Every level needs a whole number of points greater than 0';
  return null;
}

/// Re-applies pending operations over a base snapshot, silently skipping the
/// ones that no longer apply (they will be rejected by the server too).
Snapshot applyAll(Snapshot base, Iterable<Operation> ops) {
  var cur = base;
  for (final op in ops) {
    final r = applyOperation(cur, op);
    if (r.ok) cur = r.snapshot;
  }
  return cur;
}
