import 'package:flutter/material.dart';

import 'understand_topic_screen.dart';

class PatternsScreen extends StatelessWidget {
  const PatternsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnderstandTopicScreen(
      title: 'Patterns',
      subtitle: 'Patterns help you notice what changes anxiety over time.',
      icon: Icons.insights_rounded,
      color: Colors.indigo.shade400,
      gwenContext:
          'The user is reading about anxiety patterns over time: recurring triggers, body signals, thoughts, habits, sleep, stress, and what helps. Encourage noticing without judgment.',
      sections: const [
        UnderstandTopicSection(
          title: 'Patterns reduce mystery',
          body:
              'When anxiety feels random, it can feel more frightening. Looking for patterns can reveal what your body is reacting to and what helps it settle.',
        ),
        UnderstandTopicSection(
          title: 'Track gently',
          body:
              'You do not need perfect data. Notice time of day, sleep, stress, food, movement, people, places, and what helped by even a small amount.',
        ),
        UnderstandTopicSection(
          title: 'Use what you learn',
          body:
              'If a pattern appears, make one small adjustment. Prepare support before a stressful time, rest earlier, or repeat a tool that has helped before.',
        ),
      ],
      reflectionPrompts: const [
        'When does my anxiety most often rise?',
        'What seems to lower it, even slightly?',
        'What pattern am I noticing without blaming myself?',
      ],
    );
  }
}
