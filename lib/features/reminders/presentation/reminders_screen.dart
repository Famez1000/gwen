import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/glass_card.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _customReminderController =
      TextEditingController();

  final List<_ReminderItem> _reminders = [
    _ReminderItem(
      id: 1001,
      title: 'Morning check-in',
      time: '8:30 AM',
      hour: 8,
      minute: 30,
      description: 'Pause, name your mood, and set one gentle intention.',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFE7C9A9),
      isEnabled: true,
    ),
    _ReminderItem(
      id: 1002,
      title: 'Breathing break',
      time: '1:00 PM',
      hour: 13,
      minute: 0,
      description: 'Take two minutes to loosen your jaw and slow your exhale.',
      icon: Icons.air_rounded,
      color: Color(0xFF7FC8B2),
      isEnabled: true,
    ),
    _ReminderItem(
      id: 1003,
      title: 'Evening reflection',
      time: '8:00 PM',
      hour: 20,
      minute: 0,
      description: 'Write one thing you handled today, even if it was small.',
      icon: Icons.nights_stay_rounded,
      color: Color(0xFF8B85A8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleEnabledReminders();
  }

  @override
  void dispose() {
    _customReminderController.dispose();
    super.dispose();
  }

  Future<void> _scheduleEnabledReminders() async {
    for (final reminder in _reminders.where((reminder) => reminder.isEnabled)) {
      await NotificationService.instance.scheduleDailyReminder(
        id: reminder.id,
        title: reminder.title,
        body: reminder.description,
        hour: reminder.hour,
        minute: reminder.minute,
      );
    }
  }

  Future<void> _toggleReminder(int index, bool value) async {
    final reminder = _reminders[index];
    setState(() => _reminders[index].isEnabled = value);

    if (value) {
      await NotificationService.instance.scheduleDailyReminder(
        id: reminder.id,
        title: reminder.title,
        body: reminder.description,
        hour: reminder.hour,
        minute: reminder.minute,
      );
    } else {
      await NotificationService.instance.cancelReminder(reminder.id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Daily reminder scheduled' : 'Reminder cancelled',
        ),
      ),
    );
  }

  void _addCustomReminder() {
    final text = _customReminderController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _reminders.add(
        _ReminderItem(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: text,
          time: '9:00 AM',
          hour: 9,
          minute: 0,
          description: 'A personal reminder you can keep visible here.',
          icon: Icons.notifications_active_rounded,
          color: Theme.of(context).primaryColor,
        ),
      );
      _customReminderController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder added')));
  }

  Future<void> _editReminder(int index) async {
    final reminder = _reminders[index];
    final updated = await showDialog<_ReminderEditResult>(
      context: context,
      builder: (_) => _EditReminderDialog(reminder: reminder),
    );

    if (updated == null || !mounted) return;

    if (updated.shouldDelete) {
      await NotificationService.instance.cancelReminder(reminder.id);
      if (!mounted) return;

      setState(() => _reminders.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder removed')));
      return;
    }

    setState(() {
      reminder.title = updated.title;
      reminder.description = updated.description;
      reminder.hour = updated.time.hour;
      reminder.minute = updated.time.minute;
      reminder.time = _formatReminderTime(updated.time);
    });

    if (reminder.isEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        id: reminder.id,
        title: reminder.title,
        body: reminder.description,
        hour: reminder.hour,
        minute: reminder.minute,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder updated')));
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
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customReminderController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCustomReminder(),
                      decoration: const InputDecoration(
                        hintText: 'Add your own reminder...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add reminder',
                    onPressed: _addCustomReminder,
                    icon: const Icon(Icons.add_circle_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(_reminders.length, (index) {
              final reminder = _reminders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ReminderCard(
                  reminder: reminder,
                  isDark: isDark,
                  onTap: () => _editReminder(index),
                  onChanged: (value) => _toggleReminder(index, value),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Enabled reminders will send a local notification at the listed time each day.',
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
        const Spacer(),
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
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;

  const _ReminderCard({
    required this.reminder,
    required this.isDark,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reminder.color.withAlpha(42),
                shape: BoxShape.circle,
              ),
              child: Icon(reminder.icon, color: reminder.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        reminder.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: reminder.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reminder.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? Colors.white60
                          : Colors.black.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: reminder.isEnabled, onChanged: onChanged),
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
  final IconData icon;
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
    required this.color,
    this.isEnabled = false,
  });
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
