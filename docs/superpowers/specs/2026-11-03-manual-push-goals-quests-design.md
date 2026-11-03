# Manual push, activity goals and quests - design

Date: 2026-11-03. App: Personal Life RPG (Flutter, `lib/src/...`; GitHub repo as storage, writes validated by `.github/scripts/audit_entity.py`).

## Intent

The owner uses the app as a single-player RPG for personal development. Three changes:

1. Stop syncing to GitHub automatically. A button pushes, with visible progress, and only what changed since the last push goes out.
2. Regular activities (the ones living under branches) get an editable **goal**. Points scale with executed amount vs goal, so over-achieving pays more than 100%.
3. A new **quests** feature: time-boxed projects made of dated tasks, with an all-or-nothing payout.

## Goals / non-goals / anti-goals

Goals
- Pushing is always an explicit user action; nothing is sent to GitHub otherwise.
- A push sends only changes made since the previous push; the app keeps a record of pushes.
- Push shows a spinner and real progress ("Sending 3 of 12").
- Goal-based points for regular activities, never recalculating old records.
- Quests with automatic or manual task dating, a history of finished quests (completed or failed), shown under their own Quests branch.

Non-goals
- No change to how branches/activities/records are created or validated, apart from the new goal fields.
- No writing JSON files straight from the app (the validation workflow stays).
- No AI-agent features, notifications or reminders for quests.

Anti-goals (would be a failure even if it "works")
- Anything rewriting the points of records already made when a goal changes.
- A quest silently paying points it should have lost, or losing points after being completed.
- Data pushed twice or silently dropped by a failed/partial push.

## Constraints

- Existing architecture stays: local `base` snapshot + queue of pending `Operation`s (`app_controller.dart`), view = base + ops, remote validated by the Python script and workflow `create_entity.yml`. Local-only mode (GitHub not connected) keeps working as today (saved immediately on device).
- `DATA_FORMAT.md` says derived numbers are never stored. Quest status and quest points follow this rule. Record points are the exception that already exists (`xp_earned`), and goal points use it.
- Data is personal; repo stays private. No new secrets.
- `client_payload` on GitHub `repository_dispatch` allows at most 10 top-level properties and about 64 KB, so batches are capped (see below).

## Approaches considered

Push mechanism
- A. One dispatch per change, started from a button. Smallest change, but slow (quest with 20 tasks = 20+ workflow runs, each polled).
- B. **Batch several changes into one dispatch; one workflow run applies them in order and writes one status file per change.** Needs workflow + script changes. **Chosen.**
- C. App writes JSON via the GitHub contents API. Fast but bypasses validation and risks conflicts. Rejected.

Quest storage
- A. Separate records for quests and tasks. Rejected: more files and operations, checking a task becomes its own entity.
- B. **One quest entity holding its tasks; status and points derived from the data and today's date.** **Chosen**: quests cannot fail by themselves (time passing is the trigger), so deriving status avoids a "fail" write that someone must remember to push.

## Design

### 1. Manual push

- Remove all automatic pushing: `submit()` no longer starts `_drain()`; `init()` and `connect()` no longer push. Changes are applied to the local view at once and appended to the pending queue (already how `ops` works).
- Settings (and a visible spot on the main screen) get a **Push to GitHub** button with a badge showing the pending count. It is disabled when nothing is pending or GitHub is not connected.
- Pressing it: pending operations are split into batches of at most 25 and sent in order, one dispatch per batch. After each dispatch the app polls the status files of that batch's operations. A spinner dialog or banner shows "Sending N of M" and updates as each status file resolves. The user cannot start a second push while one runs.
- Result handling stays as today: SUCCESS folds the change into base; REJECTED/FAILED drops it from the queue and shows a notice with the reason. If a push stops midway (no connection, timeout), operations already confirmed stay confirmed and the rest stay pending for the next press. Never resend an operation already marked dispatched without first checking its status file.
- The app keeps a **push log** locally (time, operations sent, how many succeeded/rejected/failed), shown in Settings. The "what is new" set is exactly the pending queue; the log is the stored history of pushes. The last-push time is displayed next to the button.
- After a push finishes, the app pulls from GitHub (as it does today at the end of a drain). On app launch it still pulls (read-only) but never pushes. *(My call.)* Pull must not drop pending operations: view stays base + pending.
- Workflow/script: `create_entity.yml` accepts a payload holding an `operations` array (each: operation_id, action, entity_type, entity_id, payload) in addition to the single-operation shape. `audit_entity.py` applies them sequentially, each validated against the state left by the previous one, writes one status file per operation, and one commit covers the batch. `MAX_STATUS_FILES` must exceed a batch (raise it). One bad operation does not stop the rest of the batch. The `workflow_dispatch` manual path keeps working with a single operation.
- `apply.dart` and the Python validator keep identical rules (as the existing comment demands).

