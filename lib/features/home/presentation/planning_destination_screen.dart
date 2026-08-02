import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../profile/presentation/my_plans_screen.dart';
import 'cope_daily_plan_table.dart';

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
            Image.asset(
              'assets/images/gwyn-plan.png',
              height: 128,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(
              'To create your plan, please tell Gwyn what you want to achieve',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: mutedText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
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
                'I want to discover and understand why I feel anxious.',
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
              color: primaryColor,
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
    _PlanningDestination.cope => 'Cope Planning Result',
    _PlanningDestination.understand => 'Understand Planning Result',
    _PlanningDestination.heal => 'Heal Planning Result',
  };

  Color _color(BuildContext context) => switch (widget.destination) {
    _PlanningDestination.cope => Theme.of(context).primaryColor,
    _PlanningDestination.understand => Colors.amber.shade700,
    _PlanningDestination.heal => Theme.of(context).primaryColor,
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
        title: 'When anxiety appears, what do you feel?',
        subtitle: 'Select all that apply.',
        type: _QuestionType.multi,
        options: [
          'Racing thoughts',
          'Panic attack',
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
          'Finances',
          'Relationships',
          'Driving',
          'Crowds',
          'Unknown',
        ],
      ),
      const _QuestionConfig(
        title: 'Additional info Gwyn could use in her plan',
        type: _QuestionType.openGoal,
      ),
    ],
    _PlanningDestination.understand => [
      const _QuestionConfig(
        title: 'Write down what you feel.',
        subtitle:
            'Use your own words. Name the thought, feeling, and body signal as clearly as you can.',
        type: _QuestionType.openFirst,
        hintText:
            'Example: When I think I might fail, I feel fear in my chest.',
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
        hintText:
            'Example: It arises before meetings, especially when I imagine being judged.',
      ),
      const _QuestionConfig(
        title: 'What patterns have you noticed?',
        subtitle:
            'Look for links, such as one thought causing one feeling, or one situation causing one body signal.',
        type: _QuestionType.openGoal,
        hintText:
            'Example: The thought "I am trapped" often brings panic and tight shoulders.',
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
        title: 'Write the insights from your Understand plan.',
        subtitle:
            'Put your main cause, trigger, thought-feeling links, and certainty level here.',
        type: _QuestionType.openSecond,
        hintText:
            'Example: I think my anxiety starts when I feel judged. Certainty: 7/10.',
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
          'Finances',
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
      const _QuestionConfig(
        title: 'Additional info Gwyn could use in her plan',
        type: _QuestionType.openGoal,
        hintText:
            'Write what you want to be able to do when the anxious thought appears.',
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
    final skipGeminiForFreeCopePlan =
        widget.destination == _PlanningDestination.cope &&
        !context.read<AppState>().hasActiveSubscription;

    if (skipGeminiForFreeCopePlan) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      await _completePlanGeneration(fallbackPlan);
      return;
    }

    try {
      final results = await Future.wait([
        Future<void>.delayed(const Duration(seconds: 2)),
        GeminiService.instance.generateGwenResponse(_planPrompt()),
      ]);
      final aiText = results[1] as String;
      final generatedPlan = _GeneratedPlan.tryParse(aiText) ?? fallbackPlan;
      if (!mounted) return;

      await _completePlanGeneration(generatedPlan);
    } catch (error) {
      debugPrint('Gwyn plan generation fallback: $error');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      await _completePlanGeneration(fallbackPlan);
    }
  }

  Future<void> _completePlanGeneration(_GeneratedPlan generatedPlan) async {
    if (widget.destination == _PlanningDestination.cope) {
      final appState = context.read<AppState>();
      await appState.saveCopePlan(name: appState.nextCopePlanName);
      if (!mounted) return;
    }

    setState(() {
      _generatedPlan = generatedPlan;
      _isGeneratingPlan = false;
      _showResult = true;
    });
  }

  void _changeAnswers() {
    if (_isGeneratingPlan) return;

    setState(() {
      _showResult = false;
      _isGeneratingPlan = false;
      _step = _questions.length - 1;
    });
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
- Respond kindly to the answers the user gave before suggesting actions.
- Use 4 to 6 sections.
- Each item must be short enough for a mobile screen.
- Mention professional or emergency help only if the answers sound severe.
- For Cope plans, explain that coping means calming a panicking mind in the moment, not solving everything. Include affirmations such as "Everything will be fine" and "I will survive this", simple breathing, the leaf exercise, music, and setting reminders.
- For Understand plans, focus on journaling, finding patterns, linking specific thoughts to specific feelings or body signals, and meditations that help the user listen inward.
- For Understand plans, the result should lead toward this insight: "Aha, now I know what causes my anxiety."
- For Heal plans, use the insights from the Understand plan as the starting point.
- For Heal plans, include journaling, meditations, acceptance, forgiveness, letting go, visualization, practice with a mirror or friends, one action that thwarts the fear, and a gentle real-world test.
- For Heal plans, aim to heal the anxiety response altogether when that specific thought arises.
- For Heal plans, use at least four clear steps.
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
    final trigger = _singleAnswers[2] ?? 'your main trigger';

    return switch (widget.destination) {
      _PlanningDestination.cope => _GeneratedPlan(
        title: 'Your Cope plan',
        intro: 'Gwyn read your answers and shaped a solid plan for you',
        sections: [
          const _PlanSection('What it means to cope', [
            'Relax your panicking mind first.',
            'You do not have to solve everything in this moment.',
            'Calm your nervous system enough to take the next small step.',
          ]),
          const _PlanSection('Affirmations', [
            'Everything will be fine.',
            'I will survive this.',
            'This feeling is intense, but it will pass.',
          ]),
          const _PlanSection('Simple breathing', [
            'Breathe in gently for four counts.',
            'Breathe out slowly for six counts.',
            'Repeat for one minute before choosing what to do next.',
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
            'Use the leaf exercise when thoughts keep looping.',
            'Play calming or upbeat music to redirect your attention.',
          ]),
          const _PlanSection('Reminders', [
            'Set a reminder to breathe before stressful moments.',
            'Set a reminder for one calming exercise each day.',
            'Keep one affirmation visible where you will see it.',
          ]),
        ],
      ),
      _PlanningDestination.understand => _GeneratedPlan(
        title: 'Your Understand Plan',
        intro:
            'This plan is designed to help you reach the moment: aha, now I know what causes my anxiety.',
        sections: [
          const _PlanSection('Journal the raw moment', [
            'Write the anxious thought in one sentence.',
            'Write the exact feeling that followed it.',
            'Add the body signal: chest, stomach, throat, head, or muscles.',
          ]),
          const _PlanSection('Find the thought-feeling link', [
            'Look for a pattern such as: when I think this, I feel that.',
            'Circle thoughts that repeat across different situations.',
            'Notice which thought makes anxiety stronger.',
          ]),
          const _PlanSection('Meditate on the clue', [
            'Sit quietly and replay one anxious moment gently.',
            'Ask: what was I afraid this thought meant?',
            'Let the answer arrive without forcing it.',
          ]),
          const _PlanSection('Pattern review', [
            'Compare your notes every few days.',
            'Name the likely cause in plain language.',
            'Update your certainty level when the same link repeats.',
          ]),
          const _PlanSection('Result', [
            'Write: aha, now I know what causes my anxiety.',
            'Keep refining the cause until it feels specific and true.',
          ]),
        ],
      ),
      _PlanningDestination.heal => _GeneratedPlan(
        title: 'Healing Roadmap',
        intro:
            'Use your Understand insight as the map, then practice until that thought no longer creates anxiety.',
        sections: [
          _PlanSection('Step 1: Understand first', [
            _singleAnswers[0] == 'Yes'
                ? 'Use your Understand plan as the map for healing.'
                : 'Keep exploring the cause while you start gently.',
            if (_secondTextController.text.trim().isNotEmpty)
              'Your current insight: ${_secondTextController.text.trim()}',
          ]),
          const _PlanSection('Step 2: Journal the healing pattern', [
            'Write the anxious thought at the top of the page.',
            'Write the feeling it creates underneath.',
            'Write a kinder, truer response beside it.',
          ]),
          const _PlanSection('Step 3: Acceptance and forgiveness', [
            'Accept that anxiety is present without fighting the sensation.',
            'Forgive yourself for needing time to heal.',
            'Let go of the old protective story one small piece at a time.',
          ]),
          const _PlanSection('Step 4: Meditation and visualization', [
            'Meditate on the thought while staying soft in the body.',
            'Visualize meeting the thought without obeying it.',
            'Imagine yourself responding calmly and freely.',
          ]),
          const _PlanSection('Step 5: Real-world practice', [
            'Choose one small action that proves the fear wrong.',
            'Practice in a mirror or with a trusted person.',
            'Try a gentle real-world test and journal what changed.',
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
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Home',
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
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
                  onChangeAnswers: _changeAnswers,
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
          hintText: question.hintText ?? 'Write the situation here',
          onChanged: onTextChanged,
        ),
      ],
      _QuestionType.openSecond => [
        _OpenQuestionField(
          controller: secondTextController,
          hintText: question.hintText ?? 'Write what you fear might happen',
          onChanged: onTextChanged,
        ),
      ],
      _QuestionType.openGoal => [
        _OpenQuestionField(
          controller: goalController,
          hintText: question.hintText ?? 'Write your answer here',
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
  final VoidCallback onChangeAnswers;

  const _PlanResultView({
    required this.destination,
    required this.color,
    required this.plan,
    required this.answers,
    required this.onChangeAnswers,
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
            _PlanSection('What it means to cope', [
              'Relax your panicking mind first.',
              'You do not have to solve everything right now.',
            ]),
            _PlanSection('Affirmations', [
              'Everything will be fine.',
              'I will survive this.',
            ]),
            _PlanSection('Calming exercises', [
              'Simple breathing',
              'Leaf exercise',
              'Music',
            ]),
            _PlanSection('Reminders', [
              'Set a reminder to breathe.',
              'Set a reminder to practice one calming exercise.',
            ]),
          ],
          _PlanningDestination.understand => const [
            _PlanSection('Journal the raw moment', [
              'Write the anxious thought in one sentence.',
              'Write the feeling and body signal that followed.',
            ]),
            _PlanSection('Find the pattern', [
              'Link a thought to a specific feeling.',
              'Look for the same link across several days.',
            ]),
            _PlanSection('Meditate on the clue', [
              'Sit quietly with one anxious moment.',
              'Ask what your mind was trying to protect.',
            ]),
            _PlanSection('Result', ['Aha, now I know what causes my anxiety.']),
          ],
          _PlanningDestination.heal => const [
            _PlanSection('Step 1: Use the insight', [
              'Start with what you learned in Understand.',
            ]),
            _PlanSection('Step 2: Journal the new response', [
              'Write the anxious thought and a kinder truth.',
            ]),
            _PlanSection('Step 3: Accept, forgive, let go', [
              'Accept the sensation, forgive yourself, and release the old story.',
            ]),
            _PlanSection('Step 4: Practice freedom', [
              'Meditate, visualize, and take one small action when the thought arises.',
            ]),
          ],
        };

    final isCopePlan = destination == _PlanningDestination.cope;
    final showRoadmap =
        destination == _PlanningDestination.understand ||
        destination == _PlanningDestination.heal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _AnswerReviewCard(
          answers: answers,
          color: color,
          onChangeAnswers: onChangeAnswers,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: showRoadmap ? 21 : 24,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan?.intro ??
                          (destination == _PlanningDestination.cope
                              ? 'Gwyn will change this plan every day as the planning system grows.'
                              : 'This is your first roadmap. Soon Gwyn will adapt it from your daily check-ins.'),
                      style: TextStyle(
                        fontSize: showRoadmap ? 13 : null,
                        height: 1.35,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.black.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/images/gwyn-plan-done.png',
                width: 86,
                height: 86,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isCopePlan) ...[
          _DailyCopePlanHeader(
            color: color,
            planName: context.watch<AppState>().copePlanName,
          ),
          const SizedBox(height: 12),
          CopeDailyPlanTable(color: color),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPlansScreen()),
                );
              },
              icon: const Icon(Icons.route_rounded),
              label: const Text('Your plans'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ] else if (destination == _PlanningDestination.understand ||
            destination == _PlanningDestination.heal) ...[
          if (destination == _PlanningDestination.understand) ...[
            _CertaintyLevelIndicator(
              color: color,
              value: _certaintyFromAnswers(answers),
            ),
            const SizedBox(height: 14),
          ],
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanSectionCard(
                section: section,
                color: color,
                compact: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PlanActionButtons(color: color),
        ] else ...[
          Transform.translate(
            offset: const Offset(-4, 0),
            child: Column(
              children: [
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlanSectionCard(section: section, color: color),
                  ),
                ),
                const SizedBox(height: 6),
                _PlanSectionCard(
                  section:
                      const _PlanSection('Next, what to do with the plan?', [
                        'Choose the first action you can do today.',
                        'Keep it small enough to repeat.',
                        'Come back to the plan after trying it once.',
                      ]),
                  color: color,
                ),
                const SizedBox(height: 20),
                _PlanActionButtons(color: color),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _certaintyFromAnswers(List<_AnswerReview> answers) {
    final answered = answers
        .where(
          (answer) =>
              answer.answer.trim().isNotEmpty &&
              answer.answer.trim() != 'Not answered',
        )
        .length;
    final base = answers.isEmpty ? 0.45 : answered / answers.length;
    return (0.35 + (base * 0.5)).clamp(0.35, 0.85);
  }
}

class _DailyCopePlanHeader extends StatelessWidget {
  final Color color;
  final String planName;

  const _DailyCopePlanHeader({required this.color, required this.planName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Daily activities',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _editPlanName(context),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(
                  planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPlanName(BuildContext context) async {
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) => _PlanNameDialog(initialName: planName),
    );

    if (nextName == null || !context.mounted) return;
    await context.read<AppState>().setCopePlanName(nextName);
  }
}

class _PlanNameDialog extends StatefulWidget {
  final String initialName;

  const _PlanNameDialog({required this.initialName});

  @override
  State<_PlanNameDialog> createState() => _PlanNameDialogState();
}

class _PlanNameDialogState extends State<_PlanNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Plan name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'cope plan1'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PlanActionButtons extends StatelessWidget {
  final Color color;

  const _PlanActionButtons({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your plan is ready. Start with the first step.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start plan'),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withAlpha(120)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerReviewCard extends StatelessWidget {
  final List<_AnswerReview> answers;
  final Color color;
  final VoidCallback onChangeAnswers;

  const _AnswerReviewCard({
    required this.answers,
    required this.color,
    required this.onChangeAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your answers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: onChangeAnswers,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Change answers'),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
  final bool compact;

  const _PlanSectionCard({
    required this.section,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          ...section.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: compact ? 6 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_rounded,
                    color: color,
                    size: compact ? 17 : 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: compact ? 13 : 14,
                        height: 1.32,
                      ),
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

class _CertaintyLevelIndicator extends StatelessWidget {
  final Color color;
  final double value;

  const _CertaintyLevelIndicator({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    final label = value >= 0.75
        ? 'Strong'
        : value >= 0.55
        ? 'Growing'
        : 'Early clue';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: color, size: 19),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Certainty level',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withAlpha(35),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$label: raise this when the same thought-feeling link repeats.',
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: isDark ? Colors.white60 : Colors.black.withAlpha(153),
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
  final String? hintText;
  final _QuestionType type;
  final List<String> options;

  const _QuestionConfig({
    required this.title,
    required this.type,
    this.subtitle,
    this.hintText,
    this.options = const [],
  });
}
