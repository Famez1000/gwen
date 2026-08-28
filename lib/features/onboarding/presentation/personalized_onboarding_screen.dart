import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../subscription/presentation/subscription_screen.dart';
import '../../subscription/presentation/onboarding_paywall_result.dart';

class PersonalizedOnboardingScreen extends StatefulWidget {
  final AppState appState;
  final Future<void> Function() onComplete;
  final Future<void> Function() onAcceptTerms;
  final bool isPreview;

  const PersonalizedOnboardingScreen({
    super.key,
    required this.appState,
    required this.onComplete,
    required this.onAcceptTerms,
    this.isPreview = false,
  });

  @override
  State<PersonalizedOnboardingScreen> createState() =>
      _PersonalizedOnboardingScreenState();
}

class _PersonalizedOnboardingScreenState
    extends State<PersonalizedOnboardingScreen>
    with SingleTickerProviderStateMixin {
  static final Uri _termsUrl = Uri.parse(
    'https://mlmasters.com/TermsAndConditions_Gwyn.html',
  );
  static final Uri _privacyUrl = Uri.parse(
    'https://mlmasters.com/PrivacyPolicy_Gwyn.html',
  );

  static const int _questionCount = 8;
  static const int _welcomeStep = 0;
  static const int _firstQuestionStep = 1;
  static const int _analysisStep = 9;
  static const int _summaryStep = 10;

  final PageController _pageController = PageController();
  late final AnimationController _analysisAnimation;
  int _step = _welcomeStep;
  bool _isFinishing = false;
  bool _acceptedLegal = false;

  String? _goal;
  String? _frequency;
  double _impact = 5;
  final Set<String> _symptoms = {};
  final Set<String> _triggers = {};
  final Set<String> _timings = {};
  final Set<String> _copingMethods = {};
  String? _objective;

  @override
  void initState() {
    super.initState();
    _analysisAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _analysisAnimation.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    1 => _goal != null,
    2 => _frequency != null,
    3 => true,
    4 => _symptoms.isNotEmpty,
    5 => _triggers.isNotEmpty,
    6 => _timings.isNotEmpty,
    7 => _copingMethods.isNotEmpty,
    8 => _objective != null,
    _ => true,
  };

  Future<void> _goTo(int step) async {
    if (!mounted) return;
    setState(() => _step = step);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (step == _analysisStep) {
      _startAnalysis();
    }
  }

  Future<void> _startAnalysis() async {
    _analysisAnimation.repeat(reverse: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _step != _analysisStep) return;
    _analysisAnimation.stop();
    await _goTo(_summaryStep);
  }

  Future<void> _next() async {
    if (!_canContinue) return;
    await _goTo(_step + 1);
  }

  Future<void> _back() async {
    if (_step == _welcomeStep || _step == _analysisStep || _isFinishing) return;
    await _goTo(_step - 1);
  }

  Future<void> _openLegal(Uri uri, String label) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $label.')));
    }
  }

  Future<void> _finish() async {
    if (!_acceptedLegal || _isFinishing) return;
    setState(() => _isFinishing = true);

    if (widget.isPreview) {
      if (mounted) Navigator.maybePop(context);
      return;
    }

    await widget.onAcceptTerms();
    if (widget.appState.hasActiveSubscription) {
      switch (_goal) {
        case 'Cope':
          await widget.appState.saveCopePlan();
          break;
        case 'Understand':
          await widget.appState.saveUnderstandPlan();
          break;
        case 'Heal':
          await widget.appState.saveHealPlan();
          break;
      }
      await widget.appState.setPendingOnboardingPlan(null);
    } else {
      await widget.appState.setPendingOnboardingPlan(_goal);
    }
    if (!mounted) return;
    final result = await Navigator.of(context).push<OnboardingPaywallResult>(
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(isOnboardingPaywall: true),
      ),
    );
    if (!mounted || result == null) return;
    await widget.onComplete();
  }

  String get _strength {
    if (_copingMethods.contains('Talking to someone')) {
      return 'You already reach for connection';
    }
    if (_copingMethods.contains('Breathing or grounding')) {
      return 'You already use calming skills';
    }
    if (_copingMethods.contains('Writing or reflecting')) {
      return 'You are willing to reflect';
    }
    if (_copingMethods.contains('Movement or exercise')) {
      return 'You already take active steps';
    }
    return 'You are ready to try something new';
  }

  String get _focus => switch (_goal) {
    'Understand' => 'Notice triggers, thoughts, and body signals',
    'Heal' => 'Practice acceptance, release, and recovery habits',
    _ => 'Build reliable tools for anxious moments',
  };

  List<String> get _previewSteps => switch (_goal) {
    'Understand' => [
      'Record one anxious moment and its body signal.',
      'Notice the trigger that appeared just before it.',
    ],
    'Heal' => [
      'Reflect on one insight you have already discovered.',
      'Choose one thing to accept, forgive, or release.',
    ],
    _ => [
      'Write down the truth that helps you feel safe.',
      'Practice one short calming exercise each day.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_step >= _firstQuestionStep && _step <= _questionCount)
              _QuestionProgress(
                question: _step,
                total: _questionCount,
                color: color,
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcome(color),
                  _buildSingleQuestion(
                    title: 'What would you most like Gwyn to help with?',
                    subtitle: 'Choose the focus that feels most useful now.',
                    options: const ['Cope', 'Understand', 'Heal'],
                    selected: _goal,
                    icons: const [
                      Icons.spa_rounded,
                      Icons.lightbulb_rounded,
                      Icons.favorite_rounded,
                    ],
                    onSelected: (value) => setState(() => _goal = value),
                  ),
                  _buildSingleQuestion(
                    title: 'How often does anxiety affect you?',
                    subtitle: 'Choose the closest answer.',
                    options: const [
                      'Multiple times a day',
                      'Daily',
                      'Several times a week',
                      'Occasionally',
                    ],
                    selected: _frequency,
                    onSelected: (value) => setState(() => _frequency = value),
                  ),
                  _buildImpactQuestion(color),
                  _buildMultiQuestion(
                    title: 'What do you notice when anxiety appears?',
                    subtitle: 'Select all that apply.',
                    options: const [
                      'Racing thoughts',
                      'Fast heartbeat',
                      'Tight chest',
                      'Dizziness',
                      'Stomach discomfort',
                      'Tense muscles',
                      'Difficulty concentrating',
                    ],
                    selected: _symptoms,
                  ),
                  _buildMultiQuestion(
                    title: 'What tends to trigger it?',
                    subtitle: 'Select the situations that fit best.',
                    options: const [
                      'Social situations',
                      'Work or school',
                      'Health',
                      'Relationships',
                      'Finances',
                      'Crowds or travel',
                      'Uncertainty',
                      'I do not know yet',
                    ],
                    selected: _triggers,
                  ),
                  _buildMultiQuestion(
                    title: 'When does anxiety usually occur?',
                    subtitle: 'Select all that apply.',
                    options: const [
                      'Morning',
                      'During the day',
                      'Evening',
                      'At night',
                      'Before specific events',
                      'Without a clear pattern',
                    ],
                    selected: _timings,
                  ),
                  _buildMultiQuestion(
                    title: 'What do you currently do to cope?',
                    subtitle: 'There is no wrong answer.',
                    options: const [
                      'Breathing or grounding',
                      'Talking to someone',
                      'Writing or reflecting',
                      'Movement or exercise',
                      'Avoiding the situation',
                      'Nothing consistently helps yet',
                    ],
                    selected: _copingMethods,
                  ),
                  _buildSingleQuestion(
                    title: 'What is your main objective for the next month?',
                    subtitle: 'Your plan will be shaped around this objective.',
                    options: const [
                      'Feel calmer in anxious moments',
                      'Understand what causes my anxiety',
                      'Sleep and recover better',
                      'Face situations I currently avoid',
                      'Build a consistent daily practice',
                    ],
                    selected: _objective,
                    onSelected: (value) => setState(() => _objective = value),
                  ),
                  _buildAnalysis(color),
                  _buildSummary(color),
                  _buildPremiumPreview(color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(Color color) {
    return _OnboardingPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/icon.png', width: 150, height: 150),
          const SizedBox(height: 28),
          Text(
            'Welcome',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          const Text(
            'Gwyn will create a personal plan just for you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, height: 1.4),
          ),
          const SizedBox(height: 14),
          Text(
            'Answer 8 short questions. Your personal summary is free; the complete plan is available with Premium.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black54,
            ),
          ),
          const SizedBox(height: 34),
          _PrimaryButton(
            label: 'Personalize my plan',
            color: color,
            onTap: _next,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleQuestion({
    required String title,
    required String subtitle,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
    List<IconData>? icons,
  }) {
    return _QuestionPage(
      title: title,
      subtitle: subtitle,
      onBack: _back,
      canContinue: _canContinue,
      onContinue: _next,
      children: [
        for (var index = 0; index < options.length; index++)
          _AnswerTile(
            label: options[index],
            icon: icons == null ? null : icons[index],
            selected: selected == options[index],
            onTap: () => onSelected(options[index]),
          ),
      ],
    );
  }

  Widget _buildMultiQuestion({
    required String title,
    required String subtitle,
    required List<String> options,
    required Set<String> selected,
  }) {
    return _QuestionPage(
      title: title,
      subtitle: subtitle,
      onBack: _back,
      canContinue: _canContinue,
      onContinue: _next,
      children: [
        for (final option in options)
          _AnswerTile(
            label: option,
            selected: selected.contains(option),
            isMulti: true,
            onTap: () {
              setState(() {
                selected.contains(option)
                    ? selected.remove(option)
                    : selected.add(option);
              });
            },
          ),
      ],
    );
  }

  Widget _buildImpactQuestion(Color color) {
    return _QuestionPage(
      title: 'How strongly does anxiety affect your daily life?',
      subtitle: 'This is a personal check-in, not a diagnosis.',
      onBack: _back,
      canContinue: true,
      onContinue: _next,
      children: [
        GlassCard(
          child: Column(
            children: [
              Text(
                _impact.round().toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                value: _impact,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: color,
                label: _impact.round().toString(),
                onChanged: (value) => setState(() => _impact = value),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('A little'), Text('Very strongly')],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysis(Color color) {
    return _OnboardingPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _analysisAnimation,
            builder: (context, child) {
              final scale = 0.92 + (_analysisAnimation.value * 0.16);
              return Transform.scale(
                scale: scale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AnalysisIcon(Icons.psychology_rounded, color),
                    const SizedBox(width: 16),
                    _AnalysisIcon(Icons.menu_book_rounded, color),
                    const SizedBox(width: 16),
                    _AnalysisIcon(Icons.spa_rounded, color),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 34),
          Text(
            'Gwyn is shaping your plan…',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            'Connecting your goal, triggers, symptoms, and existing strengths.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(Color color) {
    final triggerText = _triggers.take(3).join(', ');
    return _OnboardingPage(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            'Your personal summary',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Based on the answers you shared. This is not a diagnosis.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          _SummaryTile(
            icon: Icons.speed_rounded,
            color: color,
            label: 'Check-in level',
            value: '${_impact.round()}/10',
          ),
          _SummaryTile(
            icon: Icons.bolt_rounded,
            color: Colors.amber.shade700,
            label: 'Most relevant triggers',
            value: triggerText.isEmpty ? 'Still to discover' : triggerText,
          ),
          _SummaryTile(
            icon: Icons.shield_rounded,
            color: Colors.blue.shade500,
            label: 'Existing strength',
            value: _strength,
          ),
          _SummaryTile(
            icon: Icons.track_changes_rounded,
            color: Colors.teal.shade500,
            label: 'Suggested focus',
            value: _focus,
          ),
          const SizedBox(height: 18),
          _PrimaryButton(label: 'Preview my plan', color: color, onTap: _next),
          TextButton(onPressed: _back, child: const Text('Back')),
        ],
      ),
    );
  }

  Widget _buildPremiumPreview(Color color) {
    return _OnboardingPage(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 50),
          const SizedBox(height: 14),
          Text(
            'Your personalized Gwyn Plan is ready',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Here are the first steps. Premium unlocks the complete guided plan and subscriber features.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < _previewSteps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withAlpha(31),
                      foregroundColor: color,
                      child: Text('${index + 1}'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(_previewSteps[index])),
                  ],
                ),
              ),
            ),
          GlassCard(
            child: Row(
              children: [
                Icon(Icons.lock_rounded, color: color),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Your remaining guided plan and Premium tools'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acceptedLegal,
            activeColor: color,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) =>
                setState(() => _acceptedLegal = value ?? false),
            title: const Text('I accept the Terms and Privacy Policy'),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => _openLegal(_termsUrl, 'Terms'),
                child: const Text('Terms'),
              ),
              TextButton(
                onPressed: () => _openLegal(_privacyUrl, 'Privacy Policy'),
                child: const Text('Privacy Policy'),
              ),
            ],
          ),
          _PrimaryButton(
            label: widget.isPreview ? 'Close preview' : 'Continue',
            color: color,
            onTap: _acceptedLegal && !_isFinishing ? _finish : null,
          ),
          TextButton(onPressed: _back, child: const Text('Back')),
        ],
      ),
    );
  }
}

class _QuestionProgress extends StatelessWidget {
  final int question;
  final int total;
  final Color color;

  const _QuestionProgress({
    required this.question,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$question/$total',
            textAlign: TextAlign.right,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: question / total,
              minHeight: 8,
              color: color,
              backgroundColor: color.withAlpha(31),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const _OnboardingPage({required this.child, this.scrollable = false});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: child,
    );
    return scrollable ? SingleChildScrollView(child: content) : content;
  }
}

class _QuestionPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool canContinue;
  final VoidCallback onContinue;
  final List<Widget> children;

  const _QuestionPage({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.canContinue,
    required this.onContinue,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 22),
          ...children,
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Continue',
            color: color,
            onTap: canContinue ? onContinue : null,
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool isMulti;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.isMulti = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: Border.all(
            color: selected ? color : color.withAlpha(31),
            width: selected ? 2 : 1,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                isMulti
                    ? selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded
                    : selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? color : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _AnalysisIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _AnalysisIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(31),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
