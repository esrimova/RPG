import '../../domain/repositories/index.dart';
import '../../domain/entities/index.dart';
import '../datasources/index.dart';

/// Local implementation of BranchRepository
class LocalBranchRepository implements BranchRepository {
  final LocalDataSource _localDataSource;

  LocalBranchRepository(this._localDataSource);

  @override
  Future<List<Branch>> getAllBranches() async {
    return await _localDataSource.getBranches();
  }

  @override
  Future<Branch?> getBranchById(String id) async {
    final branches = await _localDataSource.getBranches();
    try {
      return branches.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Branch> createBranch(Branch branch) async {
    final branches = await _localDataSource.getBranches();
    branches.add(branch);
    await _localDataSource.saveBranches(branches);
    return branch;
  }

  @override
  Future<Branch> updateBranch(Branch branch) async {
    final branches = await _localDataSource.getBranches();
    final index = branches.indexWhere((b) => b.id == branch.id);
    if (index >= 0) {
      branches[index] = branch;
      await _localDataSource.saveBranches(branches);
    }
    return branch;
  }

  @override
  Future<void> deleteBranch(String id) async {
    final branches = await _localDataSource.getBranches();
    branches.removeWhere((b) => b.id == id);
    await _localDataSource.saveBranches(branches);
  }

  @override
  Future<void> reorderBranches(List<String> orderedIds) async {
    final branches = await _localDataSource.getBranches();
    final reordered = <Branch>[];
    for (final id in orderedIds) {
      final branch = branches.firstWhere((b) => b.id == id);
      reordered.add(branch);
    }
    // Add any branches not in the ordered list
    for (final branch in branches) {
      if (!orderedIds.contains(branch.id)) {
        reordered.add(branch);
      }
    }
    await _localDataSource.saveBranches(reordered);
  }
}

/// Local implementation of ActivityRepository
class LocalActivityRepository implements ActivityRepository {
  final LocalDataSource _localDataSource;

  LocalActivityRepository(this._localDataSource);

  @override
  Future<List<Activity>> getActivitiesByBranch(String branchId) async {
    final activities = await _localDataSource.getActivities();
    return activities.where((a) => a.branchId == branchId).toList();
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    final activities = await _localDataSource.getActivities();
    try {
      return activities.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Activity> createActivity(Activity activity) async {
    final activities = await _localDataSource.getActivities();
    activities.add(activity);
    await _localDataSource.saveActivities(activities);
    return activity;
  }

  @override
  Future<Activity> updateActivity(Activity activity) async {
    final activities = await _localDataSource.getActivities();
    final index = activities.indexWhere((a) => a.id == activity.id);
    if (index >= 0) {
      activities[index] = activity;
      await _localDataSource.saveActivities(activities);
    }
    return activity;
  }

  @override
  Future<void> deleteActivity(String id) async {
    final activities = await _localDataSource.getActivities();
    activities.removeWhere((a) => a.id == id);
    await _localDataSource.saveActivities(activities);
  }

  @override
  Future<void> reorderActivities(String branchId, List<String> orderedIds) async {
    final activities = await _localDataSource.getActivities();
    final branchActivities = activities.where((a) => a.branchId == branchId).toList();
    final otherActivities = activities.where((a) => a.branchId != branchId).toList();
    
    final reordered = <Activity>[];
    for (final id in orderedIds) {
      final activity = branchActivities.firstWhere((a) => a.id == id);
      reordered.add(activity);
    }
    for (final activity in branchActivities) {
      if (!orderedIds.contains(activity.id)) {
        reordered.add(activity);
      }
    }
    reordered.addAll(otherActivities);
    await _localDataSource.saveActivities(reordered);
  }
}

/// Local implementation of RecordRepository
class LocalRecordRepository implements RecordRepository {
  final LocalDataSource _localDataSource;

  LocalRecordRepository(this._localDataSource);

  @override
  Future<List<Record>> getRecordsByActivity(String activityId) async {
    final records = await _localDataSource.getRecords();
    return records.where((r) => r.activityId == activityId).toList();
  }

  @override
  Future<List<Record>> getRecordsByBranch(String branchId) async {
    final records = await _localDataSource.getRecords();
    return records.where((r) => r.branchId == branchId).toList();
  }

  @override
  Future<List<Record>> getRecordsByDateRange(DateTime start, DateTime end) async {
    final records = await _localDataSource.getRecords();
    return records.where((r) => 
      r.timestamp.isAfter(start.subtract(const Duration(days: 1))) && 
      r.timestamp.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  @override
  Future<Record> createRecord(Record record) async {
    final records = await _localDataSource.getRecords();
    records.add(record);
    await _localDataSource.saveRecords(records);
    return record;
  }

  @override
  Future<Record> updateRecord(Record record) async {
    final records = await _localDataSource.getRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
      await _localDataSource.saveRecords(records);
    }
    return record;
  }

  @override
  Future<void> deleteRecord(String id) async {
    final records = await _localDataSource.getRecords();
    records.removeWhere((r) => r.id == id);
    await _localDataSource.saveRecords(records);
  }
}

/// Local implementation of UserProfileRepository
class LocalUserProfileRepository implements UserProfileRepository {
  final LocalDataSource _localDataSource;

  LocalUserProfileRepository(this._localDataSource);

  @override
  Future<UserProfile?> getProfile() async {
    return await _localDataSource.getUserProfile();
  }

  @override
  Future<UserProfile> createProfile(UserProfile profile) async {
    await _localDataSource.saveUserProfile(profile);
    return profile;
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await _localDataSource.saveUserProfile(profile);
    return profile;
  }

  @override
  Future<void> addXp(int amount) async {
    final profile = await getProfile();
    if (profile != null) {
      int newXp = profile.currentXp + amount;
      int newLevel = profile.level;
      int xpToNext = profile.xpToNextLevel;
      
      while (newXp >= xpToNext) {
        newXp -= xpToNext;
        newLevel++;
        xpToNext = (xpToNext * 1.5).round(); // Exponential growth
      }
      
      final updated = profile.copyWith(
        currentXp: newXp,
        level: newLevel,
        xpToNextLevel: xpToNext,
      );
      await updateProfile(updated);
    }
  }

  @override
  Future<void> updateStreak() async {
    final profile = await getProfile();
    if (profile != null) {
      final now = DateTime.now();
      final lastActive = profile.lastActiveDate;
      final daysDiff = now.difference(lastActive).inDays;
      
      int newStreak = profile.currentStreak;
      int newLongest = profile.longestStreak;
      
      if (daysDiff == 1) {
        // Consecutive day
        newStreak++;
        if (newStreak > newLongest) newLongest = newStreak;
      } else if (daysDiff > 1) {
        // Streak broken
        newStreak = 1;
      }
      // daysDiff == 0 means same day, no change
      
      final updated = profile.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastActiveDate: now,
      );
      await updateProfile(updated);
    }
  }
}

/// GitHub sync repository implementation
class GithubSyncRepositoryImpl implements GithubSyncRepository {
  final LocalDataSource _localDataSource;
  late GithubApiDataSource _apiDataSource;
  bool _initialized = false;

  GithubSyncRepositoryImpl(this._localDataSource);

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      final pat = await _localDataSource.getGithubPat();
      final repo = await _localDataSource.getGithubRepo();
      
      if (pat != null && repo != null) {
        final parts = repo.split('/');
        if (parts.length == 2) {
          _apiDataSource = GithubApiDataSource(
            dio: GithubApiDataSource.createDio(pat),
            pat: pat,
            repoOwner: parts[0],
            repoName: parts[1],
          );
          _initialized = true;
        }
      }
    }
  }

  @override
  Future<GithubStatus> triggerWorkflow({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    await _ensureInitialized();
    if (!_initialized) {
      return GithubStatus(
        workflowRunId: '',
        status: GithubWorkflowStatus.failed,
        entityType: entityType,
        entityId: entityId,
        message: 'GitHub not configured',
        timestamp: DateTime.now(),
      );
    }

    return await _apiDataSource.triggerWorkflow(
      entityType: entityType,
      entityId: entityId,
      payload: payload,
    );
  }

  @override
  Future<GithubStatus> pollStatus(String workflowRunId) async {
    await _ensureInitialized();
    if (!_initialized) {
      return GithubStatus(
        workflowRunId: workflowRunId,
        status: GithubWorkflowStatus.failed,
        entityType: '',
        entityId: '',
        message: 'GitHub not configured',
        timestamp: DateTime.now(),
      );
    }

    return await _apiDataSource.getWorkflowStatus(workflowRunId);
  }

  @override
  Future<GithubStatus> getStatusFile() async {
    await _ensureInitialized();
    if (!_initialized) {
      return GithubStatus(
        workflowRunId: '',
        status: GithubWorkflowStatus.unknown,
        entityType: '',
        entityId: '',
        message: 'GitHub not configured',
        timestamp: DateTime.now(),
      );
    }

    return await _apiDataSource.getStatusFile();
  }

  @override
  Future<bool> isConfigured() async {
    final pat = await _localDataSource.getGithubPat();
    final repo = await _localDataSource.getGithubRepo();
    return pat != null && repo != null;
  }

  @override
  Future<void> saveConfiguration(String pat, String repo) async {
    await _localDataSource.saveGithubPat(pat);
    await _localDataSource.saveGithubRepo(repo);
    _initialized = false; // Force re-initialization
  }

  @override
  Future<void> clearConfiguration() async {
    await _localDataSource.deleteGithubPat();
    await _localDataSource.saveGithubRepo('');
    _initialized = false;
  }
}