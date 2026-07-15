import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

@Preview(name: 'Onboarding', group: 'Gwyn', size: Size(390, 844))
Widget onboardingPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.forestTheme,
    home: OnboardingScreen(
      onComplete: onboardingPreviewNoop,
      onAcceptTerms: onboardingPreviewNoop,
      onNameSubmitted: onboardingPreviewNameNoop,
    ),
  );
}

Future<void> onboardingPreviewNoop() async {}
Future<void> onboardingPreviewNameNoop(String name) async {}

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  final Future<void> Function() onAcceptTerms;
  final Future<void> Function(String name)? onNameSubmitted;
  final bool showIntroPages;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onAcceptTerms,
    this.onNameSubmitted,
    this.showIntroPages = true,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  bool _isCompleting = false;
  String? _submittedName;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Hi, I am Gwyn',
      description: 'Vanquish your anxiety with me',
      imageAsset: 'assets/images/icon.png',
    ),
    _OnboardingPageData(
      title: 'This app guides you to',
      description: '',
      icon: Icons.spa_rounded,
    ),
    _OnboardingPageData(
      title: 'Cope',
      description:
          'Panic and anxiety attacks can feel like your mind is spiraling out of control. No matter how intense they become, the cope exercises help you break the cycle by distracting your mind',
      icon: Icons.spa_rounded,
    ),
    _OnboardingPageData(
      title: 'Understand',
      description:
          'Understand what is really happening in your mind. There is a reason you feel anxious. Once you understand the reason why, healing can begin. Explore your mind using Gwyn\'s effective tools',
      icon: Icons.lightbulb_rounded,
    ),
    _OnboardingPageData(
      title: 'Heal',
      description:
          'Healing anxiety takes courage. It means facing the fears that have been holding you back. This journey isn\'t easy, but Gwyn will stand by your side every step of the way. The courage to move forward, however, must come from within you',
      iconAsset: 'assets/images/resilient-health.png',
    ),
  ];

  int get _introPageCount => widget.showIntroPages ? _pages.length : 0;

  int get _namePageIndex => _introPageCount;

  int get _termsPageIndex => _introPageCount + (widget.showIntroPages ? 1 : 0);

  int get _pageCount => _termsPageIndex + 1;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentPage < _termsPageIndex) {
      if (widget.showIntroPages && _currentPage == _namePageIndex) {
        await _submitNameIfPresent(useDefaultName: true);
      }

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() {
      _isCompleting = true;
    });
    await _submitNameIfPresent();
    await widget.onAcceptTerms();
    await widget.onComplete();
  }

  Future<void> _submitNameIfPresent({bool useDefaultName = false}) async {
    final typedName = _nameController.text.trim();
    final name = typedName.isEmpty && useDefaultName ? 'My Friend' : typedName;
    if (name.isEmpty || name == _submittedName) return;

    _submittedName = name;
    await widget.onNameSubmitted?.call(name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (index == _termsPageIndex) {
                      return const _TermsAndConditionsPage();
                    }

                    if (widget.showIntroPages && index == _namePageIndex) {
                      return _NameOnboardingPage(controller: _nameController);
                    }

                    final page = _pages[index];
                    if (index == 0) {
                      return _GwynIntroPage(page: page);
                    }

                    if (index == 1) {
                      return _GwynBackgroundPage(page: page);
                    }

                    if (index >= 2 && index <= 4) {
                      return _FeatureOnboardingPage(page: page);
                    }

                    return Center(
                      child: GlassCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (page.imageAsset != null)
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: primaryColor.withAlpha(31),
                                backgroundImage: AssetImage(page.imageAsset!),
                              )
                            else
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: primaryColor.withAlpha(31),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  page.icon,
                                  color: primaryColor,
                                  size: 42,
                                ),
                              ),
                            const SizedBox(height: 26),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black.withAlpha(166),
                                fontSize: 50,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompleting ? null : _handlePrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _currentPage == _termsPageIndex
                        ? 'Get started'
                        : widget.showIntroPages &&
                              _currentPage == _namePageIndex
                        ? 'Continue'
                        : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

class _FeatureOnboardingPage extends StatelessWidget {
  final _OnboardingPageData page;

  const _FeatureOnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(top: 8, bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: primaryColor.withAlpha(92)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/gwyn-background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFFAF8F5).withAlpha(242),
                      const Color(0xFFFAF8F5).withAlpha(188),
                      const Color(0xFFFAF8F5).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              top: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 69,
                    height: 69,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(224),
                      shape: BoxShape.circle,
                    ),
                    child: page.iconAsset == null
                        ? Icon(page.icon, color: primaryColor, size: 32)
                        : ImageIcon(
                            AssetImage(page.iconAsset!),
                            color: primaryColor,
                            size: 34,
                          ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF2C3330),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(211),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withAlpha(168)),
                    ),
                    child: Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2C3330),
                        fontSize: 19.8,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Image.asset(
                'assets/images/gwen_relaxed.png',
                width: 132,
                height: 132,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GwynIntroPage extends StatelessWidget {
  final _OnboardingPageData page;

  const _GwynIntroPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(top: 8, bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: primaryColor.withAlpha(92)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/gwyn-onboarding1.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFAF8F5).withAlpha(238),
                      const Color(0xFFFAF8F5).withAlpha(172),
                      const Color(0xFFFAF8F5).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              top: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF2C3330),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2C3330),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
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

