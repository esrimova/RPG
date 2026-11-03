import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../domain/quests.dart';
import '../state/providers.dart';
import 'common.dart';
import 'quests_page.dart' show formatDay, questColor;
import 'theme.dart';

/// How an automatic quest picks its dates.
enum _Mode { daily, everyOther, everyN, weekdays, weekends, custom }

const _modeLabels = {
  _Mode.daily: 'Every day',
  _Mode.everyOther: 'Every other day',
  _Mode.everyN: 'Every N days',
  _Mode.weekdays: 'Weekdays only',
  _Mode.weekends: 'Weekends only',
  _Mode.custom: 'Selected days',
};

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _TaskDraft {
  _TaskDraft({required this.id, String name = '', required this.date, this.doneAt, this.isNew = true})
      : name = TextEditingController(text: name);
  final String id;
  final TextEditingController name;
  String date;
  final DateTime? doneAt;
  final bool isNew;
}

DateTime _parse(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String _addDays(String key, int days) {
  final d = _parse(key);
  return dateKey(DateTime(d.year, d.month, d.day + days));
}

/// Creates or edits an active quest. Finished quests are never opened here.
class QuestEditorPage extends ConsumerStatefulWidget {
  const QuestEditorPage({super.key, this.existing});
  final Quest? existing;
  @override
  ConsumerState<QuestEditorPage> createState() => _QuestEditorPageState();
}

class _QuestEditorPageState extends ConsumerState<QuestEditorPage> {
  late final String _today = todayKey(ref.read(clockProvider));
  Quest? get _old => widget.existing;
  late final _name = TextEditingController(text: _old?.name ?? '');
  late final _desc = TextEditingController(text: _old?.description ?? '');
  late final _points = TextEditingController(text: '${_old?.totalXp ?? 100}');
  late final _everyN = TextEditingController(text: '${_initialN()}');
  late String _start = _old?.startDate ?? _today;
  late String _end = _old?.endDate ?? _addDays(_today, 13);
  late bool _auto = _old?.auto ?? true;
  late _Mode _mode = _initialMode();
  late final Set<int> _days = {...?(_old?.pattern?.type == 'weekdays' ? _old!.pattern!.days : null)};
  late final List<_TaskDraft> _tasks = [
    for (final t in _old?.tasks ?? const <QuestTask>[])
      _TaskDraft(id: t.id, name: t.name, date: t.date, doneAt: t.doneAt, isNew: false),
  ];
  late final String _id = _old?.id ?? ref.read(appProvider.notifier).newId('qs');
  bool _busy = false;
  String? _error;

  void _setStart(String d) {
    _start = d;
    _error = null;
  }

  void _setEnd(String d) {
    _end = d;
    _error = null;
  }

  int _initialN() {
    final p = _old?.pattern;
    return p != null && p.type == 'every_n_days' && p.n > 2 ? p.n : 3;
  }

  _Mode _initialMode() {
    final p = _old?.pattern;
    if (p == null) return _Mode.daily;
    if (p.type == 'every_n_days') {
      return p.n == 1 ? _Mode.daily : (p.n == 2 ? _Mode.everyOther : _Mode.everyN);
    }
    final days = [...p.days]..sort();
    if (days.join() == '12345') return _Mode.weekdays;
    if (days.join() == '67') return _Mode.weekends;
    return _Mode.custom;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _points, _everyN, for (final t in _tasks) t.name]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The pattern chosen, or an error message.
  (QuestPattern?, String?) _pattern() {
    switch (_mode) {
      case _Mode.daily:
        return (QuestPattern.everyNDays(1), null);
      case _Mode.everyOther:
        return (QuestPattern.everyNDays(2), null);
      case _Mode.everyN:
        final n = int.tryParse(_everyN.text.trim());
        if (n == null || n < 1 || n > 365) return (null, 'Every N days needs a number from 1 to 365.');
        return (QuestPattern.everyNDays(n), null);
      case _Mode.weekdays:
        return (QuestPattern.weekdays(const [1, 2, 3, 4, 5]), null);
      case _Mode.weekends:
        return (QuestPattern.weekdays(const [6, 7]), null);
      case _Mode.custom:
        if (_days.isEmpty) return (null, 'Pick at least one day of the week.');
        return (QuestPattern.weekdays([..._days]..sort()), null);
    }
  }

  /// The quest as it would be saved, with automatic dates applied, or an
  /// error message. Task names are not checked here.
  (Quest?, String?) _build() {
    if (_start.compareTo(_end) > 0) return (null, 'The start date must not be after the end date.');
    QuestPattern? pattern;
    if (_auto) {
      final (p, err) = _pattern();
      if (err != null) return (null, err);
      pattern = p;
    }
    var q = Quest(
      id: _id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      startDate: _start,
      endDate: _end,
      totalXp: int.tryParse(_points.text.trim()) ?? 0,
      auto: _auto,
      pattern: pattern,
      createdAt: _old?.createdAt ?? DateTime.now(),
      tasks: [
        for (final t in _tasks)
          // A new task in an auto quest starts as "open" (today) so it gets re-spread.
          QuestTask(id: t.id, name: t.name.text.trim(), date: _auto && t.isNew ? _today : t.date, doneAt: t.doneAt),
      ],
    );
    if (_auto && q.tasks.isNotEmpty) {
      if (_old == null) {
        final dates = spreadDates(from: _start, end: _end, pattern: pattern!, anchor: _start, count: q.tasks.length);
        if (dates.isEmpty) return (null, 'No matching dates left');
        q = q.copyWith(tasks: [for (final (i, t) in q.tasks.indexed) t.copyWith(date: dates[i])]);
      } else {
        try {
          q = respreadTasks(q, _today);
        } on StateError catch (e) {
          return (null, e.message);
        }
      }
    }
    return (q, null);
  }

  /// A task keeps its date once checked or once that date has passed.
  bool _dateLocked(_TaskDraft t) => t.doneAt != null || (!t.isNew && t.date.compareTo(_today) < 0);

  String _defaultTaskDate() {
    if (_today.compareTo(_start) < 0) return _start;
    if (_today.compareTo(_end) > 0) return _end;
    return _today;
  }

  void _addTask() => setState(() {
        _error = null;
        _tasks.add(_TaskDraft(id: ref.read(appProvider.notifier).newId('qt'), date: _defaultTaskDate()));
      });

  void _remove(_TaskDraft t) {
    final rest = _tasks.where((x) => x != t);
    if (_old != null && rest.isNotEmpty && rest.every((x) => x.doneAt != null)) {
      setState(() => _error = 'Cannot complete a quest by removing tasks');
      return;
    }
    setState(() {
      _error = null;
      _tasks.remove(t);
    });
    // The row's TextField still listens until the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => t.name.dispose());
  }

  void _move(int i, int by) => setState(() {
        _error = null;
        final t = _tasks.removeAt(i);
        _tasks.insert(i + by, t);
      });

  void _setAuto(bool auto, (Quest?, String?) preview) {
    setState(() {
      _error = null;
      // Switching to manual keeps the dates that were planned automatically.
      if (!auto && _auto && preview.$1 != null) {
        for (final (i, t) in preview.$1!.tasks.indexed) {
          if (!_dateLocked(_tasks[i])) _tasks[i].date = t.date;
        }
      }
      _auto = auto;
    });
  }

  Future<String?> _pickDate(String current, {String? first, String? last}) async {
    final lo = _parse(first ?? _addDays(_today, -365 * 5));
    final hi = _parse(last ?? _addDays(_today, 365 * 5));
    var init = _parse(current);
    if (init.isBefore(lo)) init = lo;
    if (init.isAfter(hi)) init = hi;
    final d = await showDatePicker(context: context, initialDate: init, firstDate: lo, lastDate: hi);
    return d == null ? null : dateKey(d);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return setState(() => _error = 'Give the quest a name.');
    final pts = int.tryParse(_points.text.trim());
    if (pts == null || pts < 0 || pts > 100000) {
      return setState(() => _error = 'Total points must be a number from 0 to 100000.');
    }
    if (_tasks.any((t) => t.name.text.trim().isEmpty)) {
      return setState(() => _error = 'Every task needs a name (or remove it).');
    }
    final (q, err) = _build();
    if (err != null) return setState(() => _error = err);
    if (!_auto && q!.tasks.any((t) => t.date.compareTo(_start) < 0 || t.date.compareTo(_end) > 0)) {
      return setState(() => _error = 'Every task date must be between the start and end dates.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref.read(appProvider.notifier).saveQuest(q!, isNew: _old == null);
    if (!mounted) return;
    if (r.outcome == OpOutcome.rejected) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    toast(context, 'Quest saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _old == null;
    final preview = _build();
    final planned = preview.$1;
    // Only date problems are shown live; the rest waits for Save.
    final shown = _error ?? (_auto && preview.$2 == 'No matching dates left' ? preview.$2 : null);
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New quest' : 'Edit quest')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Build a shed'),
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description (optional)')),
        const SizedBox(height: 12),
        TextField(
          controller: _points,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              labelText: 'Total points',
              helperText: 'Each checked task earns its share. Finish all tasks by the end date to keep them.'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _DateBox(
              key: const Key('startDate'),
              label: 'Start date',
              value: _start,
              onTap: () async {
                final d = await _pickDate(_start);
                if (d != null) setState(() => _setStart(d));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DateBox(
              key: const Key('endDate'),
              label: 'End date',
              value: _end,
              onTap: () async {
                final d = await _pickDate(_end, first: _old == null ? null : _today);
                if (d != null) setState(() => _setEnd(d));
              },
            ),
          ),
        ]),
        const SizedBox(height: 20),
        const Text('Task dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Automatic'), icon: Icon(Icons.auto_awesome)),
            ButtonSegment(value: false, label: Text('Manual'), icon: Icon(Icons.edit_calendar)),
          ],
          selected: {_auto},
          onSelectionChanged: (s) => _setAuto(s.first, preview),
        ),
        const SizedBox(height: 8),
        if (_auto) ..._patternPicker() else const Text('You pick the date of each task.', style: TextStyle(color: Pal.muted, fontSize: 12)),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(child: Text('Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          TextButton.icon(onPressed: _addTask, icon: const Icon(Icons.add), label: const Text('Add task')),
        ]),
        const Text('In order: a task is never planned before the one above it.', style: TextStyle(color: Pal.muted, fontSize: 12)),
        const SizedBox(height: 8),
        if (_tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No tasks yet. A quest completes when every task is checked.', style: TextStyle(color: Pal.muted)),
          ),
        for (final (i, t) in _tasks.indexed) _taskRow(i, t, planned),
        if (shown != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(shown, style: const TextStyle(color: Pal.red))),
        const SizedBox(height: 16),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: questColor, foregroundColor: Colors.black),
          onPressed: _busy ? null : _save,
          child: Padding(padding: const EdgeInsets.all(10), child: Text(isNew ? 'Create quest' : 'Save changes')),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  List<Widget> _patternPicker() => [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in _Mode.values)
            ChoiceChip(
              label: Text(_modeLabels[m]!),
              selected: _mode == m,
              selectedColor: questColor.withValues(alpha: 0.3),
              onSelected: (_) => setState(() {
                _mode = m;
                _error = null;
              }),
            ),
        ]),
        if (_mode == _Mode.everyN)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: _everyN,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _error = null),
              decoration: const InputDecoration(labelText: 'Every how many days', helperText: 'Counted from the start date.'),
            ),
          ),
        if (_mode == _Mode.custom)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(_dayNames[d - 1]),
                  selected: _days.contains(d),
                  selectedColor: questColor.withValues(alpha: 0.3),
                  onSelected: (on) => setState(() {
                    _error = null;
                    on ? _days.add(d) : _days.remove(d);
                  }),
                ),
            ]),
          ),
      ];

  Widget _taskRow(int i, _TaskDraft t, Quest? planned) {
    final locked = _dateLocked(t);
    final Widget date;
    if (_auto || locked) {
      final d = _auto ? planned?.tasks[i].date : t.date;
      date = Text(
        d == null ? 'No date' : formatDay(d),
        style: TextStyle(color: d == null ? Pal.red : Pal.muted, fontSize: 12),
      );
    } else {
      date = _DateBox(
        key: Key('taskDate-$i'),
        label: 'Date',
        value: t.date,
        dense: true,
        onTap: () async {
          final d = await _pickDate(t.date, first: _start, last: _end);
          if (d != null) {
            setState(() {
              t.date = d;
              _error = null;
            });
          }
        },
      );
    }
    return Padding(
      key: ValueKey(t.id),
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: t.name,
                  decoration: const InputDecoration(labelText: 'Task name', hintText: 'e.g. Cut wood'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  if (t.doneAt != null) ...[
                    const Icon(Icons.check_circle, size: 16, color: Pal.green),
                    const SizedBox(width: 4),
                    const Text('Done · ', style: TextStyle(color: Pal.green, fontSize: 12)),
                  ],
                  Flexible(child: date),
                ]),
              ]),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Move up',
                visualDensity: VisualDensity.compact,
                onPressed: i == 0 ? null : () => _move(i, -1),
                icon: const Icon(Icons.arrow_upward, size: 18),
              ),
              IconButton(
                tooltip: 'Move down',
                visualDensity: VisualDensity.compact,
                onPressed: i == _tasks.length - 1 ? null : () => _move(i, 1),
                icon: const Icon(Icons.arrow_downward, size: 18),
              ),
            ]),
            IconButton(
              tooltip: 'Remove task',
              onPressed: () => _remove(t),
              icon: const Icon(Icons.delete_outline, color: Pal.red),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A tappable date shown like a text field.
class _DateBox extends StatelessWidget {
  const _DateBox({super.key, required this.label, required this.value, required this.onTap, this.dense = false});
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            suffixIcon: Icon(Icons.calendar_today, size: dense ? 16 : 18, color: Pal.muted),
          ),
          child: Text(formatDay(value), style: TextStyle(fontSize: dense ? 13 : 15)),
        ),
      );
}
