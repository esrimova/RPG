import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/index.dart';

/// Local storage keys
class LocalStorageKeys {
  static const String branches = 'rpg_branches';
  static const String activities = 'rpg_activities';
  static const String records = 'rpg_records';
  static const String userProfile = 'rpg_user_profile';
  static const String lastSync = 'rpg_last_sync';
  static const String githubRepo = 'rpg_github_repo';
}

/// Secure storage keys
class SecureStorageKeys {
  static const String githubPat = 'rpg_github_pat';
}

/// Local data source using SharedPreferences and SecureStorage
class LocalDataSource {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalDataSource(this._prefs, this._secureStorage);

  // Generic JSON storage helpers
  Future<void> _saveJson(String key, Object data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  T? _getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(map);
    } catch (e) {
      return null;
    }
  }

  List<T> _getJsonList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final list = jsonDecode(jsonString) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Branch operations
  Future<List<Branch>> getBranches() async {
    return _getJsonList(LocalStorageKeys.branches, Branch.fromJson);
  }

  Future<void> saveBranches(List<Branch> branches) async {
    await _saveJson(LocalStorageKeys.branches, branches.map((b) => b.toJson()).toList());
  }

  // Activity operations
  Future<List<Activity>> getActivities() async {
    return _getJsonList(LocalStorageKeys.activities, Activity.fromJson);
  }

  Future<void> saveActivities(List<Activity> activities) async {
    await _saveJson(LocalStorageKeys.activities, activities.map((a) => a.toJson()).toList());
  }

  // Record operations
  Future<List<Record>> getRecords() async {
    return _getJsonList(LocalStorageKeys.records, Record.fromJson);
  }

  Future<void> saveRecords(List<Record> records) async {
    await _saveJson(LocalStorageKeys.records, records.map((r) => r.toJson()).toList());
  }

  // User profile operations
  Future<UserProfile?> getUserProfile() async {
    return _getJson(LocalStorageKeys.userProfile, UserProfile.fromJson);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _saveJson(LocalStorageKeys.userProfile, profile.toJson());
  }

  // GitHub configuration
  Future<String?> getGithubPat() async {
    return await _secureStorage.read(key: SecureStorageKeys.githubPat);
  }

  Future<void> saveGithubPat(String pat) async {
    await _secureStorage.write(key: SecureStorageKeys.githubPat, value: pat);
  }

  Future<void> deleteGithubPat() async {
    await _secureStorage.delete(key: SecureStorageKeys.githubPat);
  }

  Future<String?> getGithubRepo() async {
    return _prefs.getString(LocalStorageKeys.githubRepo);
  }

  Future<void> saveGithubRepo(String repo) async {
    await _prefs.setString(LocalStorageKeys.githubRepo, repo);
  }

  // Last sync timestamp
  Future<DateTime?> getLastSync() async {
    final timestamp = _prefs.getInt(LocalStorageKeys.lastSync);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> setLastSync(DateTime dateTime) async {
    await _prefs.setInt(LocalStorageKeys.lastSync, dateTime.millisecondsSinceEpoch);
  }
}