import 'dart:async';

import 'core/state/app_state.dart';
import 'core/services/gemini_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'features/heal/presentation/heal_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/learning/presentation/understand_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/sanctuary/presentation/sanctuary_screen.dart';
import 'features/calm_down/presentation/calm_down_screen.dart';
import 'features/grounding/presentation/grounding_screen.dart';
import 'features/journaling/presentation/journaling_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter startup/runtime error: ${details.exceptionAsString()}');
  };

  // Create state singleton
  final appState = AppState();
  await appState.init();
  await _runStartupStep(
    'GeminiService.initializeApiKey',
    GeminiService.instance.initializeApiKey,
  );
  unawaited(
    _runStartupStep(
      'NotificationService.init',
      NotificationService.instance.init,
    ),
  );

  // Lock orientation to portrait for clean mobile layout
  await _runStartupStep(
    'SystemChrome.setPreferredOrientations',
    () => SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );

  runApp(StillnessApp(appState: appState));
}

Future<void> _runStartupStep(
  String label,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error, stackTrace) {
    debugPrint('Startup step failed: $label');
    debugPrint('$error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class StillnessApp extends StatelessWidget {
  final AppState appState;

  const StillnessApp({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: AnimatedBuilder(
        animation: appState,
        builder: (context, child) {
          return MaterialApp(
            title: 'Gwen',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getThemeForIndex(appState.themeModeIndex),
            themeMode: appState.themeModeIndex == 2
                ? ThemeMode.dark
                : ThemeMode.light,
            home:
                appState.onboardingCompleted && appState.healDisclaimerAccepted
                ? AppShell(appState: appState)
                : OnboardingScreen(
                    showIntroPages: !appState.onboardingCompleted,
                    onAcceptTerms: appState.acceptHealDisclaimer,
                    onNameSubmitted: appState.setUserName,
                    onComplete: () async {
                      await appState.completeOnboarding();
                      await _runStartupStep(
                        'NotificationService.scheduleDefaultDailyReminders',
                        NotificationService
                            .instance
                            .scheduleDefaultDailyReminders,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final AppState appState;

  const AppShell({Key? key, required this.appState}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final List<int> _tabHistory = [0];
  int _currentIndex = 0;
  bool _showEmergencyOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _runStartupStep(
          'NotificationService.scheduleDefaultDailyReminders',
          NotificationService.instance.scheduleDefaultDailyReminders,
        ),
      );
    });
  }

  void _navigateToTab(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
      _tabHistory.add(index);
    });
  }

  void _goBackToPreviousTab() {
    if (_tabHistory.length <= 1) return;

    setState(() {
      _tabHistory.removeLast();
      _currentIndex = _tabHistory.last;
    });
  }

  void _handleSystemBack() {
    if (_showEmergencyOverlay) {
      _dismissEmergencyOverlay();
      return;
    }

    _goBackToPreviousTab();
  }

  void _triggerEmergencyCalmDown() {
    setState(() {
      _showEmergencyOverlay = true;
    });
  }

  void _dismissEmergencyOverlay() {
    setState(() {
      _showEmergencyOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Screens mapping
    final List<Widget> screens = [
      HomeScreen(onBottomDestinationSelected: _navigateToTab),
      SanctuaryScreen(onBack: () => _navigateToTab(0)),
      JournalingScreen(
        appState: widget.appState,
        onBack: () => _navigateToTab(0),
      ),
      UnderstandScreen(onBack: () => _navigateToTab(0)),
      HealScreen(onBack: () => _navigateToTab(0), isActive: _currentIndex == 4),
    ];

    return PopScope(
      canPop: !_showEmergencyOverlay && _tabHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background soft visual decoration (Calming mesh gradient style)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                color: widget.appState.themeModeIndex == 2
                    ? AppTheme.darkBg
                    : (widget.appState.themeModeIndex == 0
                          ? AppTheme.forestBg
                          : AppTheme.lavendelBg),
              ),
            ),

            // Background glowing ambient circles
            Positioned(
              top: -100,
              right: -100,
              child: _AmbientGlow(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                size: 320,
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _AmbientGlow(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withOpacity(0.07),
                size: 280,
              ),
            ),

            // Main Screen Content
            Positioned.fill(
              child: IndexedStack(index: _currentIndex, children: screens),
            ),

            // Emergency Overlay layer
            if (_showEmergencyOverlay)
              Positioned.fill(
                child:
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          CalmDownScreen(
                            appState: widget.appState,
                            onDismiss: _dismissEmergencyOverlay,
                            onNavigateToGrounding: () {
                              debugPrint('🔎 Grounding callback triggered');
                              _dismissEmergencyOverlay();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroundingScreen(
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                            },
                          ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                    ).buildPage(
                      context,
                      const AlwaysStoppedAnimation(1.0),
                      const AlwaysStoppedAnimation(0.0),
                    ),
              ),
          ],
        ),

        // Calming, lightweight bottom navigation bar
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _navigateToTab,
            backgroundColor: isDark ? const Color(0xFF0F131E) : Colors.white,
            indicatorColor: Theme.of(context).primaryColor.withOpacity(0.12),
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 66,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.spa_outlined,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                selectedIcon: Icon(
                  Icons.spa_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Cope',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.book_outlined,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                selectedIcon: Icon(
                  Icons.book,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Journal',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.lightbulb_outline,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                selectedIcon: Icon(
                  Icons.lightbulb_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Understand',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.hub_outlined,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                selectedIcon: Icon(
                  Icons.hub_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Heal',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
