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
