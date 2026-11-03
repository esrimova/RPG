import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/goals.dart';
import '../domain/models.dart';
import '../domain/progress.dart';
import '../state/app_controller.dart';
import '../state/providers.dart';
import 'common.dart';
import 'editors.dart';
import 'home_page.dart';
import 'icons.dart';
import 'push_dialog.dart';
import 'settings_page.dart';
import 'theme.dart';

/// Main screen. Swipe left/right between branches, scroll up/down through the
/// activities of the current branch. Home button is at the top right.
class BrowserPage extends ConsumerStatefulWidget {
  const BrowserPage({super.key});
  @override
  ConsumerState<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends ConsumerState<BrowserPage> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Connected: push/pull now. Not connected: open the GitHub settings.
  void _onChipTap(AppState app) {
    if (!app.github.isConfigured) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
    } else if (!app.syncing) {
      showPushDialog(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final branches = app.view.branches;
    final count = branches.length + 1; // last page = "add branch"
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(children: [
              Expanded(
                child: Row(children: [
                  const Flexible(child: Text('Life RPG', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Flexible(child: SyncChip(onTap: () => _onChipTap(app))),
                ]),
              ),
              IconButton(
                tooltip: 'Home',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage())),
                icon: const Icon(Icons.home_rounded, size: 28, color: Pal.cyan),
              ),
            ]),
          ),
          const NoticeBanner(),
          if (branches.isNotEmpty) _dots(count, branches),
          Expanded(
            child: !app.loaded
                ? const Center(child: CircularProgressIndicator())
                : branches.isEmpty
                    ? const _EmptyStart()
                    : PageView.builder(
                        controller: _pages,
                        itemCount: count,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (_, i) => i == branches.length
                            ? const _AddBranchPage()
                            : _BranchPage(key: ValueKey(branches[i].id), branchId: branches[i].id),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _dots(int count, List<Branch> branches) => SizedBox(
        height: 28,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < count; i++)
            GestureDetector(
              onTap: () => _pages.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? (i < branches.length ? Color(branches[i].color) : Pal.muted) : Pal.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ]),
      );
}

class _EmptyStart extends ConsumerWidget {
  const _EmptyStart();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.explore_outlined, size: 64, color: Pal.cyan),
            const SizedBox(height: 16),
            const Text('Start your journey', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'A branch is an area of your life you want to develop, such as Physical Development or Family. Create your first one, then add activities to it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Pal.muted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: () => showBranchEditor(context), icon: const Icon(Icons.add), label: const Text('Create first branch')),
          ]),
        ),
      );
}

class _AddBranchPage extends StatelessWidget {
  const _AddBranchPage();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_circle_outline, size: 56, color: Pal.muted),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => showBranchEditor(context), child: const Text('Add another branch')),
        ]),
      );
}

class _BranchPage extends ConsumerWidget {
  const _BranchPage({super.key, required this.branchId});
  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider.select((a) => a.view));
    final branch = s.branches.where((b) => b.id == branchId).firstOrNull;
    if (branch == null) return const SizedBox.shrink();
    final acts = s.activitiesOf(branchId);
    final lvl = levelForXp(xpOf(s.records.where((r) => r.branchId == branchId)));
    final color = Color(branch.color);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Icon(iconFor(branch.iconCodePoint), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(branch.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              if (branch.description.isNotEmpty) Text(branch.description, style: const TextStyle(color: Pal.muted, fontSize: 13)),
            ]),
          ),
          IconButton(onPressed: () => showBranchEditor(context, existing: branch), icon: const Icon(Icons.edit_outlined, size: 20, color: Pal.muted)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text('Level ${lvl.level}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${lvl.xpIntoLevel} / ${lvl.xpForNext} XP', style: const TextStyle(color: Pal.muted, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        XpBar(fraction: lvl.fraction, color: color),
        const SizedBox(height: 20),
        if (acts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('No activities in this branch yet.', style: TextStyle(color: Pal.muted)),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: () => _newActivity(context), icon: const Icon(Icons.add), label: const Text('Add first activity')),
              ]),
            ),
          )
        else ...[
          for (final a in acts) Padding(padding: const EdgeInsets.only(bottom: 14), child: ActivityCard(key: ValueKey(a.id), activity: a)),
          Center(child: TextButton.icon(onPressed: () => _newActivity(context), icon: const Icon(Icons.add), label: const Text('Add activity'))),
        ],
      ],
    );
  }

  void _newActivity(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityEditorPage(branchId: branchId)));
}

