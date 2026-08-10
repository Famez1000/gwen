import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/global_sound_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../home/presentation/cope_daily_plan_table.dart';
import '../../home/presentation/heal_daily_plan_table.dart';
import '../../home/presentation/planning_destination_screen.dart';
import '../../home/presentation/understand_daily_plan_table.dart';

class MyPlansScreen extends StatelessWidget {
  final ValueChanged<int>? onDestinationSelected;

  const MyPlansScreen({super.key, this.onDestinationSelected});

  void _handleDestinationSelected(BuildContext context, int index) {
    final destinationCallback = onDestinationSelected;
    Navigator.of(context).popUntil((route) => route.isFirst);
    destinationCallback?.call(index);
  }

  String? _preferredPlanName(
    List<String> names,
    bool Function(String name) isActive,
  ) {
    if (names.isEmpty) return null;
    for (final name in names) {
      if (isActive(name)) return name;
    }
    return names.first;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final appState = context.watch<AppState>();
    final understandColor = Colors.amber.shade700;
    final healColor = Colors.teal.shade500;
    final copePlanName = _preferredPlanName(
      appState.copePlanNames,
      appState.isPlanActive,
    );
    final understandPlanName = _preferredPlanName(
      appState.understandPlanNames,
      appState.isUnderstandPlanActive,
    );
    final healPlanName = _preferredPlanName(
      appState.healPlanNames,
      appState.isHealPlanActive,
    );
    final planItems = <_PlanSlotItem>[
      _PlanSlotItem(
        category: 'Cope',
        planName: copePlanName,
        icon: Icons.spa_rounded,
        color: primaryColor,
        destinationBuilder: (_) => const CopePlanningScreen(),
        detailBuilder: copePlanName == null
            ? null
            : (_) => CopePlanDetailScreen(
                planName: copePlanName,
                color: primaryColor,
              ),
      ),
      _PlanSlotItem(
        category: 'Understand',
        planName: understandPlanName,
        icon: Icons.lightbulb_rounded,
        color: understandColor,
        destinationBuilder: (_) => const UnderstandPlanningScreen(),
        detailBuilder: understandPlanName == null
            ? null
            : (_) => UnderstandPlanDetailScreen(
                planName: understandPlanName,
                color: understandColor,
              ),
      ),
      _PlanSlotItem(
        category: 'Heal',
        planName: healPlanName,
        iconAsset: 'assets/images/resilient-health.png',
        color: healColor,
        destinationBuilder: (_) => const HealPlanningScreen(),
        detailBuilder: healPlanName == null
            ? null
            : (_) => HealPlanDetailScreen(
                planName: healPlanName,
                color: healColor,
              ),
      ),
    ];

    return Scaffold(
      bottomNavigationBar: _MyPlansBottomBar(
        onDestinationSelected: (index) =>
            _handleDestinationSelected(context, index),
      ),
      appBar: AppBar(
        title: const Text('My Plans'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            ...planItems.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PlanOverviewCard(
                  planName: plan.planName,
                  category: plan.category,
                  icon: plan.icon,
                  iconAsset: plan.iconAsset,
                  color: plan.color,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: plan.detailBuilder ?? plan.destinationBuilder,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPlansBottomBar extends StatelessWidget {
  final ValueChanged<int> onDestinationSelected;

  const _MyPlansBottomBar({required this.onDestinationSelected});

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

class _PlanSlotItem {
  final String? planName;
  final String category;
  final IconData? icon;
  final String? iconAsset;
  final Color color;
  final WidgetBuilder destinationBuilder;
  final WidgetBuilder? detailBuilder;

  const _PlanSlotItem({
    required this.planName,
    required this.category,
    this.icon,
    this.iconAsset,
    required this.color,
    required this.destinationBuilder,
    required this.detailBuilder,
  });
}

class _PlanOverviewCard extends StatelessWidget {
  final String? planName;
  final String category;
  final IconData? icon;
  final String? iconAsset;
  final Color color;
  final VoidCallback onTap;

  const _PlanOverviewCard({
    required this.planName,
    required this.category,
    this.icon,
    this.iconAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPlan = planName != null;

    return GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      border: Border.all(color: color.withAlpha(isDark ? 65 : 50)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: hasPlan && iconAsset != null
                    ? ImageIcon(AssetImage(iconAsset!), color: color, size: 25)
                    : Icon(
                        hasPlan ? icon : Icons.add_circle_outline_rounded,
                        color: color,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      planName ?? 'No plan yet, click to create one',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: hasPlan ? 17 : 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: hasPlan
                            ? null
                            : isDark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanStatusBadge extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _PlanStatusBadge({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        'Active plan',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Future<void> _confirmDeletePlan(
  BuildContext context, {
  required String planId,
  required String planName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete plan?'),
      content: Text(
        'Are you sure you want to delete "$planName"? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  await context.read<AppState>().deletePlan(planId);
  if (context.mounted) Navigator.pop(context);
}

Future<String?> _editPlanTitle(
  BuildContext context, {
  required String planId,
  required String planName,
}) async {
  final nextName = await showDialog<String>(
    context: context,
    builder: (_) => _EditPlanTitleDialog(initialName: planName),
  );

  final trimmedName = nextName?.trim();
  if (trimmedName == null || trimmedName.isEmpty || !context.mounted) {
    return null;
  }
  if (trimmedName == planName) return planName;

  final renamed = await context.read<AppState>().renamePlan(
    planId,
    trimmedName,
  );
  if (!context.mounted) return null;
  if (!renamed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A plan with this title already exists.')),
    );
    return null;
  }

  return trimmedName;
}

class _EditPlanTitleDialog extends StatefulWidget {
  final String initialName;

  const _EditPlanTitleDialog({required this.initialName});

  @override
  State<_EditPlanTitleDialog> createState() => _EditPlanTitleDialogState();
}

class _EditPlanTitleDialogState extends State<_EditPlanTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit plan title'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Plan title'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class CopePlanDetailScreen extends StatefulWidget {
  final String planName;
  final Color color;

  const CopePlanDetailScreen({
    super.key,
    required this.planName,
    required this.color,
  });

  @override
  State<CopePlanDetailScreen> createState() => _CopePlanDetailScreenState();
}

class _CopePlanDetailScreenState extends State<CopePlanDetailScreen> {
  late String _planName;
  late final AudioPlayer _musicPlayer;
  bool _musicMuted = false;

  @override
  void initState() {
    super.initState();
    _planName = widget.planName;
    _musicPlayer = AudioPlayer(playerId: 'cope_plan_music');
    _musicMuted = !GlobalSoundService.instance.isEnabled;
    GlobalSoundService.instance.enabled.addListener(_applyGlobalSound);
    unawaited(_startMusic());
  }

  void _applyGlobalSound() {
    final enabled = GlobalSoundService.instance.isEnabled;
    if (mounted) setState(() => _musicMuted = !enabled);
    unawaited(_musicPlayer.setVolume(enabled ? 0.5 : 0));
  }

  Future<void> _startMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource('sounds/cope-plan.mp3'),
        volume: _musicMuted ? 0 : 0.5,
      );
    } catch (error) {
      debugPrint('[CopePlanDetailScreen] Music failed: $error');
    }
  }

  Future<void> _toggleMusicMute() async {
    final shouldMute = !_musicMuted;
    setState(() => _musicMuted = shouldMute);
    try {
      await _musicPlayer.setVolume(shouldMute ? 0 : 0.5);
    } catch (error) {
      debugPrint('[CopePlanDetailScreen] Music mute failed: $error');
    }
  }

  @override
  void dispose() {
    GlobalSoundService.instance.enabled.removeListener(_applyGlobalSound);
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final planId = appState.copePlanIdForName(_planName);

    return Scaffold(
      appBar: AppBar(
        title: Text(_planName),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleMusicMute,
            icon: Icon(
              _musicMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
            color: Colors.grey,
            tooltip: _musicMuted ? 'Unmute music' : 'Mute music',
          ),
          IconButton(
            onPressed: () async {
              final nextName = await _editPlanTitle(
                context,
                planId: planId,
                planName: _planName,
              );
              if (nextName != null && mounted) {
                setState(() => _planName = nextName);
              }
            },
            icon: const Icon(Icons.edit_outlined),
            color: Colors.grey,
            tooltip: 'Edit plan title',
          ),
          IconButton(
            onPressed: () => _confirmDeletePlan(
              context,
              planId: planId,
              planName: _planName,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.grey,
            tooltip: 'Delete plan',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coping with anxiety is all about reminding yourself that you are safe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CopeDailyPlanTable(color: widget.color),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyPlansScreen()),
                  );
                },
                icon: const Icon(Icons.route_rounded),
                label: const Text('My Plans'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnderstandPlanDetailScreen extends StatefulWidget {
  final String planName;
  final Color color;

  const UnderstandPlanDetailScreen({
    super.key,
    required this.planName,
    required this.color,
  });

  @override
  State<UnderstandPlanDetailScreen> createState() =>
      _UnderstandPlanDetailScreenState();
}

class _UnderstandPlanDetailScreenState
    extends State<UnderstandPlanDetailScreen> {
  late String _planName;
  late final AudioPlayer _musicPlayer;
  bool _musicMuted = false;

  @override
  void initState() {
    super.initState();
    _planName = widget.planName;
    _musicPlayer = AudioPlayer(playerId: 'understand_plan_music');
    _musicMuted = !GlobalSoundService.instance.isEnabled;
    GlobalSoundService.instance.enabled.addListener(_applyGlobalSound);
    unawaited(_startMusic());
  }

  void _applyGlobalSound() {
    final enabled = GlobalSoundService.instance.isEnabled;
    if (mounted) setState(() => _musicMuted = !enabled);
    unawaited(_musicPlayer.setVolume(enabled ? 0.5 : 0));
  }

  Future<void> _startMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource('sounds/understand-plan.mp3'),
        volume: _musicMuted ? 0 : 0.5,
      );
    } catch (error) {
      debugPrint('[UnderstandPlanDetailScreen] Music failed: $error');
    }
  }

  Future<void> _toggleMusicMute() async {
    final shouldMute = !_musicMuted;
    setState(() => _musicMuted = shouldMute);
    try {
      await _musicPlayer.setVolume(shouldMute ? 0 : 0.5);
    } catch (error) {
      debugPrint('[UnderstandPlanDetailScreen] Music mute failed: $error');
    }
  }

  @override
  void dispose() {
    GlobalSoundService.instance.enabled.removeListener(_applyGlobalSound);
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isActive = appState.isUnderstandPlanActive(_planName);
    final planId = appState.understandPlanIdForName(_planName);

    return Scaffold(
      appBar: AppBar(
        title: Text(_planName),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleMusicMute,
            icon: Icon(
              _musicMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
            color: Colors.grey,
            tooltip: _musicMuted ? 'Unmute music' : 'Mute music',
          ),
          IconButton(
            onPressed: () async {
              final nextName = await _editPlanTitle(
                context,
                planId: planId,
                planName: _planName,
              );
              if (nextName != null && mounted) {
                setState(() => _planName = nextName);
              }
            },
            icon: const Icon(Icons.edit_outlined),
            color: Colors.grey,
            tooltip: 'Edit plan title',
          ),
          IconButton(
            onPressed: () => _confirmDeletePlan(
              context,
              planId: planId,
              planName: _planName,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.grey,
            tooltip: 'Delete plan',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Use these activities to gradually understand the reasons for your anxiety',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _PlanStatusBadge(isActive: isActive, color: widget.color),
                ],
              ),
            ),
            const SizedBox(height: 12),
            UnderstandDailyPlanTable(
              color: widget.color,
              feeling: appState.understandPlanFeeling,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyPlansScreen()),
                  );
                },
                icon: const Icon(Icons.route_rounded),
                label: const Text('My Plans'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HealPlanDetailScreen extends StatefulWidget {
  final String planName;
  final Color color;

  const HealPlanDetailScreen({
    super.key,
    required this.planName,
    required this.color,
  });

  @override
  State<HealPlanDetailScreen> createState() => _HealPlanDetailScreenState();
}

class _HealPlanDetailScreenState extends State<HealPlanDetailScreen> {
  late String _planName;

  @override
  void initState() {
    super.initState();
    _planName = widget.planName;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final planId = appState.healPlanIdForName(_planName);

    return Scaffold(
      appBar: AppBar(
        title: Text(_planName),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final nextName = await _editPlanTitle(
                context,
                planId: planId,
                planName: _planName,
              );
              if (nextName != null && mounted) {
                setState(() => _planName = nextName);
              }
            },
            icon: const Icon(Icons.edit_outlined),
            color: Colors.grey,
            tooltip: 'Edit plan title',
          ),
          IconButton(
            onPressed: () => _confirmDeletePlan(
              context,
              planId: planId,
              planName: _planName,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.grey,
            tooltip: 'Delete plan',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Use these activities to slowly vanquish your anxiety',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            HealDailyPlanTable(color: widget.color),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyPlansScreen()),
                  );
                },
                icon: const Icon(Icons.route_rounded),
                label: const Text('My Plans'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedPlanDetailScreen extends StatefulWidget {
  final String planName;
  final String category;
  final IconData icon;
  final Color color;
  final List<_PlanPreviewSection> _sections;

  const SavedPlanDetailScreen.heal({
    super.key,
    required this.planName,
    required this.color,
  }) : category = 'Heal',
       icon = Icons.volunteer_activism_rounded,
       _sections = const [
         _PlanPreviewSection('Focus', [
           'Use your Understand insight as the map.',
           'Practice acceptance, forgiveness, and letting go.',
           'Meditate, visualize, and test gently.',
         ]),
         _PlanPreviewSection('Aim', [
           'Heal the anxious response when that thought arises.',
         ]),
       ];

  @override
  State<SavedPlanDetailScreen> createState() => _SavedPlanDetailScreenState();
}

class _SavedPlanDetailScreenState extends State<SavedPlanDetailScreen> {
  late String _planName;

  @override
  void initState() {
    super.initState();
    _planName = widget.planName;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isActive = switch (widget.category) {
      'Understand' => appState.isUnderstandPlanActive(_planName),
      'Heal' => appState.isHealPlanActive(_planName),
      _ => false,
    };
    final planId = switch (widget.category) {
      'Understand' => appState.understandPlanIdForName(_planName),
      'Heal' => appState.healPlanIdForName(_planName),
      _ => '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_planName),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final nextName = await _editPlanTitle(
                context,
                planId: planId,
                planName: _planName,
              );
              if (nextName != null && mounted) {
                setState(() => _planName = nextName);
              }
            },
            icon: const Icon(Icons.edit_outlined),
            color: Colors.grey,
            tooltip: 'Edit plan title',
          ),
          IconButton(
            onPressed: () => _confirmDeletePlan(
              context,
              planId: planId,
              planName: _planName,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.grey,
            tooltip: 'Delete plan',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(28),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _planName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PlanStatusBadge(isActive: isActive, color: widget.color),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...widget._sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...section.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: widget.color,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanPreviewSection {
  final String title;
  final List<String> items;

  const _PlanPreviewSection(this.title, this.items);
}
