import 'package:flutter/material.dart';
import '../../core/theme/index.dart';

class ActivityItem extends StatelessWidget {
  final String name;
  final String description;
  final String category;
  final Color categoryColor;
  final IconData icon;
  final Color iconColor;
  final int xpReward;
  final String statReward;
  final Color statColor;
  final bool isRecording;
  final VoidCallback? onRecord;
  final VoidCallback? onSync;

  const ActivityItem({
    super.key,
    required this.name,
    required this.description,
    required this.category,
    required this.categoryColor,
    required this.icon,
    required this.iconColor,
    required this.xpReward,
    required this.statReward,
    required this.statColor,
    this.isRecording = false,
    this.onRecord,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.toUpperCase(),
                            style: AppTextStyles.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            border: Border.all(color: categoryColor, width: 1),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(color: categoryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _RewardChip(
                          icon: Icons.bolt,
                          label: '+$xpReward XP',
                          color: AppColors.electricCyan,
                        ),
                        const SizedBox(width: 8),
                        _RewardChip(
                          icon: Icons.analytics,
                          label: statReward,
                          color: statColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isRecording ? null : onRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCyan,
                    foregroundColor: AppColors.coreVoid,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRecording ? Icons.hourglass_top : Icons.play_arrow,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRecording ? 'RECORDING...' : 'RECORD',
                        style: AppTextStyles.labelMediumUpper.copyWith(
                          color: AppColors.coreVoid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onSync != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSync,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sync, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'SYNC',
                          style: AppTextStyles.labelMediumUpper,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPLETION STATE',
                  style: AppTextStyles.labelSmallUpper,
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isRecording ? AppColors.highVoltageYellow : AppColors.electricCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRecording ? 'EXECUTING PROTOCOL' : 'READY FOR EXECUTION',
                      style: AppTextStyles.labelSmallUpper.copyWith(
                        color: isRecording ? AppColors.highVoltageYellow : AppColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}