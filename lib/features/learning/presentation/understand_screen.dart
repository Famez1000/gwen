import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../subscription/application/subscription_gate.dart';
import 'ask_yourself_screen.dart';
import 'body_signals_screen.dart';
import 'faq_screen.dart';
import 'measurements_screen.dart';
import 'patterns_screen.dart';
import 'thoughts_screen.dart';
import 'triggers_screen.dart';

class UnderstandScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isActive;

  const UnderstandScreen({super.key, this.onBack, this.isActive = true});

  @override
  State<UnderstandScreen> createState() => _UnderstandScreenState();
}

class _UnderstandScreenState extends State<UnderstandScreen> {
  bool _isUnderstandPopupShowing = false;

  @override
  void didUpdateWidget(covariant UnderstandScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _showUnderstandPopupAfterTabSelection();
    }
  }

  void _showUnderstandPopupAfterTabSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isUnderstandPopupShowing) return;

      final appState = context.read<AppState>();
      if (appState.hideUnderstandMethodsMessage) return;

      _isUnderstandPopupShowing = true;
      _showUnderstandMethodsDialog(appState).whenComplete(() {
        _isUnderstandPopupShowing = false;
      });
    });
  }

  void _openSubscription(BuildContext context) {
    openGwynChatOrSubscription(
      context,
      title: 'Understand with Gwyn',
      pageContext:
          'The user opened Gwyn from the anxiety learning overview screen.',
      suggestedPrompts: const [
        'Why does anxiety happen?',
        'Help me understand my triggers',
        'What are body signals?',
        'How do I spot anxious thoughts?',
      ],
      showGwynHeader: false,
      previewBeforeSubscription: true,
      previewDialogMessage:
          'Here you can chat with Gwyn about understanding anxiety. This preview uses built-in example responses so you can see how Gwyn replies before subscribing.',
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
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

  Future<void> _showUnderstandMethodsDialog(AppState appState) async {
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
                'How to understand anxiety?',
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
                      'Understanding anxiety starts with noticing what happens before, during, and after it. Your body signals, thoughts, triggers, and patterns can show you what your nervous system is trying to protect you from.',
                      style: TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Explore one area at a time. Small observations can make anxiety feel less mysterious and give you clearer choices for what to do next.',
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
                      await appState.setHideUnderstandMethodsMessage(true);
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

    final tiles = [
      _UnderstandTileData(
        title: 'Body Signals',
        description: 'Notice what anxiety feels like.',
        icon: Icons.monitor_heart_rounded,
        color: Colors.pink.shade300,
        onTap: () => _openScreen(context, const BodySignalsScreen()),
      ),
      _UnderstandTileData(
        title: 'Thoughts',
        description: 'Spot anxious thinking loops.',
        icon: Icons.psychology_alt_rounded,
        color: Colors.deepPurple.shade300,
        onTap: () => _openScreen(context, const ThoughtsScreen()),
      ),
      _UnderstandTileData(
        title: 'Triggers',
        description: 'Learn what tends to spark anxiety.',
        icon: Icons.bolt_rounded,
        color: Colors.amber.shade700,
        onTap: () => _openScreen(context, const TriggersScreen()),
      ),
      _UnderstandTileData(
        title: 'Patterns',
        description: 'See what changes over time.',
        icon: Icons.insights_rounded,
        color: Colors.indigo.shade400,
        onTap: () => _openScreen(context, const PatternsScreen()),
      ),
      _UnderstandTileData(
        title: 'Measurements',
        description: 'Use standard anxiety check-ins.',
        icon: Icons.assignment_turned_in_rounded,
        color: Colors.blueGrey.shade500,
        onTap: () => _openScreen(context, const MeasurementsScreen()),
      ),
      _UnderstandTileData(
        title: 'Ask yourself',
        description: 'Reflect with a gentle question.',
        icon: Icons.self_improvement_rounded,
        color: Colors.teal.shade600,
        onTap: () => _openScreen(context, const AskYourselfScreen()),
      ),
      _UnderstandTileData(
        title: 'FAQ',
        description: 'Common questions about anxiety.',
        icon: Icons.quiz_rounded,
        color: Theme.of(context).primaryColor,
        onTap: () => _openScreen(context, const FaqScreen()),
      ),
    ];

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
                          'Understand anxiety',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _AskGwynButton(onTap: () => _openSubscription(context)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Try to understand the reason for your anxiety',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white60
                                : Colors.black.withAlpha(153),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _UnderstandHelpButton(
                        onTap: () {
                          final appState = context.read<AppState>();
                          _showUnderstandMethodsDialog(appState);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: tiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.98,
                ),
                itemBuilder: (context, index) {
                  return _UnderstandTile(data: tiles[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskGwynButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AskGwynButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
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
              'Understand with Gwyn',
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

class _UnderstandHelpButton extends StatelessWidget {
  final VoidCallback onTap;

  const _UnderstandHelpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Tooltip(
      message: 'How to understand anxiety?',
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

class _UnderstandTile extends StatelessWidget {
  final _UnderstandTileData data;

  const _UnderstandTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: data.onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: data.color.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.color, size: 25),
            ),
            const Spacer(),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              data.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: isDark ? Colors.white60 : Colors.black.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnderstandTileData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _UnderstandTileData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });
}
