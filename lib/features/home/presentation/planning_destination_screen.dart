import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/services/gemini_service.dart';
import '../../../core/widgets/glass_card.dart';

enum _PlanningDestination { cope, understand, heal }

class PlanningDestinationScreen extends StatelessWidget {
  const PlanningDestinationScreen({super.key});

  void _openDestination(
    BuildContext context,
    _PlanningDestination destination,
  ) {
    final screen = _PlanningFlowScreen(destination: destination);

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? Colors.white60 : Colors.black.withAlpha(153);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'What do you want to achieve?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'In order to optimize you plan, please tell what you intent to achieve.',
              style: TextStyle(fontSize: 15, height: 1.4, color: mutedText),
            ),
            const SizedBox(height: 18),
            _DestinationCard(
              icon: Icons.spa_outlined,
              title: 'Cope',
              lines: const [
                'My anxiety feels overwhelming, I am just looking for relief.',
              ],
              color: primaryColor,
              onTap: () => _openDestination(context, _PlanningDestination.cope),
            ),
            const SizedBox(height: 16),
            _DestinationCard(
              icon: Icons.lightbulb_outline,
              title: 'Understand',
              lines: const [
                'I intent to discover and understand why I feel anxious.',
              ],
              color: Colors.amber.shade700,
              onTap: () =>
                  _openDestination(context, _PlanningDestination.understand),
            ),
            const SizedBox(height: 16),
            _DestinationCard(
              imageIconPath: 'assets/images/resilient-health.png',
              title: 'Heal',
              lines: const [
                "I am committed to gradually vanquishing my anxiety. I am ready to face the fears that are causing it.",
              ],
              color: Colors.pink.shade300,
              onTap: () => _openDestination(context, _PlanningDestination.heal),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningFlowScreen extends StatefulWidget {
  final _PlanningDestination destination;

  const _PlanningFlowScreen({required this.destination});

  @override
  State<_PlanningFlowScreen> createState() => _PlanningFlowScreenState();
}

class _PlanningFlowScreenState extends State<_PlanningFlowScreen> {
  final Set<String> _multiAnswers = {};
  final TextEditingController _firstTextController = TextEditingController();
  final TextEditingController _secondTextController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final Map<int, String> _singleAnswers = {};

  int _step = 0;
  bool _isGeneratingPlan = false;
  bool _showResult = false;
  _GeneratedPlan? _generatedPlan;
  String? _firstChoice;
  String? _secondChoice;
  double _readiness = 5;

  @override
  void dispose() {
    _firstTextController.dispose();
    _secondTextController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.destination) {
    _PlanningDestination.cope => 'Cope Plan',
    _PlanningDestination.understand => 'Understand Plan',
    _PlanningDestination.heal => 'Heal Plan',
  };

  Color _color(BuildContext context) => switch (widget.destination) {
    _PlanningDestination.cope => Theme.of(context).primaryColor,
    _PlanningDestination.understand => Colors.amber.shade700,
    _PlanningDestination.heal => Colors.pink.shade300,
  };

  List<_QuestionConfig> get _questions => switch (widget.destination) {
    _PlanningDestination.cope => [
      const _QuestionConfig(
        title: 'How often do you feel anxious?',
        subtitle: 'This question is needed to make a timely plan.',
        type: _QuestionType.single,
        options: [
          'Multiple times every day',
          'Daily',
          'Several times a week',
          'Occasionally',
        ],
      ),
      const _QuestionConfig(
        title: 'When anxiety appears, what happens?',
        subtitle: 'Select all that apply.',
        type: _QuestionType.multi,
        options: [
          'Racing thoughts',
          'Panic attacks',
          'Fast heartbeat',
          'Dizziness',
          'Tight chest',
          'Nausea',
          'Stomach ache',
          'Muscles tighten',
          'Twitches',
          'Feeling in danger',
          "Can't concentrate",
          'Other',
        ],
      ),
      const _QuestionConfig(
        title: 'What usually triggers it?',
        subtitle:
            'This helps Gwyn shape the plan around the moments that need the most support.',
        type: _QuestionType.single,
        options: [
          'Social situations',
          'Work',
          'School',
          'Health',
          'Relationships',
          'Driving',
          'Crowds',
          'Unknown',
        ],
      ),
    ],
    _PlanningDestination.understand => [
      const _QuestionConfig(
        title: 'Write down what you feel.',
        subtitle:
            'Use your own words. This helps Gwyn understand the emotion, body feeling, or thought pattern.',
        type: _QuestionType.openFirst,
      ),
      const _QuestionConfig(
        title: 'How often does it occur?',
        subtitle:
            'Frequency helps Gwyn see whether the plan should be daily, weekly, or only for specific moments.',
        type: _QuestionType.single,
        options: [
          'Multiple times every day',
          'Daily',
          'Several times a week',
          'Occasionally',
        ],
      ),
      const _QuestionConfig(
        title: 'When does it arise?',
        subtitle:
            'Name the moment, place, person, task, or thought that usually comes before it.',
        type: _QuestionType.openSecond,
      ),
    ],
    _PlanningDestination.heal => [
      const _QuestionConfig(
        title: 'Have you made an Understand plan yet?',
        subtitle:
            'If there is no Understand plan yet, that would be better first. Healing can still start, but it helps to know what causes the anxiety.',
        type: _QuestionType.single,
        options: ['Yes', 'No', 'Not sure'],
      ),
      const _QuestionConfig(
        title: 'In what situation do you feel anxious?',
        subtitle:
            'Tick the situations that fit, or describe your own. Knowing this lets Gwyn make an action plan.',
        type: _QuestionType.multiWithText,
        options: [
          'Social situations',
          'Work',
          'School',
          'Health',
          'Relationships',
          'Driving',
          'Crowds',
          'Conflict',
          'Being alone',
          'Uncertainty',
        ],
      ),
      const _QuestionConfig(
        title:
            'How much time do you have available per week for healing practices?',
        subtitle:
            'This keeps the plan realistic. A small practice you repeat is better than a big plan you cannot sustain.',
        type: _QuestionType.single,
        options: ['15 min', '30 min', '1 hour', 'More than 1 hour'],
      ),
    ],
  };

  bool get _canContinue {
    final question = _questions[_step];

    return switch (question.type) {
      _QuestionType.single => _singleAnswers[_step] != null,
      _QuestionType.multi => _multiAnswers.isNotEmpty,
      _QuestionType.multiWithText =>
        _multiAnswers.isNotEmpty || _firstTextController.text.trim().isNotEmpty,
      _QuestionType.openFirst => _firstTextController.text.trim().isNotEmpty,
      _QuestionType.openSecond => _secondTextController.text.trim().isNotEmpty,
      _QuestionType.openGoal => _goalController.text.trim().isNotEmpty,
      _QuestionType.scale => true,
    };
  }

  Future<void> _continue() async {
    if (!_canContinue || _isGeneratingPlan) return;

    if (_step == _questions.length - 1) {
      await _generatePlan();
      return;
    }

    setState(() {
      _step++;
      if (_questions[_step].type == _QuestionType.single) {
        _secondChoice = null;
      }
    });
  }

  void _goBack() {
    if (_step <= 0 || _isGeneratingPlan) return;
    setState(() => _step--);
  }

  void _selectSingle(String value) {
    setState(() {
      _singleAnswers[_step] = value;
      if (_step == 0) {
        _firstChoice = value;
      } else {
        _secondChoice = value;
      }
    });
  }

  Future<void> _generatePlan() async {
    setState(() => _isGeneratingPlan = true);

    final fallbackPlan = _fallbackPlan();
    try {
      final results = await Future.wait([
        Future<void>.delayed(const Duration(seconds: 3)),
        GeminiService.instance.generateGwenResponse(_planPrompt()),
      ]);
      final aiText = results[1] as String;
      final generatedPlan = _GeneratedPlan.tryParse(aiText) ?? fallbackPlan;
      if (!mounted) return;

      setState(() {
        _generatedPlan = generatedPlan;
        _isGeneratingPlan = false;
        _showResult = true;
      });
    } catch (error) {
      debugPrint('Gwyn plan generation fallback: $error');
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      setState(() {
        _generatedPlan = fallbackPlan;
        _isGeneratingPlan = false;
        _showResult = true;
      });
    }
  }

  String _planPrompt() {
    final answers = _answerSummary();

    return '''
You are Gwyn, a warm anxiety-support companion inside a mental wellness app.
Create a short, practical, personalized ${_title.toLowerCase()} from these answers:

$answers

Return only valid JSON in this exact shape:
{
  "title": "Your ... Plan",
  "intro": "One short supportive sentence.",
  "sections": [
    {"title": "Section title", "items": ["Short action", "Short action"]}
  ]
}

Rules:
- Keep it gentle, realistic, and non-medical.
- Do not diagnose.
- Use 4 to 6 sections.
- Each item must be short enough for a mobile screen.
- Mention professional or emergency help only if the answers sound severe.
- For Heal plans, include acceptance of anxiety in the situation, one action to thwart the fear, visualization, practice with a mirror or friends, and a gentle real-world test.
''';
  }

  String _answerSummary() {
    final lines = <String>['Plan type: $_title'];

    for (var index = 0; index < _questions.length; index++) {
      final question = _questions[index];
      final answer = switch (question.type) {
        _QuestionType.single => _singleAnswers[index] ?? 'Not answered',
        _QuestionType.multi => _multiAnswers.join(', '),
        _QuestionType.multiWithText => [
          if (_multiAnswers.isNotEmpty) _multiAnswers.join(', '),
          if (_firstTextController.text.trim().isNotEmpty)
            _firstTextController.text.trim(),
        ].join('; '),
        _QuestionType.openFirst => _firstTextController.text.trim(),
        _QuestionType.openSecond => _secondTextController.text.trim(),
        _QuestionType.openGoal => _goalController.text.trim(),
        _QuestionType.scale => '${_readiness.round()} out of 10',
      };
      lines.add('${question.title}: $answer');
    }

    return lines.join('\n');
  }

  List<_AnswerReview> _answerReview() {
    return List.generate(_questions.length, (index) {
      final question = _questions[index];
      final answer = switch (question.type) {
        _QuestionType.single => _singleAnswers[index] ?? '',
        _QuestionType.multi => _multiAnswers.join(', '),
        _QuestionType.multiWithText => [
          if (_multiAnswers.isNotEmpty) _multiAnswers.join(', '),
          if (_firstTextController.text.trim().isNotEmpty)
            _firstTextController.text.trim(),
        ].join('; '),
        _QuestionType.openFirst => _firstTextController.text.trim(),
        _QuestionType.openSecond => _secondTextController.text.trim(),
        _QuestionType.openGoal => _goalController.text.trim(),
        _QuestionType.scale => '${_readiness.round()} out of 10',
      };

      return _AnswerReview(
        question: question.title,
        answer: answer.trim().isEmpty ? 'Not answered' : answer,
      );
    });
  }

  _GeneratedPlan _fallbackPlan() {
    final frequency = _singleAnswers[0] ?? 'your current rhythm';
    final symptoms = _multiAnswers.isEmpty
        ? 'your anxiety signs'
        : _multiAnswers.join(', ');
    final trigger = _singleAnswers[2] ?? 'your main trigger';

    return switch (widget.destination) {
      _PlanningDestination.cope => _GeneratedPlan(
        title: 'Your Cope Plan',
        intro:
            'Gwyn shaped this plan around $frequency anxiety, $symptoms, and $trigger.',
        sections: [
          const _PlanSection('When anxiety starts', [
            'Pause and name what is happening.',
            'Slow your exhale for one minute.',
          ]),
          _PlanSection('Body support', [
            if (_multiAnswers.contains('Tight chest') ||
                _multiAnswers.contains('Fast heartbeat'))
              'Put one hand on your chest and lengthen each out-breath.',
            if (_multiAnswers.contains('Stomach ache') ||
                _multiAnswers.contains('Nausea'))
              'Sip water and relax your belly for five breaths.',
            if (_multiAnswers.contains('Muscles tighten') ||
                _multiAnswers.contains('Twitches'))
              'Unclench your jaw, hands, and shoulders.',
            'Choose one grounding object nearby.',
          ]),
          _PlanSection('Trigger plan', [
            'When $trigger appears, lower the pressure first.',
            'Choose one small helpful action before reacting.',
          ]),
          const _PlanSection('Evening reset', [
            'Write one thing you handled today.',
            'Prepare one calming option for tomorrow.',
          ]),
        ],
      ),
      _PlanningDestination.understand => _GeneratedPlan(
        title: 'Your Understand Plan',
        intro:
            'Gwyn shaped this plan around what you feel, how often it happens, and when it arises.',
        sections: [
          const _PlanSection('Notice the pattern', [
            'Write down what happened just before anxiety appeared.',
            'Look for repeating moments, places, or thoughts.',
          ]),
          const _PlanSection('Name the need', [
            'Ask what your nervous system may be trying to protect.',
            'Separate the feeling from the facts of the situation.',
          ]),
          const _PlanSection('Daily reflection', [
            'What happened before anxiety appeared?',
            'What did my nervous system try to protect me from?',
          ]),
        ],
      ),
      _PlanningDestination.heal => _GeneratedPlan(
        title: 'Healing Roadmap',
        intro:
            'Healing starts by accepting that anxiety appears in a particular circumstance, then practicing an action that thwarts the fear.',
        sections: [
          _PlanSection('Understand first', [
            _singleAnswers[0] == 'Yes'
                ? 'Use your Understand plan as the map for healing.'
                : 'Healing can start, but first keep exploring what causes the anxiety.',
          ]),
          const _PlanSection('Choose the target moment', [
            'Pick one situation from your answers to practice with first.',
            'Keep the first practice small enough to repeat.',
          ]),
          const _PlanSection('Healing practice', [
            'Accept that anxiety appears in this circumstance.',
            'Plan one action that directly thwarts the fear.',
            'Visualize doing the action calmly.',
            'Practice in front of a mirror or with friends.',
            'Test it gently in the real world.',
          ]),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _isGeneratingPlan
              ? _PlanLoadingView(color: color)
              : _showResult
              ? _PlanResultView(
                  destination: widget.destination,
                  color: color,
                  plan: _generatedPlan,
                  answers: _answerReview(),
                )
              : _QuestionView(
                  key: ValueKey(_step),
                  question: _questions[_step],
                  step: _step,
                  totalSteps: _questions.length,
                  color: color,
                  firstChoice: _firstChoice,
                  secondChoice: _secondChoice,
                  selectedSingleAnswer: _singleAnswers[_step],
                  multiAnswers: _multiAnswers,
                  readiness: _readiness,
                  firstTextController: _firstTextController,
                  secondTextController: _secondTextController,
                  goalController: _goalController,
                  canContinue: _canContinue,
                  onSingleSelected: _selectSingle,
                  onMultiSelected: (value) {
                    setState(() {
                      if (!_multiAnswers.add(value)) {
                        _multiAnswers.remove(value);
                      }
                    });
                  },
                  onReadinessChanged: (value) {
                    setState(() => _readiness = value);
                  },
                  onTextChanged: () => setState(() {}),
                  onContinue: _continue,
                  onBack: _step > 0 ? _goBack : null,
                ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final _QuestionConfig question;
  final int step;
  final int totalSteps;
  final Color color;
  final String? firstChoice;
  final String? secondChoice;
  final String? selectedSingleAnswer;
  final Set<String> multiAnswers;
  final double readiness;
  final TextEditingController firstTextController;
  final TextEditingController secondTextController;
  final TextEditingController goalController;
  final bool canContinue;
  final ValueChanged<String> onSingleSelected;
  final ValueChanged<String> onMultiSelected;
  final ValueChanged<double> onReadinessChanged;
  final VoidCallback onTextChanged;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const _QuestionView({
    super.key,
    required this.question,
    required this.step,
    required this.totalSteps,
    required this.color,
    required this.firstChoice,
    required this.secondChoice,
    required this.selectedSingleAnswer,
    required this.multiAnswers,
    required this.readiness,
    required this.firstTextController,
    required this.secondTextController,
    required this.goalController,
    required this.canContinue,
    required this.onSingleSelected,
    required this.onMultiSelected,
    required this.onReadinessChanged,
    required this.onTextChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final questionNumber = step + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Question $questionNumber of $totalSteps',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          question.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (question.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            question.subtitle!,
            style: TextStyle(color: Colors.black.withAlpha(143), height: 1.35),
          ),
        ],
        const SizedBox(height: 22),
        ..._buildQuestionBody(context),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canContinue ? onContinue : null,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              step == totalSteps - 1 ? 'Create my plan' : 'Next',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (onBack != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildQuestionBody(BuildContext context) {
    return switch (question.type) {
      _QuestionType.single =>
        question.options
            .map(
              (option) => _ChoiceOption(
                label: option,
                color: color,
                selected:
                    (selectedSingleAnswer ??
                        (step == 0 ? firstChoice : secondChoice)) ==
                    option,
                onTap: () => onSingleSelected(option),
              ),
            )
            .toList(),
      _QuestionType.multi =>
        question.options
            .map(
              (option) => _ChoiceOption(
                label: option,
                color: color,
                selected: multiAnswers.contains(option),
                isMultiSelect: true,
                onTap: () => onMultiSelected(option),
              ),
            )
            .toList(),
      _QuestionType.multiWithText => [
        ...question.options.map(
          (option) => _ChoiceOption(
            label: option,
            color: color,
            selected: multiAnswers.contains(option),
            isMultiSelect: true,
            onTap: () => onMultiSelected(option),
          ),
        ),
        const SizedBox(height: 4),
        _OpenQuestionField(
          controller: firstTextController,
          hintText: 'Describe another situation',
          onChanged: onTextChanged,
        ),
      ],
      _QuestionType.openFirst => [
        _OpenQuestionField(
          controller: firstTextController,
          hintText: 'Write the situation here',
          onChanged: onTextChanged,
        ),
      ],
      _QuestionType.openSecond => [
        _OpenQuestionField(
          controller: secondTextController,
          hintText: 'Write what you fear might happen',
          onChanged: onTextChanged,
        ),
      ],
      _QuestionType.openGoal => [
        _OpenQuestionField(
          controller: goalController,
          hintText: 'Write your answer here',
          onChanged: onTextChanged,
        ),
      ],
      _QuestionType.scale => [
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                readiness.round().toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                value: readiness,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: color,
                label: readiness.round().toString(),
                onChanged: onReadinessChanged,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('1'), Text('10')],
              ),
            ],
          ),
        ),
      ],
    };
  }
}

class _PlanResultView extends StatelessWidget {
  final _PlanningDestination destination;
  final Color color;
  final _GeneratedPlan? plan;
  final List<_AnswerReview> answers;

  const _PlanResultView({
    required this.destination,
    required this.color,
    required this.plan,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        plan?.title ??
        switch (destination) {
          _PlanningDestination.cope => 'Your Cope Plan',
          _PlanningDestination.understand => 'Your Understand Plan',
          _PlanningDestination.heal => 'Healing Roadmap',
        };

    final sections =
        plan?.sections ??
        switch (destination) {
          _PlanningDestination.cope => const [
            _PlanSection('Morning', ['Breathing']),
            _PlanSection('Afternoon', ['Grounding exercise']),
            _PlanSection('Evening', ['Reflection']),
            _PlanSection('When panic appears', [
              'Loud music',
              'Distraction',
              'Breathing',
              'Grounding',
            ]),
          ],
          _PlanningDestination.understand => const [
            _PlanSection('Things to explore', ['Triggers', 'Body signals']),
            _PlanSection('Possible patterns', [
              'Timing',
              'Avoidance',
              'Thoughts',
            ]),
            _PlanSection('Daily reflection questions', [
              'What happened before anxiety appeared?',
              'What did my body try to protect me from?',
            ]),
            _PlanSection('Relevant articles', [
              'Body signals',
              'Anxiety patterns',
            ]),
            _PlanSection('Relevant exercises', [
              'Ask yourself',
              'Measurements',
            ]),
            _PlanSection('Journal prompts', [
              'What did I notice today?',
              'What felt familiar?',
            ]),
          ],
          _PlanningDestination.heal => const [
            _PlanSection('Week 1', ['Understanding']),
            _PlanSection('Week 2', ['Tiny exposure']),
            _PlanSection('Week 3', ['Reflection']),
            _PlanSection('Week 4', ['Slightly bigger challenge']),
            _PlanSection('Week 5', ['Review']),
          ],
        };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          plan?.intro ??
              (destination == _PlanningDestination.cope
                  ? 'Gwyn will change this plan every day as the planning system grows.'
                  : 'This is your first roadmap. Soon Gwyn will adapt it from your daily check-ins.'),
          style: TextStyle(
            height: 1.4,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : Colors.black.withAlpha(153),
          ),
        ),
        const SizedBox(height: 20),
        _AnswerReviewCard(answers: answers, color: color),
        const SizedBox(height: 20),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PlanSectionCard(section: section, color: color),
          ),
        ),
        const SizedBox(height: 6),
        _PlanSectionCard(
          section: const _PlanSection('Next, what to do with the plan?', [
            'Choose the first action you can do today.',
            'Keep it small enough to repeat.',
            'Come back to the plan after trying it once.',
          ]),
          color: color,
        ),
      ],
    );
  }
}

