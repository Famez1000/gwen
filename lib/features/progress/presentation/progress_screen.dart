import 'package:flutter/material.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../subscription/presentation/subscription_screen.dart';

class ProgressScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBack;

  const ProgressScreen({super.key, required this.appState, this.onBack});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isAnalyzing = false;
  String? _gwenAnalysis;

  Future<void> _confirmAnalyzeWithGwen() async {
    final shouldAnalyze = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Analyze with Gwen?'),
          content: const Text(
            'Gwen will review your recent anxiety levels, calm progress, and completed sessions to create a short reflection.',
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> _analyzeWithGwen() async {
    final progressText = _buildProgressTextForAnalysis();

    setState(() {
      _isAnalyzing = true;
      _gwenAnalysis = null;
    });

    String analysis;
    try {
      analysis = await GeminiService.instance.generateContextualGwenResponse(
        userMessage:
            'Analyze this progress data and respond with a short supportive reflection plus one gentle next step:\n\n$progressText',
        pageTitle: 'Progress',
        pageContext:
            'The user is viewing progress data in an anxiety support app. Data may include calm-day streak, breathing sessions, breaths taken, and before/after anxiety intervention logs. Do not diagnose or overstate patterns.',
      );
    } catch (error) {
      debugPrint('[ProgressScreen] Gwen progress analysis failed: $error');
      analysis = _generateLocalProgressAnalysis();
    }

    if (!mounted) return;
    await widget.appState.saveProgressAnalysis(analysis);
    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _gwenAnalysis = analysis;
    });
  }

  String _buildProgressTextForAnalysis() {
    final logs = widget.appState.anxietyLogs;
    final weeklyScores = _weeklyJournalAnxietyScores();
    final averageJournalScore = _averageAnxietyScore(weeklyScores);
    final buffer = StringBuffer()
      ..writeln('Calm-day streak: ${widget.appState.streakCount} / 7')
      ..writeln('Journal anxiety scores this week: ${weeklyScores.length}')
      ..writeln(
        averageJournalScore == null
            ? 'Average journal anxiety score this week: No scores yet'
            : 'Average journal anxiety score this week: ${averageJournalScore.toStringAsFixed(1)} / 10',
      )
      ..writeln(
        'Weekly calm progress from journal anxiety score: ${(_weeklyCalmProgress() * 100).round()}%',
      )
      ..writeln(
        'Breathing sessions completed: ${widget.appState.breathingSessionsCompleted}',
      )
      ..writeln(
        'Estimated breaths taken: ${widget.appState.breathingSessionsCompleted * 25}',
      )
      ..writeln('Recent anxiety logs: ${logs.length}');

    for (final log in logs.take(5)) {
      final date = log['date'] as String? ?? 'Unknown date';
      final pre = log['preScore'] as int? ?? 0;
      final post = log['postScore'] as int? ?? 0;
      final symptoms = List<String>.from(log['symptoms'] ?? []);

      buffer
        ..writeln()
        ..writeln('Date: $date')
        ..writeln('Before score: $pre / 10')
        ..writeln('After score: $post / 10')
        ..writeln('Focus: ${symptoms.join(', ')}');
    }

    return buffer.toString().trim();
  }

  List<int> _weeklyJournalAnxietyScores() {
    final today = DateTime.now();
    final startOfWeek = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));

    return widget.appState.dailyJournalEntries
        .where((entry) {
          final rawDate = entry['date'] as String?;
          if (rawDate == null) return false;
          final date = DateTime.tryParse(rawDate);
          if (date == null) return false;
          final dateOnly = DateTime(date.year, date.month, date.day);
          return !dateOnly.isBefore(startOfWeek);
        })
        .map((entry) => entry['anxietyScore'] as int? ?? 0)
        .toList();
  }

  double? _averageAnxietyScore(List<int> scores) {
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double _weeklyCalmProgress() {
    final averageScore = _averageAnxietyScore(_weeklyJournalAnxietyScores());
    if (averageScore == null) return 0;
    return ((10 - averageScore) / 10).clamp(0.0, 1.0);
  }

  String _generateLocalProgressAnalysis() {
    final logs = widget.appState.anxietyLogs;
    final sessions = widget.appState.breathingSessionsCompleted;
    final streak = widget.appState.streakCount;

    if (logs.isEmpty && sessions == 0 && streak == 0) {
      return 'Gwen does not see much progress data yet. Try one calming exercise today, then come back here to notice what changed.';
    }

    final changes = logs.map((log) {
      final pre = log['preScore'] as int? ?? 0;
      final post = log['postScore'] as int? ?? 0;
      return pre - post;
    }).toList();
    final averageChange = changes.isEmpty
        ? 0.0
        : changes.reduce((a, b) => a + b) / changes.length;

    return 'Gwen noticed $sessions completed breathing ${sessions == 1 ? 'session' : 'sessions'} and $streak calm ${streak == 1 ? 'day' : 'days'}. Your recent before-to-after anxiety shift averages ${averageChange.toStringAsFixed(1)} points. A gentle next step: repeat one tool that has helped before.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final analyses = widget.appState.progressAnalyses;
    final weeklyScores = _weeklyJournalAnxietyScores();
    final weeklyAverageAnxiety = _averageAnxietyScore(weeklyScores);
    final weeklyProgress = _weeklyCalmProgress();

    return Scaffold(
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
                      const SizedBox(width: 12),
                      _AnalyzeWithGwenButton(
                        isAnalyzing: _isAnalyzing,
                        onImageTap: _openSubscription,
                        onTap: _isAnalyzing ? null : _confirmAnalyzeWithGwen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Check how your anxiety gets vanquished over time',
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Weekly Calm Progress",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "${(weeklyProgress * 100).round()}%",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: weeklyProgress,
                              minHeight: 12,
                              backgroundColor: isDark
                                  ? Colors.white.withAlpha(20)
                                  : Colors.black.withAlpha(15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            weeklyAverageAnxiety == null
                                ? "No journal anxiety scores saved this week yet"
                                : "Based on ${weeklyScores.length} journal ${weeklyScores.length == 1 ? 'score' : 'scores'} this week. Average anxiety: ${weeklyAverageAnxiety.toStringAsFixed(1)} / 10",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black.withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Analysis Card
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Analysis (write here your own or use Gwen to analyze for you)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 160),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha(13)
                                  : Colors.black.withAlpha(8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _isAnalyzing
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('Gwen is analyzing...'),
                                    ],
                                  )
                                : Text(
                                    _gwenAnalysis ?? 'No analysis yet',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: _gwenAnalysis == null
                                          ? Colors.grey
                                          : isDark
                                          ? Colors.white70
                                          : Colors.black.withAlpha(190),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Historical Entries
                    Text(
                      "History Logs",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (analyses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          "Previous analysis",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: analyses.length > 5
                            ? 5
                            : analyses.length, // Show last 5 analyses
                        itemBuilder: (context, index) {
                          final analysisEntry = analyses[index];
                          final date = DateTime.parse(
                            analysisEntry['date'] as String,
                          );
                          final analysisText =
                              analysisEntry['analysis'] as String? ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha(5)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withAlpha(10)
                                    : Colors.black.withAlpha(8),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${date.month}/${date.day} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      analysisText,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black.withAlpha(166),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 30),
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
                isAnalyzing ? 'Analyzing...' : 'Analyze with Gwen',
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
