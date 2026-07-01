import 'package:flutter/material.dart';

import 'understand_topic_screen.dart';

class ThoughtsScreen extends StatelessWidget {
  const ThoughtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnderstandTopicScreen(
      title: 'Thoughts',
      subtitle:
          'Anxious thoughts can feel urgent, but they are signals, not facts.',
      icon: Icons.psychology_alt_rounded,
      color: Colors.deepPurple.shade300,
      gwenContext:
          'The user is reading about anxious thinking loops, catastrophizing, what-if thoughts, mind reading, and treating thoughts as signals rather than facts. Help them slow down and question anxious thoughts kindly.',
      sections: const [
        UnderstandTopicSection(
          title: 'Thoughts are not orders',
          body:
              'An anxious thought may arrive loudly, but you do not have to obey it. You can notice it, name it, and decide what deserves your attention.',
        ),
        UnderstandTopicSection(
          title: 'Common loops',
          body:
              'Anxiety often uses what-if questions, worst-case stories, mind reading, and replaying old moments. These loops try to protect you, but they can keep your body on alert.',
        ),
        UnderstandTopicSection(
          title: 'A gentle pause',
          body:
              'Try saying: I am having the thought that something bad will happen. This creates a little distance, so you can respond instead of react.',
        ),
      ],
      reflectionPrompts: const [
        'What thought is repeating the loudest right now?',
        'Is this thought a fact, a fear, or a prediction?',
        'What would I tell a friend who had this thought?',
      ],
    );
  }
}