class _AnswerReviewCard extends StatelessWidget {
  final List<_AnswerReview> answers;
  final Color color;

  const _AnswerReviewCard({required this.answers, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your answers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...answers.map(
            (answer) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answer.question,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    answer.answer,
                    style: TextStyle(
                      height: 1.35,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLoadingView extends StatelessWidget {
  final Color color;

  const _PlanLoadingView({required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(color: color, strokeWidth: 4),
            ),
            const SizedBox(height: 22),
            Image.asset(
              'assets/images/gwyn-plan.png',
              width: 116,
              height: 116,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              'Gwyn is creating your plan...',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'She is reading your answers and shaping the next steps.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.35,
                color: isDark ? Colors.white60 : Colors.black.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final IconData? icon;
  final String? imageIconPath;
  final String title;
  final List<String> lines;
  final Color color;
  final VoidCallback onTap;

  const _DestinationCard({
    this.icon,
    this.imageIconPath,
    required this.title,
    required this.lines,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = this.icon;
    final imageIconPath = this.imageIconPath;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: imageIconPath != null
                  ? ImageIcon(AssetImage(imageIconPath), color: color, size: 30)
                  : Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: isDark
                              ? Colors.white60
                              : Colors.black.withAlpha(153),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : Colors.black.withAlpha(77),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool isMultiSelect;
  final VoidCallback onTap;

  const _ChoiceOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.isMultiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isMultiSelect
                    ? selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded
                    : selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? color
                    : isDark
                    ? Colors.white38
                    : Colors.black38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenQuestionField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onChanged;

  const _OpenQuestionField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        minLines: 4,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
      ),
    );
  }
}

class _PlanSectionCard extends StatelessWidget {
  final _PlanSection section;
  final Color color;

  const _PlanSectionCard({required this.section, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSection {
  final String title;
  final List<String> items;

  const _PlanSection(this.title, this.items);
}

class _AnswerReview {
  final String question;
  final String answer;

  const _AnswerReview({required this.question, required this.answer});
}

class _GeneratedPlan {
  final String title;
  final String intro;
  final List<_PlanSection> sections;

  const _GeneratedPlan({
    required this.title,
    required this.intro,
    required this.sections,
  });

  static _GeneratedPlan? tryParse(String text) {
    try {
      final cleaned = text
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      final sectionsJson = decoded['sections'] as List<dynamic>;
      final sections = sectionsJson
          .map((section) {
            final sectionMap = Map<String, dynamic>.from(section as Map);
            final items = (sectionMap['items'] as List<dynamic>)
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toList();
            return _PlanSection('${sectionMap['title']}'.trim(), items);
          })
          .where(
            (section) => section.title.isNotEmpty && section.items.isNotEmpty,
          )
          .toList();

      if (sections.isEmpty) return null;

      return _GeneratedPlan(
        title: '${decoded['title'] ?? 'Your Plan'}'.trim(),
        intro: '${decoded['intro'] ?? ''}'.trim(),
        sections: sections,
      );
    } catch (_) {
      return null;
    }
  }
}

enum _QuestionType {
  single,
  multi,
  multiWithText,
  openFirst,
  openSecond,
  openGoal,
  scale,
}

class _QuestionConfig {
  final String title;
  final String? subtitle;
  final _QuestionType type;
  final List<String> options;

  const _QuestionConfig({
    required this.title,
    required this.type,
    this.subtitle,
    this.options = const [],
  });
}
