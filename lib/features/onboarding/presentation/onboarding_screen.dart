import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Hi I am Gwen.',
      description: 'Vanquish your anxiety with me.',
      imageAsset: 'assets/images/icon.png',
    ),
    _OnboardingPageData(
      title: 'Find calm',
      description:
          'Dummy onboarding content for the second screen. This can explain calming tools later.',
      icon: Icons.spa_rounded,
    ),
    _OnboardingPageData(
      title: 'Start gently',
      description:
          'Dummy onboarding content for the third screen. This can set expectations later.',
      icon: Icons.favorite_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentPage < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() {
      _isCompleting = true;
    });
    await widget.onComplete();
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isCompleting ? null : widget.onComplete,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
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
                                fontSize: 14,
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
                children: List.generate(_pages.length, (index) {
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
                    _currentPage == _pages.length - 1 ? 'Get started' : 'Next',
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

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData? icon;
  final String? imageAsset;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    this.icon,
    this.imageAsset,
  });
}
