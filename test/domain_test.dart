import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_rpg/src/domain/apply.dart';
import 'package:personal_life_rpg/src/domain/goals.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
import 'package:personal_life_rpg/src/domain/progress.dart';

Branch branch([String id = 'b1', String name = 'Physical']) =>
    Branch(id: id, name: name, color: 0xFF00F0FF, iconCodePoint: 1, createdAt: DateTime(2026, 1, 1));

Activity activity({String id = 'a1', String bid = 'b1', String name = 'Push-ups', List<ActivityField>? fields}) => Activity(
      id: id,
      branchId: bid,
      name: name,
      color: 1,
      iconCodePoint: 2,
      fields: fields ?? const [ActivityField(id: 'reps', name: 'Reps', type: FieldType.number)],
      createdAt: DateTime(2026, 1, 1),
    );

Record rec(String id, DateTime t, {num reps = 10, String aid = 'a1', String bid = 'b1', int xp = 10}) =>
    Record(id: id, activityId: aid, branchId: bid, timestamp: t, values: {'reps': reps}, xpEarned: xp);

Operation op(OpAction a, EntityType t, String id, Map<String, dynamic> p) => Operation(
    id: 'op_$id${a.name}', action: a, type: t, entityId: id, payload: p, createdAt: DateTime(2026, 1, 1));

