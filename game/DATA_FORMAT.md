# Data format (for any AI or script that reads this repo)

All game data lives in this `game/` folder, apart from the application code. The app keeps five JSON arrays here (`quests.json` and `stats.json` appear once the first quest or stats entry is pushed). They are the source of truth when GitHub storage is connected. Repositories created before this folder existed kept the files at the repo root: the app still reads them from there, and the workflow moves them into `game/` on the next push. Read them freely. To change data, send the same operations the app sends (see "Writing"), do not edit the files by hand.

## `branches.json` - areas of life
`id`, `name`, `description`, `accent_color` (ARGB int), `icon_code_point`, `created_at` (ISO 8601), and optional `level_costs`.

`level_costs` is a list of whole numbers > 0 (at most 200): the XP needed to leave each level of this branch, in order. Entry 0 is the cost of level 1 -> 2, entry 1 of level 2 -> 3, and so on, and the amounts may differ freely (normally growing). Levels past the end of the list cost the same as the last entry. Absent means the default curve (see Derived numbers).

## `activities.json` - things you do inside a branch
`id`, `branch_id`, `name`, `description`, `accent_color`, `icon_code_point`, `base_xp` (XP earned per record), `created_at`, and `fields`: the columns of that activity's table.

Each field: `id`, `name`, `type` (`number`, `duration`, `scale`, `yesno` or `text`), optional `unit`, `required`.
- `duration` values are stored in **seconds**.
- `scale` is 1-10. `yesno` is true/false.

Optional goal on the activity: `goal` (number > 0) and `goal_field_id` (id of one of its `number` or `duration` fields). They only exist together. The goal is in the field's own units (a `duration` goal is in seconds). `base_xp` is what reaching 100% of the goal pays. Activities without a goal pay `base_xp` per record.

## `records.json` - one row per time you did an activity
`id`, `activity_id`, `branch_id`, `timestamp`, `field_values` (map of field id to value), `xp_earned`, optional `notes`, optional `goal`.

With a goal, `xp_earned = floor(base_xp * value / goal + 0.5)` (half-up), where `value` is the goal field's value and `goal` is the one stored on the record (falling back to the activity's). A value of 0 gives 0 XP; there is no cap above 100%. Example: base 10, goal 10: 5 reps gives 5, 20 reps gives 20. `xp_earned` is fixed when the record is created; changing the goal later never touches existing records.

## `quests.json` - time-boxed projects made of dated tasks
One entity per quest: `id`, `name`, `description`, `start_date`, `end_date` (inclusive, local calendar dates `YYYY-MM-DD`), `total_xp`, `distribution` (`auto` or `manual`), optional `pattern`, `created_at`, and `tasks` (ordered list).

Each task: `id`, `name`, `date` (`YYYY-MM-DD`, inside the quest range), `done_at` (ISO 8601 timestamp when checked, absent when open).

`pattern` is used by `auto` quests, which date the tasks evenly in order over the matching dates (several tasks share a date when they outnumber the dates; dates never go backwards). Two shapes:
- `{"type": "every_n_days", "n": 2}` - every n days counted from `start_date` (n > 0; "every other day" is n = 2).
- `{"type": "weekdays", "days": [1, 3, 5]}` - selected weekdays, 1 = Monday .. 7 = Sunday. Weekdays only is `[1,2,3,4,5]`, weekends only is `[6,7]`.

Checking a task, adding or re-dating tasks, or editing the quest is an `update` of the whole quest; removing it is a `delete`.

Derived quest status and points (never stored; computed with the local date of "today", or of the operation):
- Completed: at least one task and every task checked.
- Failed: not completed and today is after `end_date`.
- Active: otherwise. A quest with no tasks is active with 0 XP until its end date, then failed.
- XP: active `floor(total_xp * checked / task_count)`; completed `total_xp`; failed `0` (shares earned along the way are lost).
- Completed and failed quests are frozen: they accept only `delete`. A quest cannot be completed by removing tasks.

## `stats.json` - character stats, one row per time they were measured
`id`, `timestamp` (ISO 8601, set by the app when the entry is saved) and `values`: a map of stat key to number (>= 0). Any subset of the keys may be present, at least one:

| key | stat | unit |
|---|---|---|
| `weight` | Weight | Kg |
| `fat` | FAT | % (max 100) |
| `wat` | WAT | % (max 100) |
| `msl` | MSL | % (max 100) |
| `bon` | BON | Kg |
| `calo` | CALO | kcal |
| `pxfat` | PXFAT | % (max 100) |
| `protein` | Protein | % (max 100) |
| `bmi` | BMI | kg/m² |

Entries can only be created or deleted (a wrong one is deleted and entered again). They give no XP.

## Derived numbers (never stored; compute them from `records.json` and `quests.json`)
- Total XP = sum of `xp_earned` + quest XP (above). A failed quest removes its points, so total XP and level can go down.
- Level costs: a branch with `level_costs` uses them (see `branches.json`). Everything else (the overall level and the Quests level) uses the default curve: level 1 -> 2 costs 500 XP and each following level costs 250 more (500, 750, 1000, ...).
- Streak = consecutive calendar days with at least one record.
- Badges are computed from the records by the app.

## Writing
The app sends a `repository_dispatch` event of type `rpg_operation` only when the user presses **Push to GitHub**; nothing is pushed automatically. The `client_payload` holds an `operations` array, in order, of at most 25 operations (and about 48 KB serialized) per dispatch. Each operation:
```
{"operation_id": "...", "action": "create|update|delete", "entity_type": "branch|activity|record|quest|stat",
 "entity_id": "...", "payload": {...}, "local_date": "YYYY-MM-DD"}
```
`local_date` is the user's local calendar date when the change was made. The validator uses it (never the runner's clock) to judge quest status, so a task checked on the last day and pushed later is still accepted.

`.github/workflows/create_entity.yml` runs `.github/scripts/audit_entity.py`, which applies the operations one by one, each validated against the state left by the previous one (duplicate ids or names, missing branch, goal and quest rules, required fields). One rejected operation does not stop the rest. It writes one `game/status/<operation_id>.json` per operation with the outcome `SUCCESS`, `REJECTED` or `FAILED`, and one commit covers the batch. Operation ids are idempotent: an id that already has a status file is skipped and its stored status is reported, so a resend never applies a change twice. The manual `workflow_dispatch` path still takes a single operation. Hand-edits skip all validation.

Privacy: this data is personal. Keep the repo private.
