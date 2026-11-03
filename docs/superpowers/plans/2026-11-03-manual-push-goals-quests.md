# Manual Push, Activity Goals and Quests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers_subagent-driven-development (recommended) or superpowers_executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace auto-sync with a manual, batched, progress-showing push; add goal-scaled points to activities; add time-boxed quests with a derived-status Quests branch.

**Architecture:** Keep the existing model (local `base` snapshot + queue of pending `Operation`s, view = base + ops, GitHub workflow validating every change). Quests are one entity (`quest`, file `quests.json`) containing its tasks; status and quest XP are derived from data plus today's date. The queue becomes the "what is new" set; a persisted push log records pushes. The workflow accepts a batch of operations per dispatch.

**Tech Stack:** Flutter/Dart (Riverpod, Dio, shared_preferences), Python 3.12 (`unittest`), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-03-manual-push-goals-quests-design.md` (including its "Resolved after the builder check" section).

## Global Constraints

- Dart rules in `lib/src/domain/apply.dart` and Python rules in `.github/scripts/audit_entity.py` must stay identical.
- Dates are local calendar dates `YYYY-MM-DD`; `end_date` is inclusive. The validator uses the operation's `local_date`, never the runner clock.
- Rounding for goal points: `floor(base_xp * value / goal + 0.5)` in both Dart and Python.
- Batch limits: at most 25 operations and about 48 KB serialized per dispatch.
- `MAX_STATUS_FILES` in the script must exceed a batch (raise to 500).
- Quest XP is derived and never stored: active `floor(total_xp * checked / task_count)`, completed `total_xp`, failed `0`.
- Quest statuses: completed (>=1 task, all checked), failed (not completed and `today > end_date`), active otherwise. Finished quests accept only delete.
- No automatic push anywhere. App launch may pull. Local-only mode (no GitHub) behaves as today.
- Run Dart tests with `flutter test`, Python tests with `python -m unittest` from `.github/scripts`.

## Review Focus

- Goal of 0 or negative, or a value of 0: must not divide by zero; value 0 gives 0 XP, goal <= 0 is rejected.
- Quest `start_date` after `end_date`, task dates outside the range, duplicate task ids: rejected with a clear message.
- Checking the last task on `end_date` pushed days later: still accepted (uses `local_date`).
- Auto quest with more tasks than matching dates: several tasks share a day, order preserved, dates never decrease.
- Re-spread when a checked task sits in the future between open tasks: open tasks before it never land after it.
- Push interrupted midway or sent twice: no operation applied twice, rest stay queued.
- A batch where an early create is rejected: later dependent operations are rejected, nothing is left half-applied.
- Quest with zero tasks: active, 0 XP, never "completed".

---

## File Structure

- `lib/src/domain/models.dart` (modify): `Activity.goal/goalFieldId`, `Record.goal`, `Quest`, `QuestTask`, `QuestPattern`, `Snapshot.quests`, `EntityType.quest`, `Operation.localDate`.
- `lib/src/domain/goals.dart` (create): goal maths.
- `lib/src/domain/quests.dart` (create): `questStatus`, `questXp`, `spreadDates`, `respreadTasks`, `dateKey`.
- `lib/src/domain/apply.dart` (modify): goal and quest rules.
- `lib/src/domain/progress.dart` (modify): total XP includes quest XP.
- `lib/src/data/remote_store.dart` (modify): `dispatchBatch`, pull `quests.json`.
- `lib/src/data/local_store.dart` (modify): push log persistence.
- `lib/src/state/app_controller.dart` (modify): manual push, coalescing, batching, progress.
- `lib/src/ui/push_dialog.dart` (create): spinner/progress.
- `lib/src/ui/quests_page.dart`, `lib/src/ui/quest_editor.dart` (create): Quests branch, history, editor.
- `lib/src/ui/browser_page.dart`, `editors.dart`, `settings_page.dart`, `common.dart`, `home_page.dart` (modify).
- `.github/scripts/audit_entity.py`, `.github/workflows/create_entity.yml` (modify); tests in `.github/scripts/test_audit_entity.py`.
- `DATA_FORMAT.md`, `README.md` (modify).

---

### Task 1: Goal maths and goal fields (Dart domain)

**Files:**
- Create: `lib/src/domain/goals.dart`
- Modify: `lib/src/domain/models.dart` (Activity, Record), `lib/src/domain/apply.dart` (activity + record validation)
- Test: `test/domain_test.dart`

**Interfaces:**
- Produces: `int goalXp({required int baseXp, required num value, required num goal})` (returns `floor(baseXp*value/goal + 0.5)`; 0 when `value <= 0`; throws `ArgumentError` when `goal <= 0`); `Activity.goal` (`double?`), `Activity.goalFieldId` (`String?`), both in `toJson` as `goal` / `goal_field_id` and in `copyWith`; `Record.goal` (`double?`, JSON key `goal`).

- [ ] **Step 1: Write failing tests** in `domain_test.dart`, group `goals`: `goalXp(baseXp: 10, value: 5, goal: 10) == 5`; `value: 20, goal: 10 == 20`; `value: 0 == 0`; `goal: 0` throws `ArgumentError`; `baseXp: 10, value: 1, goal: 4 == 3` (2.5 rounds up). Apply tests: activity with `goal` but no `goalFieldId` is rejected; `goalFieldId` pointing to a text field is rejected; `goal <= 0` is rejected; valid goal accepted; JSON round trip keeps `goal`, `goal_field_id`; a record for a goal activity whose `xp_earned` != `goalXp(...)` is rejected, a correct one accepted; an existing record is unchanged after the activity's goal is edited.
- [ ] **Step 2: Run** `flutter test test/domain_test.dart` - expect FAIL (undefined).
- [ ] **Step 3: Implement** `goals.dart` and the model fields. In `apply.dart`, activity create/update validates goal rules above; record create (not update/delete) with an activity that has a goal requires the goal field value present and `xpEarned == goalXp(baseXp, value, record.goal ?? activity.goal)`.
- [ ] **Step 4: Run** `flutter test test/domain_test.dart` - expect PASS.
- [ ] **Step 5: Commit** `feat: goal fields and goal-scaled points`.

### Task 2: Goal rules in the Python validator

**Files:**
- Modify: `.github/scripts/audit_entity.py`
- Test: `.github/scripts/test_audit_entity.py`

**Interfaces:**
- Produces: `goal_xp(base_xp, value, goal) -> int` (`math.floor(base_xp*value/goal + 0.5)`, 0 when value <= 0).

- [ ] **Step 1: Write failing tests** mirroring Task 1: goal without `goal_field_id` rejected; non-numeric goal field rejected; goal <= 0 rejected; record with wrong `xp_earned` rejected on create, correct accepted; updating the activity goal leaves stored records untouched.
- [ ] **Step 2: Run** `python -m unittest test_audit_entity` - expect FAIL.
- [ ] **Step 3: Implement** `goal_xp` and the checks in `_validate` (activity and record branches). Numeric field types in this validator: `number`, `duration`.
- [ ] **Step 4: Run** the same command - expect PASS.
- [ ] **Step 5: Commit** `feat: validate goals in the audit script`.

### Task 3: Quest model and derived status/XP

**Files:**
- Create: `lib/src/domain/quests.dart`
- Modify: `lib/src/domain/models.dart`, `lib/src/domain/progress.dart`
- Test: `test/quests_test.dart` (create)

**Interfaces:**
- Produces in `models.dart`: `QuestTask {String id; String name; String date; DateTime? doneAt}`; `QuestPattern {String type; int n; List<int> days}` with factories `QuestPattern.everyNDays(int n)` and `QuestPattern.weekdays(List<int> days)` (1=Mon..7=Sun; weekdays-only is `[1,2,3,4,5]`, weekends `[6,7]`); `Quest {String id; String name; String description; String startDate; String endDate; int totalXp; bool auto; QuestPattern? pattern; List<QuestTask> tasks; DateTime createdAt}` with `toJson/fromJson/copyWith` (JSON keys: `start_date`, `end_date`, `total_xp`, `distribution` = `auto|manual`, `pattern` = `{"type":"every_n_days","n":2}` or `{"type":"weekdays","days":[1,5]}`, `tasks[{id,name,date,done_at}]`); `Snapshot.quests` (`List<Quest>`, included in `toJson`, `fromJson`, `fromLists` as a 4th argument `quests`); `EntityType.quest`; `Operation.localDate` (`String`, JSON key `local_date`, default today's key).
- Produces in `quests.dart`: `enum QuestStatus { active, completed, failed }`; `String dateKey(DateTime d)`; `QuestStatus questStatus(Quest q, String today)`; `int questXp(Quest q, String today)`; `int totalQuestXp(Iterable<Quest> qs, String today)`.
- Modifies `progress.dart`: nothing signature-breaking; `xpOf` stays records-only; add `int playerXp(Snapshot s, String today) => xpOf(s.records) + totalQuestXp(s.quests, today)`.

- [ ] **Step 1: Write failing tests** (`quests_test.dart`): quest with 4 tasks, 3 checked, today inside range: active, XP `floor(100*3/4) == 75`; all 4 checked: completed, XP 100, also when `today` is after `end_date`; 2 checked and `today == end_date`: active; same with `today` one day after: failed, XP 0; zero tasks: active, XP 0 inside range and failed after; JSON round trip of a quest including pattern and `done_at`; `Snapshot.fromLists` with a malformed quest skips it.
- [ ] **Step 2: Run** `flutter test test/quests_test.dart` - expect FAIL.
- [ ] **Step 3: Implement** the models and functions. String comparison on `YYYY-MM-DD` is valid for date ordering.
- [ ] **Step 4: Run** `flutter test` (whole suite, to catch `Snapshot` constructor fallout) - expect PASS.
- [ ] **Step 5: Commit** `feat: quest model with derived status and XP`.

### Task 4: Automatic task distribution

**Files:**
- Modify: `lib/src/domain/quests.dart`
- Test: `test/quests_test.dart`

**Interfaces:**
- Consumes: `Quest`, `QuestPattern`, `dateKey` from Task 3.
- Produces: `List<String> spreadDates({required String from, required String end, required QuestPattern pattern, required String anchor, required int count})` - eligible dates are those in `[from, end]` matching the pattern (`everyNDays` counts from `anchor`, the quest `start_date`; `weekdays` matches `DateTime.weekday`); task i of `count` gets `eligible[floor(i * eligible.length / count)]`; returns `[]` when no eligible date and `count > 0`. `Quest respreadTasks(Quest q, String today)` - re-dates only tasks that are unchecked and have `date >= today`, processing each contiguous run of such tasks separately so a run is bounded by the neighbouring locked tasks' dates; locked tasks never change; returns `q` unchanged when `q.auto` is false; throws `StateError('No matching dates left')` when an open run has tasks but no eligible dates.

- [ ] **Step 1: Write failing tests:** Nov 10-Dec 20 with 20 tasks and pattern weekdays `[1,5]` (Mon/Fri): every date is a Monday or Friday, in range, non-decreasing in list order; 20 tasks every 2 days: dates start Nov 10 and step 2; count > eligible dates: dates repeat, order preserved; `respreadTasks` with today = Dec 1, first 5 tasks past/checked: those five dates unchanged, others fall on or after Dec 1; a checked future task in the middle: open tasks before it have dates <= its date; manual quest returns identical object; no eligible dates throws `StateError`.
- [ ] **Step 2: Run** `flutter test test/quests_test.dart` - expect FAIL.
- [ ] **Step 3: Implement** both functions as described.
- [ ] **Step 4: Run** same command - expect PASS.
- [ ] **Step 5: Commit** `feat: automatic quest task distribution`.

### Task 5: Quest rules in `apply.dart`

**Files:**
- Modify: `lib/src/domain/apply.dart`
- Test: `test/domain_test.dart`

**Interfaces:**
- Consumes: `Quest`, `questStatus`, `Operation.localDate`.
- Produces: `applyOperation` handles `EntityType.quest` for create/update/delete.

- [ ] **Step 1: Write failing tests** (group `quests`): create valid quest ok; `start_date > end_date` rejected; `total_xp < 0` rejected; empty name or task name rejected; duplicate quest name (case-insensitive) rejected; duplicate task id rejected; task date outside range rejected; update that checks a task while `local_date == end_date` ok; same update with `local_date` one day later rejected as frozen; update of a completed quest rejected, delete of it ok; update that removes the only unchecked task (leaving all checked) rejected with "Cannot complete a quest by removing tasks"; update that unchecks a task on an active quest ok; update that adds a task ok; delete of an active quest ok.
- [ ] **Step 2: Run** `flutter test test/domain_test.dart` - expect FAIL.
- [ ] **Step 3: Implement** the quest branch in `applyOperation`, using `questStatus(existing, op.localDate)` for the frozen check (frozen: completed, or failed as of `local_date`).
- [ ] **Step 4: Run** `flutter test` - expect PASS.
- [ ] **Step 5: Commit** `feat: quest validation rules in apply`.

### Task 6: Quest rules, `local_date`, batch and idempotency in Python

**Files:**
- Modify: `.github/scripts/audit_entity.py`, `.github/workflows/create_entity.yml`
- Test: `.github/scripts/test_audit_entity.py`

**Interfaces:**
- Produces: `FILES["quest"] = "quests.json"`; `EntityAuditor.audit(action, etype, eid, payload, local_date=None)`; `run_batch(root, operations) -> list[dict]` where each operation is `{operation_id, action, entity_type, entity_id, payload, local_date}`; `main()` reads `RPG_OPERATIONS` (JSON array) when set, else the single-operation env vars. Workflow: `client_payload.operations` goes to `RPG_OPERATIONS`; the single-operation inputs keep working.

- [ ] **Step 1: Write failing tests:** every quest rule from Task 5 (mirror the same cases and messages); `run_batch` with three operations (create branch, create activity, create record) writes three status files and one data state; a batch whose first create is rejected rejects the dependent ones and still applies independent ones; running `run_batch` twice with the same operation ids does not duplicate data and returns the stored status the second time; `MAX_STATUS_FILES >= 500`.
- [ ] **Step 2: Run** `python -m unittest test_audit_entity` - expect FAIL.
- [ ] **Step 3: Implement** the validator quest branch (same frozen rule using `local_date`, falling back to rejecting when it is missing for quest updates), `run_batch` (skip an `operation_id` whose status file exists, reporting its stored result), raise `MAX_STATUS_FILES`, and update the workflow env and `git add` list (`quests.json`).
- [ ] **Step 4: Run** the same command - expect PASS.
- [ ] **Step 5: Commit** `feat: quests and batched operations in the audit script`.

### Task 7: Remote store batch dispatch and quests pull

**Files:**
- Modify: `lib/src/data/remote_store.dart`
- Test: `test/controller_test.dart` (FakeRemote updated in Task 8; this task adds no separate test file)

**Interfaces:**
- Produces: `Future<void> RemoteStore.dispatchBatch(List<Operation> ops)` replacing `dispatch` (payload `{'event_type':'rpg_operation','client_payload':{'operations':[{operation_id, action, entity_type, entity_id, payload, local_date}...]}}`); `pull()` also reads `quests.json` into `Snapshot.quests`; `static List<List<Operation>> RemoteStore.chunk(List<Operation> ops, {int maxOps = 25, int maxBytes = 48000})` (a single operation over `maxBytes` goes alone).

- [ ] **Step 1: Write failing test** in `controller_test.dart`: `GithubRemoteStore.chunk` splits 60 small operations into batches of 25, 25, 10 in order; an operation whose JSON exceeds 48000 bytes forms its own batch.
- [ ] **Step 2: Run** `flutter test test/controller_test.dart` - expect FAIL.
- [ ] **Step 3: Implement** `chunk`, `dispatchBatch` (reuse the existing error mapping), and the `quests.json` pull. Remove `dispatch`.
- [ ] **Step 4: Run** the chunk test - expect PASS (other controller tests are fixed in Task 8).
- [ ] **Step 5: Commit** `feat: batched dispatch and quests pull`.

### Task 8: Manual push in the controller

**Files:**
- Modify: `lib/src/state/app_controller.dart`, `lib/src/data/local_store.dart`
- Test: `test/controller_test.dart` (rewrite affected tests)

**Interfaces:**
- Consumes: `RemoteStore.dispatchBatch`, `RemoteStore.chunk`.
- Produces: `class PushProgress {int done; int total; bool running}` in `AppState.push`; `class PushLogEntry {DateTime time; int sent; int succeeded; int rejected; int failed}` in `AppState.pushLog` (newest first, max 50) persisted via `LocalStore.loadPushLog() / savePushLog(List<PushLogEntry>)`; `Future<PushLogEntry?> AppController.pushNow()` (null when nothing pending, not connected, or already running); `int AppState.pendingCount`. `submit()` no longer calls `_drain`; `submit()` for a connected user returns `OpResult(OpOutcome.pending, 'Saved - waiting for push')` immediately. `init()`/`connect()` no longer push; `init()` still pulls when configured. `syncNow()` removed (replaced by `pushNow`).

- [ ] **Step 1: Write failing tests** (replace the auto-sync tests): submitting while connected sends nothing to the remote and keeps the item in the view; `pushNow` sends all pending in order and leaves the queue empty; `pushNow` twice in a row sends nothing the second time; the log gets one entry per push with correct counts; a rejected operation is dropped with a notice and the log counts it as rejected; offline mid-push keeps unsent operations queued and already-confirmed ones confirmed; 30 pending operations produce two `dispatchBatch` calls; two consecutive updates to the same entity are coalesced into one sent operation (latest payload); an operation already marked dispatched is first checked via `status` and not re-dispatched when its status exists; progress `done` reaches `total`; `init()` never dispatches.
- [ ] **Step 2: Run** `flutter test test/controller_test.dart test/app_flow_test.dart` - expect FAIL.
- [ ] **Step 3: Implement** `pushNow` by adapting `_drain`: coalesce updates, chunk, dispatch each chunk, poll statuses for the operations in it, fold successes into base (keeping the existing "accepted operation never vanishes from view" behaviour), update `AppState.push` after every resolved operation, append the log entry, pull at the end. Give `_op` a `localDate: dateKey(DateTime.now())`. Update `FakeRemote` to implement `dispatchBatch`. Fix `app_flow_test.dart` expectations that assumed auto-sync.
- [ ] **Step 4: Run** `flutter test` - expect PASS.
- [ ] **Step 5: Commit** `feat: manual push with batching, progress and push log`.

### Task 9: Push UI

**Files:**
- Create: `lib/src/ui/push_dialog.dart`
- Modify: `lib/src/ui/settings_page.dart`, `lib/src/ui/common.dart` (SyncChip), `lib/src/ui/browser_page.dart` (`_onChipTap`), `lib/src/ui/home_page.dart`
- Test: `test/app_flow_test.dart`

**Interfaces:**
- Consumes: `AppController.pushNow`, `AppState.push`, `AppState.pendingCount`, `AppState.pushLog`.
- Produces: `Future<void> showPushDialog(BuildContext, WidgetRef)`.

- [ ] **Step 1: Write failing widget test:** with pending changes and GitHub connected, the Settings page shows "Push to GitHub (N)"; tapping it shows a progress indicator and text "Sending"; after completion the badge count is 0 and the last-push time is shown; the button is disabled with 0 pending. The sync chip on the main screen opens the push dialog when connected and shows the pending count.
- [ ] **Step 2: Run** `flutter test test/app_flow_test.dart` - expect FAIL.
- [ ] **Step 3: Implement** the dialog (circular progress, "Sending {done} of {total}…", result summary with rejected count) and wire the button into Settings (replacing "Sync now"), the chip and Home. Show the push log (last 10 entries) in Settings.
- [ ] **Step 4: Run** `flutter test` - expect PASS.
- [ ] **Step 5: Commit** `feat: push button with progress`.

### Task 10: Goal UI

**Files:**
- Modify: `lib/src/ui/editors.dart` (activity editor), `lib/src/ui/browser_page.dart` (record card)
- Test: `test/app_flow_test.dart`

**Interfaces:**
- Consumes: `goalXp`, `Activity.goal/goalFieldId`, `Record.goal`.

- [ ] **Step 1: Write failing widget tests:** activity editor has an optional "Goal" input and, with several numeric fields, a selector for the goal field; saving with a goal but no numeric field shows an error; the record card shows a live preview ("5 / 10 = 50% → +5 XP") that updates as the number is typed; saving a record stores `xpEarned == goalXp(...)` and `goal`; after editing the goal, an earlier record still shows its old XP.
- [ ] **Step 2: Run** `flutter test test/app_flow_test.dart` - expect FAIL.
- [ ] **Step 3: Implement.** Duration goals are entered in minutes and stored in seconds, like the field value. The goal field becomes required while a goal is set; the editor blocks deleting or retyping it.
- [ ] **Step 4: Run** `flutter test` - expect PASS.
- [ ] **Step 5: Commit** `feat: goal editing and live points preview`.

### Task 11: Quests branch, history and editor

**Files:**
- Create: `lib/src/ui/quests_page.dart`, `lib/src/ui/quest_editor.dart`
- Modify: `lib/src/ui/browser_page.dart` (virtual last-before-add page), `lib/src/state/providers.dart` (`playerStatsProvider` uses `playerXp`; new `questXpProvider`), `lib/src/ui/home_page.dart` (Quests row), `lib/src/state/app_controller.dart` (`saveQuest(Quest, {required bool isNew})`, `deleteQuest(String id)`)
- Test: `test/app_flow_test.dart`

**Interfaces:**
- Consumes: Tasks 3-5 functions; `respreadTasks`, `spreadDates`, `questStatus`, `questXp`.

- [ ] **Step 1: Write failing widget tests:** the main screen always has a "Quests" page (even with no branches); creating a quest with name, dates, points, 4 tasks and "every other day" produces dated tasks; manual mode lets each task date be set; checking a task updates progress and XP shown; checking the last task marks it completed and moves it to History with full points; a quest whose end date passed appears in History as "Failed" with 0 points; History shows both outcomes; adding a task to an auto quest re-spreads open tasks only; the editor refuses removing the last unchecked task with the spec message; an auto quest with no dates left shows "No matching dates left" and saves nothing.
- [ ] **Step 2: Run** `flutter test test/app_flow_test.dart` - expect FAIL.
- [ ] **Step 3: Implement.** Quests page: level/XP bar from `totalQuestXp`, active quests with task checklists, History list with outcome chips (Completed / Failed) and final points. Editor: name, description, dates, points, distribution toggle (auto: pattern picker with every N days, weekday chips, "weekdays", "weekends" presets; manual: per-task date picker), ordered task list. Auto edits call `respreadTasks`. Finished quests are read-only except delete with confirmation. Use today's `dateKey(DateTime.now())` for derived status.
- [ ] **Step 4: Run** `flutter test` - expect PASS.
- [ ] **Step 5: Commit** `feat: quests branch with history and editor`.

### Task 12: Docs and final verification

**Files:**
- Modify: `DATA_FORMAT.md`, `README.md`

- [ ] **Step 1:** Document `quests.json`, the goal fields, record `goal`, operation `local_date`, batch dispatch shape, and manual push (what the button does, push log, pending queue) in `DATA_FORMAT.md` and `README.md`.
- [ ] **Step 2: Run** `flutter analyze` - expect no issues; `flutter test` - expect all PASS; `python -m unittest` in `.github/scripts` - expect all PASS.
- [ ] **Step 3: Commit** `docs: manual push, goals and quests`.
