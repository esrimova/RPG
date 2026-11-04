import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/local_store.dart';
import '../data/remote_store.dart';
import '../domain/models.dart';
import '../state/providers.dart';
import 'common.dart';
import 'editors.dart';
import 'icons.dart';
import 'level_costs_page.dart';
import 'push_dialog.dart';
import 'theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: ListView(padding: const EdgeInsets.all(16), children: const [
        NoticeBanner(),
        _StructureSection(),
        SizedBox(height: 20),
        _GithubSection(),
        SizedBox(height: 20),
        SizedBox(height: 32),
      ]),
    );
  }
}

Widget _title(String t, [String? sub]) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (sub != null) Text(sub, style: const TextStyle(color: Pal.muted, fontSize: 12)),
      ]),
    );

// ---------------------------------------------------------------- structure

class _StructureSection extends ConsumerWidget {
  const _StructureSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider.select((a) => a.view));
    final c = ref.read(appProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('Branches and activities', 'Create what you want to track. Nothing is preloaded.'),
      if (s.branches.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('No branches yet.', style: TextStyle(color: Pal.muted))),
      for (final b in s.branches)
        Card(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(iconFor(b.iconCodePoint), color: Color(b.color)),
              title: Text(b.name),
              subtitle: Text('${s.activitiesOf(b.id).length} ${s.activitiesOf(b.id).length == 1 ? 'activity' : 'activities'}'),
              children: [
                for (final a in s.activitiesOf(b.id))
                  ListTile(
                    dense: true,
                    leading: Icon(iconFor(a.iconCodePoint), color: Color(a.color), size: 20),
                    title: Text(a.name),
                    subtitle: Text(a.fields.isEmpty ? 'No fields' : a.fields.map((f) => f.name).join(', ')),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityEditorPage(branchId: b.id, existing: a))),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Pal.red, size: 20),
                      onPressed: () async {
                        if (await confirm(context, 'Delete "${a.name}"?', 'All its records will be deleted too.')) {
                          final r = await c.deleteActivity(a.id);
                          if (context.mounted && r.outcome == OpOutcome.rejected) toast(context, r.message, error: true);
                        }
                      },
                    ),
                  ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityEditorPage(branchId: b.id))),
                      icon: const Icon(Icons.add),
                      label: const Text('Add activity')),
                  TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LevelCostsPage(branchId: b.id))),
                      child: const Text('Level points')),
                  TextButton(onPressed: () => showBranchEditor(context, existing: b), child: const Text('Edit branch')),
                  TextButton(
                    onPressed: () async {
                      if (await confirm(context, 'Delete "${b.name}"?', 'Its activities and all their records will be deleted too.')) {
                        final r = await c.deleteBranch(b.id);
                        if (context.mounted && r.outcome == OpOutcome.rejected) toast(context, r.message, error: true);
                      }
                    },
                    child: const Text('Delete', style: TextStyle(color: Pal.red)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () => showBranchEditor(context), icon: const Icon(Icons.add), label: const Text('Add branch')),
    ]);
  }
}

// ------------------------------------------------------------------- github

class _GithubSection extends ConsumerStatefulWidget {
  const _GithubSection();
  @override
  ConsumerState<_GithubSection> createState() => _GithubSectionState();
}

class _GithubSectionState extends ConsumerState<_GithubSection> {
  final _repo = TextEditingController();
  final _pat = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  ConnectionReport? _report;
  bool _seeded = false;

  void _seed() {
    final g = ref.read(appProvider).github;
    if (_seeded || (!g.isConfigured && !ref.read(appProvider).loaded)) return;
    _seeded = true;
    _repo.text = g.repo;
    _pat.text = g.pat;
  }

  GithubConfig get _cfg => GithubConfig(repo: _repo.text.trim(), pat: _pat.text.trim());

