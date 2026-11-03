import 'models.dart';
import 'quests.dart';

/// Level maths. Going from level n to n+1 costs 100*n XP, so reaching level L
/// takes 50*L*(L-1) XP in total.
class LevelInfo {
  final int level;
  final int xpIntoLevel;
  final int xpForNext;
  const LevelInfo(this.level, this.xpIntoLevel, this.xpForNext);
  double get fraction => xpForNext == 0 ? 0 : xpIntoLevel / xpForNext;
}

LevelInfo levelForXp(int totalXp) {
  var level = 1;
  var remaining = totalXp < 0 ? 0 : totalXp;
  while (remaining >= level * 100) {
    remaining -= level * 100;
    level++;
  }
  return LevelInfo(level, remaining, level * 100);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class StreakInfo {
  final int current;
  final int longest;
  const StreakInfo(this.current, this.longest);
}

StreakInfo computeStreak(Iterable<Record> records, DateTime now) {
  final days = records.map((r) => _day(r.timestamp.toLocal())).toSet().toList()..sort();
  if (days.isEmpty) return const StreakInfo(0, 0);
  var longest = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    run = days[i].difference(days[i - 1]).inDays == 1 ? run + 1 : 1;
    if (run > longest) longest = run;
  }
  final today = _day(now);
  var cursor = days.contains(today) ? today : today.subtract(const Duration(days: 1));
  var current = 0;
  final set = days.toSet();
  while (set.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return StreakInfo(current, longest);
}

class Badge {
  final String id;
  final String title;
  final String description;
  const Badge(this.id, this.title, this.description);
}

/// Badges are computed from the history, never stored, so they can't drift.
List<Badge> computeBadges(Snapshot s, DateTime now) {
  final out = <Badge>[];
  final n = s.records.length;
  if (n >= 1) out.add(const Badge('first', 'First step', 'Recorded your first activity'));
  if (n >= 10) out.add(const Badge('r10', 'Getting going', '10 activities recorded'));
  if (n >= 50) out.add(const Badge('r50', 'Dedicated', '50 activities recorded'));
  if (n >= 100) out.add(const Badge('r100', 'Centurion', '100 activities recorded'));
  final streak = computeStreak(s.records, now);
  if (streak.longest >= 3) out.add(const Badge('s3', '3-day streak', 'Active 3 days in a row'));
  if (streak.longest >= 7) out.add(const Badge('s7', 'Week streak', 'Active 7 days in a row'));
  if (streak.longest >= 30) out.add(const Badge('s30', 'Month streak', 'Active 30 days in a row'));
  final weekAgo = now.subtract(const Duration(days: 7));
  final recentBranches = s.records.where((r) => r.timestamp.isAfter(weekAgo)).map((r) => r.branchId).toSet();
  if (recentBranches.length >= 3) out.add(const Badge('bal', 'Balanced week', 'Active in 3+ branches this week'));
  for (final a in s.activities) {
    final p = improvement(s, a);
    if (p != null && p.ratio >= 1.5) {
      out.add(Badge('imp_${a.id}', 'Progress: ${a.name}', '${p.fieldName} went from ${_fmt(p.first)} to ${_fmt(p.latest)}'));
    }
  }
  return out;
}

String _fmt(num v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

class Improvement {
  final String fieldName;
  final num first;
  final num latest;
  const Improvement(this.fieldName, this.first, this.latest);
  double get ratio => first <= 0 ? 0 : latest / first;
}

/// Compares the first and latest value of the activity's first numeric field,
/// needing at least 3 records so a single outlier doesn't count as progress.
Improvement? improvement(Snapshot s, Activity a) {
  final field = a.fields.where((f) => f.type == FieldType.number || f.type == FieldType.duration).firstOrNull;
  if (field == null) return null;
  final recs = s.recordsOfActivity(a.id).reversed.where((r) => r.values[field.id] is num).toList();
  if (recs.length < 3) return null;
  return Improvement(field.name, recs.first.values[field.id] as num, recs.last.values[field.id] as num);
}

int xpOf(Iterable<Record> records) => records.fold(0, (s, r) => s + r.xpEarned);

/// Record XP plus the derived XP of every quest.
int playerXp(Snapshot s, String today) => xpOf(s.records) + totalQuestXp(s.quests, today);
