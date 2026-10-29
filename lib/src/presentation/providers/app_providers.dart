import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/repositories/repository_impl.dart';
import '../../domain/usecases/index.dart';
import '../../domain/repositories/index.dart';
import '../../domain/entities/index.dart';
import '../../domain/services/ai_agent_service.dart';

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
  final notifier = GithubConfigNotifier(ref);
  notifier.load();
  return notifier;
});

class GithubConfigState {
  final String? pat;
  final String? repo;
  final bool isConfigured;
  final bool isLoading;
  final String? error;
  final GithubStatus? lastStatus;

  const GithubConfigState({
    this.pat,
    this.repo,
    this.isConfigured = false,
    this.isLoading = false,
    this.error,
    this.lastStatus,
  });

  GithubConfigState copyWith({
    String? pat,
    String? repo,
    bool? isConfigured,
    bool? isLoading,
    String? error,
    GithubStatus? lastStatus,
  }) {
    return GithubConfigState(
      pat: pat ?? this.pat,
      repo: repo ?? this.repo,
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}

class GithubConfigNotifier extends StateNotifier<GithubConfigState> {
  final Ref _ref;

  GithubConfigNotifier(this._ref) : super(const GithubConfigState());

  Future<void> load() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final pat = await secureStorage.read(key: SecureStorageKeys.githubPat);
    final prefs = _ref.read(sharedPreferencesProvider);
    final repo = prefs.getString('rpg_github_repo');
    
    if (pat != null && repo != null) {
      state = state.copyWith(
        pat: pat,
        repo: repo,
        isConfigured: true,
      );
    }
  }

  Future<void> configure(String pat, String repo) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.write(key: SecureStorageKeys.githubPat, value: pat);
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setString('rpg_github_repo', repo);
      state = state.copyWith(
        pat: pat,
        repo: repo,
        isConfigured: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> clear() async {
    final secureStorage = _ref.read(secureStorageProvider);
    await secureStorage.delete(key: SecureStorageKeys.githubPat);
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.remove('rpg_github_repo');
    state = const GithubConfigState();
  }
}

// Branches state provider
final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final branches = await ref.watch(getBranchesUseCaseProvider).call();
  // Return empty list on first install - no demo data
  return branches;
});

// Activities for selected branch
final activitiesProvider = FutureProvider.family<List<Activity>, String>((ref, branchId) async {
  final activities = await ref.watch(getActivitiesUseCaseProvider).call(branchId);
  return activities;
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
  final Branch? selectedBranch;
  final Activity? selectedActivity;

  const QuickEntryState({
    this.reps = 25,
    this.sets = 3,
    this.rpe = 8.5,
    this.notes,
    this.calculatedXp = 60,
    this.isSubmitting = false,
    this.selectedBranch,
    this.selectedActivity,
  });

  QuickEntryState copyWith({
    int? reps,
    int? sets,
    double? rpe,
    String? notes,
    int? calculatedXp,
    bool? isSubmitting,
    Branch? selectedBranch,
    Activity? selectedActivity,
  }) {
    return QuickEntryState(
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
      calculatedXp: calculatedXp ?? this.calculatedXp,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      selectedActivity: selectedActivity ?? this.selectedActivity,
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

  void setSelectedBranch(Branch? branch) {
    state = state.copyWith(selectedBranch: branch);
  }

  void setSelectedActivity(Activity? activity) {
    state = state.copyWith(selectedActivity: activity);
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

// AI Configuration Provider
class AiConfigState {
  final String? apiKey;
  final String? apiUrl;
  final String? model;
  final String provider;
  final bool isConfigured;
  final bool isLoading;
  final String? error;

  const AiConfigState({
    this.apiKey,
    this.apiUrl,
    this.model,
    this.provider = 'openai',
    this.isConfigured = false,
    this.isLoading = false,
    this.error,
  });

  AiConfigState copyWith({
    String? apiKey,
    String? apiUrl,
    String? model,
    String? provider,
    bool? isConfigured,
    bool? isLoading,
    String? error,
  }) {
    return AiConfigState(
      apiKey: apiKey ?? this.apiKey,
      apiUrl: apiUrl ?? this.apiUrl,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AiConfigNotifier extends StateNotifier<AiConfigState> {
  final Ref _ref;

  AiConfigNotifier(this._ref) : super(const AiConfigState());

  Future<void> configure(String apiKey, String apiUrl, String model, String provider) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.write(key: 'rpg_ai_api_key', value: apiKey);
      await secureStorage.write(key: 'rpg_ai_api_url', value: apiUrl);
      await secureStorage.write(key: 'rpg_ai_model', value: model);
      await secureStorage.write(key: 'rpg_ai_provider', value: provider);
      state = state.copyWith(
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
        provider: provider,
        isConfigured: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> clear() async {
    final secureStorage = _ref.read(secureStorageProvider);
    await secureStorage.delete(key: 'rpg_ai_api_key');
    await secureStorage.delete(key: 'rpg_ai_api_url');
    await secureStorage.delete(key: 'rpg_ai_model');
    await secureStorage.delete(key: 'rpg_ai_provider');
    state = const AiConfigState();
  }

  Future<void> load() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final apiKey = await secureStorage.read(key: 'rpg_ai_api_key');
    final apiUrl = await secureStorage.read(key: 'rpg_ai_api_url');
    final model = await secureStorage.read(key: 'rpg_ai_model');
    final provider = await secureStorage.read(key: 'rpg_ai_provider');
    
    if (apiKey != null && model != null) {
      state = state.copyWith(
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
        provider: provider ?? 'openai',
        isConfigured: true,
      );
    }
  }

  void setProvider(String provider) {
    state = state.copyWith(provider: provider);
  }

  Future<void> testConnection() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false);
      // In real app, would test actual API connection
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection test failed: $e');
    }
  }
}

final aiConfigurationProvider = StateNotifierProvider<AiConfigNotifier, AiConfigState>((ref) {
  final notifier = AiConfigNotifier(ref);
  notifier.load();
  return notifier;
});

/// AI Agent Service Provider - uses configured AI or mock
final aiAgentServiceProvider = Provider<AiAgentService>((ref) {
  final aiConfig = ref.watch(aiConfigurationProvider);
  if (aiConfig.isConfigured && aiConfig.apiKey != null) {
    return OpenAiAgentService(
      apiKey: aiConfig.apiKey!,
      baseUrl: aiConfig.apiUrl,
      model: aiConfig.model,
    );
  }
  return MockAiAgentService();
});

