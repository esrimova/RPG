import 'models.dart';

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

ApplyResult applyOperation(Snapshot s, Operation op) {
  ApplyResult fail(String m) => ApplyResult(s, m);
  switch (op.type) {
    case EntityType.branch:
      final i = s.branches.indexWhere((b) => b.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Branch already exists');
      if (op.action != OpAction.create && i < 0) return fail('Branch does not exist');
      if (op.action == OpAction.delete) {
        final gone = s.activities.where((a) => a.branchId == op.entityId).map((a) => a.id).toSet();
        return ApplyResult(Snapshot(
          branches: s.branches.where((b) => b.id != op.entityId).toList(),
          activities: s.activities.where((a) => a.branchId != op.entityId).toList(),
          records: s.records.where((r) => r.branchId != op.entityId && !gone.contains(r.activityId)).toList(),
        ));
      }
      final b = Branch.fromJson(op.payload);
      if (s.branches.any((o) => o.id != b.id && _norm(o.name) == _norm(b.name))) {
        return fail('A branch named "${b.name}" already exists');
      }
      final list = [...s.branches];
      if (i >= 0) {
        list[i] = b;
      } else {
        list.add(b);
      }
      return ApplyResult(Snapshot(branches: list, activities: s.activities, records: s.records));
    case EntityType.activity:
      final i = s.activities.indexWhere((a) => a.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Activity already exists');
      if (op.action != OpAction.create && i < 0) return fail('Activity does not exist');
      if (op.action == OpAction.delete) {
        return ApplyResult(Snapshot(
          branches: s.branches,
          activities: s.activities.where((a) => a.id != op.entityId).toList(),
          records: s.records.where((r) => r.activityId != op.entityId).toList(),
        ));
      }
      final a = Activity.fromJson(op.payload);
      if (!s.branches.any((b) => b.id == a.branchId)) return fail('Branch does not exist');
      if (s.activities.any((o) => o.id != a.id && o.branchId == a.branchId && _norm(o.name) == _norm(a.name))) {
        return fail('Activity "${a.name}" already exists in this branch');
      }
      final list = [...s.activities];
      if (i >= 0) {
        list[i] = a;
      } else {
        list.add(a);
      }
      return ApplyResult(Snapshot(branches: s.branches, activities: list, records: s.records));
    case EntityType.record:
      final i = s.records.indexWhere((r) => r.id == op.entityId);
      if (op.action == OpAction.create && i >= 0) return fail('Record already exists');
      if (op.action != OpAction.create && i < 0) return fail('Record does not exist');
      if (op.action == OpAction.delete) {
        return ApplyResult(Snapshot(
          branches: s.branches,
          activities: s.activities,
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
      final list = [...s.records];
      if (i >= 0) {
        list[i] = r;
      } else {
        list.add(r);
      }
      return ApplyResult(Snapshot(branches: s.branches, activities: s.activities, records: list));
  }
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
