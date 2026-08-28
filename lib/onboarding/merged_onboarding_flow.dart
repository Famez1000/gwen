import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/sanctuary/presentation/leaf_exercise_screen.dart';
import '../features/subscription/presentation/subscription_screen.dart';
import '../features/subscription/presentation/onboarding_paywall_result.dart';
import 'models/onboarding_answers.dart';
import 'state/onboarding_state.dart';
import 'widgets/onboarding_scaffold.dart';

/// Screenshot-led onboarding that combines the classic introduction with the
/// questions and personalised plan from the current onboarding flow.
class MergedOnboardingFlow extends StatefulWidget {
  const MergedOnboardingFlow({super.key});

  @override
  State<MergedOnboardingFlow> createState() => _MergedOnboardingFlowState();
}

class _MergedOnboardingFlowState extends State<MergedOnboardingFlow> {
  static const _pageCount = 10;
  static const _brand = Color(0xFF668D7E);
  final _controller = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int page) async {
    setState(() => _page = page);
    await _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  bool _canContinue(OnboardingAnswers answers) => switch (_page) {
    1 => answers.struggles.isNotEmpty,
    2 => answers.frequency != null,
    4 => answers.goal != null,
    _ => true,
  };

  Future<void> _continue(OnboardingState state) async {
    if (_page == 8) {
      state.setFirstName(_nameController.text.trim());
    }
    if (_page == _pageCount - 1) {
      final result = await Navigator.of(context).push<OnboardingPaywallResult>(
        MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(isOnboardingPaywall: true),
        ),
      );
      if (mounted && result != null) await state.completeOnboarding();
      return;
    }
    await _goTo(_page + 1);
  }

  Future<void> _openLegal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();
    final answers = state.answers;
    final isQuestionPage = _page == 1 || _page == 2 || _page == 4;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _HeroPage(
                        title: 'Hi, I am Gwyn',
                        subtitle: 'Vanquish your anxiety with me',
                      ),
                      _QuestionPage(
                        title: 'What are you struggling with?',
                        subtitle: 'Select all that apply.',
                        child: ListView(
                          children: AnxietyStruggle.values
                              .map(
                                (item) => MultiOptionTile(
                                  label: item.label,
                                  selected: answers.struggles.contains(item),
                                  onToggle: () => state.toggleStruggle(item),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      _QuestionPage(
                        title: 'How often do you feel this way?',
                        child: ListView(
                          children: AnxietyFrequency.values
                              .map(
                                (item) => OptionTile(
                                  label: item.label,
                                  value: item,
                                  groupValue: answers.frequency,
                                  onSelected: state.setFrequency,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const _FeaturePage(
                        icon: Icons.spa_rounded,
                        title: 'Cope',
                        message:
                            'Panic and anxiety attacks can feel as though your mind is spiralling out of control. No matter how intense they become, the exercises in this app can help you break the cycle by redirecting your attention and calming your mind.',
                      ),
                      _QuestionPage(
                        title: 'What would you like\nto work on first?',
                        child: ListView(
                          children: OnboardingGoal.values
                              .map(
                                (item) => OptionTile(
                                  label: item.label,
                                  value: item,
                                  groupValue: answers.goal,
                                  onSelected: state.setGoal,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      _ExercisePreview(
                        onTry: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LeafExerciseScreen(),
                          ),
                        ),
                      ),
                      const _FeaturePage(
                        icon: Icons.lightbulb_rounded,
                        title: 'Understand',
                        message:
                            'There is a reason you feel anxious. Understand what is really happening in your mind. Once you understand the reason why, healing can begin. Explore your mind using Gwyn’s effective tools.',
                      ),
                      const _PathsPage(),
                      _NamePage(controller: _nameController),
                      _TermsPage(
                        onOpenTerms: () => _openLegal(
                          'https://mlmasters.com/TermsAndConditions_Gwyn.html',
                        ),
                        onOpenPrivacy: () => _openLegal(
                          'https://mlmasters.com/PrivacyPolicy_Gwyn.html',
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 2,
                    left: 0,
                    right: 0,
                    child: _PageDots(currentPage: _page, count: _pageCount),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, isQuestionPage ? 8 : 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: !_canContinue(answers) || state.isCompleting
                      ? null
                      : () => _continue(state),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    disabledBackgroundColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    _page == _pageCount - 1 ? 'Get started' : 'Next',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPage extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeroPage({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => _ArtworkPage(
    child: Transform.translate(
      offset: const Offset(0, 28),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E302A),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E302A),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PageDots extends StatelessWidget {
  final int currentPage;
  final int count;

  const _PageDots({required this.currentPage, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: index == currentPage ? 32 : 11,
          height: 11,
          decoration: BoxDecoration(
            color: index == currentPage
                ? const Color(0xFF668D7E)
                : Colors.black12,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/gwyn-background.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .05),
                  Colors.white.withValues(alpha: .60),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -6,
            child: IgnorePointer(
              child: Opacity(
                opacity: .88,
                child: Image.asset('assets/images/gwyn-plan.png', height: 132),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 116),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Icon(icon, size: 42, color: const Color(0xFF668D7E)),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    message,
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.42,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ArtworkPage extends StatelessWidget {
  final Widget child;
  const _ArtworkPage({required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/gwyn-onboarding1.png', fit: BoxFit.cover),
          //Container(color: Colors.white.withValues(alpha: .08)),
          child,
        ],
      ),
    ),
  );
}

class _QuestionPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _QuestionPage({
    required this.title,
    this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      //Image.asset('assets/images/gwyn-onboarding1.png', fit: BoxFit.cover),
      //Container(color: const Color(0xFFFBF9F5).withValues(alpha: 0.90)),
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E302A),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 18),
            Expanded(child: child),
          ],
        ),
      ),
    ],
  );
}

class _ExercisePreview extends StatelessWidget {
  final VoidCallback onTry;
  const _ExercisePreview({required this.onTry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.eco_rounded, size: 76, color: Color(0xFF668D7E)),
        const SizedBox(height: 24),
        const Text(
          'Leaf exercise',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'One of the simplest ways to calm anxious thoughts is to give your mind something else to focus on. The Leaf Exercise does exactly that.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.4),
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: onTry,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Try the exercise'),
        ),
      ],
    ),
  );
}

class _PathsPage extends StatelessWidget {
  const _PathsPage();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/gwyn-background.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: .54),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 56, 32, 42),
            child: Column(
              children: [
                const Text(
                  'This app guides you to',
                  textScaler: TextScaler.noScaling,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 56),
                const _PathRow(icon: Icons.spa_rounded, label: 'Cope'),
                const SizedBox(height: 16),
                const _PathRow(
                  icon: Icons.lightbulb_rounded,
                  label: 'Understand',
                ),
                const SizedBox(height: 16),
                const _PathRow(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Heal',
                ),
                const Spacer(),
                const Text(
                  'your anxiety',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
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

class _PathRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PathRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .90),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white.withValues(alpha: .70),
          child: Icon(icon, color: const Color(0xFF668D7E), size: 30),
        ),
        const SizedBox(width: 20),
        Text(
          label,
          textScaler: TextScaler.noScaling,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});
  @override
  Widget build(BuildContext context) => _ArtworkPage(
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_rounded,
              color: Color(0xFF668D7E),
              size: 54,
            ),
            const SizedBox(height: 26),
            const Text(
              'How shall I call you?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                hintText: 'My Friend',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TermsPage extends StatelessWidget {
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  const _TermsPage({required this.onOpenTerms, required this.onOpenPrivacy});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
        child: Column(
          children: [
            const Text(
              'Terms and Conditions',
              textScaler: TextScaler.noScaling,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F2),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Text(
                'This app can support calming and emotional self-care, but it is not a substitute for professional medical, psychological, or crisis care.\n\nThe exercises in this app are intended to support your well-being. If any exercise feels overwhelming or causes significant distress, stop immediately and contact a qualified healthcare professional.',
                textScaler: TextScaler.noScaling,
                style: TextStyle(fontSize: 16, height: 1.48),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'By continuing, you agree to our ',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: 15),
                ),
                TextButton(onPressed: onOpenTerms, child: const Text('Terms')),
                const Text('and', textScaler: TextScaler.noScaling),
                TextButton(
                  onPressed: onOpenPrivacy,
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
