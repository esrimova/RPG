import '../repositories/index.dart';
import '../entities/index.dart';

/// Use case for getting all branches
class GetBranchesUseCase {
  final BranchRepository repository;

  GetBranchesUseCase(this.repository);

  Future<List<Branch>> call() => repository.getAllBranches();
}

/// Use case for getting a branch by ID
class GetBranchUseCase {
  final BranchRepository repository;

  GetBranchUseCase(this.repository);

  Future<Branch?> call(String id) => repository.getBranchById(id);
}

/// Use case for creating a branch
class CreateBranchUseCase {
  final BranchRepository repository;
  final GithubSyncRepository githubSync;

  CreateBranchUseCase(this.repository, this.githubSync);

  Future<Branch> call(Branch branch) async {
    final created = await repository.createBranch(branch);
    
    // Trigger GitHub sync
    final status = await githubSync.triggerWorkflow(
      entityType: 'branch',
      entityId: created.id,
      payload: created.toJson(),
    );
    
    if (status.status != GithubWorkflowStatus.success) {
      throw Exception('GitHub sync failed: ${status.message}');
    }
    
    return created;
  }
}

/// Use case for updating a branch
class UpdateBranchUseCase {
  final BranchRepository repository;
  final GithubSyncRepository githubSync;

  UpdateBranchUseCase(this.repository, this.githubSync);

  Future<Branch> call(Branch branch) async {
    final updated = await repository.updateBranch(branch);
    
    // Trigger GitHub sync
    final status = await githubSync.triggerWorkflow(
      entityType: 'branch',
      entityId: updated.id,
      payload: updated.toJson(),
    );
    
    if (status.status != GithubWorkflowStatus.success) {
      throw Exception('GitHub sync failed: ${status.message}');
    }
    
    return updated;
  }
}

/// Use case for deleting a branch
class DeleteBranchUseCase {
  final BranchRepository repository;
  final GithubSyncRepository githubSync;

  DeleteBranchUseCase(this.repository, this.githubSync);

  Future<void> call(String id) async {
    await repository.deleteBranch(id);
    
    // Trigger GitHub sync for deletion
    final status = await githubSync.triggerWorkflow(
      entityType: 'branch',
      entityId: id,
      payload: {'action': 'delete'},
    );
    
    if (status.status != GithubWorkflowStatus.success) {
      throw Exception('GitHub sync failed: ${status.message}');
    }
  }
}

/// Use case for getting activities by branch
class GetActivitiesUseCase {
  final ActivityRepository repository;

  GetActivitiesUseCase(this.repository);

  Future<List<Activity>> call(String branchId) => repository.getActivitiesByBranch(branchId);
}

/// Use case for creating an activity
class CreateActivityUseCase {
  final ActivityRepository repository;
  final GithubSyncRepository githubSync;

  CreateActivityUseCase(this.repository, this.githubSync);

  Future<Activity> call(Activity activity) async {
    final created = await repository.createActivity(activity);
    
    final status = await githubSync.triggerWorkflow(
      entityType: 'activity',
      entityId: created.id,
      payload: created.toJson(),
    );
    
    if (status.status != GithubWorkflowStatus.success) {
      throw Exception('GitHub sync failed: ${status.message}');
    }
    
    return created;
  }
}

/// Use case for recording an activity completion
class RecordActivityUseCase {
  final ActivityRepository activityRepository;
  final RecordRepository recordRepository;
  final UserProfileRepository profileRepository;
  final GithubSyncRepository githubSync;

  RecordActivityUseCase(
    this.activityRepository,
    this.recordRepository,
    this.profileRepository,
    this.githubSync,
  );

  Future<Record> call({
    required String activityId,
    required Map<String, dynamic> fieldValues,
    String? notes,
    Duration? duration,
  }) async {
    final activity = await activityRepository.getActivityById(activityId);
    if (activity == null) {
      throw Exception('Activity not found: $activityId');
    }

    final xpEarned = activity.calculateXpReward(fieldValues);
    final statChanges = _calculateStatChanges(activity, fieldValues);

    final record = Record(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityId: activityId,
      branchId: activity.branchId,
      timestamp: DateTime.now(),
      fieldValues: fieldValues,
      xpEarned: xpEarned,
      statChanges: statChanges,
      notes: notes,
      duration: duration,
    );

    final createdRecord = await recordRepository.createRecord(record);
    
    // Update activity XP
    final updatedActivity = activity.copyWith(
      currentXp: activity.currentXp + xpEarned,
      updatedAt: DateTime.now(),
    );
    await activityRepository.updateActivity(updatedActivity);
    
    // Update user profile
    await profileRepository.addXp(xpEarned);
    await profileRepository.updateStreak();

    // Trigger GitHub sync for record
    final status = await githubSync.triggerWorkflow(
      entityType: 'record',
      entityId: createdRecord.id,
      payload: createdRecord.toJson(),
    );
    
    if (status.status != GithubWorkflowStatus.success) {
      throw Exception('GitHub sync failed: ${status.message}');
    }

    return createdRecord;
  }

  Map<String, int> _calculateStatChanges(Activity activity, Map<String, dynamic> fieldValues) {
    final changes = <String, int>{};
    // Simplified stat calculation based on activity category
    switch (activity.category.toLowerCase()) {
      case 'strength':
      case 'cardio':
      case 'endurance':
        changes['energy'] = 2;
        break;
      case 'focus':
      case 'meditation':
      case 'reading':
        changes['synapse'] = 2;
        changes['willpower'] = 1;
        break;
      case 'code':
      case 'architecture':
      case 'ops':
        changes['synapse'] = 3;
        break;
      default:
        changes['energy'] = 1;
        changes['willpower'] = 1;
    }
    return changes;
  }
}

/// Use case for getting user profile
class GetProfileUseCase {
  final UserProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<UserProfile?> call() => repository.getProfile();
}

/// Use case for GitHub configuration
class ConfigureGithubUseCase {
  final GithubSyncRepository repository;

  ConfigureGithubUseCase(this.repository);

  Future<void> call(String pat, String repo) => repository.saveConfiguration(pat, repo);
}

/// Use case for checking GitHub sync status
class CheckGithubSyncUseCase {
  final GithubSyncRepository repository;

  CheckGithubSyncUseCase(this.repository);

  Future<GithubStatus> call() => repository.getStatusFile();
}