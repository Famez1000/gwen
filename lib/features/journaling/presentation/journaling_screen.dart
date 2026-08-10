import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';

class JournalingScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBack;

  const JournalingScreen({super.key, required this.appState, this.onBack});

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen> {
  final TextEditingController _feelingsController = TextEditingController();
  int _anxietyScore = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTodayEntry();
  }

  @override
  void dispose() {
    _feelingsController.dispose();
    super.dispose();
  }

  void _loadTodayEntry() {
    final todayEntry = widget.appState.getDailyJournalEntryForDate(
      DateTime.now(),
    );
    if (todayEntry == null) return;

    _anxietyScore = todayEntry['anxietyScore'] as int? ?? 5;
    _feelingsController.text = todayEntry['feelings'] as String? ?? '';
  }

  Future<void> _saveEntry() async {
    if (_feelingsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a few words before saving.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.appState.saveDailyJournalEntry(
      date: DateTime.now(),
      anxietyScore: _anxietyScore,
      feelings: _feelingsController.text,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Daily journal saved.')));
  }

  Future<void> _editEntry(Map<String, dynamic> entry) async {
    final date = DateTime.tryParse(entry['date'] as String? ?? '');
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This journal date could not be read.')),
      );
      return;
    }

    final result = await showDialog<_JournalEntryEditResult>(
      context: context,
      builder: (context) => _EditJournalEntryDialog(
        title: 'Edit journal entry',
        dateLabel: _formatFriendlyDate(date),
        initialAnxietyScore: entry['anxietyScore'] as int? ?? 5,
        initialFeelings: entry['feelings'] as String? ?? '',
      ),
    );
    if (result == null || !mounted) return;

    await widget.appState.saveDailyJournalEntry(
      date: date,
      anxietyScore: result.anxietyScore,
      feelings: result.feelings,
    );
    if (!mounted) return;

    final today = DateTime.now();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      setState(() {
        _anxietyScore = result.anxietyScore;
        _feelingsController.text = result.feelings;
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Journal entry updated.')));
  }

  Future<void> _addEntryForDifferentDay() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: todayOnly.subtract(const Duration(days: 1)),
      firstDate: DateTime(today.year - 10),
      lastDate: todayOnly,
      helpText: 'Choose journal date',
      selectableDayPredicate: (date) =>
          date.year != todayOnly.year ||
          date.month != todayOnly.month ||
          date.day != todayOnly.day,
    );
    if (selectedDate == null || !mounted) return;

    final existingEntry = widget.appState.getDailyJournalEntryForDate(
      selectedDate,
    );
    final result = await showDialog<_JournalEntryEditResult>(
      context: context,
      builder: (context) => _EditJournalEntryDialog(
        title: existingEntry == null
            ? 'Add journal entry'
            : 'Edit journal entry',
        dateLabel: _formatFriendlyDate(selectedDate),
        initialAnxietyScore: existingEntry?['anxietyScore'] as int? ?? 5,
        initialFeelings: existingEntry?['feelings'] as String? ?? '',
      ),
    );
    if (result == null || !mounted) return;

    await widget.appState.saveDailyJournalEntry(
      date: selectedDate,
      anxietyScore: result.anxietyScore,
      feelings: result.feelings,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existingEntry == null
              ? 'Journal entry added.'
              : 'Journal entry updated.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, child) {
        final entries = widget.appState.dailyJournalEntries;
        final hasTodayEntry =
            widget.appState.getDailyJournalEntryForDate(DateTime.now()) != null;

        return Scaffold(
          backgroundColor: widget.onBack == null
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.transparent,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Journal',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track your anxiety daily',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.black.withAlpha(153),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatFriendlyDate(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _addEntryForDifferentDay,
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                            ),
                            label: const Text('Other day'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Anxiety score',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$_anxietyScore / 10',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _anxietyScore.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _anxietyScore.toString(),
                        onChanged: (value) {
                          setState(() {
                            _anxietyScore = value.round();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _feelingsController,
                        minLines: 7,
                        maxLines: 12,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Write here today\'s thoughts',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withAlpha(13)
                              : Colors.white.withAlpha(204),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveEntry,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            _isSaving
                                ? 'Saving...'
                                : hasTodayEntry
                                ? 'Update today'
                                : 'Save today',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent entries (three months period)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Text(
                    'No journal entries yet.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  )
                else
                  ...entries
                      .take(14)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _JournalEntryCard(
                            entry: entry,
                            onEdit: () => _editEntry(entry),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFriendlyDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _JournalEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onEdit;

  const _JournalEntryCard({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = entry['date'] as String? ?? '';
    final feelings = entry['feelings'] as String? ?? '';
    final anxietyScore = entry['anxietyScore'] as int? ?? 0;

    return SizedBox(
      height: 132,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$anxietyScore / 10',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: Colors.grey,
                      tooltip: 'Edit entry',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feelings,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditJournalEntryDialog extends StatefulWidget {
  final String title;
  final String dateLabel;
  final int initialAnxietyScore;
  final String initialFeelings;

  const _EditJournalEntryDialog({
    required this.title,
    required this.dateLabel,
    required this.initialAnxietyScore,
    required this.initialFeelings,
  });

  @override
  State<_EditJournalEntryDialog> createState() =>
      _EditJournalEntryDialogState();
}

class _EditJournalEntryDialogState extends State<_EditJournalEntryDialog> {
  late final TextEditingController _controller;
  late int _anxietyScore;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFeelings);
    _anxietyScore = widget.initialAnxietyScore;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final feelings = _controller.text.trim();
    if (feelings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a few words before saving.')),
      );
      return;
    }

    Navigator.pop(
      context,
      _JournalEntryEditResult(anxietyScore: _anxietyScore, feelings: feelings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dateLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Anxiety score'),
                  Text(
                    '$_anxietyScore / 10',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _anxietyScore.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: _anxietyScore.toString(),
                onChanged: (value) {
                  setState(() => _anxietyScore = value.round());
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                minLines: 5,
                maxLines: 9,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save changes')),
      ],
    );
  }
}

class _JournalEntryEditResult {
  final int anxietyScore;
  final String feelings;

  const _JournalEntryEditResult({
    required this.anxietyScore,
    required this.feelings,
  });
}
