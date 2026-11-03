import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/local_store.dart';
import '../state/providers.dart';
import 'common.dart';
import 'theme.dart';

String formatPushTime(DateTime t) => DateFormat.MMMd().add_Hm().format(t);

/// Pushes every pending change and shows the real progress ("Sending N of M…"),
/// then a summary. With nothing pending it only refreshes from GitHub.
Future<void> showPushDialog(BuildContext context, WidgetRef ref) async {
  final app = ref.read(appProvider);
  if (!app.github.isConfigured || app.push.running) return;
  if (!app.hasPending) {
    await ref.read(appProvider.notifier).refresh();
    if (context.mounted) toast(context, 'Nothing to push. Refreshed from GitHub.');
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PushDialog(),
  );
}

class _PushDialog extends ConsumerStatefulWidget {
  const _PushDialog();
  @override
  ConsumerState<_PushDialog> createState() => _PushDialogState();
}

class _PushDialogState extends ConsumerState<_PushDialog> {
  PushLogEntry? _result;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    final entry = await ref.read(appProvider.notifier).pushNow();
    if (!mounted) return;
    setState(() {
      _result = entry;
      _finished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final p = app.push;
    if (!_finished) {
      return AlertDialog(
        title: const Text('Push to GitHub'),
        content: Row(children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 16),
          Expanded(child: Text(p.total == 0 ? 'Sending…' : 'Sending ${p.done} of ${p.total}…')),
        ]),
      );
    }
    final r = _result;
    final String summary;
    if (r == null) {
      summary = 'Nothing was sent.';
    } else {
      summary = '${r.succeeded} saved'
          '${r.rejected > 0 ? ', ${r.rejected} rejected' : ''}'
          '${r.failed > 0 ? ', ${r.failed} failed' : ''}'
          ' (of ${r.sent} sent).';
    }
    return AlertDialog(
      title: const Text('Push finished'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(summary),
        if (app.hasPending)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${app.pendingCount} change(s) still waiting.', style: const TextStyle(color: Pal.muted, fontSize: 12)),
          ),
        if (app.notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(app.notice!, style: const TextStyle(color: Pal.red, fontSize: 12)),
          ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    );
  }
}
