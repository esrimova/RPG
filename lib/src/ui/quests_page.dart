import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/models.dart';
import '../domain/progress.dart';
import '../domain/quests.dart';
import '../state/providers.dart';
import 'common.dart';
import 'quest_editor.dart';
import 'theme.dart';

/// Colour of the built-in Quests branch.
const questColor = Pal.violet;

/// `YYYY-MM-DD` shown as e.g. "Tue, Nov 3".
String formatDay(String key) {
  final d = DateTime.tryParse(key);
  return d == null ? key : DateFormat.MMMEd().format(d);
}

/// The built-in Quests branch: level bar, active quests with their task
/// checklists, and the history of completed and failed quests.
class QuestsPage extends ConsumerWidget {
  const QuestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(appProvider.select((a) => a.view.quests));
    final today = todayKey(ref.watch(clockProvider));
    final lvl = levelForXp(ref.watch(questXpProvider));
    final active = quests.where((q) => questStatus(q, today) == QuestStatus.active).toList();
    final history = quests.where((q) => questStatus(q, today) != QuestStatus.active).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: questColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.flag_outlined, color: questColor),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quests', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text('Multi-day goals with a deadline', style: TextStyle(color: Pal.muted, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text('Level ${lvl.level}', style: const TextStyle(color: questColor, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${lvl.xpIntoLevel} / ${lvl.xpForNext} XP', style: const TextStyle(color: Pal.muted, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        XpBar(fraction: lvl.fraction, color: questColor),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: questColor, foregroundColor: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestEditorPage())),
          icon: const Icon(Icons.add),
          label: const Text('New quest'),
        ),
        const SizedBox(height: 16),
        if (active.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No active quests. Start one: give it a deadline, points and a list of tasks.',
                  style: TextStyle(color: Pal.muted)),
            ),
          ),
        for (final q in active)
          Padding(padding: const EdgeInsets.only(bottom: 14), child: _QuestCard(key: ValueKey(q.id), quest: q, today: today)),
        const SizedBox(height: 12),
        const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (history.isEmpty) const Text('Completed and failed quests appear here.', style: TextStyle(color: Pal.muted)),
        for (final q in history)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: _HistoryTile(key: ValueKey(q.id), quest: q, today: today)),
      ],
    );
  }
}

Future<void> _delete(BuildContext context, WidgetRef ref, Quest q, String today) async {
  final xp = questXp(q, today);
  final body = xp > 0 ? 'This removes "${q.name}" and its $xp XP.' : 'This removes "${q.name}".';
  if (!await confirm(context, 'Delete quest?', body)) return;
  final r = await ref.read(appProvider.notifier).deleteQuest(q.id);
  if (context.mounted && r.outcome == OpOutcome.rejected) toast(context, r.message, error: true);
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({super.key, required this.quest, required this.today});
  final Quest quest;
  final String today;

  Future<void> _toggle(BuildContext context, WidgetRef ref, QuestTask t, bool check) async {
    final q = quest.copyWith(tasks: [
      for (final x in quest.tasks)
        if (x.id != t.id) x else if (check) x.copyWith(doneAt: DateTime.now()) else x.copyWith(clearDone: true),
    ]);
    final r = await ref.read(appProvider.notifier).saveQuest(q, isNew: false);
    if (!context.mounted) return;
    if (r.outcome == OpOutcome.rejected) {
      toast(context, 'Not saved: ${r.message}', error: true);
    } else if (questStatus(q, today) == QuestStatus.completed) {
      toast(context, 'Quest complete! +${q.totalXp} XP');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = quest;
    final checked = q.tasks.where((t) => t.doneAt != null).length;
    final xp = questXp(q, today);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(q.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: 'Edit quest',
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuestEditorPage(existing: q))),
              icon: const Icon(Icons.edit_outlined, size: 20, color: Pal.muted),
            ),
            IconButton(
              tooltip: 'Delete quest',
              visualDensity: VisualDensity.compact,
              onPressed: () => _delete(context, ref, q, today),
              icon: const Icon(Icons.delete_outline, size: 20, color: Pal.muted),
            ),
          ]),
          if (q.description.isNotEmpty) Text(q.description, style: const TextStyle(color: Pal.muted, fontSize: 13)),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 2),
            child: Text(
              '${formatDay(q.startDate)} → ${formatDay(q.endDate)} · $checked/${q.tasks.length} tasks · +$xp XP of ${q.totalXp}',
              style: const TextStyle(color: Pal.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: XpBar(fraction: q.tasks.isEmpty ? 0 : checked / q.tasks.length, color: questColor, height: 6),
          ),
          if (q.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('No tasks yet. Edit the quest to add some.', style: TextStyle(color: Pal.muted, fontSize: 13)),
            ),
          for (final t in q.tasks)
            CheckboxListTile(
              key: ValueKey(t.id),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: questColor,
              value: t.doneAt != null,
              onChanged: (v) => _toggle(context, ref, t, v ?? false),
              title: Text(t.name),
              subtitle: Text(
                formatDay(t.date),
                style: TextStyle(fontSize: 12, color: t.doneAt == null && t.date.compareTo(today) < 0 ? Pal.yellow : Pal.muted),
              ),
            ),
        ]),
      ),
    );
  }
}

/// A finished quest: read-only, can only be deleted.
class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({super.key, required this.quest, required this.today});
  final Quest quest;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = quest;
    final completed = questStatus(q, today) == QuestStatus.completed;
    final color = completed ? Pal.green : Pal.red;
    final checked = q.tasks.where((t) => t.doneAt != null).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Ended ${formatDay(q.endDate)} · $checked/${q.tasks.length} tasks',
                  style: const TextStyle(color: Pal.muted, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Text(completed ? 'Completed' : 'Failed', style: TextStyle(color: color, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Text('${questXp(q, today)} XP', style: TextStyle(color: completed ? questColor : Pal.muted, fontWeight: FontWeight.w700)),
          IconButton(
            tooltip: 'Delete quest',
            visualDensity: VisualDensity.compact,
            onPressed: () => _delete(context, ref, q, today),
            icon: const Icon(Icons.delete_outline, size: 20, color: Pal.muted),
          ),
        ]),
      ),
    );
  }
}
