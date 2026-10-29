import 'package:flutter/material.dart';

/// User profile and global RPG state
class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final String title; // e.g., "CYBER TITAN", "NEURAL RUNNER"
  final Map<String, int> coreStats; // energy, willpower, synapse, cyberware
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 1000,
    this.title = 'INITIATE',
    this.coreStats = const {
      'energy': 100,
      'willpower': 100,
      'synapse': 100,
      'cyberware': 100,
    },
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActiveDate,
    required this.createdAt,
    this.metadata = const {},
  });

  /// Creates a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    String? title,
    Map<String, int>? coreStats,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      title: title ?? this.title,
      coreStats: coreStats ?? this.coreStats,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Progress to next level (0.0 to 1.0)
  double get progress => currentXp / xpToNextLevel;

  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'level': level,
      'current_xp': currentXp,
      'xp_to_next_level': xpToNextLevel,
      'title': title,
      'core_stats': coreStats,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_active_date': lastActiveDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Deserializes from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      level: json['level'] as int? ?? 1,
      currentXp: json['current_xp'] as int? ?? 0,
      xpToNextLevel: json['xp_to_next_level'] as int? ?? 1000,
      title: json['title'] as String? ?? 'INITIATE',
      coreStats: Map<String, int>.from(json['core_stats'] as Map? ?? {
        'energy': 100,
        'willpower': 100,
        'synapse': 100,
        'cyberware': 100,
      }),
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActiveDate: DateTime.parse(json['last_active_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          level == other.level;

  @override
  int get hashCode => Object.hash(id, username, level);

  @override
  String toString() =>
      'UserProfile(id: $id, name: $displayName, level: $level, xp: $currentXp/$xpToNextLevel)';
}