void main() {
  group('applyOperation', () {
    test('starts empty and creates a branch, activity, record in order', () {
      var s = Snapshot.empty;
      s = applyOperation(s, op(OpAction.create, EntityType.branch, 'b1', branch().toJson())).snapshot;
      s = applyOperation(s, op(OpAction.create, EntityType.activity, 'a1', activity().toJson())).snapshot;
      final r = applyOperation(s, op(OpAction.create, EntityType.record, 'r1', rec('r1', DateTime(2026, 1, 2)).toJson()));
      expect(r.ok, isTrue);
      expect(r.snapshot.records.single.values['reps'], 10);
    });

    test('rejects duplicates and orphans', () {
      final s = Snapshot(branches: [branch()]);
      expect(applyOperation(s, op(OpAction.create, EntityType.branch, 'b1', branch().toJson())).ok, isFalse);
      expect(applyOperation(s, op(OpAction.create, EntityType.branch, 'b2', branch('b2', ' physical ').toJson())).ok, isFalse);
      expect(applyOperation(Snapshot.empty, op(OpAction.create, EntityType.activity, 'a1', activity().toJson())).ok, isFalse);
    });

    test('record must satisfy required fields', () {
      final s = Snapshot(branches: [branch()], activities: [activity()]);
      final bad = Record(id: 'r1', activityId: 'a1', branchId: 'b1', timestamp: DateTime(2026), values: {}, xpEarned: 1);
      expect(applyOperation(s, op(OpAction.create, EntityType.record, 'r1', bad.toJson())).ok, isFalse);
    });

    test('deleting a branch cascades', () {
      final s = Snapshot(branches: [branch()], activities: [activity()], records: [rec('r1', DateTime(2026))]);
      final r = applyOperation(s, op(OpAction.delete, EntityType.branch, 'b1', {'id': 'b1'}));
      expect(r.snapshot.activities, isEmpty);
      expect(r.snapshot.records, isEmpty);
    });

    test('json round trip keeps fields', () {
      final a = Activity.fromJson(activity().toJson());
      expect(a.fields.single.type, FieldType.number);
    });
  });

  group('goals', () {
    Activity goalAct({double? goal = 10, String? fieldId = 'reps', List<ActivityField>? fields}) => Activity(
          id: 'a1',
          branchId: 'b1',
          name: 'Push-ups',
          color: 1,
          iconCodePoint: 2,
          baseXp: 10,
          goal: goal,
          goalFieldId: fieldId,
          fields: fields ?? const [ActivityField(id: 'reps', name: 'Reps', type: FieldType.number)],
          createdAt: DateTime(2026, 1, 1),
        );
    final base = Snapshot(branches: [branch()]);
    ApplyResult put(Snapshot s, Activity a) => applyOperation(s, op(OpAction.create, EntityType.activity, a.id, a.toJson()));

    test('goalXp maths', () {
      expect(goalXp(baseXp: 10, value: 5, goal: 10), 5);
      expect(goalXp(baseXp: 10, value: 20, goal: 10), 20);
      expect(goalXp(baseXp: 10, value: 0, goal: 10), 0);
      expect(goalXp(baseXp: 10, value: 1, goal: 4), 3);
      expect(() => goalXp(baseXp: 10, value: 1, goal: 0), throwsArgumentError);
    });

    test('activity goal validation', () {
      expect(put(base, goalAct(fieldId: null)).ok, isFalse);
      expect(
          put(base, goalAct(fieldId: 't', fields: const [ActivityField(id: 't', name: 'Note', type: FieldType.text)])).ok,
          isFalse);
      expect(put(base, goalAct(fieldId: 'nope')).ok, isFalse);
      expect(put(base, goalAct(goal: 0)).ok, isFalse);
      expect(put(base, goalAct(goal: -3)).ok, isFalse);
      expect(put(base, goalAct()).ok, isTrue);
    });

    test('json round trip keeps goal', () {
      final j = goalAct().toJson();
      expect(j['goal'], 10.0);
      expect(j['goal_field_id'], 'reps');
      final a = Activity.fromJson(j);
      expect(a.goal, 10.0);
      expect(a.goalFieldId, 'reps');
      expect(Activity.fromJson(activity().toJson()).goal, isNull);
    });

    test('record xp must equal goal points', () {
      final s = put(base, goalAct()).snapshot;
      Record r(int xp, {double? goal}) => Record(
          id: 'r1', activityId: 'a1', branchId: 'b1', timestamp: DateTime(2026, 1, 2), values: {'reps': 5}, xpEarned: xp, goal: goal);
      ApplyResult rec1(Record x) => applyOperation(s, op(OpAction.create, EntityType.record, 'r1', x.toJson()));
      expect(rec1(r(10)).ok, isFalse);
      expect(rec1(r(5)).ok, isTrue);
      expect(rec1(r(10, goal: 5)).ok, isTrue);
      expect(Record.fromJson(r(5, goal: 5).toJson()).goal, 5.0);
    });

    test('existing record unchanged after goal edit', () {
      var s = put(base, goalAct()).snapshot;
      final r = Record(
          id: 'r1', activityId: 'a1', branchId: 'b1', timestamp: DateTime(2026, 1, 2), values: {'reps': 5}, xpEarned: 5, goal: 10);
      s = applyOperation(s, op(OpAction.create, EntityType.record, 'r1', r.toJson())).snapshot;
      final edited = goalAct(goal: 20);
      final res = applyOperation(s, op(OpAction.update, EntityType.activity, 'a1', edited.toJson()));
      expect(res.ok, isTrue);
      expect(res.snapshot.records.single.xpEarned, 5);
      expect(res.snapshot.records.single.goal, 10.0);
    });
  });

  group('progress', () {
    test('level thresholds', () {
      expect(levelForXp(0).level, 1);
      expect(levelForXp(99).level, 1);
      expect(levelForXp(100).level, 2);
      expect(levelForXp(299).level, 2);
      expect(levelForXp(300).level, 3);
      expect(levelForXp(100).xpIntoLevel, 0);
    });

    test('streak counts consecutive days ending today or yesterday', () {
      final now = DateTime(2026, 3, 10, 12);
      final recs = [for (final d in [10, 9, 8, 5, 4]) rec('r$d', DateTime(2026, 3, d, 8))];
      final s = computeStreak(recs, now);
      expect(s.current, 3);
      expect(s.longest, 3);
      expect(computeStreak(recs.where((r) => r.timestamp.day != 10), now).current, 2);
      expect(computeStreak(const [], now).current, 0);
    });

    test('improvement needs 3 records and badge needs 1.5x', () {
      final a = activity();
      final recs = [rec('1', DateTime(2026, 1, 1), reps: 3), rec('2', DateTime(2026, 1, 5), reps: 6), rec('3', DateTime(2026, 1, 9), reps: 10)];
      final s = Snapshot(branches: [branch()], activities: [a], records: recs);
      final imp = improvement(s, a)!;
      expect(imp.first, 3);
      expect(imp.latest, 10);
      expect(computeBadges(s, DateTime(2026, 1, 10)).any((b) => b.id == 'imp_a1'), isTrue);
      expect(improvement(Snapshot(activities: [a], records: recs.take(2).toList()), a), isNull);
    });
  });
}
