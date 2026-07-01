import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceText = isDark ? Colors.white : Colors.black87;
    final mutedText = isDark ? Colors.white70 : Colors.black.withAlpha(153);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Gwen Plus',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF191A2A),
                          Color(0xFF1F2933),
                          Color(0xFF172826),
                        ]
                      : const [
                          Color(0xFFF1EEFF),
                          Color(0xFFF9F7F1),
                          Color(0xFFE9F6F2),
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withAlpha(128)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Unlock Gwen support',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: surfaceText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Get access to Gwen conversations and supportive guidance throughout the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Text(
                        '\$5.99',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: surfaceText,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'per month',
                        style: TextStyle(
                          color: mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _BenefitLine(
                        icon: Icons.chat_bubble_rounded,
                        text: 'Chat with Gwen from supportive app moments',
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _BenefitLine(
                        icon: Icons.favorite_rounded,
                        text: 'Gentle anxiety support when you need it',
                        color: Colors.pink.shade300,
                      ),
                      const SizedBox(height: 12),
                      _BenefitLine(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Personalized reflections and next steps',
                        color: Colors.teal.shade500,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment setup is coming next.'),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Subscribe'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _BenefitLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
