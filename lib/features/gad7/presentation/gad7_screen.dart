import '../../../core/state/app_state.dart';
import 'package:flutter/material.dart';


// Option labels with points for GAD-7 answers
final List<String> _optionLabels = [
  'Not at all (0)',
  'Several days (1)',
  'More than half the days (2)',
  'Nearly every day (3)',
];


class GAD7Screen extends StatefulWidget {
  final AppState appState;
  const GAD7Screen({Key? key, required this.appState}) : super(key: key);

  @override
  State<GAD7Screen> createState() => _GAD7ScreenState();
}

class _GAD7ScreenState extends State<GAD7Screen> {
  final List<int> _answers = List.filled(7, -1);
  final List<String> _questions = [
    // GAD-7 questions remain unchanged

    "Feeling nervous, anxious or on edge",
    "Not being able to stop or control worrying",
    "Worrying too much about different things",
    "Trouble relaxing",
    "Being so restless that it is hard to sit still",
    "Becoming easily annoyed or irritable",
    "Feeling afraid as if something awful might happen",
  ];

  void _submit() {
    if (_answers.contains(-1)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please answer all questions')));
      return;
    }
    final total = _answers.reduce((a, b) => a + b);
    String interpretation;
    String severity;
    String comment;
    String recommendation = '';
    if (total <= 4) {
      severity = 'Minimal anxiety';
      comment = '';
    } else if (total >= 5 && total <= 9) {
      severity = 'Mild';
      comment = 'Monitor';
    } else if (total >= 10 && total <= 14) {
      severity = 'Moderate';
      comment = 'Possible clinically significant condition';
      recommendation = 'Further assessment recommended.';
    } else { // total > 15
      severity = 'Severe';
      comment = 'Active treatment probably warranted';
      recommendation = 'Further assessment recommended.';
    }
    interpretation = '$severity - $comment';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('GAD-7 Result'),
        content: Text('Score: $total\nInterpretation: $interpretation\n$recommendation'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GAD-7 Anxiety Survey')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _questions.length + 1,
          itemBuilder: (context, index) {
            if (index == _questions.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: ElevatedButton(onPressed: _submit, child: const Text('Submit')),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
  '${index + 1}. ${_questions[index]}',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
),
                Column(
                  children: List.generate(4, (i) {
                    return RadioListTile<int>(
                      title: Text(_optionLabels[i], style: const TextStyle(fontSize: 14)),
                      value: i,
                      groupValue: _answers[index],
                      onChanged: (v) => setState(() => _answers[index] = v!),
                    );
                  }),
                ),
                const Divider(),
              ],
            );
          },
        ),
      ),
    );
  }
}
