import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/progress.dart';
import '../state/providers.dart';
import 'common.dart';
import 'icons.dart';
import 'settings_page.dart';
import 'theme.dart';

/// Home: overall progress, badges and the way into Configuration.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final stats = ref.watch(playerStatsProvider);
    final s = app.view;
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const NoticeBanner(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Level ${stats.level.level}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Pal.cyan)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${stats.totalXp} XP total', style: const TextStyle(color: Pal.muted, fontSize: 12)),
                  Text('🔥 ${stats.streak.current}-day streak (best ${stats.streak.longest})', style: const TextStyle(fontSize: 12)),
                ])),
              ]),
              const SizedBox(height: 10),
              XpBar(fraction: stats.level.fraction, color: Pal.cyan, height: 10),
              const SizedBox(height: 6),
              Text('${stats.level.xpIntoLevel} / ${stats.level.xpForNext} XP to level ${stats.level.level + 1}', style: const TextStyle(color: Pal.muted, fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Badges'),
        if (stats.badges.isEmpty)
          const Text('Badges are earned from your recorded activity. Record something to unlock the first one.', style: TextStyle(color: Pal.muted))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final b in stats.badges)
              Tooltip(
                message: b.description,
                triggerMode: TooltipTriggerMode.tap,
                child: Chip(
                  avatar: const Icon(Icons.military_tech, size: 18, color: Pal.yellow),
                  label: Text(b.title),
                  backgroundColor: Pal.surface2,
                  side: const BorderSide(color: Pal.line),
                ),
              ),
          ]),
        const SizedBox(height: 20),
        _sectionTitle('Branches'),
        if (s.branches.isEmpty) const Text('No branches yet. Go back and create your first one.', style: TextStyle(color: Pal.muted)),
        for (final b in s.branches)
          Builder(builder: (_) {
            final l = levelForXp(xpOf(s.records.where((r) => r.branchId == b.id)));
            final color = Color(b.color);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(iconFor(b.iconCodePoint), color: color),
              title: Text(b.name),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: XpBar(fraction: l.fraction, color: color, height: 6)),
              trailing: Text('Lv ${l.level}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            );
          }),
        const SizedBox(height: 20),
        _navTile(context, Icons.settings, 'Configuration', 'Branches, activities, fields and GitHub storage', const SettingsPage()),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)));

  Widget _navTile(BuildContext context, IconData icon, String title, String sub, Widget page) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: ListTile(
            leading: Icon(icon, color: Pal.cyan),
            title: Text(title),
            subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          ),
        ),
      );
}
