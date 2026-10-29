import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../entities/index.dart';

/// AI Agent Service Interface for LLM integration
abstract class AiAgentService {
  /// Analyzes records and generates feedback proposals
  Future<AiFeedback> analyzeProgress({
    required List<Record> recentRecords,
    required List<Branch> branches,
    required List<Activity> activities,
    required UserProfile profile,
  });

  /// Generates a quest proposal based on current state
  Future<QuestProposal?> generateQuest({
    required List<Branch> branches,
    required UserProfile profile,
    required List<Record> recentRecords,
  });

  /// Provides a quick insight for a specific branch
  Future<String?> getBranchInsight({
    required Branch branch,
    required List<Record> branchRecords,
    required List<Activity> branchActivities,
  });
}

/// Feedback proposal from AI analysis
class AiFeedback {
  final String summary;
  final List<BadgeProposal> badgeProposals;
  final List<QuestProposal> questProposals;
  final List<InsightProposal> insights;
  final DateTime generatedAt;

  const AiFeedback({
    required this.summary,
    this.badgeProposals = const [],
    this.questProposals = const [],
    this.insights = const [],
    required this.generatedAt,
  });
}

/// Badge unlock proposal
class BadgeProposal {
  final String id;
  final String name;
  final String description;
  final Color color;
  final String iconName;
  final int xpBonus;
  final Map<String, dynamic> criteria;

  const BadgeProposal({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.iconName,
    required this.xpBonus,
    required this.criteria,
  });
}

/// Quest proposal
class QuestProposal {
  final String id;
  final String title;
  final String description;
  final String rank; // S, A, B, C, D
  final Duration timeLimit;
  final List<QuestReward> rewards;
  final String? targetBranchId;
  final String? targetActivityId;
  final Map<String, dynamic> conditions;

  const QuestProposal({
    required this.id,
    required this.title,
    required this.description,
    required this.rank,
    required this.timeLimit,
    required this.rewards,
    this.targetBranchId,
    this.targetActivityId,
    required this.conditions,
  });
}

/// Quest reward
class QuestReward {
  final String type; // xp, title, item, stat
  final String label;
  final int value;
  final Color color;

