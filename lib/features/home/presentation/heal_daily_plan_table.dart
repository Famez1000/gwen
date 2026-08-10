import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../heal/presentation/acceptance_screen.dart';
import '../../heal/presentation/forgiveness_screen.dart';
import '../../journaling/presentation/journaling_screen.dart';
import '../../meditations/presentation/meditations_screen.dart';
import '../../reminders/presentation/reminders_screen.dart';

class HealDailyPlanTable extends StatefulWidget {
  final Color color;

  const HealDailyPlanTable({super.key, required this.color});

  @override
  State<HealDailyPlanTable> createState() => _HealDailyPlanTableState();
}

class _HealDailyPlanTableState extends State<HealDailyPlanTable> {
  late final Future<List<DailyReminderSchedule>> _remindersFuture;

  @override
  void initState() {
    super.initState();
    _remindersFuture = NotificationService.instance.loadPlanReminderSchedules(
      'heal',
    );
  }

  Future<void> _openTool(Widget screen, {String? activity}) async {
    if (activity != null) {
      await context.read<AppState>().setHealActivityCompletedToday(
        activity,
        true,
      );
      if (!mounted) return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyReminderSchedule>>(
      future: _remindersFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final borderColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : Colors.black54;
        final headerColor = Theme.of(context).brightness == Brightness.dark
            ? widget.color.withAlpha(65)
            : const Color(0xFFDCE8C4);
        final reminderCount = snapshot.data!.length;

        return GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 8,
          border: Border.all(color: borderColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MessageRow(
                text:
                    'Gwyn has created $reminderCount reminders for you to help you heal',
                linkText: '(click to open)',
                onLinkTap: () => _openTool(const RemindersScreen()),
              ),
              Divider(height: 1, thickness: 1, color: borderColor),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.65),
                  1: FlexColumnWidth(1),
                },
                border: TableBorder(
                  verticalInside: BorderSide(color: borderColor),
                  horizontalInside: BorderSide(color: borderColor),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: headerColor),
                    children: const [
                      _HeaderCell('Daily Activities'),
                      _HeaderCell('Methods', centered: true),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'Reflect on the insights from the Understand phase',
                      ),
                      _MethodCell(
                        label: 'Journal',
                        icon: Icons.book_rounded,
                        color: widget.color,
                        onTap: () => _openTool(
                          JournalingScreen(appState: context.read<AppState>()),
                          activity: AppState.healJournalActivity,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'Let go of what has been worrying you',
                      ),
                      _MethodCell(
                        label: 'Acceptance',
                        icon: Icons.favorite_rounded,
                        color: Colors.pink.shade300,
                        onTap: () => _openTool(
                          const AcceptanceScreen(),
                          activity: AppState.healAcceptanceActivity,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell('Forgive what needs to be forgiven'),
                      _MethodCell(
                        label: 'Forgiveness',
                        icon: Icons.volunteer_activism_rounded,
                        color: Colors.orange.shade600,
                        onTap: () => _openTool(
                          const ForgivenessScreen(),
                          activity: AppState.healForgivenessActivity,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'In the evening, meditate on the next steps you can take to further vanquish your anxiety',
                      ),
                      _MethodCell(
                        label: 'Meditations',
                        icon: Icons.self_improvement_rounded,
                        color: Colors.indigo.shade400,
                        onTap: () => _openTool(
                          const MeditationsScreen(),
                          activity: AppState.healMeditationsActivity,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onLinkTap;

  const _MessageRow({
    required this.text,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w900,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Wrap(
        spacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: textStyle),
          InkWell(
            onTap: onLinkTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                linkText,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool centered;

  const _HeaderCell(this.text, {this.centered = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActivityCell extends StatelessWidget {
  final String text;

  const _ActivityCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
    );
  }
}

class _MethodCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MethodCell({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
