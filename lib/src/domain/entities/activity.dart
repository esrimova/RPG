import 'package:flutter/material.dart';
import 'activity_field.dart';

/// Represents an activity/ritual within a branch
class Activity {
  final String id;
  final String branchId;
  final String name;
  final String description;
  final String category;
  final Color accentColor;
  final IconData icon;
  final int baseXp;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final List<ActivityField> fields;
  final double weight;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const Activity({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    required this.category,
    required this.accentColor,
    required this.icon,
    this.baseXp = 45,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 1000,
    this.fields = const [],
    this.weight = 1.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Creates a copy with updated fields
  Activity copyWith({
    String? id,
    String? branchId,
    String? name,
    String? description,
    String? category,
    Color? accentColor,
    IconData? icon,
    int? baseXp,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    List<ActivityField>? fields,
    double? weight,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Activity(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      accentColor: accentColor ?? this.accentColor,
      icon: icon ?? this.icon,
      baseXp: baseXp ?? this.baseXp,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      fields: fields ?? this.fields,
      weight: weight ?? this.weight,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Progress to next level (0.0 to 1.0)
  double get progress => currentXp / xpToNextLevel;

  /// Calculates XP reward for a completion with given field values
  int calculateXpReward(Map<String, dynamic> fieldValues) {
    int bonus = 0;
    for (final field in fields) {
      final value = fieldValues[field.id];
      if (value != null) {
        switch (field.type) {
          case ActivityFieldType.integer:
            bonus += (value as int) * (field.step?.toInt() ?? 1);
            break;
          case ActivityFieldType.seconds:
            bonus += (value as int) ~/ 60; // 1 XP per minute
            break;
          case ActivityFieldType.slider1to10:
            bonus += ((value as double) * 2).round(); // Up to 20 XP for RPE
            break;
          default:
            break;
        }
      }
    }
    return baseXp + bonus;
  }

  /// Serializes to JSON (IconData and Color need special handling)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'description': description,
      'category': category,
      'accent_color': accentColor.value,
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      'icon_font_package': icon.fontPackage,
      'base_xp': baseXp,
      'level': level,
      'current_xp': currentXp,
      'xp_to_next_level': xpToNextLevel,
      'fields': fields.map((f) => f.toJson()).toList(),
      'weight': weight,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Deserializes from JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      accentColor: Color(json['accent_color'] as int),
      icon: IconData(
        json['icon_code_point'] as int,
        fontFamily: json['icon_font_family'] as String?,
        fontPackage: json['icon_font_package'] as String?,
      ),
      baseXp: json['base_xp'] as int? ?? 45,
      level: json['level'] as int? ?? 1,
      currentXp: json['current_xp'] as int? ?? 0,
      xpToNextLevel: json['xp_to_next_level'] as int? ?? 1000,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((f) => ActivityField.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          branchId == other.branchId &&
          name == other.name &&
          level == other.level &&
          currentXp == other.currentXp;

  @override
  int get hashCode =>
      Object.hash(id, branchId, name, level, currentXp);

  @override
  String toString() =>
      'Activity(id: $id, name: $name, level: $level, xp: $currentXp/$xpToNextLevel)';
}