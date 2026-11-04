# Life RPG

Android app (Flutter) that tracks personal development as an RPG: **branches** (areas of life) contain **activities**, each with user-defined **fields**; you record results, earn XP/levels/streaks/badges. Activities can have a **goal** that scales points, and **quests** are dated projects with an all-or-nothing payout. Any AI can read your data from the repo (see `game/DATA_FORMAT.md`); the app itself has no AI built in. Design intent: `personal_life_rpg_project_overview.md`.

## How it works
- **Main screen**: swipe left/right between branches, scroll up/down through the branch's activities, fill the fields and press *Record*. **Home** (top right) -> progress, badges, Configuration. The chip next to the title shows sync state ("Local only", "N pending", "Synced") and is tappable: when connected it opens the push dialog, when not connected it opens the GitHub settings.
- **Manual push**: nothing is sent to GitHub on its own. Changes show instantly and join the **pending queue** (exactly what is new since the last push). Press **Push to GitHub (N)** (Home or Configuration; N in the label is the pending count, also shown as "N pending" on the title chip) to send them, with a "Sending N of M" progress dialog. Configuration also shows a **push log** (time, sent, saved, rejected, failed) and a **Refresh from GitHub** button that only pulls (it never sends pending changes). App launch only pulls; it never pushes.
- **Disconnecting** GitHub keeps all data on the phone. If changes are still pending, the confirmation warns that they are not pushed and could be lost if you reconnect: push first. On reconnect the app queues local items missing from the repository as creates and items whose local copy differs as updates, but a local delete of an item still in the repository is not recovered.
- **Goals**: an activity may have a goal on one number or duration field. A record then earns `floor(base_xp * value / goal + 0.5)` XP: `base_xp` is the pay for 100% of the goal and there is no cap above it. The record screen previews it before saving. Changing the goal never changes old records.
- **Quests**: a built-in **Quests** branch (always present, not stored in `branches.json`) with its own level bar, your active quests and a **history** of completed and failed ones. A quest has a date range, total points and ordered dated tasks, dated manually or automatically by a pattern. Points are derived: a share while active, everything when all tasks are checked, zero if the end date passes first. Finished quests are read-only and can be deleted.
- **History**: the clock button on an activity opens its **history page**, separate from where you record. Records are grouped by year and month, each one collapsible (the newest year and month start open), and any record can be deleted there. A wrong record is deleted and entered again.
- **Character stats**: Home -> *Character stats*. Weight (Kg), FAT, WAT, MSL, BON (Kg), CALO, PXFAT, Protein and BMI; fill in any of them and the date and time are saved with the entry. Past entries are on a separate history page (by year/month, deletable).
- **Level points**: each branch has its own XP cost per level (the sliders icon on the branch, or Configuration -> *Level points*). The cost can differ for every level, normally growing; *Fill with a pattern* generates a growing series you can then edit. Default: 500 XP for level 1 -> 2, then 250 more each level. The overall and Quests levels use the default.
- **Storage**: with GitHub connected, the files in the `game/` folder of your repository (`branches.json`, `activities.json`, `records.json`, `quests.json`, `stats.json`) are the source of truth. A push sends the pending changes in batches (up to 25 operations / ~48 KB per `repository_dispatch` `rpg_operation`); `.github/workflows/create_entity.yml` runs `.github/scripts/audit_entity.py`, which validates each operation (duplicates, references, required fields, goal, quest, stat and level rules), applies it and writes one `game/status/<operation_id>.json` per operation (SUCCESS / REJECTED / FAILED). Operation ids are idempotent, so an interrupted or repeated push never applies a change twice. The app polls those files, then pulls the data. Rejected changes are dropped with the reason; the rest stay queued if a push stops midway.
- **Without GitHub** the app works fully, data stays on the phone ("Local only"). Connecting later uploads what already exists.
- XP, levels, streaks and badges are always computed from the records and quests (nothing to drift out of sync). Quest points count toward total XP, so a failed quest can lower your level.
- **AI**: not part of the app. The data format is documented in `game/DATA_FORMAT.md` so an external assistant can read the repo.

## Setup
1. Create a **private** GitHub repo and push this project (the `.github` folder must be on the default branch). Keep `game/branches.json`, `game/activities.json`, `game/records.json` as `[]` for an empty start (`quests.json` and `stats.json` are created with the first quest or stats entry).
2. Create a fine-grained token for that repo: *Contents: read/write*, *Actions: read/write* (needed for dispatch + reading status).
3. In the app: Home -> Configuration -> GitHub storage -> repo `owner/name` + token -> *Test connection* -> *Connect* (later, *Update* saves a changed repo or token; it does not push).

Note: after updating the app, push the updated `.github` folder (workflow and `audit_entity.py`) to the default branch of your data repo before pushing from the app; an old workflow writes to the old locations and does not know stats or level points. If your data files are still at the repo root, the app reads them from there and the first push moves them into `game/`.

## Repository layout
- `game/` - **the game**: your data (`*.json`), `status/` (results of pushed changes) and `DATA_FORMAT.md`. Nothing here is application code.
- `lib/`, `android/`, `test/`, `assets/`, `pubspec.yaml` - the Flutter application.
- `.github/` - the workflow and script that validate and store changes into `game/`.
- `docs/`, `mockups/`, `personal_life_rpg_project_overview.md`, `AUDIT.md` - design notes.

## Develop
```
flutter pub get
flutter analyze && flutter test
python -m unittest discover -s .github/scripts      # backend tests
flutter build apk --release                         # needs android/key.properties for signing
```
Security note: the token is stored encrypted on the device (Android Keystore) and is never in the APK, but it can write to the repo, so scope it to that one repository.
