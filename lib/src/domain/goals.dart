/// Points for a record against an activity goal:
/// `floor(baseXp * value / goal + 0.5)`; 0 when [value] is not positive.
/// Must match `goal_xp` in `.github/scripts/audit_entity.py`.
int goalXp({required int baseXp, required num value, required num goal}) {
  if (goal <= 0) throw ArgumentError.value(goal, 'goal', 'must be greater than 0');
  if (value <= 0) return 0;
  return (baseXp * value / goal + 0.5).floor();
}
