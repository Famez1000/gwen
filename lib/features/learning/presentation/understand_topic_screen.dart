import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../subscription/application/subscription_gate.dart';

class UnderstandTopicScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<UnderstandTopicSection> sections;
  final List<String> reflectionPrompts;
  final String gwenContext;

  const UnderstandTopicScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.sections,
    required this.reflectionPrompts,
    required this.gwenContext,
  });

  void _openSubscription(BuildContext context) {
    openGwenChatOrSubscription(
      context,
      title: '$title with Gwen',
      pageContext: gwenContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withAlpha(31),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TopicSectionCard(section: section),
                  ),
                ),
                if (reflectionPrompts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ask yourself',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reflectionPrompts.map(
                    (prompt) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PromptCard(prompt: prompt, color: color),
                    ),
                  ),
                ],
              ],
            ),
            Positioned(
              top: 6,
              left: 16,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withAlpha(13)
                      : Colors.black.withAlpha(8),
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Positioned(
              top: 6,
              right: 16,
              child: _AskGwenButton(onTap: () => _openSubscription(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class UnderstandTopicSection {
  final String title;
  final String body;

  const UnderstandTopicSection({required this.title, required this.body});
}

class _TopicSectionCard extends StatelessWidget {
  final UnderstandTopicSection section;

  const _TopicSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String prompt;
  final Color color;

  const _PromptCard({required this.prompt, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: color.withAlpha(isDark ? 28 : 20),
      child: Row(
        children: [
          Icon(Icons.help_outline_rounded, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prompt,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
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
