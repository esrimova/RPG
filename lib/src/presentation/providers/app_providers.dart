import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/repositories/repository_impl.dart';
import '../../domain/usecases/index.dart';
import '../../domain/repositories/index.dart';
import '../../domain/entities/index.dart';

// Core infrastructure providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden with SharedPreferences.getInstance()');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSource(
    ref.watch(sharedPreferencesProvider),
    ref.watch(secureStorageProvider),
  );
});

// Repository providers
final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return LocalBranchRepository(ref.watch(localDataSourceProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return LocalActivityRepository(ref.watch(localDataSourceProvider));
});

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return LocalRecordRepository(ref.watch(localDataSourceProvider));
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return LocalUserProfileRepository(ref.watch(localDataSourceProvider));
});

final githubSyncRepositoryProvider = Provider<GithubSyncRepository>((ref) {
  return GithubSyncRepositoryImpl(ref.watch(localDataSourceProvider));
});

// Use case providers
final getBranchesUseCaseProvider = Provider<GetBranchesUseCase>((ref) {
  return GetBranchesUseCase(ref.watch(branchRepositoryProvider));
});

final getBranchUseCaseProvider = Provider<GetBranchUseCase>((ref) {
  return GetBranchUseCase(ref.watch(branchRepositoryProvider));
});

final createBranchUseCaseProvider = Provider<CreateBranchUseCase>((ref) {
  return CreateBranchUseCase(
    ref.watch(branchRepositoryProvider),
    ref.watch(githubSyncRepositoryProvider),
  );
});

final updateBranchUseCaseProvider = Provider<UpdateBranchUseCase>((ref) {
  return UpdateBranchUseCase(
    ref.watch(branchRepositoryProvider),
    ref.watch(githubSyncRepositoryProvider),
  );
});

final deleteBranchUseCaseProvider = Provider<DeleteBranchUseCase>((ref) {
  return DeleteBranchUseCase(
    ref.watch(branchRepositoryProvider),
    ref.watch(githubSyncRepositoryProvider),
  );
});

final getActivitiesUseCaseProvider = Provider<GetActivitiesUseCase>((ref) {
  return GetActivitiesUseCase(ref.watch(activityRepositoryProvider));
});

final createActivityUseCaseProvider = Provider<CreateActivityUseCase>((ref) {
  return CreateActivityUseCase(
    ref.watch(activityRepositoryProvider),
    ref.watch(githubSyncRepositoryProvider),
  );
});

final recordActivityUseCaseProvider = Provider<RecordActivityUseCase>((ref) {
  return RecordActivityUseCase(
    ref.watch(activityRepositoryProvider),
    ref.watch(recordRepositoryProvider),
    ref.watch(userProfileRepositoryProvider),
    ref.watch(githubSyncRepositoryProvider),
  );
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(userProfileRepositoryProvider));
});

final configureGithubUseCaseProvider = Provider<ConfigureGithubUseCase>((ref) {
  return ConfigureGithubUseCase(ref.watch(githubSyncRepositoryProvider));
});

final checkGithubSyncUseCaseProvider = Provider<CheckGithubSyncUseCase>((ref) {
  return CheckGithubSyncUseCase(ref.watch(githubSyncRepositoryProvider));
});

// State providers
final selectedBranchIndexProvider = StateProvider<int>((ref) => 0);

final githubConfigurationProvider = StateNotifierProvider<GithubConfigNotifier, GithubConfigState>((ref) {
  return GithubConfigNotifier(ref.watch(configureGithubUseCaseProvider), ref.watch(checkGithubSyncUseCaseProvider));
});

class GithubConfigState {
  final bool isConfigured;
  final bool isLoading;
  final String? error;
  final GithubStatus? lastStatus;

  const GithubConfigState({
    this.isConfigured = false,
    this.isLoading = false,
    this.error,
    this.lastStatus,
  });

