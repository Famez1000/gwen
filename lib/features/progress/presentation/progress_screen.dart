import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../home/presentation/planning_destination_screen.dart';
import '../../profile/presentation/my_plans_screen.dart';
import '../../sanctuary/presentation/anxiety_persona_screen.dart';
import '../../sanctuary/presentation/my_truth_editor.dart';

class ProgressScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBack;
  final ValueChanged<int>? onDestinationSelected;

  const ProgressScreen({
    super.key,
    required this.appState,
    this.onBack,
    this.onDestinationSelected,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  void _handleDestinationSelected(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onDestinationSelected?.call(index);
  }

  Future<void> _markSwipeHintSeen() async {
    await widget.appState.markProgressSwipeHintSeen();
    if (mounted) setState(() {});
  }

  Future<void> _openUnderstandPlanning() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnderstandPlanningScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCopePlanning() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CopePlanningScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAnxietyPersona() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnxietyPersonaScreen(appState: widget.appState),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openHealPlanning() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealPlanningScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCopePlan(String planName, Color color) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CopePlanDetailScreen(planName: planName, color: color),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openUnderstandPlan(String planName, Color color) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UnderstandPlanDetailScreen(planName: planName, color: color),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openHealPlan(String planName, Color color) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealPlanDetailScreen(planName: planName, color: color),
      ),
    );
    if (mounted) setState(() {});
  }

  _ProgressMetric _dailyCopeMetric({
    required String activity,
    required String label,
    required IconData icon,
    bool automaticallyTracked = false,
    String? trackingScreenName,
  }) {
    final streak = widget.appState.copeActivityStreak(activity);
    final completedToday = widget.appState.isCopeActivityCompletedToday(
      activity,
    );
    final nextMilestone = streak < 3
        ? 3
        : streak < 7
        ? 7
        : streak < 14
        ? 14
        : 30;
    final reward = switch (streak) {
      >= 30 => '🏆 30-day champion reward',
      >= 14 => '💚 14-day reward earned',
      >= 7 => '⭐ 7-day reward earned',
      >= 3 => '🌱 3-day reward earned',
      _ => 'Next reward: $nextMilestone days',
    };

    return _ProgressMetric.dailyStreak(
      icon: icon,
      label: label,
      value: '$streak day${streak == 1 ? '' : 's'}',
      progress: (streak / nextMilestone).clamp(0, 1),
      goal: reward,
      isChecked: completedToday,
      onChecked: automaticallyTracked
          ? null
          : (value) async {
              await widget.appState.setCopeActivityCompletedToday(
                activity,
                value,
              );
              if (mounted) setState(() {});
            },
      onHelp: automaticallyTracked
          ? () => _showDailyCounterHelp(
              label,
              trackingScreenName ?? label.replaceFirst('Daily ', ''),
            )
          : null,
    );
  }

  _ProgressMetric _dailyUnderstandMetric({
    required String activity,
    required String label,
    required IconData icon,
    bool automaticallyTracked = false,
    String? trackingScreenName,
  }) {
    final streak = widget.appState.understandActivityStreak(activity);
    final completedToday = widget.appState.isUnderstandActivityCompletedToday(
      activity,
    );
    final nextMilestone = streak < 3
        ? 3
        : streak < 7
        ? 7
        : streak < 14
        ? 14
        : 30;
    final reward = switch (streak) {
      >= 30 => '🏆 30-day champion reward',
      >= 14 => '💚 14-day reward earned',
      >= 7 => '⭐ 7-day reward earned',
      >= 3 => '🌱 3-day reward earned',
      _ => 'Next reward: $nextMilestone days',
    };

    return _ProgressMetric.dailyStreak(
      icon: icon,
      label: label,
      value: '$streak day${streak == 1 ? '' : 's'}',
      progress: (streak / nextMilestone).clamp(0, 1),
      goal: reward,
      isChecked: completedToday,
      onChecked: automaticallyTracked
          ? null
          : (value) async {
              await widget.appState.setUnderstandActivityCompletedToday(
                activity,
                value,
              );
              if (mounted) setState(() {});
            },
      onHelp: automaticallyTracked
          ? () => _showDailyCounterHelp(
              label,
              trackingScreenName ?? label.replaceFirst('Daily ', ''),
              planArea: 'Understand plan',
            )
          : null,
    );
  }

  _ProgressMetric _dailyHealMetric({
    required String activity,
    required String label,
    required IconData icon,
    required String trackingScreenName,
  }) {
    final streak = widget.appState.healActivityStreak(activity);
    final completedToday = widget.appState.isHealActivityCompletedToday(
      activity,
    );
    final nextMilestone = streak < 3
        ? 3
        : streak < 7
        ? 7
        : streak < 14
        ? 14
        : 30;
    final reward = switch (streak) {
      >= 30 => '🏆 30-day champion reward',
      >= 14 => '💚 14-day reward earned',
      >= 7 => '⭐ 7-day reward earned',
      >= 3 => '🌱 3-day reward earned',
      _ => 'Next reward: $nextMilestone days',
    };

    return _ProgressMetric.dailyStreak(
      icon: icon,
      label: label,
      value: '$streak day${streak == 1 ? '' : 's'}',
      progress: (streak / nextMilestone).clamp(0, 1),
      goal: reward,
      isChecked: completedToday,
      onChecked: null,
      onHelp: () => _showDailyCounterHelp(
        label,
        trackingScreenName,
        planArea: 'Heal plan',
      ),
    );
  }

  void _showDailyCounterHelp(
    String label,
    String screenName, {
    String planArea = 'Cope',
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$label counter'),
        content: Text(
          'The counter increases once when you open the $screenName screen from $planArea on a new day. Opening it more than once on the same day still counts as one day. Consecutive days build your streak and unlock rewards.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final copeProgress = widget.appState.copePlanNames.isEmpty
        ? [
            _ProgressMetric.action(
              icon: Icons.add_circle_outline_rounded,
              label: 'No plan yet, click to create one',
              onTap: _openCopePlanning,
            ),
          ]
        : [
            _ProgressMetric.checklist(
              icon: Icons.fact_check_rounded,
              label: 'My Truth',
              isChecked: widget.appState.moodRealityText.trim().isNotEmpty,
              onTap: () async {
                await showMyTruthEditor(context, widget.appState);
                if (mounted) setState(() {});
              },
            ),
            _ProgressMetric.checklist(
              icon: Icons.visibility_rounded,
              label: 'Persona',
              isChecked: widget.appState.hasAnxietyPersona,
              onTap: _openAnxietyPersona,
            ),
            _dailyCopeMetric(
              activity: AppState.copeAffirmationsActivity,
              label: 'Affirmations',
              icon: Icons.record_voice_over_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Affirmations',
            ),
            _dailyCopeMetric(
              activity: AppState.copeGroundingActivity,
              label: 'Grounding',
              icon: Icons.filter_center_focus_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Grounding',
            ),
            _dailyCopeMetric(
              activity: AppState.copeMeditationsActivity,
              label: 'Meditations',
              icon: Icons.self_improvement_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Meditations',
            ),
            _dailyCopeMetric(
              activity: AppState.copeLeafActivity,
              label: 'Mind distraction',
              icon: Icons.eco_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Leaf Exercise',
            ),
          ];
    final understandProgress = widget.appState.understandPlanNames.isEmpty
        ? [
            _ProgressMetric.action(
              icon: Icons.add_circle_outline_rounded,
              label: 'No plan yet, click to create one',
              onTap: _openUnderstandPlanning,
            ),
          ]
        : [
            _dailyUnderstandMetric(
              activity: AppState.understandBodySignalsActivity,
              label: 'Body Signals',
              icon: Icons.monitor_heart_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Body Signals',
            ),
            _dailyUnderstandMetric(
              activity: AppState.understandTriggersActivity,
              label: 'Triggers',
              icon: Icons.bolt_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Triggers',
            ),
            _dailyUnderstandMetric(
              activity: AppState.understandPatternsActivity,
              label: 'Patterns',
              icon: Icons.insights_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Patterns',
            ),
            _dailyUnderstandMetric(
              activity: AppState.understandAskYourselfActivity,
              label: 'Ask yourself',
              icon: Icons.question_answer_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Ask yourself',
            ),
            _dailyUnderstandMetric(
              activity: AppState.understandJournalActivity,
              label: 'Journal',
              icon: Icons.menu_book_rounded,
              automaticallyTracked: true,
              trackingScreenName: 'Journal',
            ),
          ];
    final healProgress = widget.appState.healPlanNames.isEmpty
        ? [
            _ProgressMetric.action(
              icon: Icons.add_circle_outline_rounded,
              label: 'No plan yet, click to create one',
              onTap: _openHealPlanning,
            ),
          ]
        : [
            _dailyHealMetric(
              activity: AppState.healJournalActivity,
              label: 'Journal',
              icon: Icons.book_rounded,
              trackingScreenName: 'Journal',
            ),
            _dailyHealMetric(
              activity: AppState.healAcceptanceActivity,
              label: 'Acceptance',
              icon: Icons.favorite_rounded,
              trackingScreenName: 'Acceptance',
            ),
            _dailyHealMetric(
              activity: AppState.healForgivenessActivity,
              label: 'Forgiveness',
              icon: Icons.volunteer_activism_rounded,
              trackingScreenName: 'Forgiveness',
            ),
            _dailyHealMetric(
              activity: AppState.healMeditationsActivity,
              label: 'Meditations',
              icon: Icons.self_improvement_rounded,
              trackingScreenName: 'Meditations',
            ),
          ];

    return Scaffold(
      bottomNavigationBar: _ProgressBottomBar(
        onDestinationSelected: _handleDestinationSelected,
      ),
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
                          'Your Progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HorizontalProgressSection(
                      title: 'Cope',
                      subtitle:
                          'Shows the progress according to the coping plan',
                      color: primaryColor,
                      headerIcon: Icons.spa_rounded,
                      metrics: copeProgress,
                      planLabel: widget.appState.copePlanNames.isEmpty
                          ? null
                          : 'My Cope plan',
                      onPlanTap: widget.appState.copePlanNames.isEmpty
                          ? null
                          : () => _openCopePlan(
                              widget.appState.copePlanNames.first,
                              primaryColor,
                            ),
                      showSwipeHint: !widget.appState.progressSwipeHintSeen,
                      onSwiped: _markSwipeHintSeen,
                    ),
                    const SizedBox(height: 24),
                    _HorizontalProgressSection(
                      title: 'Understand',
                      subtitle: 'The patterns you are noticing',
                      color: Colors.amber.shade700,
                      headerIcon: Icons.lightbulb_rounded,
                      metrics: understandProgress,
                      planLabel: widget.appState.understandPlanNames.isEmpty
                          ? null
                          : 'My Understand plan',
                      onPlanTap: widget.appState.understandPlanNames.isEmpty
                          ? null
                          : () => _openUnderstandPlan(
                              widget.appState.understandPlanNames.first,
                              Colors.amber.shade700,
                            ),
                      showSwipeHint: !widget.appState.progressSwipeHintSeen,
                      onSwiped: _markSwipeHintSeen,
                    ),
                    const SizedBox(height: 24),
                    _HorizontalProgressSection(
                      title: 'Heal',
                      subtitle: 'Your healing progress is shown here',
                      color: Colors.teal.shade500,
                      headerImageAsset: 'assets/images/resilient-health.png',
                      metrics: healProgress,
                      planLabel: widget.appState.healPlanNames.isEmpty
                          ? null
                          : 'My Heal plan',
                      onPlanTap: widget.appState.healPlanNames.isEmpty
                          ? null
                          : () => _openHealPlan(
                              widget.appState.healPlanNames.first,
                              Colors.teal.shade500,
                            ),
                      showSwipeHint: !widget.appState.progressSwipeHintSeen,
                      onSwiped: _markSwipeHintSeen,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBottomBar extends StatelessWidget {
  final ValueChanged<int> onDestinationSelected;

  const _ProgressBottomBar({required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final unselectedColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(13)
                : Colors.black.withAlpha(13),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: isDark ? const Color(0xFF0F131E) : Colors.white,
        indicatorColor: primaryColor.withAlpha(31),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 66,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: unselectedColor),
            selectedIcon: Icon(Icons.home_rounded, color: primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined, color: unselectedColor),
            selectedIcon: Icon(Icons.spa_rounded, color: primaryColor),
            label: 'Cope',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined, color: unselectedColor),
            selectedIcon: Icon(Icons.book, color: primaryColor),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline, color: unselectedColor),
            selectedIcon: Icon(Icons.lightbulb_rounded, color: primaryColor),
            label: 'Understand',
          ),
          NavigationDestination(
            icon: ImageIcon(
              const AssetImage('assets/images/resilient-health.png'),
              color: unselectedColor,
            ),
            selectedIcon: ImageIcon(
              const AssetImage('assets/images/resilient-health.png'),
              color: primaryColor,
            ),
            label: 'Heal',
          ),
        ],
      ),
    );
  }
}

