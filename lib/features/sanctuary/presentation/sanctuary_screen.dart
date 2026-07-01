import 'package:flutter/material.dart';
import '../../affirmations/presentation/affirmations_screen.dart';
import '../../breathing/presentation/breathing_screen.dart';
import '../../bubble_pop/presentation/bubble_pop_screen.dart';
import '../../drawing_guess/presentation/drawing_guess_screen.dart';
import '../../grounding/presentation/grounding_screen.dart';
import '../../meditations/presentation/meditations_screen.dart';
import '../../reflection/presentation/reflection_screen.dart';
import '../../subscription/presentation/subscription_screen.dart';
import '../../thought_support/presentation/thought_support_screen.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import 'leaf_exercise_screen.dart';

import 'package:provider/provider.dart';

class SanctuaryScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const SanctuaryScreen({super.key, this.onBack});

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
                        onPressed: onBack ?? () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Calm your mind",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _VanquishWithGwenButton(
                        onTap: () => _navigateToScreen(
                          context,
                          const SubscriptionScreen(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Easy you anxiety with one of these excercises',
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  _SanctuaryCard(
                    title: "Draw & Guess",
                    desc:
                        "Sketch anything on the canvas and let Gwen make a playful guess.",
                    icon: Icons.brush_rounded,
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
                    title: "Let Gwen tell you a joke",
                    desc:
                        "Let Gwen find a gentle, relaxing joke for a small smile.",
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    imageAsset: 'assets/images/gwen_funny2.png',
                    color: Colors.orange.shade600,
                    onTap: () =>
                        _navigateToScreen(context, const SubscriptionScreen()),
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

class _VanquishWithGwenButton extends StatelessWidget {
  final VoidCallback onTap;

  const _VanquishWithGwenButton({required this.onTap});

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
              'Vanquish with Gwen',
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