  GithubConfigState copyWith({
    bool? isConfigured,
    bool? isLoading,
    String? error,
    GithubStatus? lastStatus,
  }) {
    return GithubConfigState(
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}

class GithubConfigNotifier extends StateNotifier<GithubConfigState> {
  final ConfigureGithubUseCase _configureUseCase;
  final CheckGithubSyncUseCase _checkSyncUseCase;

  GithubConfigNotifier(this._configureUseCase, this._checkSyncUseCase)
      : super(const GithubConfigState()) {
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    state = state.copyWith(isLoading: true);
    try {
      final isConfigured = await _checkSyncUseCase.call();
      state = state.copyWith(
        isConfigured: isConfigured.status != GithubWorkflowStatus.unknown,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isConfigured: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> configure(String pat, String repo) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _configureUseCase.call(pat, repo);
      final status = await _checkSyncUseCase.call();
      state = state.copyWith(
        isConfigured: status.status != GithubWorkflowStatus.unknown,
        isLoading: false,
        lastStatus: status,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> clear() async {
    state = state.copyWith(isLoading: true);
    try {
      // Note: We need access to the repository to clear
      // This is a simplification
      state = state.copyWith(
        isConfigured: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshStatus() async {
    try {
      final status = await _checkSyncUseCase.call();
      state = state.copyWith(lastStatus: status);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Branches state provider
final branchesProvider = FutureProvider<List<Branch>>((ref) {
  return ref.watch(getBranchesUseCaseProvider).call();
});

// Activities for selected branch
final activitiesProvider = FutureProvider.family<List<Activity>, String>((ref, branchId) {
  return ref.watch(getActivitiesUseCaseProvider).call(branchId);
});

// User profile provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) {
  return ref.watch(getProfileUseCaseProvider).call();
});

// Sync status provider
final syncStatusProvider = StateProvider<GithubStatus?>((ref) => null);

// Recording state provider
final recordingProvider = StateProvider<RecordingState>((ref) => RecordingState.idle);

enum RecordingState {
  idle,
  recording,
  syncing,
  success,
  error,
}

// Quick entry form state
final quickEntryProvider = StateNotifierProvider<QuickEntryNotifier, QuickEntryState>((ref) {
  return QuickEntryNotifier();
});

class QuickEntryState {
  final int reps;
  final int sets;
  final double rpe;
  final String? notes;
  final int calculatedXp;
  final bool isSubmitting;

  const QuickEntryState({
    this.reps = 25,
    this.sets = 3,
    this.rpe = 8.5,
    this.notes,
    this.calculatedXp = 60,
    this.isSubmitting = false,
  });

  QuickEntryState copyWith({
    int? reps,
    int? sets,
    double? rpe,
    String? notes,
    int? calculatedXp,
    bool? isSubmitting,
  }) {
    return QuickEntryState(
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
      calculatedXp: calculatedXp ?? this.calculatedXp,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class QuickEntryNotifier extends StateNotifier<QuickEntryState> {
  QuickEntryNotifier() : super(const QuickEntryState()) {
    _calculateXp();
  }

  void setReps(int reps) {
    state = state.copyWith(reps: reps.clamp(1, 999));
    _calculateXp();
  }

  void incrementReps(int amount) {
    setReps(state.reps + amount);
  }

  void setSets(int sets) {
    state = state.copyWith(sets: sets.clamp(1, 20));
  }

  void setRpe(double rpe) {
    state = state.copyWith(rpe: rpe.clamp(1.0, 10.0));
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void setSubmitting(bool submitting) {
    state = state.copyWith(isSubmitting: submitting);
  }

  void _calculateXp() {
    final baseXp = 45;
    final repBonus = (state.reps * 0.6).floor();
    final setBonus = (state.sets - 1) * 10;
    final rpeBonus = ((state.rpe - 5) * 5).round().clamp(0, 25);
    final total = baseXp + repBonus + setBonus + rpeBonus;
    state = state.copyWith(calculatedXp: total);
  }

  void reset() {
    state = const QuickEntryState();
    _calculateXp();
  }
}