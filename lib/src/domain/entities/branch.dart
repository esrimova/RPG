import 'package:flutter/material.dart';
import 'activity.dart';

/// Represents a skill branch/tree in the RPG system
class Branch {
  final String id;
  final String name;
  final String description;
  final Color accentColor;
  final IconData icon;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final double weight;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Activity> activities;
  final Map<String, dynamic> metadata;

  const Branch({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
    required this.icon,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 5000,
    this.weight = 1.0,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.activities = const [],
    this.metadata = const {},
  });

  /// Creates a copy with updated fields
  Branch copyWith({
    String? id,
    String? name,
    String? description,
    Color? accentColor,
    IconData? icon,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    double? weight,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Activity>? activities,
    Map<String, dynamic>? metadata,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      accentColor: accentColor ?? this.accentColor,
      icon: icon ?? this.icon,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      weight: weight ?? this.weight,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activities: activities ?? this.activities,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Progress to next level (0.0 to 1.0)
  double get progress => currentXp / xpToNextLevel;

  /// Total XP earned across all activities in this branch
  int get totalActivityXp => activities.fold(0, (sum, a) => sum + a.currentXp);

  /// Number of active activities
  int get activeActivityCount => activities.where((a) => a.isActive).length;

  /// Weekly XP estimate based on activity weights
  int get estimatedWeeklyXp =>
      (activities.fold(0.0, (sum, a) => sum + (a.baseXp * a.weight)) * 7).round();

  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'accent_color': accentColor.value,
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      'icon_font_package': icon.fontPackage,
      'level': level,
      'current_xp': currentXp,
      'xp_to_next_level': xpToNextLevel,
      'weight': weight,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'activities': activities.map((a) => a.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Deserializes from JSON
  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      accentColor: Color(json['accent_color'] as int),
      icon: IconData(
        json['icon_code_point'] as int,
        fontFamily: json['icon_font_family'] as String?,
        fontPackage: json['icon_font_package'] as String?,
      ),
      level: json['level'] as int? ?? 1,
      currentXp: json['current_xp'] as int? ?? 0,
      xpToNextLevel: json['xp_to_next_level'] as int? ?? 5000,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      activities: (json['activities'] as List<dynamic>?)
              ?.map((a) => Activity.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          level == other.level &&
          currentXp == other.currentXp;

  @override
  int get hashCode => Object.hash(id, name, level, currentXp);

  @override
  String toString() =>
      'Branch(id: $id, name: $name, level: $level, xp: $currentXp/$xpToNextLevel, activities: ${activities.length})';
}