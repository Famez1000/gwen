import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/glass_card.dart';

class ThoughtSupportScreen extends StatefulWidget {
  const ThoughtSupportScreen({Key? key}) : super(key: key);

  @override
  State<ThoughtSupportScreen> createState() => _ThoughtSupportScreenState();
}

class _ThoughtSupportScreenState extends State<ThoughtSupportScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _thoughtController = TextEditingController();

  int _currentIndex = 0;
  String _userThought = "";

  // Animation states for Balloon Release
  late AnimationController _balloonController;
  late Animation<double> _balloonYOffset;
  late Animation<double> _balloonScale;
  late Animation<double> _balloonOpacity;

  bool _isFloating = false;
  bool _isPopped = false;

  @override
  void initState() {
    super.initState();

    _balloonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _balloonYOffset = Tween<double>(begin: 0.0, end: -450.0).animate(
      CurvedAnimation(parent: _balloonController, curve: Curves.easeInQuad),
    );

    _balloonScale = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _balloonController, curve: Curves.easeInQuad),
    );

    _balloonOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _balloonController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _balloonController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isPopped = true;
        });
        HapticFeedback.vibrate();
      }
    });
  }

  void _nextCard() {
    if (_currentIndex == 0) {
      if (_thoughtController.text.trim().isEmpty) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _userThought = _thoughtController.text.trim();
      });
    }

    setState(() {
      _currentIndex++;
    });
    _pageController.animateToPage(
      _currentIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _releaseBalloon() {
    setState(() {
      _isFloating = true;
    });
    HapticFeedback.mediumImpact();
    _balloonController.forward();
  }

  void _reset() {
    setState(() {
      _currentIndex = 0;
      _userThought = "";
      _isFloating = false;
      _isPopped = false;
      _thoughtController.clear();
    });
    _balloonController.reset();
    _pageController.jumpToPage(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thoughtController.dispose();
    _balloonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thought Diffuser",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentIndex > 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Horizontal progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? primaryColor
                          : (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepInput(isDark, primaryColor),
                    _buildStepDefusion(isDark, primaryColor),
                    _buildStepReframing(isDark, primaryColor),
                    _buildStepBalloonRelease(isDark, primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 1: Input scary thought
  Widget _buildStepInput(bool isDark, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What thought is scaring you right now?",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Describe the worry in one simple sentence.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 36),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _thoughtController,
            maxLines: 2,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _nextCard(),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: const InputDecoration(
              hintText: "e.g., 'Something bad is going to happen today'",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              counterText: "",
            ),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: ElevatedButton(
            onPressed: _nextCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Continue"),
          ),
        ),
      ],
    );
  }

  // Card 2: Restate thought to gain cognitive distance
  Widget _buildStepDefusion(bool isDark, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Creating Distance",
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        const Text(
          "Your brain presents thoughts as absolute facts. Let's create space. Try reading this statement aloud:",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 36),
        GlassCard(
          color: primary.withOpacity(0.08),
          padding: const EdgeInsets.all(24),
          child: Text(
            "\"I am having the thought that: $_userThought.\"",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Notice how adding those prefix words reminds you: this is just an event in your mind, not a permanent physical reality.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black.withOpacity(0.6),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: ElevatedButton(
            onPressed: _nextCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Fine"),
          ),
        ),
      ],
    );
  }

  // Card 3: Cognitive Reframing
  Widget _buildStepReframing(bool isDark, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Inspecting your Track Record",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Have you felt this level of threat or uncertainty before?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _nextCard,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: const Text("Yes, often", textAlign: TextAlign.center),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _nextCard,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: const Text("A few times", textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _nextCard,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: const Text("No, this is new", textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          "No matter what, your track record of surviving is 100%. You survived every single scary thought before. You will survive this one too.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black.withOpacity(0.6),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Card 4: Balloon Release Animation
  Widget _buildStepBalloonRelease(bool isDark, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isFloating && !_isPopped) ...[
          const Text(
            "Release the Thought",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Watch this thought float away as we release it into the atmosphere.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],

        if (_isPopped) ...[
          const Icon(Icons.auto_awesome, size: 64, color: Colors.amberAccent),
          const SizedBox(height: 20),
          const Text(
            "It is Gone.",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Thoughts are just clouds in the sky. Let them pass, let them go.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Finish"),
          ),
        ] else ...[
          Expanded(
            child: AnimatedBuilder(
              animation: _balloonController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Moving Balloon
                    Transform.translate(
                      offset: Offset(0, _balloonYOffset.value),
                      child: Transform.scale(
                        scale: _balloonScale.value,
                        child: Opacity(
                          opacity: _balloonOpacity.value,
                          child: GestureDetector(
                            onTap: _isFloating ? null : _releaseBalloon,
                            child: Container(
                              width: 170,
                              height: 220,
                              child: CustomPaint(
                                painter: _BalloonPainter(
                                  color: primary,
                                  thoughtText: _userThought,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (!_isFloating)
                      const Positioned(
                        bottom: 40,
                        child: Text(
                          "Tap the balloon to release it",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _BalloonPainter extends CustomPainter {
  final Color color;
  final String thoughtText;
  final bool isDark;

  _BalloonPainter({
    required this.color,
    required this.thoughtText,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final center = Offset(w / 2, h * 0.45);
    final radiusX = w * 0.45;

    final paintBalloon = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(isDark ? 0.3 : 0.6),
          color.withOpacity(0.85),
          color.withOpacity(0.5),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTRB(w * 0.05, h * 0.07, w * 0.95, h * 0.83));

    // Balloon body path
    final balloonPath = Path();
    balloonPath.moveTo(center.dx, h * 0.07);
    // Draw egg shape
    balloonPath.cubicTo(
      center.dx + radiusX,
      h * 0.07,
      center.dx + radiusX,
      h * 0.83,
      center.dx,
      h * 0.83,
    );
    balloonPath.cubicTo(
      center.dx - radiusX,
      h * 0.83,
      center.dx - radiusX,
      h * 0.07,
      center.dx,
      h * 0.07,
    );
    canvas.drawPath(balloonPath, paintBalloon);

    // Balloon knot
    final paintKnot = Paint()..color = color.withOpacity(0.9);
    final knotPath = Path();
    knotPath.moveTo(center.dx, h * 0.83);
    knotPath.lineTo(center.dx - 10, h * 0.88);
    knotPath.lineTo(center.dx + 10, h * 0.88);
    knotPath.close();
    canvas.drawPath(knotPath, paintKnot);

    // Balloon string
    final paintString = Paint()
      ..color = isDark ? Colors.white30 : Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final stringPath = Path();
    stringPath.moveTo(center.dx, h * 0.88);
    stringPath.quadraticBezierTo(
      center.dx - 15,
      h * 0.94,
      center.dx + 5,
      h * 1.0,
    );
    canvas.drawPath(stringPath, paintString);

    // Draw thought text inside balloon
    final textSpan = TextSpan(
      text: thoughtText,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 6,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: w * 0.72);
    final offset = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - (textPainter.height / 2),
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter oldDelegate) {
    return oldDelegate.thoughtText != thoughtText || oldDelegate.color != color;
  }
}
