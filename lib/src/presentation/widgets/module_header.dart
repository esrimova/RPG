import 'package:flutter/material.dart';
import '../../core/theme/index.dart';

class ModuleHeader extends StatelessWidget {
  final String moduleCode;
  final String? status;
  final Color statusColor;
  final Widget? trailing;

  const ModuleHeader({
    super.key,
    required this.moduleCode,
    this.status,
    this.statusColor = AppColors.electricCyan,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.brushedMetallicTrim,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.electricCyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            moduleCode.toUpperCase(),
            style: AppTextStyles.labelSmallUpper.copyWith(
              color: AppColors.electricCyan,
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 12),
            Text(
              status!,
              style: AppTextStyles.labelSmallUpper.copyWith(
                color: statusColor,
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}