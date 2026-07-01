import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class BubblePopScreen extends StatefulWidget {
  const BubblePopScreen({super.key});

  @override
  State<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _BubblePopScreenState extends State<BubblePopScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final List<_Bubble> _bubbles = [];

  late final Ticker _ticker;
  late final AudioPlayer _popPlayer;
  late final AudioPlayer _musicPlayer;
  Duration _lastElapsed = Duration.zero;
  Size _playAreaSize = Size.zero;
  double _spawnAccumulator = 0;
  double _speedMultiplier = 0.7;
  int _score = 0;
  int _missed = 0;
  bool _musicEnabled = false;

  @override
  void initState() {
    super.initState();
    _popPlayer = AudioPlayer(playerId: 'bubble_pop_sound');
    _musicPlayer = AudioPlayer(playerId: 'bubble_pop_music');
    unawaited(_popPlayer.setReleaseMode(ReleaseMode.stop));
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _popPlayer.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final deltaSeconds = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds /
              Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;

    if (_playAreaSize == Size.zero) return;

    _spawnAccumulator += deltaSeconds;
    if (_spawnAccumulator >= 0.42 && _bubbles.length < 24) {
      _spawnAccumulator = 0;
      _spawnBubble();
    }

    for (final bubble in _bubbles) {
      if (bubble.isPopped) {
        bubble.popProgress += deltaSeconds * 4.5;
      } else {
        bubble.center = Offset(
          bubble.center.dx +
              sin(elapsed.inMilliseconds / 500 + bubble.phase) * 0.25,
          bubble.center.dy + bubble.speed * _speedMultiplier * deltaSeconds,
        );
      }
    }

    var missedThisFrame = 0;
    _bubbles.removeWhere((bubble) {
      if (bubble.isPopped && bubble.popProgress >= 1) return true;
      if (bubble.center.dy - bubble.radius > _playAreaSize.height) {
        missedThisFrame++;
        return true;
      }
      return false;
    });
    if (missedThisFrame > 0) {
      _missed += missedThisFrame;
    }

    if (mounted) setState(() {});
  }

  void _spawnBubble() {
    final radius = 22 + _random.nextDouble() * 28;
    final x =
        radius + _random.nextDouble() * (_playAreaSize.width - radius * 2);
    final colors = [
      const Color(0xFF7FC8B2),
      const Color(0xFF6FA8DC),
      const Color(0xFFC9C3E6),
      const Color(0xFFE7C9A9),
      const Color(0xFFA8D5BA),
    ];

    _bubbles.add(
      _Bubble(
        center: Offset(x, -radius),
        radius: radius,
        speed: 10 + _random.nextDouble() * 128,
        color: colors[_random.nextInt(colors.length)],
        phase: _random.nextDouble() * pi * 2,
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    final position = details.localPosition;
    _Bubble? hit;

    for (final bubble in _bubbles.reversed) {
      if (bubble.isPopped) continue;
      final distance = (bubble.center - position).distance;
      if (distance <= bubble.radius) {
        hit = bubble;
        break;
      }
    }

    if (hit == null) return;

    HapticFeedback.lightImpact();
    setState(() {
      hit!.isPopped = true;
      hit.popProgress = 0;
      _score++;
    });
  }

  Future<void> _startMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource('sounds/meditation_sacred Space_432_369.mp3'),
        volume: 0.32,
      );
    } catch (error) {
      debugPrint('[BubblePopScreen] Music failed: $error');
    }
  }

  void _toggleMusic() {
    HapticFeedback.selectionClick();
    setState(() => _musicEnabled = !_musicEnabled);

    unawaited(
      (_musicEnabled ? _startMusic() : _musicPlayer.pause()).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint('[BubblePopScreen] Music toggle failed: $error');
      }),
    );
  }

  void _restart() {
    HapticFeedback.selectionClick();
    setState(() {
      _bubbles.clear();
      _score = 0;
      _missed = 0;
      _spawnAccumulator = 0;
      _lastElapsed = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bubble Pop',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _musicEnabled ? 'Sound on' : 'Sound off',
            onPressed: _toggleMusic,
            icon: Icon(
              _musicEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Restart',
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  _ScorePill(
                    icon: Icons.bubble_chart_rounded,
                    label: 'Popped',
                    value: _score,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 12),
                  _ScorePill(
                    icon: Icons.water_drop_outlined,
                    label: 'Floated by',
                    value: _missed,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _playAreaSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _handleTap,
                    child: CustomPaint(
                      size: _playAreaSize,
                      painter: _BubblePainter(
                        bubbles: List<_Bubble>.unmodifiable(_bubbles),
                        isDark: isDark,
                      ),
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _score == 0 && _bubbles.length < 3 ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            'Tap bubbles to pop them',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black.withAlpha(112),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: _SpeedControl(
                value: _speedMultiplier,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _speedMultiplier = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedControl extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _SpeedControl({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(12)
            : Colors.white.withAlpha(178),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed_rounded, size: 20),
          const SizedBox(width: 10),
          Text(
            '${value.toStringAsFixed(1)}x',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: value,
              min: 0.5,
              max: 2.0,
              divisions: 4,
              label: '${value.toStringAsFixed(1)}x',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _ScorePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.white.withAlpha(166),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final bool isDark;

  const _BubblePainter({required this.bubbles, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF1F2933), const Color(0xFF263545)]
            : [const Color(0xFFFAF8F5), const Color(0xFFEAF5F1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    for (final bubble in bubbles) {
      final popScale = bubble.isPopped ? 1 + bubble.popProgress * 0.8 : 1.0;
      final opacity = bubble.isPopped ? 1 - bubble.popProgress : 1.0;
      if (opacity <= 0) continue;

      final rect = Rect.fromCircle(
        center: bubble.center,
        radius: bubble.radius * popScale,
      );
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withAlpha((190 * opacity).round()),
            bubble.color.withAlpha((150 * opacity).round()),
            bubble.color.withAlpha((55 * opacity).round()),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(rect);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withAlpha((155 * opacity).round());

      canvas.drawCircle(bubble.center, bubble.radius * popScale, fillPaint);
      canvas.drawCircle(bubble.center, bubble.radius * popScale, strokePaint);

      if (!bubble.isPopped) {
        final shinePaint = Paint()
          ..color = Colors.white.withAlpha(150)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(
            center: bubble.center.translate(
              -bubble.radius * 0.28,
              -bubble.radius * 0.32,
            ),
            width: bubble.radius * 0.42,
            height: bubble.radius * 0.22,
          ),
          shinePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.bubbles != bubbles || oldDelegate.isDark != isDark;
  }
}

class _Bubble {
  Offset center;
  final double radius;
  final double speed;
  final Color color;
  final double phase;
  bool isPopped;
  double popProgress;

  _Bubble({
    required this.center,
    required this.radius,
    required this.speed,
    required this.color,
    required this.phase,
  }) : isPopped = false,
       popProgress = 0;
}
