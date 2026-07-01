import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;
  final double blur;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.color,
    this.border,
    this.blur = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark
        ? const Color(0xFF181D2B).withOpacity(0.45)
        : Colors.white.withOpacity(0.65);
    
    final fallbackBorder = Border.all(
      color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.45),
      width: 1.5,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: color ?? fallbackColor,
            borderRadius: BorderRadius.circular(borderRadius ?? 24.0),
            border: border ?? fallbackBorder,
          ),
          child: child,
        ),
      ),
    );
  }
}
