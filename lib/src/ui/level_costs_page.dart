import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../domain/apply.dart' show maxLevelCosts;
import '../domain/progress.dart';
import '../state/providers.dart';
import 'common.dart';
import 'theme.dart';

/// Sets how many XP each level of a branch costs. Level 1 -> 2 is the first row;
/// the cost may grow from one level to the next by whatever amount you choose.
class LevelCostsPage extends ConsumerStatefulWidget {
  const LevelCostsPage({super.key, required this.branchId});
  final String branchId;
  @override
  ConsumerState<LevelCostsPage> createState() => _LevelCostsPageState();
}

class _LevelCostsPageState extends ConsumerState<LevelCostsPage> {
  static const _defaultRows = 10;
  late final List<TextEditingController> _rows;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final b = _branch;
    final costs = b?.levelCosts ?? [for (var l = 1; l <= _defaultRows; l++) levelCost(l)];
    _rows = [for (final c in costs) TextEditingController(text: '$c')];
  }

  Branch? get _branch => ref.read(appProvider).view.branches.where((b) => b.id == widget.branchId).firstOrNull;

  @override
  void dispose() {
    for (final c in _rows) {
      c.dispose();
    }
    super.dispose();
  }

  /// The costs as typed, or null (with [_error] set) when a row is not a whole number above 0.
  List<int>? _parse() {
    final out = <int>[];
    for (var i = 0; i < _rows.length; i++) {
      final n = int.tryParse(_rows[i].text.trim());
      if (n == null || n <= 0) {
        setState(() => _error = 'Level ${i + 1} needs a whole number of points greater than 0.');
        return null;
      }
      out.add(n);
    }
    if (out.isEmpty) {
      setState(() => _error = 'Add at least one level.');
      return null;
    }
    return out;
  }

  void _setRows(List<int> costs) => setState(() {
        for (final c in _rows) {
          c.dispose();
        }
        _rows
          ..clear()
          ..addAll([for (final c in costs) TextEditingController(text: '$c')]);
        _error = null;
      });

  Future<void> _generate() async {
    final first = TextEditingController(text: '$defaultFirstLevelCost');
    final step = TextEditingController(text: '$defaultLevelStep');
    final count = TextEditingController(text: '20');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Fill with a pattern'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: first, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Points for level 1 → 2')),
          const SizedBox(height: 10),
          TextField(controller: step, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Extra points each level', helperText: '0 keeps every level the same.')),
          const SizedBox(height: 10),
          TextField(controller: count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of levels')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Fill')),
        ],
      ),
    );
    final f = int.tryParse(first.text.trim());
    final st = int.tryParse(step.text.trim());
    final n = int.tryParse(count.text.trim());
    first.dispose();
    step.dispose();
    count.dispose();
    if (ok != true || !mounted) return;
    if (f == null || f <= 0 || st == null || st < 0 || n == null || n < 1 || n > maxLevelCosts) {
      setState(() => _error = 'Use whole numbers: first level above 0, extra points 0 or more, 1 to $maxLevelCosts levels.');
      return;
    }
    _setRows([for (var i = 0; i < n; i++) f + st * i]);
  }

  Future<void> _save({bool useDefault = false}) async {
    final costs = useDefault ? null : _parse();
    if (!useDefault && costs == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final b = _branch;
    if (b == null) return;
    final r = await ref.read(appProvider.notifier).saveBranch(
          costs == null ? b.copyWith(clearLevelCosts: true) : b.copyWith(levelCosts: costs),
          isNew: false,
        );
    if (!mounted) return;
    if (r.outcome == OpOutcome.rejected) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    toast(context, useDefault ? 'Back to the default level points' : 'Level points saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(appProvider.select((a) => a.view.branches.where((x) => x.id == widget.branchId).firstOrNull));
    if (b == null) return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    final color = Color(b.color);
    return Scaffold(
      appBar: AppBar(title: Text('${b.name}: level points')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        const Text(
          'How many XP it takes to leave each level. Set any amount per level, usually more as the level goes up. '
          'Levels after the last row cost the same as the last row.',
          style: TextStyle(color: Pal.muted, fontSize: 13),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            b.levelCosts == null ? 'Using the default: $defaultFirstLevelCost XP, then $defaultLevelStep more each level.' : 'Custom points for this branch.',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(onPressed: _generate, icon: const Icon(Icons.auto_fix_high, size: 18), label: const Text('Fill with a pattern')),
          OutlinedButton.icon(
            onPressed: _rows.length >= maxLevelCosts
                ? null
                : () => setState(() {
                      final last = int.tryParse(_rows.isEmpty ? '' : _rows.last.text.trim());
                      _rows.add(TextEditingController(text: '${last ?? defaultFirstLevelCost}'));
                    }),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add level'),
          ),
        ]),
        const SizedBox(height: 12),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 96, child: Text('${i + 1} → ${i + 2}', style: const TextStyle(color: Pal.muted))),
              Expanded(
                child: TextField(
                  key: ValueKey('cost-$i'),
                  controller: _rows[i],
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(suffixText: 'XP'),
                ),
              ),
              IconButton(
                tooltip: 'Remove level',
                onPressed: _rows.length <= 1
                    ? null
                    : () => setState(() {
                          _rows.removeAt(i).dispose();
                          _error = null;
                        }),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
              ),
            ]),
          ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 4, bottom: 8), child: Text(_error!, style: const TextStyle(color: Pal.red))),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        FilledButton(onPressed: _busy ? null : _save, child: const Padding(padding: EdgeInsets.all(10), child: Text('Save level points'))),
        if (b.levelCosts != null)
          TextButton(onPressed: _busy ? null : () => _save(useDefault: true), child: const Text('Use the default points')),
      ]),
    );
  }
}
