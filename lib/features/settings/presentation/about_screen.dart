import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/widgets/glass_card.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final Set<int> _openSections = {};

  void _toggleSection(int index) {
    setState(() {
      if (_openSections.contains(index)) {
        _openSections.remove(index);
      } else {
        _openSections.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About this app'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AboutCard(
              title: 'Version',
              isOpen: _openSections.contains(0),
              onTap: () => _toggleSection(0),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  return Text(
                    'Gwyn - v$version',
                    style: _aboutTextStyle(context),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _AboutCard(
              title: 'Privacy & safety',
              isOpen: _openSections.contains(1),
              onTap: () => _toggleSection(1),
              child: Text(
                'Your data is saved locally on your phone and never shared with anyone.',
                style: _aboutTextStyle(context),
              ),
            ),
            const SizedBox(height: 14),
            _AboutCard(
              title: 'Who built this app?',
              isOpen: _openSections.contains(2),
              onTap: () => _toggleSection(2),
              child: Text(
                'This app is for anxiety relief, created by someone who has been struggling with anxiety for a long time. For more information see the website at http://www.mlmasters.com/gwyn',
                style: _aboutTextStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _aboutTextStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextStyle(
      fontSize: 14,
      height: 1.5,
      color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final bool isOpen;
  final VoidCallback onTap;
  final Widget child;

  const _AboutCard({
    required this.title,
    required this.isOpen,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: child,
              ),
              crossFadeState: isOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}