  const QuestReward({
    required this.type,
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Insight proposal
class InsightProposal {
  final String category; // performance, recovery, balance, streak
  final String title;
  final String description;
  final String actionableAdvice;
  final Color color;
  final double severity; // 0.0 to 1.0

  const InsightProposal({
    required this.category,
    required this.title,
    required this.description,
    required this.actionableAdvice,
    required this.color,
    required this.severity,
  });
}

/// Mock AI Agent Service for testing and development
class MockAiAgentService implements AiAgentService {
  @override
  Future<AiFeedback> analyzeProgress({
    required List<Record> recentRecords,
    required List<Branch> branches,
    required List<Activity> activities,
    required UserProfile profile,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final badgeProposals = <BadgeProposal>[];
    final questProposals = <QuestProposal>[];
    final insights = <InsightProposal>[];
    
    // Analyze streak
    if (profile.currentStreak >= 7 && profile.currentStreak < 14) {
      badgeProposals.add(BadgeProposal(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Maintained a 7-day overclock streak',
        color: AppColors.highVoltageYellow,
        iconName: 'local_fire_department',
        xpBonus: 500,
        criteria: {'streak': 7},
      ));
    }
    
    if (profile.currentStreak >= 14) {
      badgeProposals.add(BadgeProposal(
        id: 'fortnight_phantom',
        name: 'Fortnight Phantom',
        description: '14 consecutive days of neural synchronization',
        color: AppColors.electricCyan,
        iconName: 'bolt',
        xpBonus: 1500,
        criteria: {'streak': 14},
      ));
    }
    
    // Analyze branch progress
    for (final branch in branches) {
      final branchRecords = recentRecords.where((r) => r.branchId == branch.id).toList();
      final totalXp = branchRecords.fold(0, (sum, r) => sum + r.xpEarned);
      
      if (branch.progress >= 0.9 && branch.progress < 1.0) {
        questProposals.add(QuestProposal(
          id: 'push_${branch.id}',
          title: 'FINAL ASCENSION: ${branch.name.toUpperCase()}',
          description: 'Branch at ${(branch.progress * 100).round()}%. Push to level ${branch.level + 1}.',
          rank: 'A',
          timeLimit: const Duration(hours: 24),
          rewards: [
            QuestReward(type: 'xp', label: '+500 XP', value: 500, color: AppColors.electricCyan),
            QuestReward(type: 'stat', label: '+5 ${branch.name.split(' ').first}', value: 5, color: branch.accentColor),
          ],
          targetBranchId: branch.id,
          conditions: {'branch_progress': branch.progress},
        ));
      }
    }
    
    // Generate insights
    final todayRecords = recentRecords.where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
    if (todayRecords.isEmpty) {
      insights.add(InsightProposal(
        category: 'streak',
        title: 'NEURAL SILENCE DETECTED',
        description: 'No activity recorded in the last 24 hours. Streak at risk.',
        actionableAdvice: 'Execute at least one protocol before cycle reset.',
        color: AppColors.overloadCrimson,
        severity: 0.8,
      ));
    } else if (todayRecords.length >= 3) {
      insights.add(InsightProposal(
        category: 'performance',
        title: 'OVERCLOCK SUSTAINED',
        description: '${todayRecords.length} protocols executed today. Synapse efficiency elevated.',
        actionableAdvice: 'Maintain momentum. Consider a recovery protocol tonight.',
        color: AppColors.electricCyan,
        severity: 0.3,
      ));
    }
    
    // Check balance
    final branchXp = <String, int>{};
    for (final record in recentRecords) {
      branchXp[record.branchId] = (branchXp[record.branchId] ?? 0) + record.xpEarned;
    }
    if (branchXp.length >= 2) {
      final values = branchXp.values.toList()..sort();
      if (values.last > values.first * 3) {
        insights.add(InsightProposal(
          category: 'balance',
          title: 'ATTRIBUTE IMBALANCE',
          description: 'One branch dominates XP allocation. Other pathways atrophying.',
          actionableAdvice: 'Diversify protocol execution across all active branches.',
          color: AppColors.electricViolet,
          severity: 0.6,
        ));
      }
    }
    
    return AiFeedback(
      summary: _generateSummary(profile, recentRecords, branches),
      badgeProposals: badgeProposals,
      questProposals: questProposals,
      insights: insights,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<QuestProposal?> generateQuest({
    required List<Branch> branches,
    required UserProfile profile,
    required List<Record> recentRecords,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (branches.isEmpty) return null;
    
    // Pick a random active branch
    final activeBranches = branches.where((b) => b.isActive).toList();
    if (activeBranches.isEmpty) return null;
    
    final branch = activeBranches[DateTime.now().millisecond % activeBranches.length];
    final activities = branch.activities.where((a) => a.isActive).toList();
    if (activities.isEmpty) return null;
    
    final activity = activities[DateTime.now().millisecond % activities.length];
    
    return QuestProposal(
      id: 'quest_${DateTime.now().millisecondsSinceEpoch}',
      title: 'SPONTANEOUS: ${activity.name.toUpperCase()}',
      description: 'A.E.G.I.S. detects optimal conditions for ${activity.category.toLowerCase()} enhancement.',
      rank: ['B', 'A', 'S'][DateTime.now().millisecond % 3],
      timeLimit: Duration(hours: 2 + (DateTime.now().millisecond % 6)),
      rewards: [
        QuestReward(type: 'xp', label: '+${activity.baseXp + 50} EXP', value: activity.baseXp + 50, color: AppColors.electricCyan),
        QuestReward(type: 'stat', label: '+3 ${activity.category}', value: 3, color: activity.accentColor),
      ],
      targetBranchId: branch.id,
      targetActivityId: activity.id,
      conditions: {'activity': activity.id, 'branch': branch.id},
    );
  }

  @override
  Future<String?> getBranchInsight({
    required Branch branch,
    required List<Record> branchRecords,
    required List<Activity> branchActivities,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (branchRecords.isEmpty) {
      return 'Branch "${branch.name}" is dormant. Initiate first protocol to establish baseline telemetry.';
    }
    
    final recentXp = branchRecords
        .where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .fold(0, (sum, r) => sum + r.xpEarned);
    
    if (recentXp == 0) {
      return 'No activity in 7 cycles. Recommend reactivation protocol to prevent skill decay.';
    }
    
    final avgXp = recentXp / 7;
    if (avgXp > 200) {
      return 'High-yield branch (${avgXp.round()} XP/cycle). Consider increasing difficulty for exponential growth.';
    } else if (avgXp < 50) {
      return 'Low yield detected (${avgXp.round()} XP/cycle). Optimize activity selection or increase frequency.';
    }
    
    return 'Stable progression (${avgXp.round()} XP/cycle). Current trajectory projects Level ${branch.level + 1} in ${((branch.xpToNextLevel - branch.currentXp) / avgXp).round()} days.';
  }

  String _generateSummary(UserProfile profile, List<Record> records, List<Branch> branches) {
    final todayXp = records
        .where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .fold(0, (sum, r) => sum + r.xpEarned);
    
    return 'Operator ${profile.displayName} at Level ${profile.level} (${profile.title}). '
        'Today: $todayXp XP across ${records.where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 1)))).length} protocols. '
        'Streak: ${profile.currentStreak} cycles. ${branches.where((b) => b.isActive).length} active neural pathways.';
  }
}

/// OpenAI-compatible AI Agent Service
class OpenAiAgentService implements AiAgentService {
  final String _apiKey;
  final String _baseUrl;
  final String _model;

  OpenAiAgentService({
    required String apiKey,
    this._baseUrl = 'https://api.openai.com/v1',
    this._model = 'gpt-4o-mini',
  }) : _apiKey = apiKey;

  @override
  Future<AiFeedback> analyzeProgress({
    required List<Record> recentRecords,
    required List<Branch> branches,
    required List<Activity> activities,
    required UserProfile profile,
  }) async {
    // In production, this would call the OpenAI API
    // For now, fall back to mock
    return MockAiAgentService().analyzeProgress(
      recentRecords: recentRecords,
      branches: branches,
      activities: activities,
      profile: profile,
    );
  }

  @override
  Future<QuestProposal?> generateQuest({
    required List<Branch> branches,
    required UserProfile profile,
    required List<Record> recentRecords,
  }) async {
    return MockAiAgentService().generateQuest(
      branches: branches,
      profile: profile,
      recentRecords: recentRecords,
    );
  }

  @override
  Future<String?> getBranchInsight({
    required Branch branch,
    required List<Record> branchRecords,
    required List<Activity> branchActivities,
  }) async {
    return MockAiAgentService().getBranchInsight(
      branch: branch,
      branchRecords: branchRecords,
      branchActivities: branchActivities,
    );
  }
}