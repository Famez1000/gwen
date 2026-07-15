import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class HowToUnderstandAnxietyScreen extends StatelessWidget {
  const HowToUnderstandAnxietyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bodyColor = isDark ? Colors.white70 : Colors.black.withAlpha(166);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'How to understand anxiety?',
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
                      Icons.manage_search_rounded,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Understanding anxiety starts with getting curious instead of judging yourself.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Anxiety is often a protection signal. It may be trying to prepare you, prevent danger, or avoid a feeling that once felt too big.',
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
            _UnderstandingStepCard(
              icon: Icons.monitor_heart_rounded,
              color: Colors.pink.shade300,
              title: 'Notice the body signal',
              text:
                  'Look for tightness, heat, shallow breathing, restlessness, nausea, or pressure. The body often speaks before thoughts become clear.',
            ),
            const SizedBox(height: 12),
            _UnderstandingStepCard(
              icon: Icons.psychology_alt_rounded,
              color: Colors.deepPurple.shade300,
              title: 'Name the thought',
              text:
                  'Ask: What is my mind predicting right now? Many anxious thoughts are warnings about rejection, failure, danger, or losing control.',
            ),
            const SizedBox(height: 12),
            _UnderstandingStepCard(
              icon: Icons.bolt_rounded,
              color: Colors.amber.shade700,
              title: 'Find the trigger',
              text:
                  'A trigger can be a place, task, person, memory, sensation, or uncertainty. Naming it turns the fear from a fog into something you can work with.',
            ),
            const SizedBox(height: 12),
            _UnderstandingStepCard(
              icon: Icons.insights_rounded,
              color: Colors.indigo.shade400,
              title: 'Look for patterns',
              text:
                  'Notice when anxiety gets stronger or softer. Time of day, sleep, conflict, caffeine, avoidance, and pressure can all shape the pattern.',
            ),
            const SizedBox(height: 12),
            _UnderstandingStepCard(
              icon: Icons.question_answer_rounded,
              color: Colors.teal.shade600,
              title: 'Ask one kind question',
              text:
                  'Try: What is this anxiety trying to protect me from? What would help me feel one percent safer right now?',
            ),
          ],
        ),
      ),
    );
  }
}

class _UnderstandingStepCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _UnderstandingStepCard({
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
