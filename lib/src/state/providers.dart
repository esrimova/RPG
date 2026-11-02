import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local_store.dart';
import '../data/remote_store.dart';
import '../domain/progress.dart';
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

/// Derived player numbers, always computed from the records.
class PlayerStats {
  final int totalXp;
  final LevelInfo level;
  final StreakInfo streak;
  final List<Badge> badges;
  const PlayerStats(this.totalXp, this.level, this.streak, this.badges);
}

final playerStatsProvider = Provider<PlayerStats>((ref) {
  final s = ref.watch(appProvider.select((a) => a.view));
  final now = DateTime.now();
  final xp = xpOf(s.records);
  return PlayerStats(xp, levelForXp(xp), computeStreak(s.records, now), computeBadges(s, now));
});
