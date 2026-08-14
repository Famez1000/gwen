import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class AutogenicTrainingScreen extends StatelessWidget {
  const AutogenicTrainingScreen({super.key});

  static const _steps = [
    (
      title: 'Heaviness',
      phrase: 'My arms and legs are pleasantly heavy.',
      icon: Icons.accessibility_new_rounded,
    ),
    (
      title: 'Warmth',
      phrase: 'My arms and legs are pleasantly warm.',
      icon: Icons.wb_sunny_rounded,
    ),
    (
      title: 'Calm heartbeat',
      phrase: 'My heartbeat is calm and regular.',
      icon: Icons.favorite_rounded,
    ),
    (
      title: 'Natural breathing',
      phrase: 'My breathing is calm and effortless.',
      icon: Icons.air_rounded,
    ),
    (
      title: 'Warm abdomen',
      phrase: 'My abdomen feels pleasantly warm.',
      icon: Icons.local_fire_department_rounded,
    ),
    (
      title: 'Cool forehead',
      phrase: 'My forehead is pleasantly cool.',
      icon: Icons.ac_unit_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bodyColor = isDark ? Colors.white70 : Colors.black.withAlpha(166);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Autogenic training',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      Icons.spa_rounded,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Relax through calm, repeated phrases',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Autogenic training is a relaxation technique developed by German psychiatrist Johannes Heinrich Schultz. It uses passive attention to create sensations such as heaviness, warmth, slow breathing, and relaxation.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: bodyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'A typical session',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ..._steps.indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TrainingStepCard(
                  number: entry.$1 + 1,
                  title: entry.$2.title,
                  phrase: entry.$2.phrase,
                  icon: entry.$2.icon,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _InfoCard(
              icon: Icons.self_improvement_rounded,
              title: 'How to practice',
              text:
                  'Lie down or sit comfortably. Repeat each phrase slowly and observe what you feel without trying to force a sensation. A session can last 5–15 minutes.',
              color: Colors.teal.shade600,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.wb_twilight_rounded,
              title: 'Finish gently',
              text:
                  'Move your hands and arms, breathe more deeply, and open your eyes when you are ready.',
              color: Colors.indigo.shade400,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.health_and_safety_rounded,
              title: 'A supportive practice',
              text:
                  'Similar to self-hypnosis or guided body relaxation, autogenic training may help reduce stress and anxiety, improve sleep, and ease tension-related symptoms. It should complement—not replace—medical care, especially for persistent pain or other symptoms.',
              color: Colors.amber.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingStepCard extends StatelessWidget {
  final int number;
  final String title;
  final String phrase;
  final IconData icon;
  final Color color;

  const _TrainingStepCard({
    required this.number,
    required this.title,
    required this.phrase,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: 19,
                  height: 19,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
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
                const SizedBox(height: 5),
                Text(
                  '“$phrase”',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 23),
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
