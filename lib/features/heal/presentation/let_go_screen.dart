import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LetGoScreen extends StatefulWidget {
  const LetGoScreen({super.key});

  @override
  State<LetGoScreen> createState() => _LetGoScreenState();
}

class _LetGoScreenState extends State<LetGoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _balloonController;
  late final Animation<double> _floatProgress;
  late final Animation<double> _floatScale;
  late final Animation<double> _floatOpacity;

  bool _isReleased = false;
  bool _hasDriftedAway = false;

  @override
  void initState() {
    super.initState();
    _balloonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _floatProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _balloonController, curve: Curves.easeInOutCubic),
    );
    _floatScale = Tween<double>(begin: 1, end: 0.32).animate(
      CurvedAnimation(parent: _balloonController, curve: Curves.easeInOutCubic),
    );
    _floatOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _balloonController,
        curve: const Interval(0.72, 1, curve: Curves.easeOut),
      ),
    );

    _balloonController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _hasDriftedAway = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _balloonController.dispose();
    super.dispose();
  }

  void _releaseBalloon() {
    if (_textController.text.trim().isEmpty || _isReleased) return;
    setState(() {
      _isReleased = true;
      _hasDriftedAway = false;
    });
    HapticFeedback.lightImpact();
    _balloonController.forward(from: 0);
  }

  void _reset() {
    setState(() {
      _isReleased = false;
      _hasDriftedAway = false;
      _textController.clear();
    });
    _balloonController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.lightBlue.shade100,
      appBar: AppBar(
        title: const Text(
          'Let it go',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/let_go_sky_background.png',
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withAlpha(56)
                      : Colors.white.withAlpha(38),
                ),
              ),
              SafeArea(
                child: _hasDriftedAway
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 68, 20, 24),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TextButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Take another balloon'),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final keyboardInset = MediaQuery.viewInsetsOf(
                            context,
                          ).bottom;
                          const topPadding = 68.0;
                          const bottomPadding = 24.0;
                          final contentHeight =
                              constraints.maxHeight -
                              topPadding -
                              bottomPadding -
                              keyboardInset;

                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              topPadding,
                              20,
                              bottomPadding + keyboardInset,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth - 40,
                                minHeight: contentHeight.clamp(
                                  0.0,
                                  double.infinity,
                                ),
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    if (!_isReleased) ...[
                                      Text(
                                        'Write what you are ready to release',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Let the balloon drift away ...',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black.withAlpha(153),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    _BalloonReleaseArea(
                                      controller: _textController,
                                      animation: _balloonController,
                                      floatProgress: _floatProgress,
                                      floatScale: _floatScale,
                                      floatOpacity: _floatOpacity,
                                      isReleased: _isReleased,
                                      primaryColor: primaryColor,
                                      isDark: isDark,
                                      onChanged: () => setState(() {}),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isReleased ||
                                                _textController.text
                                                    .trim()
                                                    .isEmpty
                                            ? null
                                            : _releaseBalloon,
                                        icon: const Icon(
                                          Icons.air_rounded,
                                          size: 28,
                                        ),
                                        label: const Text(
                                          'Let it go',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: primaryColor
                                              .withAlpha(isDark ? 96 : 116),
                                          disabledForegroundColor: Colors.white
                                              .withAlpha(190),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalloonReleaseArea extends StatelessWidget {
  final TextEditingController controller;
  final Animation<double> animation;
  final Animation<double> floatProgress;
  final Animation<double> floatScale;
  final Animation<double> floatOpacity;
  final bool isReleased;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onChanged;

  const _BalloonReleaseArea({
    required this.controller,
    required this.animation,
    required this.floatProgress,
    required this.floatScale,
    required this.floatOpacity,
    required this.isReleased,
    required this.primaryColor,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final releaseDistance = MediaQuery.sizeOf(context).height + 360;
          final verticalOffset = -releaseDistance * floatProgress.value;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, verticalOffset),
                child: Transform.scale(
                  scale: floatScale.value,
                  child: Opacity(
                    opacity: floatOpacity.value,
                    child: SizedBox(
                      width: 210,
                      height: 270,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(210, 270),
                            painter: _LetGoBalloonPainter(
                              color: primaryColor,
                              isDark: isDark,
                            ),
                          ),
                          Positioned(
                            top: 78,
                            left: 30,
                            right: 30,
                            child: TextField(
                              controller: controller,
                              enabled: !isReleased,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 90,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (_) => onChanged(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Write it here',
                                counterText: '',
                                hintStyle: TextStyle(color: Colors.black12),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isReleased)
                Positioned(
                  bottom: 12,
                  child: Text(
                    'Letting it drift...',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LetGoBalloonPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _LetGoBalloonPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height * 0.39);

    final balloonPath = Path()
      ..moveTo(center.dx, height * 0.04)
      ..cubicTo(
        width * 0.92,
        height * 0.06,
        width * 0.95,
        height * 0.62,
        center.dx,
        height * 0.76,
      )
      ..cubicTo(
        width * 0.05,
        height * 0.62,
        width * 0.08,
        height * 0.06,
        center.dx,
        height * 0.04,
      );

    final balloonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.0,
        colors: [
          Colors.white.withAlpha(isDark ? 94 : 166),
          color.withAlpha(222),
          color.withAlpha(136),
        ],
        stops: const [0, 0.62, 1],
      ).createShader(Rect.fromLTWH(0, 0, width, height * 0.78));

    canvas.drawPath(balloonPath, balloonPaint);

    final outlinePaint = Paint()
      ..color = color.withAlpha(170)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(balloonPath, outlinePaint);

    final knotPaint = Paint()..color = color.withAlpha(220);
    final knotPath = Path()
      ..moveTo(center.dx, height * 0.76)
      ..lineTo(center.dx - 12, height * 0.84)
      ..lineTo(center.dx + 12, height * 0.84)
      ..close();
    canvas.drawPath(knotPath, knotPaint);

    final stringPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final stringPath = Path()
      ..moveTo(center.dx, height * 0.84)
      ..quadraticBezierTo(center.dx - 20, height * 0.92, center.dx + 4, height);
    canvas.drawPath(stringPath, stringPaint);
  }

  @override
  bool shouldRepaint(covariant _LetGoBalloonPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
