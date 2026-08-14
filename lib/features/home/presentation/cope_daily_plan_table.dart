import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../affirmations/presentation/affirmations_screen.dart';
import '../../grounding/presentation/grounding_screen.dart';
import '../../meditations/presentation/meditations_screen.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../sanctuary/presentation/anxiety_persona_screen.dart';
import '../../sanctuary/presentation/leaf_exercise_screen.dart';
import '../../sanctuary/presentation/my_truth_editor.dart';

class CopeDailyPlanTable extends StatefulWidget {
  final Color color;

  const CopeDailyPlanTable({super.key, required this.color});

  @override
  State<CopeDailyPlanTable> createState() => _CopeDailyPlanTableState();
}

class _CopeDailyPlanTableState extends State<CopeDailyPlanTable> {
  late final Future<List<DailyReminderSchedule>> _remindersFuture;

  @override
  void initState() {
    super.initState();
    _remindersFuture = NotificationService.instance.loadPlanReminderSchedules(
      'cope',
    );
  }

  void _openTool(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
                    'Gwyn has created $reminderCount reminders for you to help you with this',
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
                      _HeaderCell('Planned Activities'),
                      _HeaderCell('Methods', centered: true),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'Write down your truth in this app and on a piece of paper and always carry it around',
                      ),
                      _MethodCell(
                        label: 'My Truth',
                        icon: Icons.fact_check_rounded,
                        color: Colors.green.shade600,
                        onTap: () => showMyTruthEditor(
                          context,
                          context.read<AppState>(),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'Give your anxious thoughts a face and a name so you can separate them from yourself',
                      ),
                      _MethodCell(
                        label: 'Create persona',
                        icon: Icons.visibility_rounded,
                        color: Colors.amber.shade700,
                        onTap: () => _openTool(
                          AnxietyPersonaScreen(
                            appState: context.read<AppState>(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'In the morning start with affirmations to shape a positive mindset for the day',
                      ),
                      _MethodCell(
                        label: 'Affirmations',
                        icon: Icons.record_voice_over_rounded,
                        color: Colors.blue.shade500,
                        onTap: () => _openTool(const AffirmationsScreen()),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'Around noon do a grounding exercise to reduce stress',
                      ),
                      _MethodCell(
                        label: 'Grounding',
                        icon: Icons.filter_center_focus_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        onTap: () => _openTool(
                          GroundingScreen(appState: context.read<AppState>()),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'In the evening do a meditation when there is time to relax',
                      ),
                      _MethodCell(
                        label: 'Meditations',
                        icon: Icons.self_improvement_rounded,
                        color: Colors.indigo.shade400,
                        onTap: () => _openTool(const MeditationsScreen()),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _ActivityCell(
                        'Throughout the day, distract your mind whenever anxiety rises',
                      ),
                      _MethodCell(
                        label: 'Leaf Exercise',
                        icon: Icons.eco_rounded,
                        color: Colors.green.shade600,
                        onTap: () => _openTool(const LeafExerciseScreen()),
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
  final String? linkText;
  final VoidCallback? onLinkTap;

  const _MessageRow({required this.text, this.linkText, this.onLinkTap});

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
          if (linkText != null)
            InkWell(
              onTap: onLinkTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  linkText!,
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
