import 'models.dart';

/// One character stat the user can record. Keys are what is stored in
/// `game/stats.json`; they must match `STAT_KEYS` in `.github/scripts/audit_entity.py`.
class StatDef {
  final String key;
  final String label; // short code shown in the app
  final String name; // what it is
  final String? unit;
  final double? max; // upper limit (100 for percentages)
  const StatDef(this.key, this.label, this.name, {this.unit, this.max});
}

const statDefs = <StatDef>[
  StatDef('weight', 'Weight', 'Body weight', unit: 'Kg'),
  StatDef('fat', 'FAT', 'Body fat', unit: '%', max: 100),
  StatDef('wat', 'WAT', 'Water', unit: '%', max: 100),
  StatDef('msl', 'MSL', 'Muscle', unit: '%', max: 100),
  StatDef('bon', 'BON', 'Bone mass', unit: 'Kg'),
  StatDef('calo', 'CALO', 'Calories', unit: 'kcal'),
  StatDef('pxfat', 'PXFAT', 'Visceral fat', unit: '%', max: 100),
  StatDef('protein', 'Protein', 'Protein', unit: '%', max: 100),
  StatDef('bmi', 'BMI', 'Body mass index', unit: 'kg/m²'),
];

StatDef? statDef(String key) => statDefs.where((d) => d.key == key).firstOrNull;

/// The same rules as `stat_error` in the validator. Null when the entry is valid.
String? statError(StatEntry e) {
  if (e.id.isEmpty) return 'Stat entry needs an id';
  if (e.values.isEmpty) return 'Enter at least one stat';
  for (final v in e.values.entries) {
    final d = statDef(v.key);
    if (d == null) return "Unknown stat '${v.key}'";
    if (!v.value.isFinite || v.value < 0) return "Stat '${v.key}' must be a number of 0 or more";
    if (d.max != null && v.value > d.max!) return "Stat '${v.key}' cannot be more than ${d.max!.round()}";
  }
  return null;
}

/// Newest first.
List<StatEntry> statsNewestFirst(Iterable<StatEntry> stats) =>
    stats.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

/// The most recent recorded value of each stat (a stat may be missing from the latest entry).
Map<String, num> latestStatValues(Iterable<StatEntry> stats) {
  final out = <String, num>{};
  for (final e in statsNewestFirst(stats)) {
    for (final v in e.values.entries) {
      out.putIfAbsent(v.key, () => v.value);
    }
  }
  return out;
}
