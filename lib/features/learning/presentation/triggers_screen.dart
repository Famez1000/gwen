import 'package:flutter/material.dart';

import 'understand_topic_screen.dart';

class TriggersScreen extends StatelessWidget {
  const TriggersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnderstandTopicScreen(
      title: 'Triggers',
      subtitle:
          'Triggers are clues about what your nervous system has learned to watch for.',
      icon: Icons.bolt_rounded,
      color: Colors.amber.shade700,
      gwenContext:
          'The user is reading about anxiety triggers: situations, memories, body sensations, uncertainty, conflict, pressure, and avoidance. Explain triggers as clues and help them identify patterns without blame.',
      sections: const [
        UnderstandTopicSection(
          title: 'A trigger is a clue',
          body:
              'A trigger is something that sparks anxiety. It may be a place, task, memory, sensation, person, or kind of uncertainty. Noticing it is information, not failure.',
        ),
        UnderstandTopicSection(
          title: 'Look for patterns',
          body:
              'Patterns can show up around sleep, hunger, conflict, deadlines, crowded spaces, social pressure, or feeling trapped. Small details can matter.',
        ),
        UnderstandTopicSection(
          title: 'Respond gently',
          body:
              'Once you spot a trigger, ask what kind of support fits: grounding, reassurance, movement, planning, rest, or talking to someone safe.',
        ),
      ],
      reflectionPrompts: const [
        'What was happening right before the anxiety rose?',
        'Was I tired, hungry, rushed, overstimulated, or uncertain?',
        'What support would match this trigger next time?',
      ],
    );
  }
}
