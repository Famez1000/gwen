import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class HowToCopeAnxietyScreen extends StatelessWidget {
  const HowToCopeAnxietyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bodyColor = isDark ? Colors.white70 : Colors.black.withAlpha(166);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'How to cope with anxiety?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Coping with anxiety means helping your body feel safer while the anxious wave passes.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You do not have to solve every thought. Start with one steadying action, then choose the next small step.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: bodyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CopingStepCard(
              icon: Icons.air_rounded,
              color: Colors.teal.shade600,
              title: 'Slow the alarm',
              text:
                  'Make your exhale a little longer than your inhale. This gives your nervous system a signal that the danger level can come down.',
            ),
            const SizedBox(height: 12),
            _CopingStepCard(
              icon: Icons.filter_center_focus_rounded,
              color: Theme.of(context).colorScheme.secondary,
              title: 'Come back to the room',
              text:
                  'Name what you can see, touch, hear, smell, and taste. Grounding helps your brain notice the present instead of chasing imagined danger.',
            ),
            const SizedBox(height: 12),
            _CopingStepCard(
              icon: Icons.bubble_chart_rounded,
              color: Theme.of(context).colorScheme.tertiary,
              title: 'Unhook from the thought',
              text:
                  'Try saying: I am having the thought that something bad will happen. That small distance can make the thought less powerful.',
            ),
            const SizedBox(height: 12),
            _CopingStepCard(
              icon: Icons.draw_rounded,
              color: Colors.amber.shade700,
              title: 'Give the feeling somewhere to go',
              text:
                  'Write one sentence, draw the feeling, pop bubbles, or move your body gently. Anxiety often softens when it has an outlet.',
            ),
            const SizedBox(height: 12),
            _CopingStepCard(
              icon: Icons.volunteer_activism_rounded,
              color: Colors.pink.shade300,
              title: 'Choose one kind action',
              text:
                  'Drink water, sit down, text someone safe, step outside, or lower one demand. Coping is built from small acts of care.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CopingStepCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _CopingStepCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? Colors.white70
                        : Colors.black.withAlpha(166),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
