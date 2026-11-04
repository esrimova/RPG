# Game data

Everything in this folder is the *game* (your branches, activities, records, quests and character stats). The application lives elsewhere in the repository.

- `branches.json`, `activities.json`, `records.json`, `quests.json`, `stats.json` - the data. Written by the workflow, read by the app. Do not edit by hand.
- `status/` - one small file per pushed change with its outcome (SUCCESS / REJECTED / FAILED).
- `DATA_FORMAT.md` - the format, for any AI or script that reads this data.
