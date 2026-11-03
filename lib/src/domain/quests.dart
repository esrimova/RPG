import 'models.dart';

enum QuestStatus { active, completed, failed }

/// Local calendar date as `YYYY-MM-DD`. Strings in this form sort by date.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Completed: at least one task and all checked. Failed: not completed and
/// [today] is past the inclusive end date. Active otherwise.
QuestStatus questStatus(Quest q, String today) {
  if (q.tasks.isNotEmpty && q.tasks.every((t) => t.doneAt != null)) return QuestStatus.completed;
  if (today.compareTo(q.endDate) > 0) return QuestStatus.failed;
  return QuestStatus.active;
}

/// Quest XP is derived, never stored.
int questXp(Quest q, String today) {
  switch (questStatus(q, today)) {
    case QuestStatus.completed:
      return q.totalXp;
    case QuestStatus.failed:
      return 0;
    case QuestStatus.active:
      if (q.tasks.isEmpty) return 0;
      final checked = q.tasks.where((t) => t.doneAt != null).length;
      return (q.totalXp * checked) ~/ q.tasks.length;
  }
}

int totalQuestXp(Iterable<Quest> qs, String today) => qs.fold(0, (s, q) => s + questXp(q, today));

DateTime _parseDate(String s) {
  final p = s.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Dates in `[from, end]` matching [pattern]. `everyNDays` counts from [anchor]
/// (the quest start date); `weekdays` matches `DateTime.weekday` (1=Mon..7=Sun).
List<String> _eligibleDates(String from, String end, QuestPattern pattern, String anchor) {
  final stop = _parseDate(end);
  final anchorDay = _parseDate(anchor);
  final out = <String>[];
  for (var d = _parseDate(from); !d.isAfter(stop); d = d.add(const Duration(days: 1))) {
    final bool match;
    if (pattern.type == 'weekdays') {
      match = pattern.days.contains(d.weekday);
    } else {
      final diff = d.difference(anchorDay).inDays;
      match = pattern.n > 0 && diff >= 0 && diff % pattern.n == 0;
    }
    if (match) out.add(dateKey(d));
  }
  return out;
}

/// Task i of [count] gets `eligible[floor(i * eligible.length / count)]`, so
/// dates never decrease and repeat when tasks outnumber eligible dates.
/// Returns `[]` when there is no eligible date.
List<String> spreadDates({
  required String from,
  required String end,
  required QuestPattern pattern,
  required String anchor,
  required int count,
}) {
  if (count <= 0) return [];
  final eligible = _eligibleDates(from, end, pattern, anchor);
  if (eligible.isEmpty) return [];
  return [for (var i = 0; i < count; i++) eligible[(i * eligible.length) ~/ count]];
}

String _maxDate(String a, String b) => a.compareTo(b) >= 0 ? a : b;
String _minDate(String a, String b) => a.compareTo(b) <= 0 ? a : b;

/// Re-dates the open tasks (unchecked, `date >= today`) of an auto quest.
/// Each contiguous run of open tasks is spread separately, bounded by the
/// dates of the locked tasks next to it. Throws if a run has no eligible date.
Quest respreadTasks(Quest q, String today) {
  final pattern = q.pattern;
  if (!q.auto || pattern == null) return q;
  bool open(QuestTask t) => t.doneAt == null && t.date.compareTo(today) >= 0;
  final tasks = [...q.tasks];
  var i = 0;
  while (i < tasks.length) {
    if (!open(tasks[i])) {
      i++;
      continue;
    }
    var j = i;
    while (j < tasks.length && open(tasks[j])) {
      j++;
    }
    var from = _maxDate(q.startDate, today);
    var to = q.endDate;
    if (i > 0) from = _maxDate(from, tasks[i - 1].date);
    if (j < tasks.length) to = _minDate(to, tasks[j].date);
    final dates = spreadDates(from: from, end: to, pattern: pattern, anchor: q.startDate, count: j - i);
    if (dates.isEmpty) throw StateError('No matching dates left');
    for (var k = i; k < j; k++) {
      tasks[k] = tasks[k].copyWith(date: dates[k - i]);
    }
    i = j;
  }
  return q.copyWith(tasks: tasks);
}
