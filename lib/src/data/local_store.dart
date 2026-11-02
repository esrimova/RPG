import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';

abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class KeychainSecretStore implements SecretStore {
  final _s = const FlutterSecureStorage();
  @override
  Future<String?> read(String key) async {
    try {
      return await _s.read(key: key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class GithubConfig {
  final String repo;
  final String pat;
  const GithubConfig({this.repo = '', this.pat = ''});
  bool get isConfigured => repo.isNotEmpty && pat.isNotEmpty;
}

class LocalStore {
  LocalStore(this._prefs, this._secrets);
  final SharedPreferences _prefs;
  final SecretStore _secrets;

  static const _base = 'rpg_base_v2';
  static const _ops = 'rpg_ops_v2';
  static const _lastSync = 'rpg_last_sync_v2';

  Snapshot loadBase() {
    final s = _prefs.getString(_base);
    if (s == null) return Snapshot.empty;
    try {
      return Snapshot.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
    } catch (_) {
      return Snapshot.empty;
    }
  }

  Future<void> saveBase(Snapshot s) => _prefs.setString(_base, jsonEncode(s.toJson()));

  List<Operation> loadOps() => Operation.decodeList(_prefs.getString(_ops));
  Future<void> saveOps(List<Operation> ops) => _prefs.setString(_ops, Operation.encodeList(ops));

  DateTime? loadLastSync() {
    final ms = _prefs.getInt(_lastSync);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastSync(DateTime t) => _prefs.setInt(_lastSync, t.millisecondsSinceEpoch);

  Future<GithubConfig> loadGithub() async =>
      GithubConfig(repo: _prefs.getString('rpg_gh_repo') ?? '', pat: await _secrets.read('rpg_gh_pat') ?? '');

  Future<void> saveGithub(GithubConfig c) async {
    await _prefs.setString('rpg_gh_repo', c.repo);
    await _secrets.write('rpg_gh_pat', c.pat);
  }

  Future<void> clearGithub() async {
    await _prefs.remove('rpg_gh_repo');
    await _secrets.delete('rpg_gh_pat');
  }
}
