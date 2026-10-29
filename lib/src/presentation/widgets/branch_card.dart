import 'package:flutter/material.dart';
import '../../core/theme/index.dart';
import '../../domain/entities/branch.dart';

class BranchCard extends StatelessWidget {
  final String name;
  final String description;
  final int level;
  final int xpToday;
  final double progress;
  final Color accentColor;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const BranchCard({
    super.key,
    required this.name,
    required this.description,
    required this.level,
    required this.xpToday,
    required this.progress,
    required this.accentColor,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  // Constructor from Branch entity
  factory BranchCard.fromEntity({
    required Branch branch,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return BranchCard(
      name: branch.name,
      description: branch.description,
      level: branch.level,
      xpToday: 0, // Would be calculated from today's records
      progress: branch.progress,
      accentColor: branch.accentColor,
      icon: branch.icon,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      borderColor: isSelected ? accentColor : AppColors.brushedMetallicTrim,
      glowColor: accentColor,
      isActive: isSelected,
      onTap: onTap,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      border: Border.all(color: accentColor, width: 1),
                    ),
                    child: Text(
                      'LVL $level',
                      style: AppTextStyles.hudMetricSmall.copyWith(
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+$xpToday XP TODAY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            style: AppTextStyles.headlineSmall.copyWith(color: accentColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NODE PROGRESS',
                      style: AppTextStyles.labelSmallUpper,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTextStyles.hudMetricSmall.copyWith(
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedProgressBar(
                  progress: progress,
                  segments: 10,
                  filledColor: accentColor,
                  emptyColor: AppColors.surfaceContainer,
                  borderColor: AppColors.brushedMetallicTrim,
                  height: 6,
                  segmentGap: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : AppColors.brushedMetallicTrim,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSelected ? 'SELECTED BRANCH' : 'TAP TO SWITCH',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: isSelected ? accentColor : AppColors.outlineVariant,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isSelected ? accentColor : AppColors.outlineVariant,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}