import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../subscription/application/subscription_gate.dart';
import 'ask_yourself_screen.dart';
import 'body_signals_screen.dart';
import 'faq_screen.dart';
import 'patterns_screen.dart';
import 'thoughts_screen.dart';
import 'triggers_screen.dart';

class UnderstandScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const UnderstandScreen({super.key, this.onBack});

  void _openSubscription(BuildContext context) {
    openGwenChatOrSubscription(
      context,
      title: 'Understand with Gwen',
      pageContext:
          'The user opened Gwen from the anxiety learning overview screen.',
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
                        onPressed: onBack ?? () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Why feel anxious?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _AskGwenButton(onTap: () => _openSubscription(context)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Try to understand the reason for your anxiety',
                    style: TextStyle(
                      fontSize: 13,
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
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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

class _AskGwenButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AskGwenButton({required this.onTap});

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
              'Understand with Gwen',
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
