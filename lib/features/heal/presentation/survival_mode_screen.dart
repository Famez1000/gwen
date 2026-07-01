import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class SurvivalModeScreen extends StatelessWidget {
  const SurvivalModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceText = isDark ? Colors.white : Colors.black87;
    final mutedText = isDark ? Colors.white70 : Colors.black.withAlpha(153);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Out of survival mode',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF142323),
                          Color(0xFF1F2933),
                          Color(0xFF201F2B),
                        ]
                      : const [
                          Color(0xFFEAF7F2),
                          Color(0xFFF8F7F1),
                          Color(0xFFEDECF8),
                        ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 90,
            left: -48,
            child: _SoftCircle(
              size: 190,
              color: Colors.teal.withAlpha(isDark ? 38 : 54),
            ),
          ),
          Positioned(
            bottom: 78,
            right: -58,
            child: _SoftCircle(
              size: 220,
              color: primaryColor.withAlpha(isDark ? 38 : 46),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 96).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Help your body remember it is safe now.',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: surfaceText,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No fixing everything. Just one signal of safety, then one tiny next step.',
                              style: TextStyle(
                                fontSize: 13,
                                color: mutedText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start here',
                                style: TextStyle(
                                  color: surfaceText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SafetyStep(
                                icon: Icons.chair_rounded,
                                title: 'Find support',
                                text:
                                    'Sit down, lean back, or place both feet on the floor.',
                                color: primaryColor,
                                textColor: mutedText,
                              ),
                              const SizedBox(height: 14),
                              _SafetyStep(
                                icon: Icons.water_drop_rounded,
                                title: 'Offer care',
                                text:
                                    'Drink water, eat something small, or loosen tight clothing.',
                                color: Colors.teal.shade500,
                                textColor: mutedText,
                              ),
                              const SizedBox(height: 14),
                              _SafetyStep(
                                icon: Icons.air_rounded,
                                title: 'Slow the signal',
                                text:
                                    'Breathe out a little longer than you breathe in.',
                                color: Colors.indigo.shade400,
                                textColor: mutedText,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        GlassCard(
                          padding: const EdgeInsets.all(18),
                          color: isDark
                              ? Colors.white.withAlpha(16)
                              : Colors.white.withAlpha(130),
                          child: Text(
                            'Say quietly: I do not have to solve my life right now. I only have to help my body feel a little safer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mutedText,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color textColor;

  const _SafetyStep({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withAlpha(31),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(text, style: TextStyle(color: textColor, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.35,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}
