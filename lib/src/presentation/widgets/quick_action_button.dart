import 'package:flutter/material.dart';
import '../../core/theme/index.dart';

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isExpanded;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChamferedContainer(
      onTap: onPressed,
      backgroundColor: Colors.transparent,
      borderColor: AppColors.highVoltageYellow,
      chamferSize: 12,
      boxShadow: AppColors.voltageFlareGlow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.coreVoid, size: 24),
          const SizedBox(width: 12),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelLargeUpper.copyWith(
              color: AppColors.coreVoid,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}