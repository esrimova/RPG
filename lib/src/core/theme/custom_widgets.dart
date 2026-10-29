import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// A card with cyberpunk styling - metallic borders, chamfered corners, glow effects
class CyberCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? glowColor;
  final bool isActive;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const CyberCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.glowColor,
    this.isActive = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.brushedMetallicTrim;
    final effectiveGlowColor = glowColor ?? AppColors.electricCyan;
    
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: effectiveGlowColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                ...AppColors.cardElevation,
              ]
            : AppColors.cardElevation,
      ),
      child: child,
    );
    
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: card,
        ),
      );
    }
    
    return card;
  }
}

/// Chamfered corner container for primary action buttons
class ChamferedContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double chamferSize;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const ChamferedContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.chamferSize = 8,
    this.padding,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = CustomPaint(
      painter: _ChamferedPainter(
        backgroundColor: backgroundColor ?? AppColors.elevatedPlate,
        borderColor: borderColor ?? AppColors.electricCyan,
        borderWidth: 1.5,
        chamferSize: chamferSize,
        boxShadow: boxShadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: child,
      ),
    );
    
    if (onTap != null) {
      container = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: container,
        ),
      );
    }
    
    return container;
  }
}

class _ChamferedPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double chamferSize;
  final List<BoxShadow>? boxShadow;

  _ChamferedPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.chamferSize,
    this.boxShadow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final r = chamferSize;
    
    // Draw shadow first
    if (boxShadow != null) {
      final shadowPath = Path()
        ..moveTo(r, 0)
        ..lineTo(size.width - r, 0)
        ..lineTo(size.width, r)
        ..lineTo(size.width, size.height - r)
        ..lineTo(size.width - r, size.height)
        ..lineTo(r, size.height)
        ..lineTo(0, size.height - r)
        ..lineTo(0, r)
        ..close();
      
      for (final shadow in boxShadow!) {
        canvas.drawPath(
          shadowPath.shift(shadow.offset),
          Paint()
            ..color = shadow.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius),
        );
      }
    }
    
    // Main shape
    path
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..lineTo(size.width, r)
      ..lineTo(size.width, size.height - r)
      ..lineTo(size.width - r, size.height)
      ..lineTo(r, size.height)
      ..lineTo(0, size.height - r)
      ..lineTo(0, r)
      ..close();
    
    // Fill
    canvas.drawPath(path, Paint()..color = backgroundColor);
    
    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Segmented progress bar with discrete cells
class SegmentedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int segments;
  final Color filledColor;
  final Color emptyColor;
  final Color borderColor;
  final double height;
  final double segmentGap;
  final Widget? label;
  final TextStyle? labelStyle;

  const SegmentedProgressBar({
    super.key,
    required this.progress,
    this.segments = 10,
    this.filledColor = AppColors.electricCyan,
    this.emptyColor = AppColors.elevatedPlate,
    this.borderColor = AppColors.brushedMetallicTrim,
    this.height = 12,
    this.segmentGap = 2,
    this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final filledSegments = (progress * segments).round().clamp(0, segments);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          label!,
          const SizedBox(height: 8),
        ],
        Row(
          children: List.generate(segments, (index) {
            final isFilled = index < filledSegments;
            return Expanded(
              child: Container(
                height: height,
                margin: EdgeInsets.only(
                  right: index == segments - 1 ? 0 : segmentGap,
                ),
                decoration: BoxDecoration(
                  color: isFilled ? filledColor : emptyColor,
                  border: Border.all(
                    color: isFilled ? filledColor : borderColor,
                    width: 1,
                  ),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: filledColor.withValues(alpha: 0.7),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Neon border container for active/focused elements
class NeonBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderWidth;
  final double borderRadius;
  final double glowRadius;
  final EdgeInsetsGeometry? padding;

  const NeonBorder({
    super.key,
    required this.child,
    this.color = AppColors.electricCyan,
    this.borderWidth = 1.5,
    this.borderRadius = 0,
    this.glowRadius = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: borderWidth),
        borderRadius: borderRadius > 0 ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: glowRadius,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: glowRadius * 2.5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Toast/notification overlay
class CyberToast extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Duration duration;

  const CyberToast({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.verified,
    this.iconColor = AppColors.highVoltageYellow,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<CyberToast> createState() => _CyberToastState();
}

class _CyberToastState extends State<CyberToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
    
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              border: Border.all(
                color: widget.iconColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        widget.message,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'OK',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: widget.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a cyberpunk toast notification
void showCyberToast(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.verified,
  Color iconColor = AppColors.highVoltageYellow,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: CyberToast(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
      ),
    ),
  );
  
  Overlay.of(context).insert(entry!);
  
  Future.delayed(duration + const Duration(milliseconds: 300), () {
    entry?.remove();
  });
}