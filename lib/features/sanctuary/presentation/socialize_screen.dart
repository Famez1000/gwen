import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class SocializeScreen extends StatelessWidget {
  const SocializeScreen({super.key});

  static const _options = [
    _SocializeOption(
      title: 'WhatsApp',
      description: 'Message someone you trust.',
      icon: Icons.chat_rounded,
      color: Color(0xFF25A866),
    ),
    _SocializeOption(
      title: 'Phone',
      description: 'Call a friend or family member.',
      icon: Icons.phone_rounded,
      color: Color(0xFF3F7EDB),
    ),
    _SocializeOption(
      title: 'Gaming',
      description: 'Play something together.',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFF7E57C2),
    ),
    _SocializeOption(
      title: 'Talk to Gwyn',
      description: 'Share what is on your mind.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFE88A3D),
    ),
    _SocializeOption(
      title: 'Go to the Supermarket',
      description: 'Get out and be around people.',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFF2E9D78),
    ),
    _SocializeOption(
      title: 'Go Dancing',
      description: 'Move and connect through music.',
      icon: Icons.music_note_rounded,
      color: Color(0xFFD64F86),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Socialize'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a simple way to connect with someone.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  itemCount: _options.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) =>
                      _SocializeCard(option: _options[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocializeCard extends StatelessWidget {
  final _SocializeOption option;

  const _SocializeCard({required this.option});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: option.color.withAlpha(32),
            ),
            child: Icon(option.icon, color: option.color, size: 29),
          ),
          const SizedBox(height: 13),
          Text(
            option.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            option.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocializeOption {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _SocializeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
