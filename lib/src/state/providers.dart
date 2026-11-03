import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local_store.dart';
import '../data/remote_store.dart';
import '../domain/progress.dart';
import '../domain/quests.dart';
import 'app_controller.dart';

final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('override in main'));
final secretsProvider = Provider<SecretStore>((_) => KeychainSecretStore());
final localStoreProvider = Provider((ref) => LocalStore(ref.watch(prefsProvider), ref.watch(secretsProvider)));

final appProvider = StateNotifierProvider<AppController, AppState>((ref) {
  final c = AppController(
    ref.watch(localStoreProvider),
    (cfg) => GithubRemoteStore(repo: cfg.repo, pat: cfg.pat),
  );
  c.init();
  return c;
});

/// The clock used for derived, date-dependent values (quest status, streaks).
/// Read it on each use so the date stays current; override it in tests.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Today's local date as `YYYY-MM-DD`.
String todayKey(DateTime Function() clock) => dateKey(clock());

/// Derived player numbers, always computed from the records and quests.
class PlayerStats {
  final int totalXp;
  final LevelInfo level;
  final StreakInfo streak;
  final List<Badge> badges;
  const PlayerStats(this.totalXp, this.level, this.streak, this.badges);
}

final playerStatsProvider = Provider<PlayerStats>((ref) {
  final s = ref.watch(appProvider.select((a) => a.view));
  final now = ref.watch(clockProvider)();
  final xp = playerXp(s, dateKey(now));
  return PlayerStats(xp, levelForXp(xp), computeStreak(s.records, now), computeBadges(s, now));
});

/// XP of the built-in Quests branch: the derived points of every quest.
final questXpProvider = Provider<int>((ref) {
  final quests = ref.watch(appProvider.select((a) => a.view.quests));
  return totalQuestXp(quests, todayKey(ref.watch(clockProvider)));
});
