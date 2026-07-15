import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../meditations/presentation/meditations_screen.dart';
import '../../subscription/application/subscription_gate.dart';
import 'acceptance_screen.dart';
import 'forgiveness_screen.dart';
import 'let_go_screen.dart';
import 'survival_mode_screen.dart';

class HealScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isActive;

  const HealScreen({super.key, this.onBack, this.isActive = true});

  @override
  State<HealScreen> createState() => _HealScreenState();
}

class _HealScreenState extends State<HealScreen> {
  bool _isHealingPopupShowing = false;

  @override
  void didUpdateWidget(covariant HealScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _showHealingPopupAfterTabSelection();
    }
  }

  void _showHealingPopupAfterTabSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isHealingPopupShowing) return;

      final appState = context.read<AppState>();
      if (appState.hideHealMethodsMessage) return;

      _isHealingPopupShowing = true;
      _showHealingMethodsDialog(appState).whenComplete(() {
        _isHealingPopupShowing = false;
      });
    });
  }

  void _openGwynChat(BuildContext context) {
    openGwynChatOrSubscription(
      context,
      title: 'Heal with Gwyn',
      pageContext:
          'The user opened Gwyn from the healing space screen, which includes acceptance, letting go, forgiveness, survival mode support, and guided meditations.',
      suggestedPrompts: const [
        'Help me accept this feeling',
        'I want to let something go',
        'Help me calm survival mode',
        'Guide me back to my body',
      ],
      showGwynHeader: false,
      previewBeforeSubscription: true,
      previewDialogMessage:
          'Here you can chat with Gwyn about healing anxiety. This preview uses built-in example responses so you can see how Gwyn replies before subscribing.',
    );
  }

  void _openAcceptance(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AcceptanceScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  void _openLetGo(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LetGoScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  void _openForgiveness(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ForgivenessScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  void _openMeditations(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MeditationsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  void _openSurvivalModeSupport(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SurvivalModeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  Future<void> _showHealingMethodsDialog(AppState appState) async {
    var doNotShowAgain = false;
    final primaryColor = Theme.of(context).primaryColor;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 56,
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              title: Text(
                'How to heal anxiety?',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                height: 430,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Healing anxiety can happen through repeated practice. The tools and methods provided here help you accept what you feel, release what you are carrying, forgive what needs forgiveness, leave survival mode, and return to your inner strength through meditation.',
                      style: TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose one method at a time. Small moments of safety and courage can teach your nervous system that the anxious wave can pass.',
                      style: TextStyle(height: 1.45),
                    ),
                    const Spacer(),
                    CheckboxListTile(
                      value: doNotShowAgain,
                      onChanged: (value) {
                        setDialogState(() {
                          doNotShowAgain = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: primaryColor,
                      title: const Text(
                        'Do not show this message again',
                        style: TextStyle(fontSize: 14, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () async {
                    if (doNotShowAgain) {
                      await appState.setHideHealMethodsMessage(true);
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withAlpha(13)
                              : Colors.black.withAlpha(8),
                        ),
                        onPressed:
                            widget.onBack ?? () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Healing space',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HealWithGwynButton(onTap: () => _openGwynChat(context)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Healing from anxiety is possible. Be strong and be courageous !',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : Colors.black.withAlpha(153),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HealHelpButton(
                        onTap: () {
                          final appState = context.read<AppState>();
                          _showHealingMethodsDialog(appState);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  GestureDetector(
                    onTap: () => _openAcceptance(context),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.pink.withAlpha(31),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.pink.shade300,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Acceptance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Make room for this moment without fighting what you feel.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black.withAlpha(153),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? Colors.white30
                                : Colors.black.withAlpha(77),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _openLetGo(context),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.withAlpha(31),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bubble_chart_rounded,
                              color: Colors.lightBlue.shade600,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Let it go',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Write what you are ready to release, then let a balloon drift away or pop it.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black.withAlpha(153),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? Colors.white30
                                : Colors.black.withAlpha(77),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _openForgiveness(context),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(31),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.volunteer_activism_rounded,
                              color: Colors.orange.shade600,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Forgiveness',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Practice gently releasing what you no longer need to carry.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black.withAlpha(153),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? Colors.white30
                                : Colors.black.withAlpha(77),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _openSurvivalModeSupport(context),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.withAlpha(31),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.health_and_safety_rounded,
                              color: Colors.teal.shade500,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Get out of survival mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Help your nervous system feel safer with one gentle next step.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black.withAlpha(153),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? Colors.white30
                                : Colors.black.withAlpha(77),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _openMeditations(context),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withAlpha(31),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.self_improvement_rounded,
                              color: Colors.indigo.shade400,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Guided meditations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Follow a gentle prompt to return to your breath and body.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black.withAlpha(153),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? Colors.white30
                                : Colors.black.withAlpha(77),
                          ),
                        ],
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
}

class _HealWithGwynButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HealWithGwynButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withAlpha(128)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/icon.png',
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Heal with Gwyn',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealHelpButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HealHelpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Tooltip(
      message: 'How to heal anxiety?',
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.help_outline_rounded),
        color: primaryColor,
        iconSize: 20,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: isDark
              ? Colors.white.withAlpha(13)
              : primaryColor.withAlpha(20),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
