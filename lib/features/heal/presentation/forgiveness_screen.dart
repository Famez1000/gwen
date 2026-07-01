import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/glass_card.dart';

class ForgivenessScreen extends StatefulWidget {
  const ForgivenessScreen({super.key});

  @override
  State<ForgivenessScreen> createState() => _ForgivenessScreenState();
}

class _ForgivenessScreenState extends State<ForgivenessScreen> {
  final TextEditingController _burdenController = TextEditingController();
  bool _hasSoftened = false;

  @override
  void dispose() {
    _burdenController.dispose();
    super.dispose();
  }

  void _softenAroundIt() {
    if (_burdenController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSoftened = true;
    });
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _burdenController.clear();
      _hasSoftened = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceText = isDark ? Colors.white : Colors.black87;
    final mutedText = isDark ? Colors.white70 : Colors.black.withAlpha(153);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Forgiveness',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF2A211A),
                            Color(0xFF1F2933),
                            Color(0xFF202B24),
                          ]
                        : const [
                            Color(0xFFFFF1E4),
                            Color(0xFFF9F7F1),
                            Color(0xFFEAF3EC),
                          ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 90,
              left: -46,
              child: _SoftCircle(
                size: 190,
                color: Colors.orange.withAlpha(isDark ? 38 : 54),
              ),
            ),
            Positioned(
              bottom: 76,
              right: -54,
              child: _SoftCircle(
                size: 220,
                color: primaryColor.withAlpha(isDark ? 38 : 46),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      72,
                      20,
                      24 + keyboardInset,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 96).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.volunteer_activism_rounded,
                            color: Colors.orange.shade600,
                            size: 56,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Forgiveness can begin as a little less tension.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: surfaceText,
                                  fontWeight: FontWeight.bold,
                                  height: 1.25,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'You do not have to approve of what happened. Just notice what you are ready to stop carrying today.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'What are you ready to soften around?',
                                  style: TextStyle(
                                    color: surfaceText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _burdenController,
                                  minLines: 3,
                                  maxLines: 5,
                                  maxLength: 160,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onChanged: (_) {
                                    if (_hasSoftened) {
                                      setState(() {
                                        _hasSoftened = false;
                                      });
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'I am ready to loosen my grip on...',
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    counterText: '',
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withAlpha(13)
                                        : Colors.white.withAlpha(176),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed:
                                      _burdenController.text.trim().isEmpty
                                      ? null
                                      : _softenAroundIt,
                                  icon: const Icon(Icons.favorite_rounded),
                                  label: const Text('Soften around this'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: _hasSoftened
                                ? _ForgivenessResult(
                                    burden: _burdenController.text.trim(),
                                    onReset: _reset,
                                  )
                                : _ForgivenessPrompt(
                                    isDark: isDark,
                                    primaryColor: primaryColor,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgivenessPrompt extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;

  const _ForgivenessPrompt({required this.isDark, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black.withAlpha(153);

    return GlassCard(
      key: const ValueKey('prompt'),
      padding: const EdgeInsets.all(18),
      color: isDark ? Colors.white.withAlpha(16) : Colors.white.withAlpha(130),
      child: Column(
        children: [
          _PracticeLine(
            icon: Icons.pan_tool_alt_rounded,
            text: 'Place a hand somewhere steady.',
            color: primaryColor,
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _PracticeLine(
            icon: Icons.air_rounded,
            text: 'Breathe out and let your shoulders drop.',
            color: Colors.teal.shade300,
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _PracticeLine(
            icon: Icons.volunteer_activism_rounded,
            text: 'Say: I can release this one breath at a time.',
            color: Colors.orange.shade600,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _ForgivenessResult extends StatelessWidget {
  final String burden;
  final VoidCallback onReset;

  const _ForgivenessResult({required this.burden, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GlassCard(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      color: isDark ? Colors.white.withAlpha(18) : Colors.white.withAlpha(150),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: primaryColor, size: 38),
          const SizedBox(height: 12),
          Text(
            'A little softer is enough.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '"$burden"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withAlpha(153),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Forgiveness does not have to happen all at once. Today, you practiced putting the weight down for a moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withAlpha(153),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Practice again'),
          ),
        ],
      ),
    );
  }
}

class _PracticeLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  const _PracticeLine({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(color: textColor, height: 1.35)),
        ),
      ],
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.35,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}
