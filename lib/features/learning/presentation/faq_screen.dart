import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/glass_card.dart';
import '../../subscription/application/subscription_gate.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final Set<int> _openQuestions = {};
  List<_FaqItem> _faqItems = const [];
  bool _isLoadingFaq = true;
  String? _faqLoadError;

  @override
  void initState() {
    super.initState();
    _loadFaqItems();
  }

  Future<void> _loadFaqItems() async {
    try {
      final jsonText = await rootBundle.loadString(
        'assets/data/learning_faq.json',
      );
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .map(_FaqItem.fromJson)
          .where((item) => item.question.isNotEmpty && item.answer.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _faqItems = items;
        _isLoadingFaq = false;
        _faqLoadError = null;
      });
    } catch (error) {
      debugPrint('[FaqScreen] Failed to load FAQ JSON: $error');
      if (!mounted) return;
      setState(() {
        _faqItems = const [];
        _isLoadingFaq = false;
        _faqLoadError = 'Could not load the learning questions.';
      });
    }
  }

  void _toggleQuestion(int index) {
    setState(() {
      if (_openQuestions.contains(index)) {
        _openQuestions.remove(index);
      } else {
        _openQuestions.add(index);
      }
    });
  }

  void _openSubscription(BuildContext context) {
    openGwenChatOrSubscription(
      context,
      title: 'Anxiety FAQ with Gwen',
      pageContext:
          'The user opened Gwen from the anxiety FAQ screen with common questions and answers about anxiety.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
              children: [
                Text(
                  'What is Anxiety?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap a question to open it. Tap it again to close it.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_isLoadingFaq)
                  const Center(child: CircularProgressIndicator())
                else if (_faqLoadError != null)
                  Text(
                    _faqLoadError!,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  )
                else if (_faqItems.isEmpty)
                  Text(
                    'No learning questions yet.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  )
                else
                  ...List.generate(_faqItems.length, (index) {
                    final item = _faqItems[index];
                    final isOpen = _openQuestions.contains(index);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _FaqCard(
                        item: item,
                        isOpen: isOpen,
                        onTap: () => _toggleQuestion(index),
                      ),
                    );
                  }),
              ],
            ),
            Positioned(
              top: 6,
              left: 16,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withAlpha(13)
                      : Colors.black.withAlpha(8),
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Positioned(
              top: 6,
              right: 16,
              child: _AskGwenButton(onTap: () => _openSubscription(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskGwenButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AskGwenButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withAlpha(128)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/icon.png',
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Understand with Gwen',
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
    );
  }
}

class _FaqCard extends StatelessWidget {
  final _FaqItem item;
  final bool isOpen;
  final VoidCallback onTap;

  const _FaqCard({
    required this.item,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  item.answer,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? Colors.white70
                        : Colors.black.withAlpha(166),
                  ),
                ),
              ),
              crossFadeState: isOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  factory _FaqItem.fromJson(Map<String, dynamic> json) {
    return _FaqItem(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}