/// One activity with its input fields: fill in, press Record. Two interactions.
class ActivityCard extends ConsumerStatefulWidget {
  const ActivityCard({super.key, required this.activity});
  final Activity activity;
  @override
  ConsumerState<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<ActivityCard> {
  final Map<String, TextEditingController> _text = {};
  final Map<String, double> _scale = {};
  final Map<String, bool> _bool = {};
  String? _error;

  Activity get a => widget.activity;

  TextEditingController _ctl(String id) => _text.putIfAbsent(id, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  ActivityField? get _goalField {
    if (a.goal == null || a.goalFieldId == null) return null;
    for (final f in a.fields) {
      if (f.id == a.goalFieldId && (f.type == FieldType.number || f.type == FieldType.duration)) return f;
    }
    return null;
  }

  /// Value typed in the goal field, in stored units (seconds for durations); 0 when empty or invalid.
  double _goalValue(ActivityField f) {
    final n = double.tryParse(_ctl(f.id).text.trim().replaceAll(',', '.'));
    if (n == null || n < 0) return 0;
    return f.type == FieldType.duration ? (n * 60).roundToDouble() : n;
  }

  /// Points this record would earn right now.
  int get _points {
    final f = _goalField;
    if (f == null) return a.baseXp;
    return goalXp(baseXp: a.baseXp, value: _goalValue(f), goal: a.goal!);
  }

  String? get _preview {
    final f = _goalField;
    if (f == null) return null;
    final v = _goalValue(f);
    final g = a.goal!;
    final d = f.type == FieldType.duration ? 60 : 1;
    final pct = (v / g * 100).round();
    return '${_n(v / d)} / ${_n(g / d)} = $pct% → +$_points XP';
  }

  Future<void> _record() async {
    final values = <String, dynamic>{};
    for (final f in a.fields) {
      switch (f.type) {
        case FieldType.number:
        case FieldType.duration:
          final raw = _ctl(f.id).text.trim().replaceAll(',', '.');
          if (raw.isEmpty) {
            if (f.required || f.id == _goalField?.id) return setState(() => _error = 'Enter ${f.name}.');
            continue;
          }
          final n = double.tryParse(raw);
          if (n == null || n < 0) return setState(() => _error = '${f.name} must be a positive number.');
          if (f.type == FieldType.duration) {
            values[f.id] = (n * 60).round();
          } else {
            values[f.id] = n == n.roundToDouble() ? n.round() : n;
          }
        case FieldType.scale:
          values[f.id] = (_scale[f.id] ?? 5).round();
        case FieldType.yesNo:
          values[f.id] = _bool[f.id] ?? false;
        case FieldType.text:
          final t = _ctl(f.id).text.trim();
          if (t.isEmpty && f.required) return setState(() => _error = 'Enter ${f.name}.');
          if (t.isNotEmpty) values[f.id] = t;
      }
    }
    setState(() => _error = null);
    final c = ref.read(appProvider.notifier);
    final rec = Record(
      id: c.newId('rc'),
      activityId: a.id,
      branchId: a.branchId,
      timestamp: DateTime.now(),
      values: values,
      xpEarned: _points,
      goal: _goalField == null ? null : a.goal,
    );
    final earned = rec.xpEarned;
    final before = ref.read(playerStatsProvider).level.level;
    final r = await c.addRecord(rec);
    if (!mounted) return;
    if (r.outcome == OpOutcome.rejected) {
      toast(context, 'Not saved: ${r.message}', error: true);
      return;
    }
    for (final t in _text.values) {
      t.clear();
    }
    _scale.clear();
    _bool.clear();
    setState(() {});
    final after = ref.read(playerStatsProvider).level.level;
    toast(context, after > before ? 'Recorded +$earned XP. Level up! You are now level $after.' : 'Recorded +$earned XP');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider.select((x) => x.view));
    final recs = s.recordsOfActivity(a.id);
    final last = recs.firstOrNull;
    final color = Color(a.color);
    final imp = improvement(s, a);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(iconFor(a.iconCodePoint), color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(a.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: 'History',
              visualDensity: VisualDensity.compact,
              onPressed: () => showHistory(context, a),
              icon: const Icon(Icons.history, size: 22, color: Pal.muted),
            ),
            IconButton(
              tooltip: 'Edit activity',
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityEditorPage(branchId: a.branchId, existing: a))),
              icon: const Icon(Icons.edit_outlined, size: 20, color: Pal.muted),
            ),
          ]),
          Text(
            last == null ? 'No records yet' : '${recs.length} ${recs.length == 1 ? 'record' : 'records'} · last ${DateFormat.MMMd().add_Hm().format(last.timestamp.toLocal())}',
            style: const TextStyle(color: Pal.muted, fontSize: 12),
          ),
          if (imp != null && imp.ratio > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${imp.fieldName}: ${_n(imp.first)} → ${_n(imp.latest)}', style: TextStyle(color: color, fontSize: 12)),
            ),
          const SizedBox(height: 10),
          for (final f in a.fields) _fieldInput(f, last),
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Pal.red, fontSize: 13))),
          if (_preview != null)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_preview!, style: TextStyle(color: color, fontSize: 13))),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
              onPressed: _record,
              icon: const Icon(Icons.check),
              label: Text('Record  (+$_points XP)'),
            ),
          ),
        ]),
      ),
    );
  }

  String _n(num v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  Widget _fieldInput(ActivityField f, Record? last) {
    final label = f.unit == null ? f.name : '${f.name} (${f.unit})';
    final lastVal = last?.values[f.id];
    switch (f.type) {
      case FieldType.number:
      case FieldType.duration:
        String? hint;
        if (lastVal is num) hint = 'last: ${_n(f.type == FieldType.duration ? lastVal / 60 : lastVal)}';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _ctl(f.id),
            onChanged: (_) => setState(() => _error = null),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: f.type == FieldType.duration ? '$label - minutes' : label, hintText: hint),
          ),
        );
      case FieldType.scale:
        final v = _scale[f.id] ?? 5;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(child: Text('$label: ${v.round()}')),
            Expanded(flex: 2, child: Slider(value: v, min: 1, max: 10, divisions: 9, label: '${v.round()}', onChanged: (x) => setState(() => _scale[f.id] = x))),
          ]),
        );
      case FieldType.yesNo:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label),
          value: _bool[f.id] ?? false,
          onChanged: (x) => setState(() => _bool[f.id] = x),
        );
      case FieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(controller: _ctl(f.id), onChanged: (_) { if (_error != null) setState(() => _error = null); }, decoration: InputDecoration(labelText: label)),
        );
    }
  }
}

