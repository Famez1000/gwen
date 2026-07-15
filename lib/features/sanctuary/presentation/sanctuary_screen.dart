import 'package:flutter/material.dart';
import '../../affirmations/presentation/affirmations_screen.dart';
import '../../breathing/presentation/breathing_screen.dart';
import '../../bubble_pop/presentation/bubble_pop_screen.dart';
import '../../drawing_guess/presentation/drawing_guess_screen.dart';
import '../../grounding/presentation/grounding_screen.dart';
import '../../meditations/presentation/meditations_screen.dart';
import '../../reflection/presentation/reflection_screen.dart';
import '../../subscription/application/subscription_gate.dart';
import '../../thought_support/presentation/thought_support_screen.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import 'gwen_joke_screen.dart';
import 'leaf_exercise_screen.dart';

import 'package:provider/provider.dart';

class SanctuaryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isActive;

  const SanctuaryScreen({super.key, this.onBack, this.isActive = true});

  @override
  State<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends State<SanctuaryScreen> {
  bool _isCopePopupShowing = false;

  @override
  void didUpdateWidget(covariant SanctuaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _showCopePopupAfterTabSelection();
    }
  }

  void _showCopePopupAfterTabSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isCopePopupShowing) return;

      final appState = context.read<AppState>();
      if (appState.hideCopeMethodsMessage) return;

      _isCopePopupShowing = true;
      _showCopeMethodsDialog(appState).whenComplete(() {
        _isCopePopupShowing = false;
      });
    });
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
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

  Future<void> _showCopeMethodsDialog(AppState appState) async {
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
                'How to cope with anxiety?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                height: 390,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coping tools help you interrupt the anxiety spiral in the moment. They can distract your mind, steady your body, and give your nervous system a small signal of safety.',
                      style: TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose one tool at a time. You do not need to feel calm immediately; even a tiny pause, breath, laugh, or grounding moment can help the wave pass.',
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
                      await appState.setHideCopeMethodsMessage(true);
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
    //debugPrint('SanctuaryScreen build started');
    final appState = Provider.of<AppState>(context, listen: false);
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
                          "Cope with anxiety",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _VanquishWithGwynButton(
                        onTap: () => openGwynChatOrSubscription(
                          context,
                          title: 'Cope with Gwyn',
                          pageContext:
                              'The user opened Gwyn from the calm tools screen with grounding, breathing, drawing, meditations, affirmations, and reflection tools.',
                          suggestedPrompts: const [
                            'Help me calm down right now',
                            'Distract me from panic',
                            'Give me a grounding exercise',
                            'Tell me something reassuring',
                          ],
                          previewBeforeSubscription: true,
                          previewDialogMessage:
                              'Here you can chat with Gwyn about coping with anxiety. This preview uses built-in example responses so you can see how Gwyn replies before subscribing.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Easy you anxiety with one of these excercises',
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
                      _CopeHelpButton(
                        onTap: () {
                          final appState = context.read<AppState>();
                          _showCopeMethodsDialog(appState);
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
                  _SanctuaryCard(
                    title: "Draw & Guess",
                    desc:
                        "Sketch anything on the canvas and let Gwyn make a playful guess.",
                    icon: Icons.brush_rounded,
                    imageAsset: 'assets/images/gwyn-draw.png',
                    color: Colors.deepPurple.shade300,
                    onTap: () =>
                        _navigateToScreen(context, const DrawingGuessScreen()),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Leaf Exercise",
                    desc:
                        "Quietly watch leaves drifting to distract your mind.",
                    icon: Icons.eco_rounded,
                    color: Colors.green.shade600,
                    onTap: () =>
                        _navigateToScreen(context, const LeafExerciseScreen()),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Let Gwyn tell a joke",
                    desc: "Let Gwyn tell a good joke for a smile.",
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    imageAsset: 'assets/images/gwen_funny2.png',
                    color: Colors.orange.shade600,
                    onTap: () => openSubscribedFeatureOrSubscription(
                      context,
                      const GwynJokeScreen(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Grounding Sanctuary",
                    desc:
                        "Shift racing thoughts using the interactive 5-4-3-2-1 sensory awareness method.",
                    icon: Icons.filter_center_focus_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => _navigateToScreen(
                      context,
                      GroundingScreen(appState: appState),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Breathe Exercises",
                    desc:
                        "Practice guided breathing patterns to steady your body and calm your nervous system.",
                    icon: Icons.air_rounded,
                    color: Colors.teal.shade600,
                    onTap: () => _navigateToScreen(
                      context,
                      BreathingScreen(appState: appState),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Meditations",
                    desc:
                        "Play calming sound clips for breathing, drawing, grounding, or quiet rest.",
                    icon: Icons.spa_rounded,
                    color: Colors.indigo.shade400,
                    onTap: () =>
                        _navigateToScreen(context, const MeditationsScreen()),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Thought Diffuser",
                    desc:
                        "Defuse spiraling thoughts, inspect threat levels, and watch them drift away in a balloon.",
                    icon: Icons.bubble_chart_rounded,
                    color: Theme.of(context).colorScheme.tertiary,
                    onTap: () => _navigateToScreen(
                      context,
                      const ThoughtSupportScreen(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Affirmations",
                    desc:
                        "Choose gentle reminders for anxious moments and copy the words you want to keep nearby.",
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.pink.shade300,
                    onTap: () =>
                        _navigateToScreen(context, const AffirmationsScreen()),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Bubble Pop",
                    desc:
                        "Pop falling bubbles for a playful stress-release break with light taps and soft visuals.",
                    icon: Icons.bubble_chart_rounded,
                    color: Colors.cyan.shade600,
                    onTap: () =>
                        _navigateToScreen(context, const BubblePopScreen()),
                  ),
                  const SizedBox(height: 16),

                  _SanctuaryCard(
                    title: "Daily Reflection",
                    desc:
                        "Track trigger factors, write a brief sentence journal, or save local voice notes.",
                    icon: Icons.draw_rounded,
                    color: Colors.amber.shade700,
                    onTap: () => _navigateToScreen(
                      context,
                      ReflectionScreen(appState: appState),
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

class _VanquishWithGwynButton extends StatelessWidget {
  final VoidCallback onTap;

  const _VanquishWithGwynButton({required this.onTap});

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
              'Vanquish with Gwyn',
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

class _CopeHelpButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CopeHelpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Tooltip(
      message: 'How to cope with anxiety?',
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

class _SanctuaryCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final String? imageAsset;
  final Color color;
  final VoidCallback onTap;

  const _SanctuaryCard({
    required this.title,
    required this.desc,
    required this.icon,
    this.imageAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                child: imageAsset == null
                    ? Icon(icon, color: color, size: 26)
                    : ClipOval(
                        child: Image.asset(
                          imageAsset!,
                          width: 26,
                          height: 26,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(width: 18),
              Flexible(
                fit: FlexFit.loose,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
                color: isDark ? Colors.white30 : Colors.black.withAlpha(77),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
