/// Application-wide constants for Personal Life RPG
class AppConstants {
  // GitHub API
  static const String githubApiBaseUrl = 'https://api.github.com';
  static const String githubRepoOwner = 'esrimova';
  static const String githubRepoName = 'RPG';
  
  // GitHub Workflow
  static const String createEntityWorkflow = 'create_entity.yml';
  static const String statusFilePath = '.rpg_status.json';
  
  // Polling Configuration
  static const int initialPollDelayMs = 2000;
  static const int maxPollDelayMs = 8000;
  static const int maxPollAttempts = 10;
  
  // Storage Keys
  static const String githubPatKey = 'github_pat';
  static const String githubRepoKey = 'github_repo';
  static const String userProfileKey = 'user_profile';
  static const String lastSyncKey = 'last_sync';
  
  // Default Branches
  static const List<String> defaultBranches = [
    'Physical Development',
    'Professional Skills',
    'Personal Skills',
    'Family & Bonding',
  ];
  
  // Activity Field Types
  static const List<String> activityFieldTypes = [
    'integer',
    'seconds',
    'slider_1_10',
    'boolean',
    'text',
  ];
  
  // XP Constants
  static const int baseXpPerActivity = 45;
  static const double xpMultiplierPerRep = 0.6;
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}