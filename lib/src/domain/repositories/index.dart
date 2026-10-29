import '../entities/branch.dart';
import '../entities/activity.dart';
import '../entities/record.dart';
import '../entities/user_profile.dart';
import '../entities/github_status.dart';

/// Repository interface for branch operations
abstract class BranchRepository {
  Future<List<Branch>> getAllBranches();
  Future<Branch?> getBranchById(String id);
  Future<Branch> createBranch(Branch branch);
  Future<Branch> updateBranch(Branch branch);
  Future<void> deleteBranch(String id);
  Future<void> reorderBranches(List<String> orderedIds);
}

/// Repository interface for activity operations
abstract class ActivityRepository {
  Future<List<Activity>> getActivitiesByBranch(String branchId);
  Future<Activity?> getActivityById(String id);
  Future<Activity> createActivity(Activity activity);
  Future<Activity> updateActivity(Activity activity);
  Future<void> deleteActivity(String id);
  Future<void> reorderActivities(String branchId, List<String> orderedIds);
}

/// Repository interface for record operations
abstract class RecordRepository {
  Future<List<Record>> getRecordsByActivity(String activityId);
  Future<List<Record>> getRecordsByBranch(String branchId);
  Future<List<Record>> getRecordsByDateRange(DateTime start, DateTime end);
  Future<Record> createRecord(Record record);
  Future<Record> updateRecord(Record record);
  Future<void> deleteRecord(String id);
}

/// Repository interface for user profile operations
abstract class UserProfileRepository {
  Future<UserProfile?> getProfile();
  Future<UserProfile> createProfile(UserProfile profile);
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<void> addXp(int amount);
  Future<void> updateStreak();
}

/// Repository interface for GitHub synchronization
abstract class GithubSyncRepository {
  Future<GithubStatus> triggerWorkflow({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  });
  Future<GithubStatus> pollStatus(String workflowRunId);
  Future<GithubStatus> getStatusFile();
  Future<bool> isConfigured();
  Future<void> saveConfiguration(String pat, String repo);
  Future<void> clearConfiguration();
}