class _GwynBackgroundPage extends StatelessWidget {
  final _OnboardingPageData page;

  const _GwynBackgroundPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(top: 8, bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: primaryColor.withAlpha(92)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/gwyn-background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF2C3330).withAlpha(220),
                      const Color(0xFF2C3330).withAlpha(122),
                      const Color(0xFF2C3330).withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              top: 72,
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF2C3330),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              top: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _OnboardingBullet(
                    icon: Icons.spa_rounded,
                    label: 'Cope',
                  ),
                  const SizedBox(height: 16),
                  const _OnboardingBullet(
                    icon: Icons.lightbulb_rounded,
                    label: 'Understand',
                  ),
                  const SizedBox(height: 16),
                  const _OnboardingBullet(
                    icon: Icons.hub_rounded,
                    iconAsset: 'assets/images/resilient-health.png',
                    label: 'Heal',
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

class _OnboardingBullet extends StatelessWidget {
  final IconData icon;
  final String? iconAsset;
  final String label;

  const _OnboardingBullet({
    required this.icon,
    required this.label,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(224),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: iconAsset == null
                ? Icon(icon, color: Theme.of(context).primaryColor, size: 25)
                : ImageIcon(
                    AssetImage(iconAsset!),
                    color: Theme.of(context).primaryColor,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2C3330),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameOnboardingPage extends StatelessWidget {
  final TextEditingController controller;

  const _NameOnboardingPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = keyboardVisible || constraints.maxHeight < 520;
        final imageSize = compact ? 56.0 : 125.0;
        final titleSize = compact ? 19.8 : 27.0;

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: compact ? 12 : 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: compact ? Alignment.center : const Alignment(0, -0.2),
              child: _ImageOnboardingFrame(
                height: constraints.maxHeight,
                child: GlassCard(
                  padding: EdgeInsets.all(compact ? 14 : 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/icon3.png',
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: compact ? 10 : 24),
                      Text(
                        'How shall I call you?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF2C3330),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                      SizedBox(height: compact ? 12 : 22),
                      TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(height: 1.2),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'My Friend',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withAlpha(115)
                                : Colors.black.withAlpha(115),
                            height: 1.2,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageOnboardingFrame extends StatelessWidget {
  final Widget child;
  final double? height;

  const _ImageOnboardingFrame({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      height: height,
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryColor.withAlpha(92)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/gwyn-background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFFAF8F5).withAlpha(235),
                    const Color(0xFFFAF8F5).withAlpha(168),
                    const Color(0xFFFAF8F5).withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _LegalLinksText extends StatelessWidget {
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _LegalLinksText({required this.onTermsTap, required this.onPrivacyTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    const baseStyle = TextStyle(fontSize: 13, height: 1.35);
    final linkStyle = baseStyle.copyWith(
      color: primaryColor,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'By continuing, you agree to our ',
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(color: Colors.black.withAlpha(166)),
        ),
        InkWell(
          onTap: onTermsTap,
          child: Text('Terms', style: linkStyle),
        ),
        Text(
          ' and ',
          style: baseStyle.copyWith(color: Colors.black.withAlpha(166)),
        ),
        InkWell(
          onTap: onPrivacyTap,
          child: Text('Privacy Policy', style: linkStyle),
        ),
      ],
    );
  }
}

class _TermsAndConditionsPage extends StatelessWidget {
  static final Uri _termsUrl = Uri.parse(
    'https://mlmasters.com/TermsAndConditions_Gwyn.html',
  );
  static final Uri _privacyUrl = Uri.parse(
    'https://mlmasters.com/PrivacyPolicy_Gwyn.html',
  );

  const _TermsAndConditionsPage();

  Future<void> _openLegalUrl(
    BuildContext context,
    Uri url,
    String label,
  ) async {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $label.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            width: double.infinity,
            height: constraints.maxHeight,
            constraints: const BoxConstraints(maxWidth: 360),
            margin: const EdgeInsets.only(top: 8, bottom: 6),
            child: GlassCard(
              borderRadius: 28,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: primaryColor,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Terms and Conditions',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.black.withAlpha(8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FutureBuilder<String>(
                        future: rootBundle.loadString(
                          'assets/data/heal_read_first_disclaimer.txt',
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final text =
                              snapshot.data ??
                              'The exercises in this appare supportive tools and are not a substitute for professional or emergency care.';

                          return SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                text,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withAlpha(217)
                                      : Colors.black.withAlpha(191),
                                  fontSize: 17,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LegalLinksText(
                    onTermsTap: () =>
                        _openLegalUrl(context, _termsUrl, 'Terms'),
                    onPrivacyTap: () =>
                        _openLegalUrl(context, _privacyUrl, 'Privacy Policy'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData? icon;
  final String? iconAsset;
  final String? imageAsset;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    this.icon,
    this.iconAsset,
    this.imageAsset,
  });
}