### 2. Goals on regular activities

- `Activity` gains an optional goal: `goal` (positive number) and `goal_field_id` (which of the activity's numeric fields the goal is measured against; for activities with one number field it is selected automatically). Goals are in the same units the field already uses (duration fields keep storing seconds; the editor shows minutes as today).
- Activities without a goal behave exactly as now: each record earns `base_xp`.
- With a goal, recording computes `xp_earned = round(base_xp * value / goal)` at the moment of recording and stores it in the record, together with the `goal` that was used (`goal` stored on the record for transparency). `base_xp` is the points awarded for reaching 100% of the goal. Example: base 10, goal 10: 5 reps gives 5 points, 20 reps gives 20 points (200%).
- No cap on the percentage.
- Editing the goal later only affects records created afterwards; stored records are never touched, and the validator must not recompute them.
- UI: goal field in the activity editor; the record card shows the preview ("5 / 10 = 50% -> +5 XP") before saving and the percentage after.
- Data format docs and the Python validator accept the new optional fields (goal > 0 when present, `goal_field_id` must reference a numeric field).

### 3. Quests

**Data**: new file `quests.json` and entity type `quest`. A quest:
`id`, `name`, `description`, `start_date`, `end_date` (inclusive, local calendar dates `YYYY-MM-DD`), `total_xp`, `distribution` (`auto` or `manual`), `pattern` (used by `auto`; see below), `created_at`, and an ordered list `tasks`, each with `id`, `name`, `date` (`YYYY-MM-DD`), `done_at` (null or timestamp). All of a quest is one entity, so checking a task, adding a task or re-spreading dates is a quest `update` operation. Deleting a quest is a quest `delete`.

**Derived status** (never stored, computed with today's local date):
- *Completed*: has at least one task and every task is checked. Reached the day the last task is checked, even if after the schedule dates; checking tasks is allowed any time up to and including `end_date`.
- *Failed*: not completed and today is after `end_date`.
- *Active*: otherwise.
A quest with zero tasks stays active until it has tasks or fails at its end date.
Completed and failed quests are frozen (read-only) and form the **history**.

**Derived points**:
- Active: `floor(total_xp * checked / task_count)` (progressive share).
- Completed: `total_xp` in full.
- Failed: 0, including shares earned along the way.
These are added to total XP and level, and are the XP of the Quests branch. Since they are derived, a quest failing automatically removes its points.

**Quests branch**: a built-in branch, always present, labelled Quests, outside `branches.json` (my call: it is not a user branch and cannot be deleted/renamed, and it avoids touching the branch-delete cascade). It has its own level/XP bar from quest points, a list of active quests, and a **history** list of completed and failed quests, each marked with its outcome and the points it ended with.

**Creating a quest**: name, optional description, start and end date, total points, then tasks (add/edit/remove, ordered) and a distribution:
- *Manual*: the user sets each task's date within the range.
- *Automatic*: the user picks a pattern and the app dates the tasks. Patterns: every N days (including every other day), selected weekdays (any subset of Mon-Sun), weekdays only, weekends only. Tasks are spread evenly in order across the matching dates in the range; when there are more tasks than matching dates, some dates get several tasks. Task order is kept, so dates never go backwards (a "paint" task cannot land before "cut wood").

**Editing an active quest**: tasks can be added, edited, removed, reordered (calendar rules below).
- Manual quests: nothing moves on its own; the user dates new tasks.
- Automatic quests: after adding/removing/editing a task, the app re-spreads the tasks whose date has not passed (today counts as not passed) and are unchecked, using the same pattern, over the matching dates from today to `end_date`. Tasks with a past date, or already checked, keep their date forever. If no matching dates remain, the user is told the new task cannot be placed (my call: refuse the change).
- Changing `total_xp` or dates of an active quest is allowed through the same editor (my call); changing the range or pattern in an auto quest re-spreads open tasks the same way.
- A task with a past date can still be checked (that is how "skipped days, still completed" works), but its date cannot be moved.

**Validation** (Python script and `apply.dart`, same rules): start <= end; `total_xp` >= 0; task ids unique within a quest; dates are valid and inside the range; names non-empty; quest names unique; frozen quests (derived Completed/Failed as of the operation's date) cannot be updated except to be deleted (my call: the validator uses the date at which the operation is applied; operations queued offline for a quest that failed before they were pushed are rejected with a clear message).

## What is left to the builder
- Exact screens, widgets, icons and colour for the Quests branch, history list, push progress UI, and goal preview (follow the existing cyberpunk theme).
- File/class layout, helper for the auto-distribution algorithm, naming of providers.
- Batch size tuning (25 is a starting point; keep it under the payload limit).
- Test plan: extend `domain_test.dart`, `controller_test.dart`, `app_flow_test.dart` and `test_audit_entity.py` (goal maths, status/points derivation incl. date boundaries, auto-spread and re-spread, batch push with partial failure, no automatic push anywhere).
- Updating `DATA_FORMAT.md` and README for the new files, fields and manual push.
- Migration: existing data has no goals or quests; both are optional, so no data migration is needed.

## Decisions by whom
- Chosen by the owner: manual push with progress, only-new-changes, goals as described, quest rules as described, Quests branch with history, approaches B and B.
- My calls (listed above as "my call", for the owner to check): built-in Quests branch outside `branches.json`; ordered tasks that never go backwards in date; refusing a change when an auto quest has no matching dates left; editable total points/dates while active; frozen finished quests; launch still pulls (never pushes); batch cap 25.

## Resolved after the builder check (all are my calls unless noted)

**Push safety**
- Operation ids are stable and persisted with a `dispatched` flag. On the next push, the app first reads the status files of operations already marked dispatched and only re-sends those with no status file after a reasonable wait. The script skips any `operation_id` that already has a status file and reports that stored status, so a resend can never apply a change twice.
- Dependent operations: if a create is rejected, later operations on the same entity are rejected by the validator ("does not exist"). The app drops them from the queue with a notice naming the reason. No special dependency tracking.
- Before pushing, consecutive pending updates to the same entity are collapsed into the latest one (a quest edited ten times sends once). Batches are limited by serialized size (about 48 KB) as well as by count (25); a single operation larger than that is sent alone.
- Single device is assumed. If the remote changed meanwhile, the last write wins; no conflict detection.

**Dates and the validator**
- Each operation carries the device's local date (`local_date`). The validator uses that, never the runner's clock, so a check done on the last day and pushed later is still valid, and offline queues are judged by when the user acted.
- A quest is frozen for an operation if `local_date` is after `end_date`, or if every task was already checked. A frozen quest accepts only delete.

**Payout rules for active quests**
- A task can be unchecked while the quest is active, but a quest that has completed (all tasks checked) is final.
- Removing a task is refused if it would leave all remaining tasks checked, so a quest can't be completed by deleting work. Completion only happens by checking the last task.
- Adding a task to a nearly finished quest is allowed (it just lowers each share).
- An active quest can be deleted by the user (with confirmation); its points go with it. Finished quests can also be deleted from history, with confirmation.

**Goals**
- A goal is only valid together with `goal_field_id`, which must be a number or duration field. The editor picks it automatically when there is one candidate and asks otherwise. That field becomes required when a goal is set, and the editor refuses to delete or retype it while a goal exists.
- A value of 0 gives 0 XP. Rounding is half-up on non-negative numbers (`floor(x + 0.5)`) in both Dart and Python.
- On create, the validator checks `xp_earned == floor(base_xp * value / goal + 0.5)` using the goal stored on the record. It never checks existing records.

**XP and level**
- Quest points join total XP and the Quests branch XP as derived values. A failed quest lowers total XP, so a level can go down; this follows your "all points are lost" rule. Badges and streaks are unaffected, since quest points aren't dated records.
