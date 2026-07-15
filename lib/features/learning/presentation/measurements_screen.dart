import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../gad7/presentation/gad7_screen.dart';

class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  void _openGad7(BuildContext context) {
    final appState = context.read<AppState>();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GAD7Screen(appState: appState)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurements'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Standard tools',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Use these questionnaires to notice patterns over time. They are not a diagnosis.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white60 : Colors.black.withAlpha(153),
              ),
            ),
            const SizedBox(height: 18),
            _MeasurementToolCard(
              title: 'GAD-7',
              description:
                  'A 7-question screening tool for anxiety symptoms over the last two weeks.',
              icon: Icons.fact_check_rounded,
              color: primaryColor,
              onTap: () => _openGad7(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementToolCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MeasurementToolCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark
                          ? Colors.white60
                          : Colors.black.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
