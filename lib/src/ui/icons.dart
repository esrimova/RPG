import 'package:flutter/material.dart';

/// Curated icon set. Icons are stored by code point and looked up here, which
/// keeps release builds tree-shakeable.
const pickableIcons = <IconData>[
  Icons.fitness_center,
  Icons.directions_run,
  Icons.self_improvement,
  Icons.menu_book,
  Icons.code,
  Icons.work,
  Icons.school,
  Icons.family_restroom,
  Icons.favorite,
  Icons.groups,
  Icons.restaurant,
  Icons.bedtime,
  Icons.savings,
  Icons.palette,
  Icons.music_note,
  Icons.sports_esports,
  Icons.eco,
  Icons.pets,
  Icons.home,
  Icons.flight,
  Icons.timer,
  Icons.psychology,
  Icons.directions_bike,
  Icons.pool,
];

IconData iconFor(int codePoint) =>
    pickableIcons.firstWhere((i) => i.codePoint == codePoint, orElse: () => Icons.star);