class _AnxietyChartPoint {
  final DateTime date;
  final int score;

  const _AnxietyChartPoint({required this.date, required this.score});
}

class _ProgressMetric {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final String goal;
  final VoidCallback? onTap;
  final bool isChecklist;
  final bool? isChecked;
  final ValueChanged<bool>? onChecked;
  final VoidCallback? onHelp;
  final double width;

  const _ProgressMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.goal,
  }) : onTap = null,
       isChecklist = false,
       isChecked = null,
       onChecked = null,
       onHelp = null,
       width = 190;

  const _ProgressMetric.action({
    required this.icon,
    required this.label,
    required this.onTap,
  }) : value = '',
       progress = 0,
       goal = '',
       isChecklist = false,
       isChecked = null,
       onChecked = null,
       onHelp = null,
       width = 190;

  const _ProgressMetric.checklist({
    required this.icon,
    required this.label,
    required this.isChecked,
    required this.onTap,
  }) : value = '',
       progress = 0,
       goal = '',
       onChecked = null,
       onHelp = null,
       isChecklist = true,
       width = 95;

  const _ProgressMetric.dailyStreak({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.goal,
    required this.isChecked,
    required this.onChecked,
    this.onHelp,
  }) : onTap = null,
       isChecklist = false,
       width = 190;
}