  Future<void> _test() async {
    setState(() => _busy = true);
    final r = await ref.read(appProvider.notifier).testConnection(_cfg);
    if (mounted) {
      setState(() {
        _busy = false;
        _report = r;
      });
    }
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    final r = await ref.read(appProvider.notifier).connect(_cfg);
    if (mounted) {
      setState(() {
        _busy = false;
        _report = r;
      });
      if (r.ok) toast(context, 'GitHub connected. Syncing your data…');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    _seed();
    final connected = app.github.isConfigured;
    final report = _report ?? app.connection;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('GitHub storage', 'Your data lives as JSON files in a private repository you own. Without it, data stays on this phone only.'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(connected ? Icons.cloud_done : Icons.cloud_off, color: connected ? Pal.green : Pal.muted),
              const SizedBox(width: 8),
              Expanded(child: Text(connected ? 'Connected to ${app.github.repo}' : 'Not connected (local only)', style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            if (connected) ...[
              const SizedBox(height: 4),
              Text(
                app.lastSync == null ? 'Never synced' : 'Last sync ${DateFormat.MMMd().add_Hm().format(app.lastSync!)} · ${app.pendingCount} change(s) waiting',
                style: const TextStyle(color: Pal.muted, fontSize: 12),
              ),
              Text(
                app.pushLog.isEmpty ? 'Never pushed' : 'Last push ${formatPushTime(app.pushLog.first.time)}',
                style: const TextStyle(color: Pal.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            TextField(controller: _repo, autocorrect: false, decoration: const InputDecoration(labelText: 'Repository', hintText: 'owner/name')),
            const SizedBox(height: 10),
            TextField(
              controller: _pat,
              obscureText: _hide,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Personal access token',
                helperText: 'Needs Contents (read/write) and Actions on that repository. Stored encrypted on this device.',
                helperMaxLines: 3,
                suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hide = !_hide)),
              ),
            ),
            if (report != null) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(report.ok ? Icons.check_circle : Icons.error, color: report.ok ? Pal.green : Pal.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(report.message, style: const TextStyle(fontSize: 13))),
              ]),
            ],
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(),
            Wrap(spacing: 8, runSpacing: 4, children: [
              OutlinedButton(onPressed: _busy ? null : _test, child: const Text('Test connection')),
              FilledButton(onPressed: _busy ? null : _connect, child: Text(connected ? 'Update' : 'Connect')),
              if (connected)
                FilledButton.icon(
                  onPressed: app.syncing || !app.hasPending ? null : () => showPushDialog(context, ref),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text('Push to GitHub (${app.pendingCount})'),
                ),
              if (connected)
                OutlinedButton(
                    onPressed: app.syncing ? null : () => ref.read(appProvider.notifier).refresh(),
                    child: const Text('Refresh from GitHub')),
              if (connected)
                TextButton(
                  onPressed: () async {
                    final n = ref.read(appProvider).pendingCount;
                    final text = n > 0
                        ? 'Data stays on this phone but will no longer sync.\n\n'
                            '$n change(s) are not pushed to GitHub and could be lost if you reconnect - push first.'
                        : 'Data stays on this phone but will no longer sync.';
                    if (await confirm(context, 'Disconnect GitHub?', text, action: 'Disconnect')) {
                      await ref.read(appProvider.notifier).disconnect();
                      if (mounted) setState(() => _report = null);
                    }
                  },
                  child: const Text('Disconnect', style: TextStyle(color: Pal.red)),
                ),
            ]),
          ]),
        ),
      ),
      if (connected && app.pushLog.isNotEmpty) ...[
        const SizedBox(height: 16),
        _title('Push log', 'Last ${app.pushLog.length > 10 ? 10 : app.pushLog.length} pushes'),
        Card(
          child: Column(children: [
            for (final e in app.pushLog.take(10))
              ListTile(
                dense: true,
                leading: Icon(e.rejected + e.failed > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: e.rejected + e.failed > 0 ? Pal.yellow : Pal.green, size: 20),
                title: Text(formatPushTime(e.time)),
                subtitle: Text('${e.sent} sent · ${e.succeeded} saved · ${e.rejected} rejected · ${e.failed} failed'),
              ),
          ]),
        ),
      ],
    ]);
  }
}

// ----------------------------------------------------------------------- ai
