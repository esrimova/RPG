import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

/// Items grouped by year, then month, newest first. Every year and every month
/// can be collapsed. The newest year and its newest month start open; a group
/// keeps its open/closed state when an item is deleted.
class HistoryTree<T> extends StatelessWidget {
  const HistoryTree({
    super.key,
    required this.items,
    required this.timeOf,
    required this.tileBuilder,
    this.summary,
  });

  final List<T> items;
  final DateTime Function(T) timeOf;
  final Widget Function(BuildContext, T) tileBuilder;

  /// Text shown under a year or month title, e.g. "4 records · 40 XP".
  final String Function(List<T>)? summary;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => timeOf(b).compareTo(timeOf(a)));
    final years = <int, Map<int, List<T>>>{};
    for (final it in sorted) {
      final t = timeOf(it).toLocal();
      years.putIfAbsent(t.year, () => {}).putIfAbsent(t.month, () => []).add(it);
    }
    final yearKeys = years.keys.toList(); // already newest first (insertion order of sorted)
    return Column(children: [
      for (var yi = 0; yi < yearKeys.length; yi++)
        _group(
          context,
          key: ValueKey('year-${yearKeys[yi]}'),
          title: '${yearKeys[yi]}',
          items: [for (final m in years[yearKeys[yi]]!.values) ...m],
          open: yi == 0,
          indent: 0,
          children: [
            for (var mi = 0; mi < years[yearKeys[yi]]!.length; mi++)
              _group(
                context,
                key: ValueKey('month-${yearKeys[yi]}-${years[yearKeys[yi]]!.keys.elementAt(mi)}'),
                title: DateFormat.MMMM().format(DateTime(yearKeys[yi], years[yearKeys[yi]]!.keys.elementAt(mi))),
                items: years[yearKeys[yi]]!.values.elementAt(mi),
                open: yi == 0 && mi == 0,
                indent: 12,
                children: [for (final it in years[yearKeys[yi]]!.values.elementAt(mi)) tileBuilder(context, it)],
              ),
          ],
        ),
    ]);
  }

  Widget _group(
    BuildContext context, {
    required Key key,
    required String title,
    required List<T> items,
    required bool open,
    required double indent,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 6),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: key,
            initiallyExpanded: open,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 6, 6),
            iconColor: Pal.cyan,
            collapsedIconColor: Pal.muted,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(summary?.call(items) ?? '${items.length}', style: const TextStyle(color: Pal.muted, fontSize: 12)),
            children: children,
          ),
        ),
      ),
    );
  }
}