class _HorizontalProgressSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData? headerIcon;
  final String? headerImageAsset;
  final List<_ProgressMetric> metrics;
  final String? planLabel;
  final VoidCallback? onPlanTap;
  final bool showSwipeHint;
  final VoidCallback onSwiped;

  const _HorizontalProgressSection({
    required this.title,
    required this.subtitle,
    required this.color,
    this.headerIcon,
    this.headerImageAsset,
    required this.metrics,
    this.planLabel,
    this.onPlanTap,
    required this.showSwipeHint,
    required this.onSwiped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (headerImageAsset != null)
                        ImageIcon(
                          AssetImage(headerImageAsset!),
                          color: color,
                          size: 24,
                        )
                      else if (headerIcon != null)
                        Icon(headerIcon, color: color, size: 24),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (planLabel != null)
                        InkWell(
                          onTap: onPlanTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            child: Text(
                              planLabel!,
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (showSwipeHint)
              Icon(Icons.swipe_rounded, size: 19, color: color.withAlpha(180)),
          ],
        ),
        const SizedBox(height: 12),
        NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (showSwipeHint && notification.scrollDelta != 0) {
              onSwiped();
            }
            return false;
          },
          child: SizedBox(
            height: 176,
            child: LayoutBuilder(
              builder: (_, _) {
                final cardsWidth = metrics.fold<double>(
                  0,
                  (width, metric) => width + metric.width,
                );
                final gapsWidth = (metrics.length - 1) * 12.0;
                final naturalWidth = cardsWidth + gapsWidth + 24;

                return SingleChildScrollView(
                  key: ValueKey('${title.toLowerCase()}-progress-scroll'),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    width: naturalWidth,
                    height: 176,
                    padding: const EdgeInsets.all(10),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 36 : 22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withAlpha(isDark ? 145 : 100),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final entry in metrics.indexed) ...[
                          if (entry.$1 > 0) const SizedBox(width: 12),
                          SizedBox(
                            width: entry.$2.width,
                            height: double.infinity,
                            child: _ProgressMetricCard(
                              metric: entry.$2,
                              color: color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressMetricCard extends StatelessWidget {
  final _ProgressMetric metric;
  final Color color;

  const _ProgressMetricCard({required this.metric, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = metric.progress.clamp(0.0, 1.0);

    final card = GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.all(metric.isChecklist ? 10 : 16),
      border: Border.all(color: color.withAlpha(isDark ? 65 : 50)),
      child: metric.isChecklist
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(metric.icon, color: color, size: 25),
                const SizedBox(height: 6),
                Text(
                  metric.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                IgnorePointer(
                  child: Checkbox(
                    key: ValueKey('${metric.label}-completion-checkbox'),
                    value: metric.isChecked ?? false,
                    onChanged: (_) {},
                    activeColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            )
          : metric.onTap != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(metric.icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(
                  metric.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(metric.icon, color: color, size: 21),
                    const Spacer(),
                    Text(
                      metric.value,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (metric.onHelp != null) ...[
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          tooltip: 'How this counter works',
                          onPressed: metric.onHelp,
                          padding: EdgeInsets.zero,
                          iconSize: 21,
                          color: color,
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                      ),
                    ] else if (metric.onChecked != null) ...[
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Checkbox(
                          value: metric.isChecked ?? false,
                          onChanged: (value) {
                            if (value != null) metric.onChecked?.call(value);
                          },
                          activeColor: color,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(14),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  metric.goal,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
    );

    if (metric.onTap == null) return card;
    return Semantics(
      button: true,
      label: metric.label,
      child: GestureDetector(onTap: metric.onTap, child: card),
    );
  }
}

// Kept available for a future detailed trend view outside this overview.
// ignore: unused_element
class _MonthlyAnxietyChart extends StatelessWidget {
  final List<_AnxietyChartPoint> points;
  final Color color;
  final bool isDark;

  const _MonthlyAnxietyChart({
    required this.points,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final mutedColor = isDark ? Colors.white38 : Colors.black38;
    final gridColor = isDark
        ? Colors.white.withAlpha(18)
        : Colors.black.withAlpha(16);

    return CustomPaint(
      painter: _MonthlyAnxietyChartPainter(
        points: points,
        color: color,
        textColor: textColor,
        mutedColor: mutedColor,
        gridColor: gridColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MonthlyAnxietyChartPainter extends CustomPainter {
  final List<_AnxietyChartPoint> points;
  final Color color;
  final Color textColor;
  final Color mutedColor;
  final Color gridColor;

  _MonthlyAnxietyChartPainter({
    required this.points,
    required this.color,
    required this.textColor,
    required this.mutedColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 34.0;
    const rightPadding = 10.0;
    const topPadding = 12.0;
    const bottomPadding = 32.0;

    final chartLeft = leftPadding;
    final chartTop = topPadding;
    final chartRight = size.width - rightPadding;
    final chartBottom = size.height - bottomPadding;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final axisPaint = Paint()
      ..color = mutedColor
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (final score in [0, 2, 4, 6, 8, 10]) {
      final y = chartBottom - (score / 10) * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _drawText(
        canvas,
        score.toString(),
        Offset(0, y - 8),
        mutedColor,
        fontSize: 10,
        width: leftPadding - 7,
        textAlign: TextAlign.right,
      );
    }

    canvas.drawLine(
      Offset(chartLeft, chartTop),
      Offset(chartLeft, chartBottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      axisPaint,
    );

    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month, today.day);
    final startDate = endDate.subtract(const Duration(days: 29));
    final midDate = startDate.add(const Duration(days: 15));

    _drawXLabel(
      canvas,
      _formatAxisDate(startDate),
      chartLeft,
      chartBottom + 10,
    );
    _drawXLabel(
      canvas,
      _formatAxisDate(midDate),
      chartLeft + chartWidth / 2,
      chartBottom + 10,
      centered: true,
    );
    _drawXLabel(
      canvas,
      _formatAxisDate(endDate),
      chartRight,
      chartBottom + 10,
      rightAligned: true,
    );

    if (points.isEmpty) {
      _drawText(
        canvas,
        'No scores yet',
        Offset(chartLeft, chartTop + chartHeight / 2 - 10),
        mutedColor,
        fontSize: 13,
        width: chartWidth,
        textAlign: TextAlign.center,
      );
      return;
    }

    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final dayOffset = point.date.difference(startDate).inDays.clamp(0, 29);
      final x = chartLeft + (dayOffset / 29) * chartWidth;
      final y = chartBottom - (point.score.clamp(0, 10) / 10) * chartHeight;

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      final dayOffset = point.date.difference(startDate).inDays.clamp(0, 29);
      final x = chartLeft + (dayOffset / 29) * chartWidth;
      final y = chartBottom - (point.score.clamp(0, 10) / 10) * chartHeight;
      canvas.drawCircle(Offset(x, y), 4.5, pointPaint);
      canvas.drawCircle(Offset(x, y), 4.5, pointBorderPaint);
    }
  }

  void _drawXLabel(
    Canvas canvas,
    String text,
    double x,
    double y, {
    bool centered = false,
    bool rightAligned = false,
  }) {
    const width = 48.0;
    final dx = rightAligned
        ? x - width
        : centered
        ? x - width / 2
        : x;
    _drawText(
      canvas,
      text,
      Offset(dx, y),
      mutedColor,
      fontSize: 10,
      width: width,
      textAlign: rightAligned
          ? TextAlign.right
          : centered
          ? TextAlign.center
          : TextAlign.left,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    required double fontSize,
    required double width,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  String _formatAxisDate(DateTime date) => '${date.month}/${date.day}';

  @override
  bool shouldRepaint(covariant _MonthlyAnxietyChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.gridColor != gridColor;
  }
}
