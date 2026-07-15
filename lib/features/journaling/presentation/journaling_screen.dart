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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, child) {
        final entries = widget.appState.dailyJournalEntries;

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                      Text(
                        _formatFriendlyDate(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                          label: Text(_isSaving ? 'Saving...' : 'Save today'),
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
                  'Recent entries',
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
                          child: _JournalEntryCard(entry: entry),
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

  const _JournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = entry['date'] as String? ?? '';
    final feelings = entry['feelings'] as String? ?? '';
    final anxietyScore = entry['anxietyScore'] as int? ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '$anxietyScore / 10',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feelings,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
