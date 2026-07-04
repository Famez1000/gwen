import 'package:flutter/material.dart';

import '../../../core/services/gemini_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../subscription/application/subscription_gate.dart';

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
  bool _isAnalyzing = false;

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

  Future<void> _analyzeWithGwen() async {
    final journalText = _buildJournalTextForAnalysis();
    if (journalText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write or save an entry first.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    String summary;
    try {
      summary = await GeminiService.instance.summarizeJournalEntries(
        journalText,
      );
    } catch (error) {
      debugPrint('[JournalingScreen] Gwen journal summary failed: $error');
      summary = _generateLocalJournalSummary();
    }

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
    });

    _showGwenSummary(summary: summary, journalText: journalText);
  }

  Future<void> _confirmAnalyzeWithGwen() async {
    final shouldAnalyze = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Summarize with Gwen?'),
          content: const Text(
            'Gwen will review your recent journal entries and create a short reflection you can chat about.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start analysis'),
            ),
          ],
        );
      },
    );

    if (shouldAnalyze == true && mounted) {
      await _analyzeWithGwen();
    }
  }

  void _openSubscription() {
    openGwenChatOrSubscription(
      context,
      title: 'Journal with Gwen',
      pageContext:
          'The user opened Gwen from the daily journal screen, where they write feelings and track an anxiety score.',
    );
  }

  String _buildJournalTextForAnalysis() {
    final buffer = StringBuffer();
    final draftText = _feelingsController.text.trim();
    final todayKey = _dateKey(DateTime.now());

    if (draftText.isNotEmpty) {
      buffer.writeln('Date: $todayKey');
      buffer.writeln('Anxiety score: $_anxietyScore / 10');
      buffer.writeln('Entry: $draftText');
      buffer.writeln();
    }

    for (final entry in widget.appState.dailyJournalEntries.take(14)) {
      final date = entry['date'] as String? ?? 'Unknown date';
      final feelings = (entry['feelings'] as String? ?? '').trim();
      if (feelings.isEmpty) continue;
      if (date == todayKey && feelings == draftText) continue;

      final anxietyScore = entry['anxietyScore'] as int? ?? 0;
      buffer.writeln('Date: $date');
      buffer.writeln('Anxiety score: $anxietyScore / 10');
      buffer.writeln('Entry: $feelings');
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  String _generateLocalJournalSummary() {
    final entries = widget.appState.dailyJournalEntries;
    final draftText = _feelingsController.text.trim();
    final entryCount = entries.length + (draftText.isNotEmpty ? 1 : 0);

    if (entryCount == 0) {
      return 'Gwen needs at least one journal entry before she can reflect anything back.';
    }

    final scores = [
      if (draftText.isNotEmpty) _anxietyScore,
      ...entries.map((entry) => entry['anxietyScore'] as int? ?? 0),
    ];
    final averageScore = scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a + b) / scores.length;

    return 'Gwen noticed $entryCount written ${entryCount == 1 ? 'entry' : 'entries'}.\n\n'
        '- Average anxiety score: ${averageScore.toStringAsFixed(1)} / 10.\n'
        '- Your entries show you are paying attention to what anxiety feels like day by day.\n'
        '- A gentle next step: reread the most recent entry and choose one small act of care for today.';
  }

  void _showGwenSummary({
    required String summary,
    required String journalText,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _GwenJournalChatDialog(summary: summary, journalText: journalText),
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
                    const SizedBox(width: 14),
                    _AnalyzeWithGwenButton(
                      isAnalyzing: _isAnalyzing,
                      onImageTap: _openSubscription,
                      onTap: _isAnalyzing ? null : _confirmAnalyzeWithGwen,
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
                          hintText: 'How do you feel today?',
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

  String _dateKey(DateTime dt) {
    final date = DateTime(dt.year, dt.month, dt.day);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _AnalyzeWithGwenButton extends StatelessWidget {
  final bool isAnalyzing;
  final VoidCallback onImageTap;
  final VoidCallback? onTap;

  const _AnalyzeWithGwenButton({
    required this.isAnalyzing,
    required this.onImageTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.62 : 1,
        child: SizedBox(
          width: 82,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onImageTap,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withAlpha(128)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/icon.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                      ),
                      if (isAnalyzing)
                        Container(
                          color: Colors.black.withAlpha(72),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAnalyzing ? 'Summarizing...' : 'Summarize with Gwen',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GwenJournalChatDialog extends StatefulWidget {
  final String summary;
  final String journalText;

  const _GwenJournalChatDialog({
    required this.summary,
    required this.journalText,
  });

  @override
  State<_GwenJournalChatDialog> createState() => _GwenJournalChatDialogState();
}

class _GwenJournalChatDialogState extends State<_GwenJournalChatDialog> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_JournalChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_JournalChatMessage(text: widget.summary, isUser: false));
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
    final question = _chatController.text.trim();
    if (question.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_JournalChatMessage(text: question, isUser: true));
      _isSending = true;
    });
    _chatController.clear();
    _scrollToBottom();

    String answer;
    try {
      answer = await GeminiService.instance.respondToJournalSummaryQuestion(
        journalEntries: widget.journalText,
        summary: widget.summary,
        question: question,
      );
    } catch (error) {
      debugPrint('[JournalingScreen] Gwen journal chat failed: $error');
      answer =
          'I could not reach the AI just now, but your question matters. Try asking again in a moment, or reread the summary and choose one small next step that feels kind.';
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_JournalChatMessage(text: answer, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return AlertDialog(
      backgroundColor: isDark
          ? const Color(0xFF1E2435)
          : const Color(0xFFF9F7F5),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/icon.png',
              width: 38,
              height: 38,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Gwen\'s Summary')),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 430,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return const _JournalTypingBubble();
                  }

                  return _JournalMessageBubble(message: _messages[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendQuestion(),
                    decoration: InputDecoration(
                      hintText: 'Ask Gwen for useful tips...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withAlpha(13)
                          : Colors.white.withAlpha(204),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSending ? null : _sendQuestion,
                  style: IconButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalMessageBubble extends StatelessWidget {
  final _JournalChatMessage message;

  const _JournalMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isUser
        ? primaryColor
        : (isDark ? Colors.white.withAlpha(18) : Colors.white.withAlpha(220));
    final textColor = message.isUser
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black.withAlpha(190));

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, height: 1.4),
        ),
      ),
    );
  }
}

class _JournalTypingBubble extends StatelessWidget {
  const _JournalTypingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha(18)
              : Colors.white.withAlpha(220),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Gwen is thinking',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalChatMessage {
  final String text;
  final bool isUser;

  const _JournalChatMessage({required this.text, required this.isUser});
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
