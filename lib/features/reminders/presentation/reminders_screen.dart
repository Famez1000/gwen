import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final Map<String, List<_ReminderItem>> _remindersByAspect = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminderSchedules();
  }

  Future<void> _loadReminderSchedules() async {
    final results = await Future.wait([
      NotificationService.instance.loadPlanReminderSchedules('cope'),
      NotificationService.instance.loadPlanReminderSchedules('understand'),
      NotificationService.instance.loadPlanReminderSchedules('heal'),
    ]);
    if (!mounted) return;

    setState(() {
      _remindersByAspect
        ..clear()
        ..['cope'] = results[0]
            .map(
              (schedule) => _ReminderItem.fromSchedule(
                schedule,
                color: Theme.of(context).primaryColor,
                icon: Icons.spa_rounded,
              ),
            )
            .toList()
        ..['understand'] = results[1]
            .map(
              (schedule) => _ReminderItem.fromSchedule(
                schedule,
                color: Colors.amber.shade700,
                icon: Icons.lightbulb_outline_rounded,
              ),
            )
            .toList()
        ..['heal'] = results[2]
            .map(
              (schedule) => _ReminderItem.fromSchedule(
                schedule,
                color: Colors.teal.shade500,
                icon: Icons.healing_rounded,
                imageAsset: 'assets/images/resilient-health.png',
              ),
            )
            .toList();
    });

    await _syncAndScheduleReminders();
    if (mounted) setState(() => _isLoading = false);
  }

  bool _hasAspectPlan(AppState appState, String aspect) {
    return switch (aspect) {
      'cope' => appState.copePlanNames.isNotEmpty,
      'understand' => appState.understandPlanNames.isNotEmpty,
      'heal' => appState.healPlanNames.isNotEmpty,
      _ => false,
    };
  }

  bool _isAspectActive(AppState appState, String aspect) {
    return _hasAspectPlan(appState, aspect) &&
        (_remindersByAspect[aspect]?.any((reminder) => reminder.isEnabled) ??
            false);
  }

  Future<void> _syncAndScheduleReminders() async {
    final appState = context.read<AppState>();

    for (final aspectEntry in _remindersByAspect.entries) {
      final reminders = aspectEntry.value;
      if (!_hasAspectPlan(appState, aspectEntry.key)) {
        var changed = false;
        for (final reminder in reminders) {
          if (!reminder.isEnabled) continue;
          reminder.isEnabled = false;
          changed = true;
          await NotificationService.instance.cancelReminder(reminder.id);
        }
        if (changed) await _saveReminderSchedules(aspectEntry.key);
        continue;
      }

      for (final entry in reminders.indexed.where(
        (entry) => entry.$2.isEnabled,
      )) {
        await NotificationService.instance.schedulePlanReminder(
          entry.$2.toSchedule(),
          position: entry.$1,
        );
      }
    }
  }

  Future<void> _saveReminderSchedules(String aspect) async {
    final reminders = _remindersByAspect[aspect] ?? const <_ReminderItem>[];
    await NotificationService.instance.savePlanReminderSchedules(
      aspect,
      reminders.map((reminder) => reminder.toSchedule()).toList(),
    );
  }

  Future<void> _toggleReminder(String aspect, int index, bool value) async {
    final reminders = _remindersByAspect[aspect];
    if (reminders == null || index >= reminders.length) return;

    if (value && !_hasAspectPlan(context.read<AppState>(), aspect)) {
      await _showMissingPlanDialog(aspect);
      return;
    }

    final reminder = reminders[index];
    setState(() => reminder.isEnabled = value);
    await _saveReminderSchedules(aspect);

    if (value) {
      await NotificationService.instance.schedulePlanReminder(
        reminder.toSchedule(),
        position: index,
      );
    } else {
      await NotificationService.instance.cancelReminder(reminder.id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? '${reminder.frequency} reminder scheduled'
              : 'Reminder cancelled',
        ),
      ),
    );
  }

  Future<void> _showMissingPlanDialog(String aspect) async {
    final planName = switch (aspect) {
      'cope' => 'Cope',
      'understand' => 'Understand',
      'heal' => 'Heal',
      _ => 'This',
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plan not found'),
        content: Text(
          'Create a $planName plan before activating its reminders.',
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

  Future<void> _toggleAspectActivation(String aspect) async {
    final appState = context.read<AppState>();
    if (!_hasAspectPlan(appState, aspect)) {
      await _showMissingPlanDialog(aspect);
      return;
    }

    final isActivating = !_isAspectActive(appState, aspect);
    final reminders = _remindersByAspect[aspect];
    if (reminders == null) return;

    for (final reminder in reminders) {
      reminder.isEnabled = isActivating;
    }
    await _saveReminderSchedules(aspect);

    await _syncAndScheduleReminders();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editReminder(String aspect, int index) async {
    if (!_hasAspectPlan(context.read<AppState>(), aspect)) {
      await _showMissingPlanDialog(aspect);
      return;
    }

    final reminders = _remindersByAspect[aspect];
    if (reminders == null || index >= reminders.length) return;
    final reminder = reminders[index];
    final updated = await showDialog<_ReminderEditResult>(
      context: context,
      builder: (_) => _EditReminderDialog(reminder: reminder),
    );

    if (updated == null || !mounted) return;

    if (updated.shouldDelete) {
      setState(() => reminders.removeAt(index));
      await _saveReminderSchedules(aspect);
      await NotificationService.instance.cancelReminder(reminder.id);

      for (final entry in reminders.indexed.where(
        (entry) => entry.$2.isEnabled,
      )) {
        await NotificationService.instance.schedulePlanReminder(
          entry.$2.toSchedule(),
          position: entry.$1,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
      return;
    }

    setState(() {
      reminder.title = updated.title;
      reminder.description = updated.description;
      reminder.hour = updated.time.hour;
      reminder.minute = updated.time.minute;
      reminder.time = _formatReminderTime(updated.time);
    });
    await _saveReminderSchedules(aspect);

    if (reminder.isEnabled) {
      await NotificationService.instance.schedulePlanReminder(
        reminder.toSchedule(),
        position: index,
      );
    }
  }

  String _formatReminderTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final activeColor = Theme.of(context).primaryColor;
    final aspects = [
      _ReminderAspect(
        keyName: 'cope',
        title: 'Cope',
        subtitle: 'Reminders that help you steady yourself',
        color: Theme.of(context).primaryColor,
      ),
      _ReminderAspect(
        keyName: 'understand',
        title: 'Understand',
        subtitle: 'Reminders that help you notice your patterns',
        color: Colors.amber.shade700,
      ),
      _ReminderAspect(
        keyName: 'heal',
        title: 'Heal',
        subtitle: 'Reminders that support your healing practice',
        color: Colors.teal.shade500,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...aspects.indexed.expand((entry) {
                final aspect = entry.$2;
                final reminders =
                    _remindersByAspect[aspect.keyName] ??
                    const <_ReminderItem>[];
                final isActive = _isAspectActive(appState, aspect.keyName);
                return [
                  _ReminderAspectSection(
                    aspect: aspect,
                    reminders: reminders,
                    isDark: isDark,
                    isActive: isActive,
                    activeColor: activeColor,
                    onActivationTap: () =>
                        _toggleAspectActivation(aspect.keyName),
                    showSwipeHint: !appState.reminderSwipeHintSeen,
                    onSwiped: appState.markReminderSwipeHintSeen,
                    onEdit: (index) => _editReminder(aspect.keyName, index),
                    onChanged: (index, value) =>
                        _toggleReminder(aspect.keyName, index, value),
                  ),
                  if (entry.$1 < aspects.length - 1) const SizedBox(height: 26),
                ];
              }),
            const SizedBox(height: 20),
            Text(
              'Tap a reminder to edit its text or time. Use the switch to enable or disable its notification.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white54 : Colors.black.withAlpha(143),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderAspect {
  final String keyName;
  final String title;
  final String subtitle;
  final Color color;

  const _ReminderAspect({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _ReminderAspectSection extends StatelessWidget {
  final _ReminderAspect aspect;
  final List<_ReminderItem> reminders;
  final bool isDark;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onActivationTap;
  final bool showSwipeHint;
  final VoidCallback onSwiped;
  final ValueChanged<int> onEdit;
  final void Function(int index, bool value) onChanged;

  const _ReminderAspectSection({
    required this.aspect,
    required this.reminders,
    required this.isDark,
    required this.isActive,
    required this.activeColor,
    required this.onActivationTap,
    required this.showSwipeHint,
    required this.onSwiped,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aspect.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aspect.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: onActivationTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withAlpha(isDark ? 70 : 30)
                      : Colors.grey.withAlpha(isDark ? 60 : 32),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? 'activated' : 'deactivated',
                  style: TextStyle(
                    color: isActive ? activeColor : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (showSwipeHint)
              Icon(
                Icons.swipe_rounded,
                size: 19,
                color: aspect.color.withAlpha(180),
              ),
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
            height: 210,
            child: ListView.separated(
              key: ValueKey('${aspect.keyName}-reminders-scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: reminders.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 270,
                child: _ReminderCard(
                  reminder: reminders[index],
                  isDark: isDark,
                  isActive: isActive,
                  activeColor: activeColor,
                  onTap: () => onEdit(index),
                  onChanged: (value) => onChanged(index, value),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditReminderDialog extends StatefulWidget {
  final _ReminderItem reminder;

  const _EditReminderDialog({required this.reminder});

  @override
  State<_EditReminderDialog> createState() => _EditReminderDialogState();
}

class _EditReminderDialogState extends State<_EditReminderDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(
      text: widget.reminder.description,
    );
    _selectedTime = TimeOfDay(
      hour: widget.reminder.hour,
      minute: widget.reminder.minute,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }

  void _save() {
    final title = _capitalizeSentence(_titleController.text.trim());
    final description = _capitalizeSentence(_descriptionController.text.trim());
    if (title.isEmpty || description.isEmpty) return;

    Navigator.pop(
      context,
      _ReminderEditResult(
        title: title,
        description: description,
        time: _selectedTime,
      ),
    );
  }

  String _capitalizeSentence(String value) {
    if (value.isEmpty) return value;

    final firstLetterIndex = value.indexOf(RegExp(r'[A-Za-z]'));
    if (firstLetterIndex == -1) return value;

    return value.replaceRange(
      firstLetterIndex,
      firstLetterIndex + 1,
      value[firstLetterIndex].toUpperCase(),
    );
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete reminder?'),
          content: const Text(
            'This will remove the reminder and cancel its notification.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    Navigator.pop(
      context,
      const _ReminderEditResult(
        title: '',
        description: '',
        time: TimeOfDay(hour: 0, minute: 0),
        shouldDelete: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notification text'),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text('Time: ${_selectedTime.format(context)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _delete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final _ReminderItem reminder;
  final bool isDark;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;

  const _ReminderCard({
    required this.reminder,
    required this.isDark,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        color: isActive
            ? activeColor.withAlpha(isDark ? 90 : 55)
            : Colors.grey.withAlpha(isDark ? 55 : 35),
        border: Border.all(
          color: isActive
              ? activeColor.withAlpha(isDark ? 150 : 105)
              : Colors.grey.withAlpha(isDark ? 100 : 75),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: reminder.color.withAlpha(42),
                    shape: BoxShape.circle,
                  ),
                  child: reminder.imageAsset == null
                      ? Icon(reminder.icon, color: reminder.color, size: 21)
                      : ImageIcon(
                          AssetImage(reminder.imageAsset!),
                          color: reminder.color,
                          size: 21,
                        ),
                ),
                const Spacer(),
                Switch(
                  value: reminder.isEnabled,
                  onChanged: onChanged,
                  activeTrackColor: reminder.color.withAlpha(150),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              reminder.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                reminder.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark ? Colors.white60 : Colors.black.withAlpha(153),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: reminder.color),
                const SizedBox(width: 5),
                Text(
                  reminder.time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: reminder.color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reminder.frequency,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderItem {
  final int id;
  String title;
  String time;
  int hour;
  int minute;
  String description;
  String frequency;
  final IconData icon;
  final String? imageAsset;
  final Color color;
  bool isEnabled;

  _ReminderItem({
    required this.id,
    required this.title,
    required this.time,
    required this.hour,
    required this.minute,
    required this.description,
    required this.icon,
    this.imageAsset,
    required this.color,
    this.frequency = 'Daily',
    this.isEnabled = false,
  });

  factory _ReminderItem.fromSchedule(
    DailyReminderSchedule schedule, {
    Color? color,
    IconData? icon,
    String? imageAsset,
  }) {
    return _ReminderItem(
      id: schedule.id,
      title: schedule.title,
      time: _formatScheduleTime(schedule.hour, schedule.minute),
      hour: schedule.hour,
      minute: schedule.minute,
      description: schedule.body,
      frequency: schedule.frequency,
      icon:
          icon ??
          switch (schedule.id) {
            1001 => Icons.wb_sunny_rounded,
            1002 => Icons.air_rounded,
            1003 => Icons.wb_twilight_rounded,
            _ => Icons.notifications_active_rounded,
          },
      imageAsset: imageAsset,
      color:
          color ??
          switch (schedule.id) {
            1001 => const Color(0xFFE7C9A9),
            1002 => const Color(0xFF7FC8B2),
            1003 => const Color(0xFF8B85A8),
            _ => const Color(0xFF7FC8B2),
          },
      isEnabled: schedule.isEnabled,
    );
  }

  DailyReminderSchedule toSchedule() {
    return DailyReminderSchedule(
      id: id,
      title: title,
      body: description,
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
      frequency: frequency,
    );
  }

  static String _formatScheduleTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}

class _ReminderEditResult {
  final String title;
  final String description;
  final TimeOfDay time;
  final bool shouldDelete;

  const _ReminderEditResult({
    required this.title,
    required this.description,
    required this.time,
    this.shouldDelete = false,
  });
}
