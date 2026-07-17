import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../home/presentation/planning_intro_screen.dart';

class ProgressScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBack;

  const ProgressScreen({super.key, required this.appState, this.onBack});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<_AnxietyChartPoint> _monthlyJournalAnxietyPoints() {
    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month, today.day);
    final startDate = endDate.subtract(const Duration(days: 29));

    final points = widget.appState.dailyJournalEntries
        .map((entry) {
          final rawDate = entry['date'] as String?;
          final rawScore = entry['anxietyScore'] as int?;
          if (rawDate == null || rawScore == null) return null;

          final date = DateTime.tryParse(rawDate);
          if (date == null) return null;

          final dateOnly = DateTime(date.year, date.month, date.day);
          if (dateOnly.isBefore(startDate) || dateOnly.isAfter(endDate)) {
            return null;
          }

          return _AnxietyChartPoint(date: dateOnly, score: rawScore);
        })
        .whereType<_AnxietyChartPoint>()
        .toList();

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  double? _averageAnxietyScore(List<int> scores) {
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  List<String> _extractiveJournalSummary() {
    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month, today.day);
    final startDate = endDate.subtract(const Duration(days: 29));
    final sentences = <_RankedSentence>[];

    for (final entry in widget.appState.dailyJournalEntries) {
      final rawDate = entry['date'] as String?;
      final feelings = (entry['feelings'] as String? ?? '').trim();
      if (rawDate == null || feelings.isEmpty) continue;

      final date = DateTime.tryParse(rawDate);
      if (date == null) continue;

      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.isBefore(startDate) || dateOnly.isAfter(endDate)) continue;

      for (final sentence in _splitIntoSentences(feelings)) {
        if (_tokenize(sentence).length < 3) continue;
        sentences.add(
          _RankedSentence(sentence: sentence, order: sentences.length),
        );
      }
    }

    if (sentences.isEmpty) return const [];

    final frequencies = <String, int>{};
    for (final sentence in sentences) {
      for (final token in _tokenize(sentence.sentence)) {
        frequencies[token] = (frequencies[token] ?? 0) + 1;
      }
    }

    final ranked =
        sentences.map((sentence) {
          final tokens = _tokenize(sentence.sentence);
          final score =
              tokens.fold<double>(
                0,
                (total, token) => total + (frequencies[token] ?? 0),
              ) /
              tokens.length;
          return sentence.copyWith(score: score);
        }).toList()..sort((a, b) {
          final scoreCompare = b.score.compareTo(a.score);
          if (scoreCompare != 0) return scoreCompare;
          return a.order.compareTo(b.order);
        });

    final selected = ranked.take(3).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return selected.map((sentence) => sentence.sentence).toList();
  }

  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList();
  }

  List<String> _tokenize(String sentence) {
    const stopWords = {
      'a',
      'an',
      'and',
      'are',
      'as',
      'at',
      'be',
      'but',
      'by',
      'for',
      'from',
      'had',
      'has',
      'have',
      'i',
      'in',
      'is',
      'it',
      'me',
      'my',
      'of',
      'on',
      'or',
      'so',
      'that',
      'the',
      'this',
      'to',
      'was',
      'were',
      'with',
    };

    return sentence
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 2 && !stopWords.contains(token))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final monthlyAnxietyPoints = _monthlyJournalAnxietyPoints();
    final monthlyAverageAnxiety = _averageAnxietyScore(
      monthlyAnxietyPoints.map((point) => point.score).toList(),
    );
    final monthlyAverageProgress = (monthlyAverageAnxiety ?? 0) / 10;
    final summarySentences = _extractiveJournalSummary();

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
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlanningIntroScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Plan with Gwyn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Average anxiety score",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                monthlyAverageAnxiety == null
                                    ? '-'
                                    : '${monthlyAverageAnxiety.toStringAsFixed(1)} / 10',
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
                              value: monthlyAverageProgress,
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
                            monthlyAverageAnxiety == null
                                ? 'No journal anxiety scores saved in the last month yet'
                                : 'Based on ${monthlyAnxietyPoints.length} journal ${monthlyAnxietyPoints.length == 1 ? 'score' : 'scores'} from the last month.',
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

                    // Monthly score trend
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Last month trend",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 220,
                            child: _MonthlyAnxietyChart(
                              points: monthlyAnxietyPoints,
                              color: primaryColor,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            monthlyAnxietyPoints.isEmpty
                                ? 'Save journal anxiety scores to see the last month here.'
                                : 'Last 30 days from your daily journal anxiety score.',
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

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analysis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Offline extractive summary from your journal entries.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black.withAlpha(153),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (summarySentences.isEmpty)
                            Text(
                              'No journal text from the last month to summarize yet.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black.withAlpha(166),
                              ),
                            )
                          else
                            ...summarySentences.map(
                              (sentence) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  sentence,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black.withAlpha(166),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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

class _AnxietyChartPoint {
  final DateTime date;
  final int score;

  const _AnxietyChartPoint({required this.date, required this.score});
}

class _RankedSentence {
  final String sentence;
  final int order;
  final double score;

  const _RankedSentence({
    required this.sentence,
    required this.order,
    this.score = 0,
  });

  _RankedSentence copyWith({double? score}) {
    return _RankedSentence(
      sentence: sentence,
      order: order,
      score: score ?? this.score,
    );
  }
}

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
