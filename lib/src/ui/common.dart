import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'icons.dart';
import 'theme.dart';

void toast(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? Pal.red.withValues(alpha: 0.95) : Pal.surface2,
    duration: Duration(seconds: error ? 6 : 3),
  ));
}

/// Shows whether data is local-only, syncing, waiting or synced.
class SyncChip extends ConsumerWidget {
  const SyncChip({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(appProvider);
    late String label;
    late IconData icon;
    late Color color;
    if (!a.github.isConfigured) {
      label = 'Local only';
      icon = Icons.phone_android;
      color = Pal.muted;
    } else if (a.syncing) {
      label = 'Syncing…';
      icon = Icons.sync;
      color = Pal.cyan;
    } else if (a.hasPending) {
      label = '${a.ops.length} pending';
      icon = Icons.cloud_upload_outlined;
      color = Pal.yellow;
    } else {
      label = 'Synced';
      icon = Icons.cloud_done_outlined;
      color = Pal.green;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12))),
        ]),
      ),
    );
  }
}

class NoticeBanner extends ConsumerWidget {
  const NoticeBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(appProvider.select((a) => a.notice));
    if (n == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(color: Pal.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Pal.red.withValues(alpha: 0.5))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Pal.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(n, style: const TextStyle(fontSize: 13))),
        IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(appProvider.notifier).dismissNotice(),
            icon: const Icon(Icons.close, size: 18)),
      ]),
    );
  }
}

class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.fraction, required this.color, this.height = 8});
  final double fraction;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: fraction.clamp(0, 1),
          minHeight: height,
          backgroundColor: Pal.line,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
}

class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, children: [
        for (final c in Pal.picks)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(color: c == value ? Colors.white : Colors.transparent, width: 3),
              ),
            ),
          ),
      ]);
}

class IconPicker extends StatelessWidget {
  const IconPicker({super.key, required this.value, required this.color, required this.onChanged});
  final int value;
  final int color;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final i in pickableIcons)
          GestureDetector(
            onTap: () => onChanged(i.codePoint),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: i.codePoint == value ? Color(color).withValues(alpha: 0.25) : Pal.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: i.codePoint == value ? Color(color) : Pal.line),
              ),
              child: Icon(i, color: i.codePoint == value ? Color(color) : Pal.muted, size: 22),
            ),
          ),
      ]);
}

Future<bool> confirm(BuildContext context, String title, String body, {String action = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(action, style: const TextStyle(color: Pal.red))),
      ],
    ),
  );
  return r ?? false;
}
