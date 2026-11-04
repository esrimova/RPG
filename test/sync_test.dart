import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
import 'package:personal_life_rpg/src/domain/quests.dart' show dateKey;

import 'controller_test.dart' show setup, branch, activity;

/// Order-independent text form of everything the game stores.
String canon(Snapshot s) {
  final j = s.toJson();
  return jsonEncode({
    for (final e in j.entries)
      e.key: ([...(e.value as List)]..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String))),
  });
}

void main() {
  test('push mirrors the app in GitHub: inserts, updates and deletes of every kind of data', () async {
    final (c, remote) = await setup();
    final now = DateTime.now();
    final today = dateKey(now);
    final later = dateKey(now.add(const Duration(days: 10)));

    Record rec(String id, String act, String br) => Record(
        id: id, activityId: act, branchId: br, timestamp: now, values: const {'min': 600}, xpEarned: 10);
    Quest quest({String description = ''}) => Quest(
          id: 'q1',
          name: 'Quest',
          description: description,
          startDate: today,
          endDate: later,
          totalXp: 100,
          tasks: [QuestTask(id: 't1', name: 'Task', date: today)],
          createdAt: now,
        );

    Future<void> pushAndCompare(String step) async {
      final entry = await c.pushNow();
      expect(entry, isNotNull, reason: step);
      expect(entry!.rejected + entry.failed, 0, reason: step);
      expect(c.state.ops, isEmpty, reason: '$step: nothing left pending');
      expect(canon(remote.data), canon(c.state.view), reason: '$step: GitHub equals the app');
    }

    // 1. inserts
    await c.saveBranch(branch('b1', 'Physical'), isNew: true);
    await c.saveBranch(branch('b2', 'Mind'), isNew: true);
    await c.saveActivity(activity('a1', 'b1'), isNew: true);
    await c.saveActivity(activity('a2', 'b2'), isNew: true);
    await c.addRecord(rec('r1', 'a1', 'b1'));
    await c.addRecord(rec('r2', 'a2', 'b2'));
    await c.saveQuest(quest(), isNew: true);
    await c.addStat(StatEntry(id: 's1', timestamp: now, values: const {'weight': 80}));
    await c.addStat(StatEntry(id: 's2', timestamp: now, values: const {'weight': 79, 'fat': 18}));
    await pushAndCompare('inserts');
    expect(remote.data.stats, hasLength(2));
    expect(remote.data.records, hasLength(2));

    // 2. updates and deletes together
    await c.saveBranch(c.state.view.branches.firstWhere((b) => b.id == 'b1').copyWith(name: 'Body', levelCosts: [500, 900]), isNew: false);
    await c.saveActivity(c.state.view.activities.firstWhere((a) => a.id == 'a1').copyWith(name: 'Running', baseXp: 25), isNew: false);
    await c.saveQuest(quest(description: 'changed'), isNew: false);
    await c.deleteRecord('r1');
    await c.deleteStat('s1');
    await c.deleteBranch('b2'); // takes its activity and record with it
    await pushAndCompare('updates and deletes');
    expect(remote.data.branches.single.name, 'Body');
    expect(remote.data.branches.single.levelCosts, [500, 900]);
    expect(remote.data.activities.single.name, 'Running');
    expect(remote.data.quests.single.description, 'changed');
    expect(remote.data.records, isEmpty);
    expect(remote.data.stats.map((s) => s.id), ['s2']);

    // 3. delete everything that is left
    await c.deleteActivity('a1');
    await c.deleteQuest('q1');
    await c.deleteStat('s2');
    await c.deleteBranch('b1');
    await pushAndCompare('delete the rest');
    expect(canon(remote.data), canon(Snapshot.empty));
  });

  test('a record created and deleted before pushing leaves GitHub unchanged', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch('b1', 'Physical'), isNew: true);
    await c.saveActivity(activity('a1', 'b1'), isNew: true);
    await c.pushNow();
    final before = canon(remote.data);
    await c.addRecord(Record(
        id: 'r1', activityId: 'a1', branchId: 'b1', timestamp: DateTime.now(), values: const {'min': 60}, xpEarned: 10));
    await c.deleteRecord('r1');
    await c.pushNow();
    expect(canon(remote.data), before);
    expect(canon(remote.data), canon(c.state.view));
  });
}
