# Data format (for any AI or script that reads this repo)

The app keeps three JSON arrays at the repo root. They are the source of truth when GitHub storage is connected. Read them freely. To change data, send the same operations the app sends (see "Writing"), do not edit the files by hand.

## `branches.json` - areas of life
`id`, `name`, `description`, `accent_color` (ARGB int), `icon_code_point`, `created_at` (ISO 8601).

## `activities.json` - things you do inside a branch
`id`, `branch_id`, `name`, `description`, `accent_color`, `icon_code_point`, `base_xp` (XP earned per record), `created_at`, and `fields`: the columns of that activity's table.

Each field: `id`, `name`, `type` (`number`, `duration`, `scale`, `yesno` or `text`), optional `unit`, `required`.
- `duration` values are stored in **seconds**.
- `scale` is 1-10. `yesno` is true/false.

## `records.json` - one row per time you did an activity
`id`, `activity_id`, `branch_id`, `timestamp`, `field_values` (map of field id to value), `xp_earned`, optional `notes`.

## Derived numbers (never stored; compute them from `records.json`)
- Total XP = sum of `xp_earned`.
- Going from level n to n+1 costs 100*n XP, so reaching level L takes 50*L*(L-1) XP in total.
- Streak = consecutive calendar days with at least one record.
- Badges are computed from the records by the app.

## Writing
The app sends a `repository_dispatch` event of type `rpg_operation`. `.github/workflows/create_entity.yml` runs `.github/scripts/audit_entity.py`, which validates the change (duplicate ids or names, missing branch, required fields) and writes `status/<operation_id>.json` with the outcome `SUCCESS`, `REJECTED` or `FAILED`. Hand-edits skip that validation.

Privacy: this data is personal. Keep the repo private.
