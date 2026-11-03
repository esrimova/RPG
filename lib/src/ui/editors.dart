import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../state/providers.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

/// Turns a save result into UI feedback. Returns true when the editor can close.
bool _handleResult(BuildContext context, OpResult r, String what) {
  switch (r.outcome) {
    case OpOutcome.success:
      toast(context, '$what saved');
      return true;
    case OpOutcome.pending:
      toast(context, '$what is still syncing with GitHub. It will finish in the background.');
      return true;
    case OpOutcome.failed:
      toast(context, '$what is saved on this device and queued. ${r.message}', error: true);
      return true;
    case OpOutcome.rejected:
      return false;
  }
}

Future<void> showBranchEditor(BuildContext context, {Branch? existing}) =>
    showDialog(context: context, builder: (_) => _BranchDialog(existing: existing));

class _BranchDialog extends ConsumerStatefulWidget {
  const _BranchDialog({this.existing});
  final Branch? existing;
  @override
  ConsumerState<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends ConsumerState<_BranchDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _desc = TextEditingController(text: widget.existing?.description ?? '');
  late int _color = widget.existing?.color ?? Pal.picks.first;
  late int _icon = widget.existing?.iconCodePoint ?? pickableIcons.first.codePoint;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the branch a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final c = ref.read(appProvider.notifier);
    final isNew = widget.existing == null;
    final b = (widget.existing ??
            Branch(id: c.newId('br'), name: name, color: _color, iconCodePoint: _icon, createdAt: DateTime.now()))
        .copyWith(name: name, description: _desc.text.trim(), color: _color, iconCodePoint: _icon);
    final r = await c.saveBranch(b, isNew: isNew);
    if (!mounted) return;
    if (_handleResult(context, r, 'Branch')) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = r.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New branch' : 'Edit branch'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _name, autofocus: true, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Physical Development')),
          const SizedBox(height: 12),
          TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description (optional)')),
          const SizedBox(height: 16),
          const Text('Color', style: TextStyle(color: Pal.muted, fontSize: 12)),
          const SizedBox(height: 8),
          ColorPicker(value: _color, onChanged: (v) => setState(() => _color = v)),
          const SizedBox(height: 16),
          const Text('Icon', style: TextStyle(color: Pal.muted, fontSize: 12)),
          const SizedBox(height: 8),
          IconPicker(value: _icon, color: _color, onChanged: (v) => setState(() => _icon = v)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Pal.red)),
          ],
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            const Text('Saving and syncing…', style: TextStyle(color: Pal.muted, fontSize: 12)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}

/// Full-screen activity editor with the field (metric) definitions.
class ActivityEditorPage extends ConsumerStatefulWidget {
  const ActivityEditorPage({super.key, required this.branchId, this.existing});
  final String branchId;
  final Activity? existing;
  @override
  ConsumerState<ActivityEditorPage> createState() => _ActivityEditorPageState();
}

class _FieldDraft {
  _FieldDraft({String? id, String name = '', this.type = FieldType.number, String unit = '', this.required = true})
      : id = id ?? 'f${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        name = TextEditingController(text: name),
        unit = TextEditingController(text: unit);
  final String id;
  final TextEditingController name;
  final TextEditingController unit;
  FieldType type;
  bool required;
}

