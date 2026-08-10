import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../affirmations/presentation/affirmations_screen.dart';
import '../../grounding/presentation/grounding_screen.dart';
import '../../meditations/presentation/meditations_screen.dart';
import '../../profile/presentation/my_plans_screen.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../sanctuary/presentation/anxiety_persona_screen.dart';
import '../../sanctuary/presentation/leaf_exercise_screen.dart';
import '../../sanctuary/presentation/my_truth_editor.dart';
import 'heal_daily_plan_table.dart';
import 'understand_daily_plan_table.dart';

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

class UnderstandPlanningScreen extends StatelessWidget {
  const UnderstandPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlanningFlowScreen(
      destination: _PlanningDestination.understand,
    );
  }
}

class CopePlanningScreen extends StatelessWidget {
  const CopePlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlanningFlowScreen(destination: _PlanningDestination.cope);
  }
}

class HealPlanningScreen extends StatelessWidget {
  const HealPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlanningFlowScreen(destination: _PlanningDestination.heal);
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
    _PlanningDestination.cope => 'Cope Planning',
    _PlanningDestination.understand => 'Understand Planning',
    _PlanningDestination.heal => 'Heal Planning',
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
          'Multiple times a day',
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
        title:
            'Have you made an Understand plan yet? If yes, write the insights from it.',
        subtitle:
            'An Understand plan is helpful, but you can still start healing if you do not have one yet.',
        hintText:
            'Write the main cause, trigger, thought-feeling links, and certainty level you discovered.',
        type: _QuestionType.singleWithText,
        options: ['Yes', 'No'],
      ),
      const _QuestionConfig(
        title: "Is there something you've been struggling to accept?",
        subtitle:
            'Name what feels difficult to accept right now, without judging yourself for it.',
        type: _QuestionType.openFirst,
        hintText: 'Write what you are working to accept.',
      ),
      const _QuestionConfig(
        title:
            'Is there someone you can forgive now, or someone you feel ready to ask for forgiveness?',
        subtitle:
            'This can include forgiving yourself. Share only what feels safe and useful.',
        type: _QuestionType.openGoal,
        hintText:
            'Write who comes to mind and what forgiveness could mean for you.',
      ),
    ],
  };

  bool get _canContinue {
    final question = _questions[_step];

    if (widget.destination == _PlanningDestination.cope &&
        _step == 3 &&
        question.type == _QuestionType.openGoal) {
      return true;
    }

    return switch (question.type) {
      _QuestionType.single => _singleAnswers[_step] != null,
      _QuestionType.singleWithText =>
        _singleAnswers[_step] != null &&
            (_singleAnswers[_step] != 'Yes' ||
                _secondTextController.text.trim().isNotEmpty),
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

    final generatedPlan = _fallbackPlan();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await _completePlanGeneration(generatedPlan);
  }

  Future<void> _completePlanGeneration(_GeneratedPlan generatedPlan) async {
    final appState = context.read<AppState>();
    switch (widget.destination) {
      case _PlanningDestination.cope:
        await appState.saveCopePlan(name: appState.nextCopePlanName);
        final reminders = NotificationService.instance
            .copePlanReminderSchedules(
              frequency: _singleAnswers[0] ?? 'Daily',
              feelings: _multiAnswers.toList(),
              trigger: _singleAnswers[2] ?? '',
              additionalInfo: _goalController.text,
            );
        await NotificationService.instance.savePlanReminderSchedules(
          'cope',
          reminders,
        );
        break;
      case _PlanningDestination.understand:
        await appState.saveUnderstandPlan(
          name: appState.nextUnderstandPlanName,
          feeling: _firstTextController.text,
        );
        await NotificationService.instance.savePlanReminderSchedules(
          'understand',
          NotificationService.instance.defaultPlanReminderSchedules(
            'understand',
          ),
        );
        break;
      case _PlanningDestination.heal:
        await appState.saveHealPlan(name: appState.nextHealPlanName);
        await NotificationService.instance.savePlanReminderSchedules(
          'heal',
          NotificationService.instance.defaultPlanReminderSchedules('heal'),
        );
        break;
    }
    if (!mounted) return;

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

  List<_AnswerReview> _answerReview() {
    return List.generate(_questions.length, (index) {
      final question = _questions[index];
      final answer = switch (question.type) {
        _QuestionType.single => _singleAnswers[index] ?? '',
        _QuestionType.singleWithText => [
          _singleAnswers[index] ?? '',
          if (_secondTextController.text.trim().isNotEmpty)
            _secondTextController.text.trim(),
        ].where((answer) => answer.isNotEmpty).join('; '),
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
          _PlanSection('Step 2: Practice acceptance', [
            'What you are working to accept: ${_firstTextController.text.trim()}',
            'Let the feeling be present without judging or fighting it.',
            'Write one gentle truth that makes acceptance feel safer.',
          ]),
          _PlanSection('Step 3: Practice forgiveness', [
            'Your forgiveness focus: ${_goalController.text.trim()}',
            'Choose one small step toward forgiving or asking for forgiveness.',
            'Include self-forgiveness wherever it is needed.',
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
      _QuestionType.singleWithText => [
        if (question.options.isNotEmpty)
          _ChoiceOption(
            label: question.options.first,
            color: color,
            selected:
                (selectedSingleAnswer ??
                    (step == 0 ? firstChoice : secondChoice)) ==
                question.options.first,
            onTap: () => onSingleSelected(question.options.first),
          ),
        _OpenQuestionField(
          controller: secondTextController,
          hintText: question.hintText ?? 'Write your insights here',
          onChanged: onTextChanged,
        ),
        const SizedBox(height: 12),
        ...question.options
            .skip(1)
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
            ),
      ],
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
    if (destination == _PlanningDestination.cope) {
      return _CopePlanResultView(
        color: color,
        answers: answers,
        plan: plan,
        onChangeAnswers: onChangeAnswers,
      );
    }

    if (destination == _PlanningDestination.understand) {
      return _UnderstandPlanResultView(
        color: color,
        answers: answers,
        plan: plan,
        onChangeAnswers: onChangeAnswers,
      );
    }

    if (destination == _PlanningDestination.heal) {
      return _HealPlanResultView(
        color: color,
        answers: answers,
        plan: plan,
        onChangeAnswers: onChangeAnswers,
      );
    }

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
        _PlanningResultTable(
          destination: destination,
          sections: sections,
          color: color,
        ),
        const SizedBox(height: 20),
        _PlanActionButtons(color: color),
      ],
    );
  }
}

class _CopePlanResultView extends StatelessWidget {
  final Color color;
  final List<_AnswerReview> answers;
  final _GeneratedPlan? plan;
  final VoidCallback onChangeAnswers;

  const _CopePlanResultView({
    required this.color,
    required this.answers,
    required this.plan,
    required this.onChangeAnswers,
  });

  String get _frequency => answers.isEmpty ? '' : answers.first.answer;

  int get _reminderCount => switch (_frequency.toLowerCase()) {
    'multiple times a day' || 'multiple times every day' => 6,
    'daily' || 'several times a week' => 3,
    'occasionally' => 1,
    _ => 1,
  };

  void _openTool(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black54;
    final headerColor = Theme.of(context).brightness == Brightness.dark
        ? color.withAlpha(65)
        : const Color(0xFFDCE8C4);

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
                      'Your Cope plan',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan?.intro ??
                          'Gwyn read your answers and shaped a solid plan for you',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
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
                width: 100,
                height: 112,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 8,
          border: Border.all(color: borderColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CopePlanMessageRow(
                text:
                    'Coping with anxiety is all about reminding yourself that you are safe',
              ),
              Divider(height: 1, thickness: 1, color: borderColor),
              _CopePlanMessageRow(
                text: 'Gwyn has created $_reminderCount reminders for you',
                linkText: '(click to open)',
                onLinkTap: () => _openTool(context, const RemindersScreen()),
              ),
              Divider(height: 1, thickness: 1, color: borderColor),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.65),
                  1: FlexColumnWidth(1),
                },
                border: TableBorder(
                  verticalInside: BorderSide(color: borderColor),
                  horizontalInside: BorderSide(color: borderColor),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: headerColor),
                    children: const [
                      _CopePlanHeaderCell('Planned Activities'),
                      _CopePlanHeaderCell('Methods', centered: true),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _CopePlanActivityCell(
                        'Write down your truth in this app and on a piece of paper and always carry it around',
                      ),
                      _CopePlanMethodCell(
                        label: 'My Truth',
                        icon: Icons.fact_check_rounded,
                        color: Colors.green.shade600,
                        onTap: () => showMyTruthEditor(
                          context,
                          context.read<AppState>(),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _CopePlanActivityCell(
                        'Give your anxious thoughts a face and a name so you can separate them from yourself',
                      ),
                      _CopePlanMethodCell(
                        label: 'Create persona',
                        icon: Icons.theater_comedy_rounded,
                        color: Colors.amber.shade700,
                        onTap: () => _openTool(
                          context,
                          AnxietyPersonaScreen(
                            appState: context.read<AppState>(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _CopePlanActivityCell(
                        'In the morning start with affirmations to shape a positive mindset for the day',
                      ),
                      _CopePlanMethodCell(
                        label: 'Affirmations',
                        icon: Icons.record_voice_over_rounded,
                        color: Colors.blue.shade500,
                        onTap: () =>
                            _openTool(context, const AffirmationsScreen()),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _CopePlanActivityCell(
                        'Around noon do a grounding exercise to reduce stress',
                      ),
                      _CopePlanMethodCell(
                        label: 'Grounding',
                        icon: Icons.filter_center_focus_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        onTap: () => _openTool(
                          context,
                          GroundingScreen(appState: context.read<AppState>()),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _CopePlanActivityCell(
                        'In the evening do a meditation when there is time to relax',
                      ),
                      _CopePlanMethodCell(
                        label: 'Meditations',
                        icon: Icons.self_improvement_rounded,
                        color: Colors.indigo.shade400,
                        onTap: () =>
                            _openTool(context, const MeditationsScreen()),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _CopePlanActivityCell(
                        'Throughout the day, distract your mind whenever anxiety rises',
                      ),
                      _CopePlanMethodCell(
                        label: 'Leaf Exercise',
                        icon: Icons.eco_rounded,
                        color: Colors.green.shade600,
                        onTap: () =>
                            _openTool(context, const LeafExerciseScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _PlanActionButtons(color: color),
      ],
    );
  }
}

class _UnderstandPlanResultView extends StatelessWidget {
  final Color color;
  final List<_AnswerReview> answers;
  final _GeneratedPlan? plan;
  final VoidCallback onChangeAnswers;

  const _UnderstandPlanResultView({
    required this.color,
    required this.answers,
    required this.plan,
    required this.onChangeAnswers,
  });

  String get _firstAnswer =>
      answers.isEmpty ? 'what you feel' : answers.first.answer.toLowerCase();

  @override
  Widget build(BuildContext context) {
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
                      'Your Understand plan',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan?.intro ??
                          'Gwyn read your answers and shaped a plan to help you understand your anxiety',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
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
                width: 100,
                height: 112,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        UnderstandDailyPlanTable(color: color, feeling: _firstAnswer),
        const SizedBox(height: 32),
        _PlanActionButtons(color: color),
      ],
    );
  }
}

class _HealPlanResultView extends StatelessWidget {
  final Color color;
  final List<_AnswerReview> answers;
  final _GeneratedPlan? plan;
  final VoidCallback onChangeAnswers;

  const _HealPlanResultView({
    required this.color,
    required this.answers,
    required this.plan,
    required this.onChangeAnswers,
  });

  @override
  Widget build(BuildContext context) {
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
                      'Your Heal plan',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan?.intro ??
                          'Gwyn read your answers and shaped a plan to support your healing',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
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
                width: 100,
                height: 112,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        HealDailyPlanTable(color: color),
        const SizedBox(height: 32),
        _PlanActionButtons(color: color),
      ],
    );
  }
}

class _PlanMethodIconCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PlanMethodIconCell({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 25),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CopePlanMessageRow extends StatelessWidget {
  final String text;
  final String? linkText;
  final VoidCallback? onLinkTap;

  const _CopePlanMessageRow({
    required this.text,
    this.linkText,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Wrap(
        spacing: 5,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: textStyle),
          if (linkText != null)
            InkWell(
              onTap: onLinkTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  linkText!,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CopePlanHeaderCell extends StatelessWidget {
  final String text;
  final bool centered;

  const _CopePlanHeaderCell(this.text, {this.centered = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CopePlanActivityCell extends StatelessWidget {
  final String text;

  const _CopePlanActivityCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
    );
  }
}

class _CopePlanMethodCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CopePlanMethodCell({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanActionButtons extends StatelessWidget {
  final Color color;

  const _PlanActionButtons({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyPlansScreen()),
          );
        },
        icon: const Icon(Icons.route_rounded),
        label: const Text('My Plans'),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
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
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _PlanningResultTable extends StatefulWidget {
  final _PlanningDestination destination;
  final List<_PlanSection> sections;
  final Color color;

  const _PlanningResultTable({
    required this.destination,
    required this.sections,
    required this.color,
  });

  @override
  State<_PlanningResultTable> createState() => _PlanningResultTableState();
}

class _PlanningResultTableState extends State<_PlanningResultTable> {
  static const _times = ['Morning', 'Noon', 'Evening'];

  List<DailyReminderSchedule> _reminders = const [];
  bool _isLoadingReminders = true;

  String get _planType => widget.destination.name;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await NotificationService.instance
        .loadPlanReminderSchedules(_planType);
    if (!mounted) return;

    setState(() {
      _reminders = reminders;
      _isLoadingReminders = false;
    });

    for (final entry in reminders.indexed.where(
      (entry) => entry.$2.isEnabled,
    )) {
      await NotificationService.instance.schedulePlanReminder(
        entry.$2,
        position: entry.$1,
      );
    }
  }

  Future<void> _toggleReminder(int index) async {
    if (_isLoadingReminders || index >= _reminders.length) return;

    final current = _reminders[index];
    final updated = DailyReminderSchedule(
      id: current.id,
      title: current.title,
      body: current.body,
      hour: current.hour,
      minute: current.minute,
      isEnabled: !current.isEnabled,
      frequency: current.frequency,
    );
    final reminders = [..._reminders]..[index] = updated;
    setState(() => _reminders = reminders);

    await NotificationService.instance.savePlanReminderSchedules(
      _planType,
      reminders,
    );
    if (updated.isEnabled) {
      await NotificationService.instance.schedulePlanReminder(
        updated,
        position: index,
      );
    } else {
      await NotificationService.instance.cancelReminder(updated.id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.isEnabled ? 'Reminder added' : 'Reminder removed',
        ),
      ),
    );
  }

  List<_PlanSection> _dailySections() {
    final groups = List.generate(3, (_) => <_PlanSection>[]);
    for (var index = 0; index < widget.sections.length; index++) {
      final groupIndex = index < 2 ? index : 2;
      groups[groupIndex].add(widget.sections[index]);
    }

    return List.generate(3, (index) {
      final group = groups[index];
      if (group.isEmpty) {
        return const _PlanSection('Plan check-in', [
          'Review your plan and choose one small action.',
        ]);
      }
      return _PlanSection(
        group.map((section) => section.title).join(' + '),
        group.expand((section) => section.items).toList(),
      );
    });
  }

  Widget _copeReminderTable(Color color) {
    final frequency = _reminders.isEmpty ? '—' : _reminders.first.frequency;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(1.4), 1: FlexColumnWidth(1)},
          border: TableBorder(
            horizontalInside: BorderSide(color: color.withAlpha(42)),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: color.withAlpha(24)),
              children: const [
                _PlanningResultHeaderCell('frequency'),
                _PlanningResultHeaderCell('Type'),
              ],
            ),
            TableRow(
              children: [
                _PlanningResultCell(
                  child: Text(
                    frequency,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _PlanningResultCell(
                  child: Text(
                    'Reminder',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _dailySections();
    final color = widget.color;
    if (widget.destination == _PlanningDestination.cope) {
      return _copeReminderTable(color);
    }
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(0.8),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(2),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: color.withAlpha(42)),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: color.withAlpha(24)),
              children: const [
                _PlanningResultHeaderCell('Time'),
                _PlanningResultHeaderCell('Focus'),
                _PlanningResultHeaderCell('What to do'),
              ],
            ),
            ...sections.indexed.map(
              (entry) => TableRow(
                children: [
                  _PlanningResultCell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _times[entry.$1],
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (entry.$1 < _reminders.length) ...[
                          const SizedBox(height: 3),
                          Text(
                            _reminders[entry.$1].frequency,
                            style: TextStyle(
                              color: color.withAlpha(190),
                              fontSize: 10,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        IconButton(
                          tooltip:
                              entry.$1 < _reminders.length &&
                                  _reminders[entry.$1].isEnabled
                              ? 'Remove reminder'
                              : 'Add reminder',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: _isLoadingReminders
                              ? null
                              : () => _toggleReminder(entry.$1),
                          icon: Icon(
                            entry.$1 < _reminders.length &&
                                    _reminders[entry.$1].isEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notification_add_outlined,
                            color:
                                entry.$1 < _reminders.length &&
                                    _reminders[entry.$1].isEnabled
                                ? color
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PlanningResultCell(
                    child: Text(
                      widget.destination == _PlanningDestination.cope &&
                              entry.$1 < _reminders.length
                          ? _reminders[entry.$1].title
                          : entry.$2.title,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _PlanningResultCell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          (widget.destination == _PlanningDestination.cope &&
                                      entry.$1 < _reminders.length
                                  ? [_reminders[entry.$1].body]
                                  : entry.$2.items)
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '• $item',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningResultHeaderCell extends StatelessWidget {
  final String label;

  const _PlanningResultHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PlanningResultCell extends StatelessWidget {
  final Widget child;

  const _PlanningResultCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: child,
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
}

enum _QuestionType {
  single,
  singleWithText,
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
