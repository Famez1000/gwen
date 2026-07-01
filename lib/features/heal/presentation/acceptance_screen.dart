import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/glass_card.dart';

class AcceptanceScreen extends StatefulWidget {
  const AcceptanceScreen({super.key});

  @override
  State<AcceptanceScreen> createState() => _AcceptanceScreenState();
}

class _AcceptanceScreenState extends State<AcceptanceScreen> {
  final TextEditingController _feelingController = TextEditingController();
  bool _hasAccepted = false;

  @override
  void dispose() {
    _feelingController.dispose();
    super.dispose();
  }

  void _acceptThisMoment() {
    if (_feelingController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _hasAccepted = true;
    });
    FocusScope.of(context).unfocus();
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _feelingController.clear();
      _hasAccepted = false;
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
          'Acceptance',
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
                            Color(0xFF231B2B),
                            Color(0xFF1F2933),
                            Color(0xFF182B2D),
                          ]
                        : const [
                            Color(0xFFFFF1F5),
                            Color(0xFFF8F7EF),
                            Color(0xFFE9F4EE),
                          ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 88,
              right: -44,
              child: _SoftCircle(
                size: 180,
                color: Colors.pink.withAlpha(isDark ? 38 : 56),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -54,
              child: _SoftCircle(
                size: 210,
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
                            Icons.favorite_rounded,
                            color: Colors.pink.shade300,
                            size: 54,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Let this feeling be here without having to become it.',
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
                            'Notice what is present, name it gently, then offer it a little space.',
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
                                  'What are you making room for?',
                                  style: TextStyle(
                                    color: surfaceText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _feelingController,
                                  minLines: 3,
                                  maxLines: 5,
                                  maxLength: 140,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onChanged: (_) {
                                    if (_hasAccepted) {
                                      setState(() {
                                        _hasAccepted = false;
                                      });
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'I notice sadness, tightness, worry...',
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
                                      _feelingController.text.trim().isEmpty
                                      ? null
                                      : _acceptThisMoment,
                                  icon: const Icon(Icons.spa_rounded),
                                  label: const Text('Make space for this'),
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
                            child: _hasAccepted
                                ? _AcceptanceResult(
                                    feeling: _feelingController.text.trim(),
                                    onReset: _reset,
                                  )
                                : _AcceptancePrompt(
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

class _AcceptancePrompt extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;

  const _AcceptancePrompt({required this.isDark, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black.withAlpha(153);

    return GlassCard(
      key: const ValueKey('prompt'),
      padding: const EdgeInsets.all(18),
      color: isDark ? Colors.white.withAlpha(16) : Colors.white.withAlpha(130),
      child: Column(
        children: [
          _BreathLine(
            icon: Icons.visibility_rounded,
            text: 'Notice it without fixing it.',
            color: primaryColor,
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _BreathLine(
            icon: Icons.favorite_border_rounded,
            text: 'Let your body know it is allowed to soften.',
            color: Colors.pink.shade300,
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _BreathLine(
            icon: Icons.air_rounded,
            text: 'Take one slow breath and give it room.',
            color: Colors.teal.shade300,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _AcceptanceResult extends StatelessWidget {
  final String feeling;
  final VoidCallback onReset;

  const _AcceptanceResult({required this.feeling, required this.onReset});

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
            'This can be here.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '"$feeling"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withAlpha(153),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'You do not have to like it, solve it, or push it away. For this breath, you can simply make room.',
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

class _BreathLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  const _BreathLine({
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