String formatValue(ActivityField f, Object? v) {
  if (v == null) return '-';
  switch (f.type) {
    case FieldType.duration:
      return v is num ? '${(v / 60).toStringAsFixed(v % 60 == 0 ? 0 : 1)} min' : '$v';
    case FieldType.yesNo:
      return v == true ? 'Yes' : 'No';
    default:
      return '$v${f.unit == null ? '' : ' ${f.unit}'}';
  }
}

void showHistory(BuildContext context, Activity a) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Pal.surface,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => _HistorySheet(activityId: a.id, scroll: scroll),
    ),
  );
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({required this.activityId, required this.scroll});
  final String activityId;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider.select((x) => x.view));
    final a = s.activities.where((x) => x.id == activityId).firstOrNull;
    if (a == null) return const SizedBox.shrink();
    final recs = s.recordsOfActivity(a.id);
    final imp = improvement(s, a);
    return ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
      Text(a.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('${recs.length} ${recs.length == 1 ? 'record' : 'records'} · ${recs.fold<int>(0, (t, r) => t + r.xpEarned)} XP',
          style: const TextStyle(color: Pal.muted)),
      if (imp != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('${imp.fieldName}: ${imp.first} → ${imp.latest}', style: const TextStyle(color: Pal.green)),
        ),
      const Divider(height: 28),
      if (recs.isEmpty) const Text('Nothing recorded yet.', style: TextStyle(color: Pal.muted)),
      for (final r in recs)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(a.fields.isEmpty ? 'Done' : a.fields.map((f) => '${f.name}: ${formatValue(f, r.values[f.id])}').join('   ')),
          subtitle: Text(DateFormat.yMMMd().add_Hm().format(r.timestamp.toLocal())),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Pal.muted),
            onPressed: () async {
              if (await confirm(context, 'Delete record?', 'This removes the record and its ${r.xpEarned} XP.')) {
                final res = await ref.read(appProvider.notifier).deleteRecord(r.id);
                if (context.mounted && res.outcome == OpOutcome.rejected) toast(context, res.message, error: true);
              }
            },
          ),
        ),
    ]);
  }
}