class _ActivityEditorPageState extends ConsumerState<ActivityEditorPage> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _desc = TextEditingController(text: widget.existing?.description ?? '');
  late final _xp = TextEditingController(text: '${widget.existing?.baseXp ?? 10}');
  late int _color = widget.existing?.color ?? Pal.picks.first;
  late int _icon = widget.existing?.iconCodePoint ?? pickableIcons.first.codePoint;
  late final List<_FieldDraft> _fields = [
    for (final f in widget.existing?.fields ?? const <ActivityField>[])
      _FieldDraft(id: f.id, name: f.name, type: f.type, unit: f.unit ?? '', required: f.required),
  ];
  late final _goal = TextEditingController(text: _initialGoalText());
  late String? _goalFieldId = widget.existing?.goalFieldId;
  bool _busy = false;
  String? _error;

  /// Duration goals are shown in minutes (stored in seconds, like the field value).
  String _initialGoalText() {
    final a = widget.existing;
    final g = a?.goal;
    if (a == null || g == null) return '';
    final isDuration = a.fields.any((f) => f.id == a.goalFieldId && f.type == FieldType.duration);
    return _num(isDuration ? g / 60 : g);
  }

  static String _num(num v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  bool _countable(_FieldDraft f) => f.type == FieldType.number || f.type == FieldType.duration;

  bool get _hasGoal => _goal.text.trim().isNotEmpty;

  List<_FieldDraft> get _candidates => _fields.where(_countable).toList();

  /// The field the goal is counted on: the chosen one, else the first number/duration field.
  _FieldDraft? get _goalField {
    final c = _candidates;
    if (c.isEmpty) return null;
    return c.firstWhere((f) => f.id == _goalFieldId, orElse: () => c.first);
  }

  @override
  void initState() {
    super.initState();
    // A leftover snackbar from the previous screen must not cover the Save button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Give the activity a name.');
    final xp = int.tryParse(_xp.text.trim());
    if (xp == null || xp < 0 || xp > 1000) return setState(() => _error = 'XP per record must be a number from 0 to 1000.');
    for (final f in _fields) {
      if (f.name.text.trim().isEmpty) return setState(() => _error = 'Every field needs a name (or remove it).');
    }
    final names = _fields.map((f) => f.name.text.trim().toLowerCase()).toList();
    if (names.toSet().length != names.length) return setState(() => _error = 'Two fields have the same name.');

    final gf = _goalField;
    double? goal;
    if (_hasGoal) {
      if (gf == null) return setState(() => _error = 'A goal needs a number or duration field to count. Add one or clear the goal.');
      final g = double.tryParse(_goal.text.trim().replaceAll(',', '.'));
      if (g == null || g <= 0) return setState(() => _error = 'The goal must be a number greater than 0.');
      goal = gf.type == FieldType.duration ? g * 60 : g;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final c = ref.read(appProvider.notifier);
    final fields = [
      for (final f in _fields)
        ActivityField(
            id: f.id,
            name: f.name.text.trim(),
            type: f.type,
            unit: f.unit.text.trim().isEmpty ? null : f.unit.text.trim(),
            required: f.required || (goal != null && f.id == gf?.id)),
    ];
    final isNew = widget.existing == null;
    final a = (widget.existing ??
            Activity(id: c.newId('ac'), branchId: widget.branchId, name: name, color: _color, iconCodePoint: _icon, createdAt: DateTime.now()))
        .copyWith(name: name, description: _desc.text.trim(), color: _color, iconCodePoint: _icon, baseXp: xp, fields: fields, goal: goal, goalFieldId: goal == null ? null : gf!.id, clearGoal: goal == null);
    final r = await c.saveActivity(a, isNew: isNew);
    if (!mounted) return;
    if (_handleResult(context, r, 'Activity')) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = r.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New activity' : 'Edit activity')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Push-ups')),
        const SizedBox(height: 12),
        TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description (optional)')),
        const SizedBox(height: 12),
        TextField(
            controller: _xp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'XP earned per record', helperText: 'Each time you record this activity you earn this much XP.')),
        const SizedBox(height: 12),
        TextField(
          controller: _goal,
          onChanged: (_) => setState(() => _goalFieldId ??= _goalField?.id),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Goal',
            helperText: _goalField?.type == FieldType.duration
                ? 'Optional. In minutes. Reaching it earns the full XP; more or less scales it.'
                : 'Optional. Reaching it earns the full XP; more or less scales it.',
          ),
        ),
        if (_hasGoal && _candidates.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<String>(
              key: ValueKey('goalfield-${_goalField?.id}-${_candidates.length}'),
              initialValue: _goalField?.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Goal field'),
              items: [
                for (final f in _candidates)
                  DropdownMenuItem(value: f.id, child: Text(f.name.text.trim().isEmpty ? 'Unnamed field' : f.name.text.trim(), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _goalFieldId = v),
            ),
          )
        else if (_hasGoal && _candidates.length == 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Counted on: ${_goalField!.name.text.trim().isEmpty ? 'your field' : _goalField!.name.text.trim()}',
                style: const TextStyle(color: Pal.muted, fontSize: 12)),
          ),
        const SizedBox(height: 16),
        const Text('Color', style: TextStyle(color: Pal.muted, fontSize: 12)),
        const SizedBox(height: 8),
        ColorPicker(value: _color, onChanged: (v) => setState(() => _color = v)),
        const SizedBox(height: 16),
        const Text('Icon', style: TextStyle(color: Pal.muted, fontSize: 12)),
        const SizedBox(height: 8),
        IconPicker(value: _icon, color: _color, onChanged: (v) => setState(() => _icon = v)),
        const SizedBox(height: 24),
        Row(children: [
          const Expanded(child: Text('What do you measure?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          TextButton.icon(onPressed: () => setState(() => _fields.add(_FieldDraft())), icon: const Icon(Icons.add), label: const Text('Add field')),
        ]),
        const Text('Fields appear when you record this activity (for example Reps, or Duration).', style: TextStyle(color: Pal.muted, fontSize: 12)),
        const SizedBox(height: 8),
        if (_fields.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No fields: recording will just log that you did it.', style: TextStyle(color: Pal.muted)),
          ),
        for (final f in _fields) _fieldCard(f),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Pal.red))),
        const SizedBox(height: 16),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        FilledButton(onPressed: _busy ? null : _save, child: Padding(padding: const EdgeInsets.all(10), child: Text(isNew ? 'Create activity' : 'Save changes'))),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _fieldCard(_FieldDraft f) {
    final locked = _hasGoal && _goalField?.id == f.id; // the goal needs this field
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                Expanded(child: TextField(controller: f.name, decoration: const InputDecoration(labelText: 'Field name', hintText: 'e.g. Reps'))),
                IconButton(
                  tooltip: locked ? 'Clear the goal to delete this field' : null,
                  onPressed: locked ? null : () => setState(() => _fields.remove(f)),
                  icon: Icon(Icons.delete_outline, color: locked ? Pal.muted : Pal.red)),
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<FieldType>(
                initialValue: f.type,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Type',
                  helperText: locked ? 'Used by the goal' : (f.type == FieldType.duration ? 'You enter minutes when recording.' : null),
                ),
                items: [for (final t in FieldType.values) DropdownMenuItem(value: t, child: Text(t.label, overflow: TextOverflow.ellipsis))],
                onChanged: locked ? null : (v) => setState(() => f.type = v ?? f.type),
              ),
              const SizedBox(height: 10),
              TextField(controller: f.unit, decoration: const InputDecoration(labelText: 'Unit (optional)', hintText: 'e.g. kg, km, reps')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Required'),
                value: f.required || locked,
                onChanged: locked ? null : (v) => setState(() => f.required = v),
              ),
            ]),
          ),
        ),
    );
  }
}
