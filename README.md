# Life RPG

Android app (Flutter) that tracks personal development as an RPG: **branches** (areas of life) contain **activities**, each with user-defined **fields**; you record results, earn XP/levels/streaks/badges. Any AI can read your data from the repo (see `DATA_FORMAT.md`); the app itself has no AI built in. Design intent: `personal_life_rpg_project_overview.md`.

## How it works
- **Main screen**: swipe left/right between branches, scroll up/down through the branch's activities, fill the fields and press *Record*. **Home** (top right) -> progress, badges, Configuration. The chip next to the title shows sync state and is the sync button.
- **Storage**: with GitHub connected, `branches.json`, `activities.json`, `records.json` in your repository are the source of truth. The app sends each change as a `repository_dispatch` (`rpg_operation`); `.github/workflows/create_entity.yml` runs `.github/scripts/audit_entity.py`, which validates (duplicates, references, required fields), applies the change and writes `status/<operation_id>.json` (SUCCESS / REJECTED / FAILED). The app polls that file for its own operation id, then pulls the data. Changes show instantly, are queued offline and rolled back if rejected.
- **Without GitHub** the app works fully, data stays on the phone ("Local only"). Connecting later uploads what already exists.
- XP, levels, streaks and badges are always computed from the records (nothing to drift out of sync).
- **AI**: not part of the app. The data format is documented in `DATA_FORMAT.md` so an external assistant can read the repo.

## Setup
1. Create a **private** GitHub repo and push this project (the `.github` folder must be on the default branch). Keep `branches.json`, `activities.json`, `records.json` as `[]` for an empty start.
2. Create a fine-grained token for that repo: *Contents: read/write*, *Actions: read/write* (needed for dispatch + reading status).
3. In the app: Home -> Configuration -> GitHub storage -> repo `owner/name` + token -> *Test connection* -> *Connect*.

## Develop
```
flutter pub get
flutter analyze && flutter test
python -m unittest discover -s .github/scripts      # backend tests
flutter build apk --release                         # needs android/key.properties for signing
```
Security note: the token is stored encrypted on the device (Android Keystore) and is never in the APK, but it can write to the repo, so scope it to that one repository.
