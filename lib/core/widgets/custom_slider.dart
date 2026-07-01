import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAnxietySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool hapticsEnabled;

  const CustomAnxietySlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.hapticsEnabled = true,
  }) : super(key: key);

  String _getLabelForLevel(int level) {
    if (level <= 2) return "Safe & Grounded";
    if (level <= 4) return "Mild Unease";
    if (level <= 6) return "Racing Thoughts";
    if (level <= 8) return "High Tension";
    return "Panic & Overwhelm";
  }

  Color _getColorForLevel(int level, bool isDark) {
    // Soft transitions of calming colors (no harsh reds)
    if (level <= 2) {
      return isDark ? const Color(0xFF759D8C) : const Color(0xFF5F8474); // Sage Green
    }
    if (level <= 5) {
      return isDark ? const Color(0xFF8BA2C1) : const Color(0xFF6B82A1); // Calm Blue
    }
    if (level <= 7) {
      return isDark ? const Color(0xFFA5A0BF) : const Color(0xFF8B85A8); // Lavender
    }
    return isDark ? const Color(0xFFC79E9E) : const Color(0xFFB88C8C); // Warm Muted Peach
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = _getColorForLevel(value, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Level Indicator Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Level $value",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getLabelForLevel(value),
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Custom Gestural Track
        LayoutBuilder(
          builder: (context, constraints) {
            final double trackWidth = constraints.maxWidth;
            final double stepWidth = trackWidth / 9;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                final double localX = details.localPosition.dx;
                final double percent = localX / trackWidth;
                final int rawLevel = (percent * 9).round() + 1;
                final int newLevel = rawLevel.clamp(1, 10);
                if (newLevel != value) {
                  onChanged(newLevel);
                  if (hapticsEnabled) {
                    HapticFeedback.selectionClick();
                  }
                }
              },
              onTapDown: (details) {
                final double localX = details.localPosition.dx;
                final double percent = localX / trackWidth;
                final int rawLevel = (percent * 9).round() + 1;
                final int newLevel = rawLevel.clamp(1, 10);
                if (newLevel != value) {
                  onChanged(newLevel);
                  if (hapticsEnabled) {
                    HapticFeedback.selectionClick();
                  }
                }
              },
              child: Container(
                height: 50,
                color: Colors.transparent, // Expand touch target
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track line
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2435) : const Color(0xFFE2E0DD),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    // Active track fill
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: stepWidth * (value - 1),
                        height: 6,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Interactive points
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(10, (index) {
                        final int level = index + 1;
                        final bool isActive = level == value;
                        final bool isVisited = level < value;
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 22 : 12,
                          height: isActive ? 22 : 12,
                          decoration: BoxDecoration(
                            color: isActive
                                ? themeColor
                                : (isVisited ? themeColor.withOpacity(0.4) : (isDark ? const Color(0xFF2E3547) : const Color(0xFFC7C5C2))),
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: themeColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                            border: Border.all(
                              color: isDark ? const Color(0xFF0F131E) : Colors.white,
                              width: isActive ? 3 : 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
