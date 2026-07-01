import 'package:flutter/material.dart';

import 'understand_topic_screen.dart';

class AskYourselfScreen extends StatelessWidget {
  const AskYourselfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnderstandTopicScreen(
      title: 'Ask yourself',
      subtitle:
          'Gentle questions can help you understand what anxiety is trying to protect.',
      icon: Icons.self_improvement_rounded,
      color: Colors.teal.shade600,
      gwenContext:
          'The user is reading self-reflection questions for anxiety. Help them ask kind, curious questions about needs, fears, safety, support, and next steps without self-criticism.',
      sections: const [
        UnderstandTopicSection(
          title: 'Start with kindness',
          body:
              'Reflection works best when it is gentle. You are not interrogating yourself. You are listening for what your nervous system needs.',
        ),
        UnderstandTopicSection(
          title: 'Ask smaller questions',
          body:
              'Instead of asking “Why am I like this?”, try “What am I afraid might happen?” or “What would help me feel safer right now?”',
        ),
        UnderstandTopicSection(
          title: 'Choose one next step',
          body:
              'After you ask, choose one small response: breathe, write a sentence, drink water, move your body, ask for support, or take a short break.',
        ),
      ],
      reflectionPrompts: const [
        'What is my anxiety trying to protect me from?',
        'What do I need right now: comfort, clarity, rest, or action?',
        'What is one kind next step I can take?',
      ],
    );
  }
}
