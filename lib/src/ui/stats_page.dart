import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/models.dart';
import '../domain/stats.dart';
import '../state/providers.dart';
import 'common.dart';
import 'history_tree.dart';
import 'theme.dart';

String _n(num v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

String _withUnit(StatDef d, num v) => d.unit == null ? _n(v) : '${_n(v)} ${d.unit}';

/// Character stats: the latest values, and where a new timestamped entry is made.
/// Past entries live on their own page ([StatsHistoryPage]).
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final Map<String, TextEditingController> _ctl = {for (final d in statDefs) d.key: TextEditingController()};
  String? _error;

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final values = <String, num>{};
    for (final d in statDefs) {
      final raw = _ctl[d.key]!.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) continue;
      final n = double.tryParse(raw);
      if (n == null || !n.isFinite || n < 0) return setState(() => _error = '${d.label} must be a number of 0 or more.');
      if (d.max != null && n > d.max!) return setState(() => _error = '${d.label} cannot be more than ${d.max!.round()}.');
      values[d.key] = n == n.roundToDouble() ? n.round() : n;
    }
    if (values.isEmpty) return setState(() => _error = 'Enter at least one stat.');
    setState(() => _error = null);
    final c = ref.read(appProvider.notifier);
    final r = await c.addStat(StatEntry(id: c.newId('st'), timestamp: DateTime.now(), values: values));
    if (!mounted) return;
    if (r.outcome == OpOutcome.rejected) {
      toast(context, 'Not saved: ${r.message}', error: true);
      return;
    }
    for (final t in _ctl.values) {
      t.clear();
    }
    toast(context, 'Stats saved');
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(appProvider.select((a) => a.view.stats));
    final latest = latestStatValues(stats);
    final newest = statsNewestFirst(stats).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Character stats'), actions: [
        IconButton(
          tooltip: 'Stats history',
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsHistoryPage())),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Pal.red, fontSize: 13))),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Save stats')),
          ]),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        const NoticeBanner(),
        const Text('Current', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          newest == null ? 'Nothing recorded yet.' : 'Last entry ${DateFormat.yMMMd().add_Hm().format(newest.timestamp.toLocal())}',
          style: const TextStyle(color: Pal.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final d in statDefs)
            Container(
              key: ValueKey('latest-${d.key}'),
              width: 104,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Pal.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Pal.line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.label, style: const TextStyle(color: Pal.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(latest[d.key] == null ? '-' : _withUnit(d, latest[d.key]!),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Pal.cyan)),
              ]),
            ),
        ]),
        const SizedBox(height: 24),
        const Text('New entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const Text('Fill in what you measured today; leave the rest empty. The date and time are saved automatically.',
            style: TextStyle(color: Pal.muted, fontSize: 12)),
        const SizedBox(height: 12),
        for (final d in statDefs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _ctl[d.key],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: d.unit == null ? d.label : '${d.label} (${d.unit})',
                helperText: d.name,
                hintText: latest[d.key] == null ? null : 'last: ${_n(latest[d.key]!)}',
              ),
            ),
          ),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsHistoryPage())),
            icon: const Icon(Icons.history),
            label: const Text('See history'),
          ),
        ),
      ]),
    );
  }
}

/// Every stats entry, by year and month (each collapsible), each deletable.
class StatsHistoryPage extends ConsumerWidget {
  const StatsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(appProvider.select((a) => a.view.stats));
    String count(List<StatEntry> l) => '${l.length} ${l.length == 1 ? 'entry' : 'entries'}';
    return Scaffold(
      appBar: AppBar(title: const Text('Stats history')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        const NoticeBanner(),
        Text(count(stats), style: const TextStyle(color: Pal.muted)),
        const SizedBox(height: 14),
        if (stats.isEmpty) const Text('Nothing recorded yet.', style: TextStyle(color: Pal.muted)),
        HistoryTree<StatEntry>(
          items: stats,
          timeOf: (e) => e.timestamp,
          summary: count,
          tileBuilder: (ctx, e) => ListTile(
            key: ValueKey(e.id),
            contentPadding: EdgeInsets.zero,
            title: Text(DateFormat.MMMd().add_Hm().format(e.timestamp.toLocal())),
            subtitle: Text([
              for (final d in statDefs)
                if (e.values[d.key] != null) '${d.label} ${_withUnit(d, e.values[d.key]!)}',
            ].join('  ·  ')),
            trailing: IconButton(
              tooltip: 'Delete entry',
              icon: const Icon(Icons.delete_outline, color: Pal.muted),
              onPressed: () async {
                if (await confirm(ctx, 'Delete entry?', 'This removes the stats saved on ${DateFormat.yMMMd().add_Hm().format(e.timestamp.toLocal())}.')) {
                  final res = await ref.read(appProvider.notifier).deleteStat(e.id);
                  if (ctx.mounted && res.outcome == OpOutcome.rejected) toast(ctx, res.message, error: true);
                }
              },
            ),
          ),
        ),
      ]),
    );
  }
}
