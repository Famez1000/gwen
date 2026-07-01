import 'package:flutter/material.dart';

import 'understand_topic_screen.dart';

class BodySignalsScreen extends StatelessWidget {
  const BodySignalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnderstandTopicScreen(
      title: 'Body Signals',
      subtitle:
          'Anxiety often speaks through the body before the mind can explain it.',
      icon: Icons.monitor_heart_rounded,
      color: Colors.pink.shade300,
      gwenContext:
          'The user is reading about body signals of anxiety: racing heart, tight chest, shaking, dizziness, stomach sensations, and muscle tension. Explain sensations gently and encourage grounding or medical help for severe or unusual symptoms.',
      sections: const [
        UnderstandTopicSection(
          title: 'Why it happens',
          body:
              'When your nervous system senses danger, it prepares you to act. Your heart may beat faster, breathing can change, and muscles may tighten. These sensations are uncomfortable, but they are common anxiety signals.',
        ),
        UnderstandTopicSection(
          title: 'Common signals',
          body:
              'You might notice a tight chest, warm face, shaky hands, nausea, dizziness, sweating, or a restless body. Naming the signal can make it feel less mysterious.',
        ),
        UnderstandTopicSection(
          title: 'What helps',
          body:
              'Try orienting to the room, relaxing your jaw, lowering your shoulders, and making your exhale a little longer. If a symptom feels severe, new, or unsafe, reach out for medical help.',
        ),
      ],
      reflectionPrompts: const [
        'Where do I feel anxiety first in my body?',
        'What sensation can I name without judging it?',
        'What would help my body feel 1 percent safer?',
      ],
    );
  }
}
