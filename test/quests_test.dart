import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_rpg/src/domain/apply.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
import 'package:personal_life_rpg/src/domain/progress.dart';
import 'package:personal_life_rpg/src/domain/quests.dart';

Quest quest({int tasks = 4, int checked = 0, String start = '2026-11-01', String end = '2026-11-10', int xp = 100}) {
  return Quest(
    id: 'q1',
    name: 'Quest',
    startDate: start,
    endDate: end,
    totalXp: xp,
    createdAt: DateTime(2026, 11, 1),
    tasks: [
      for (var i = 0; i < tasks; i++)
        QuestTask(id: 't$i', name: 'Task $i', date: '2026-11-0${i + 1}', doneAt: i < checked ? DateTime(2026, 11, 2) : null),
    ],
  );
}

void main() {
  group('quest status and xp', () {
    test('3 of 4 checked inside range is active with floor xp', () {
      final q = quest(checked: 3);
      expect(questStatus(q, '2026-11-05'), QuestStatus.active);
      expect(questXp(q, '2026-11-05'), 75);
    });

    test('all checked is completed, even after end_date', () {
      final q = quest(checked: 4);
      expect(questStatus(q, '2026-11-05'), QuestStatus.completed);
      expect(questXp(q, '2026-11-05'), 100);
      expect(questStatus(q, '2026-12-01'), QuestStatus.completed);
      expect(questXp(q, '2026-12-01'), 100);
    });

    test('on end_date still active, one day later failed', () {
      final q = quest(checked: 2);
      expect(questStatus(q, '2026-11-10'), QuestStatus.active);
      expect(questXp(q, '2026-11-10'), 50);
      expect(questStatus(q, '2026-11-11'), QuestStatus.failed);
      expect(questXp(q, '2026-11-11'), 0);
    });

    test('zero tasks is active then failed, never completed', () {
      final q = quest(tasks: 0);
      expect(questStatus(q, '2026-11-05'), QuestStatus.active);
      expect(questXp(q, '2026-11-05'), 0);
      expect(questStatus(q, '2026-11-11'), QuestStatus.failed);
      expect(questXp(q, '2026-11-11'), 0);
    });

    test('totalQuestXp and playerXp add up', () {
      final done = quest(checked: 4);
      final half = quest(checked: 2);
      expect(totalQuestXp([done, half], '2026-11-05'), 150);
      final s = Snapshot(quests: [done, half]);
      expect(playerXp(s, '2026-11-05'), 150);
    });

    test('dateKey formats local date', () {
      expect(dateKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });
  });

  group('quest json', () {
    test('round trips with pattern and done_at', () {
      final q = Quest(
        id: 'q1',
        name: 'Run',
        description: 'desc',
        startDate: '2026-11-01',
        endDate: '2026-11-10',
        totalXp: 80,
        auto: true,
        pattern: QuestPattern.weekdays([1, 5]),
        tasks: [
          QuestTask(id: 't1', name: 'A', date: '2026-11-02', doneAt: DateTime.utc(2026, 11, 2, 10)),
          const QuestTask(id: 't2', name: 'B', date: '2026-11-06'),
        ],
        createdAt: DateTime.utc(2026, 11, 1),
      );
      final j = q.toJson();
      expect(j['start_date'], '2026-11-01');
      expect(j['total_xp'], 80);
      expect(j['distribution'], 'auto');
      expect(j['pattern'], {'type': 'weekdays', 'days': [1, 5]});
      final back = Quest.fromJson(Map<String, dynamic>.from(j));
      expect(back.toJson(), j);
      expect(back.tasks.first.doneAt, DateTime.utc(2026, 11, 2, 10));
      expect(back.tasks.last.doneAt, isNull);
    });

    test('every_n_days pattern json and manual distribution', () {
      final q = quest().copyWith(auto: false, pattern: QuestPattern.everyNDays(2));
      final j = q.toJson();
      expect(j['distribution'], 'manual');
      expect(j['pattern'], {'type': 'every_n_days', 'n': 2});
    });

    test('Snapshot.fromLists skips a malformed quest', () {
      final good = quest().toJson();
      final s = Snapshot.fromLists(const [], const [], const [], [good, {'id': 'bad'}]);
      expect(s.quests.length, 1);
      expect(s.quests.first.id, 'q1');
    });

    test('Snapshot json keeps quests', () {
      final s = Snapshot(quests: [quest(checked: 1)]);
      final back = Snapshot.fromJson(Map<String, dynamic>.from(s.toJson()));
      expect(back.quests.single.tasks.first.doneAt, isNotNull);
    });
  });

  group('operation local_date', () {
    test('round trips and defaults to today', () {
      final o = Operation(
          id: 'o', action: OpAction.create, type: EntityType.quest, entityId: 'q', payload: const {}, createdAt: DateTime(2026, 1, 1));
      expect(o.localDate, dateKey(DateTime.now()));
      final j = o.toJson();
      expect(j['local_date'], o.localDate);
      expect(j['entity_type'], 'quest');
      final custom = Operation.fromJson({...j, 'local_date': '2026-02-03'});
      expect(custom.localDate, '2026-02-03');
      expect(custom.markDispatched().localDate, '2026-02-03');
    });
  });

  group('apply keeps quests', () {
    Operation op(OpAction a, EntityType t, String id, Map<String, dynamic> p) =>
        Operation(id: 'o$id', action: a, type: t, entityId: id, payload: p, createdAt: DateTime(2026, 1, 1));

    test('branch, activity and record operations carry quests over', () {
      var s = Snapshot(quests: [quest(checked: 1)]);
      final b = Branch(id: 'b1', name: 'Body', color: 1, iconCodePoint: 2, createdAt: DateTime(2026, 1, 1));
      s = applyOperation(s, op(OpAction.create, EntityType.branch, 'b1', b.toJson())).snapshot;
      expect(s.quests.length, 1);
      final a = Activity(id: 'a1', branchId: 'b1', name: 'Run', color: 1, iconCodePoint: 2, createdAt: DateTime(2026, 1, 1));
      s = applyOperation(s, op(OpAction.create, EntityType.activity, 'a1', a.toJson())).snapshot;
      expect(s.quests.length, 1);
      final r = Record(
          id: 'r1', activityId: 'a1', branchId: 'b1', timestamp: DateTime(2026, 1, 2), values: const {}, xpEarned: 10);
      s = applyOperation(s, op(OpAction.create, EntityType.record, 'r1', r.toJson())).snapshot;
      expect(s.quests.length, 1);
      s = applyOperation(s, op(OpAction.delete, EntityType.record, 'r1', {'id': 'r1'})).snapshot;
      expect(s.quests.length, 1);
      s = applyOperation(s, op(OpAction.delete, EntityType.activity, 'a1', {'id': 'a1'})).snapshot;
      expect(s.quests.length, 1);
      s = applyOperation(s, op(OpAction.update, EntityType.branch, 'b1', b.copyWith(name: 'Mind').toJson())).snapshot;
      expect(s.quests.length, 1);
      s = applyOperation(s, op(OpAction.delete, EntityType.branch, 'b1', {'id': 'b1'})).snapshot;
      expect(s.quests.length, 1);
    });
  });

  group('task distribution', () {
    QuestTask t(int i, String date, {bool done = false}) =>
        QuestTask(id: 't$i', name: 'T$i', date: date, doneAt: done ? DateTime(2026, 11, 2) : null);
    Quest auto(List<QuestTask> tasks, {QuestPattern? p, String start = '2026-11-10', String end = '2026-12-20'}) => Quest(
        id: 'q', name: 'Q', startDate: start, endDate: end, totalXp: 100, auto: true,
        pattern: p ?? QuestPattern.everyNDays(1), tasks: tasks, createdAt: DateTime(2026, 11, 1));

    test('weekdays Mon/Fri over 20 tasks', () {
      final d = spreadDates(from: '2026-11-10', end: '2026-12-20', pattern: QuestPattern.weekdays([1, 5]), anchor: '2026-11-10', count: 20);
      expect(d.length, 20);
      for (final s in d) {
        expect([1, 5], contains(DateTime.parse(s).weekday));
        expect(s.compareTo('2026-11-10') >= 0 && s.compareTo('2026-12-20') <= 0, isTrue);
      }
      for (var i = 1; i < d.length; i++) {
        expect(d[i].compareTo(d[i - 1]) >= 0, isTrue);
      }
    });

    test('every 2 days starts on from and steps 2', () {
      final d = spreadDates(from: '2026-11-10', end: '2026-12-20', pattern: QuestPattern.everyNDays(2), anchor: '2026-11-10', count: 20);
      expect(d.first, '2026-11-10');
      for (var i = 1; i < d.length; i++) {
        expect(DateTime.parse(d[i]).difference(DateTime.parse(d[i - 1])).inDays, 2);
      }
    });

    test('every N days is anchored at start_date, not from', () {
      final d = spreadDates(from: '2026-11-11', end: '2026-11-20', pattern: QuestPattern.everyNDays(3), anchor: '2026-11-10', count: 3);
      expect(d, ['2026-11-13', '2026-11-16', '2026-11-19']);
    });

    test('more tasks than dates repeats in order', () {
      final d = spreadDates(from: '2026-11-10', end: '2026-11-12', pattern: QuestPattern.everyNDays(1), anchor: '2026-11-10', count: 6);
      expect(d, ['2026-11-10', '2026-11-10', '2026-11-11', '2026-11-11', '2026-11-12', '2026-11-12']);
    });

    test('no eligible dates returns empty', () {
      expect(spreadDates(from: '2026-11-10', end: '2026-11-10', pattern: QuestPattern.weekdays([3]), anchor: '2026-11-10', count: 2), isEmpty);
      expect(spreadDates(from: '2026-11-12', end: '2026-11-10', pattern: QuestPattern.everyNDays(1), anchor: '2026-11-10', count: 2), isEmpty);
    });

    test('respread keeps past/checked tasks and moves open ones to today or later', () {
      final tasks = [
        for (var i = 0; i < 10; i++)
          t(i, dateKey(DateTime(2026, 11, 10).add(Duration(days: i * 5))), done: i < 5)
      ];
      final q = auto(tasks);
      final r = respreadTasks(q, '2026-12-01');
      for (var i = 0; i < 5; i++) {
        expect(r.tasks[i].date, q.tasks[i].date);
      }
      for (var i = 5; i < 10; i++) {
        expect(r.tasks[i].date.compareTo('2026-12-01') >= 0, isTrue);
      }
    });

    test('today counts as open, checked future task bounds earlier open ones', () {
      final q = auto([t(0, '2026-11-12'), t(1, '2026-11-13'), t(2, '2026-11-14', done: true), t(3, '2026-11-15'), t(4, '2026-11-16')]);
      final r = respreadTasks(q, '2026-11-12');
      expect(r.tasks[2].date, '2026-11-14');
      expect(r.tasks[2].doneAt, isNotNull);
      expect(r.tasks[0].date.compareTo('2026-11-14') <= 0, isTrue);
      expect(r.tasks[1].date.compareTo('2026-11-14') <= 0, isTrue);
      expect(r.tasks[3].date.compareTo('2026-11-14') >= 0, isTrue);
      expect(r.tasks[0].date.compareTo('2026-11-12') >= 0, isTrue);
      expect(r.tasks[4].date.compareTo(r.tasks[3].date) >= 0, isTrue);
    });

    test('manual quest is returned identical', () {
      final q = auto([t(0, '2026-11-12')]).copyWith(auto: false);
      expect(identical(respreadTasks(q, '2026-11-12'), q), isTrue);
    });

    test('open run with no eligible dates throws', () {
      final q = auto([t(0, '2026-11-12'), t(1, '2026-11-13', done: true), t(2, '2026-11-13')], p: QuestPattern.weekdays([1]));
      expect(() => respreadTasks(q, '2026-11-12'), throwsA(isA<StateError>()));
      final q2 = auto([t(0, '2026-12-19')], p: QuestPattern.weekdays([1]));
      expect(() => respreadTasks(q2, '2026-12-19'), throwsA(isA<StateError>()));
    });
  });
}
