import 'package:flutter/material.dart';
import '../../core/theme/index.dart';

class StatPod extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color valueColor;
  final double? progress;

  const StatPod({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.electricCyan,
    this.valueColor = AppColors.peakPhosphorWhite,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelSmallUpper,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.hudMetric.copyWith(color: valueColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (progress != null) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 30,
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: progress!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: valueColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}