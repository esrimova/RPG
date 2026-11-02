# Audit of the previous build (code-verified) and what was done

## Root causes found
1. Every create/record failed: `triggerWorkflow` returned `running` on HTTP 204, every use case demanded `success` and nothing polled -> data saved locally then an exception shown; lists never refreshed.
2. GitHub pipeline could not work: audit script wrote `status=` to stdout, not `$GITHUB_OUTPUT` (commit step never ran); payload interpolated into shell; one shared status file (races); app read branch `main` while repo is `master`; update/delete sent as `create_*` and rejected as duplicates; run matching used `head_commit.message`; repo shipped 4 seeded branches; app never read data back.
3. Fake features: quick-entry submit was `Future.delayed`; metrics dialog discarded fields (activities always had `fields: []`); AI service and "test connection" were stubs calling a mock; demo activities; empty `onPressed`; no UserProfile ever created so XP/streak did nothing.
4. Release APK had **no INTERNET permission** (only debug/profile manifests had it) so GitHub and AI could never work on the phone.
5. UI contradicted the spec (bottom tabs instead of swipe + Home), duplicated dialogs, jargon labels; `google_fonts` needed network at runtime.

## Replaced by
Rewritten domain/data/state/UI (`lib/src`), new workflow + audit script with tests, INTERNET permission, 31 automated tests (18 Dart, 13 Python), `flutter analyze` clean (was 101 issues).

## Not verified (needs you)
- Real GitHub round trip (needs the new `.github` pushed + a token). The pipeline is tested with a faithful fake and the Python script was run end to end locally.
- Install/run on the phone (left untouched because another process has priority there).

## Decision
The in-app AI coach and AI settings were removed: an assistant reads the repo instead (`DATA_FORMAT.md`).
