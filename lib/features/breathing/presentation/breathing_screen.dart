import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/state/app_state.dart';

class BreathingTechnique {
  final String name;
  final String description;
  final List<BreathingStep> steps;

  BreathingTechnique({
    required this.name,
    required this.description,
    required this.steps,
  });
}

class BreathingStep {
  final String actionText;
  final int durationSeconds;
  final double targetScale; // 0.0 to 1.0

  BreathingStep({
    required this.actionText,
    required this.durationSeconds,
    required this.targetScale,
  });
}

class BreathingScreen extends StatefulWidget {
  final AppState appState;

  const BreathingScreen({Key? key, required this.appState}) : super(key: key);

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;
  late Animation<double> _orbAnimation;

  final List<BreathingTechnique> _techniques = [
    BreathingTechnique(
      name: "Coherent Breathing",
      description:
          "Slows breathing rate to 6 breaths/min. Resonates with natural heart rhythm.",
      steps: [
        BreathingStep(
          actionText: "Inhale...",
          durationSeconds: 5,
          targetScale: 1.0,
        ),
        BreathingStep(
          actionText: "Exhale...",
          durationSeconds: 5,
          targetScale: 0.3,
        ),
      ],
    ),
    BreathingTechnique(
      name: "Box Breathing",
      description:
          "Equal parts breathing to stabilize nervous system. Favored by Navy SEALs.",
      steps: [
        BreathingStep(
          actionText: "Inhale...",
          durationSeconds: 4,
          targetScale: 1.0,
        ),
        BreathingStep(
          actionText: "Hold...",
          durationSeconds: 4,
          targetScale: 1.0,
        ),
        BreathingStep(
          actionText: "Exhale...",
          durationSeconds: 4,
          targetScale: 0.3,
        ),
        BreathingStep(
          actionText: "Hold...",
          durationSeconds: 4,
          targetScale: 0.3,
        ),
      ],
    ),
    BreathingTechnique(
      name: "4-7-8 Breathing",
      description:
          "Deep somatic relaxer. Excellent for drifting to sleep and relieving panic.",
      steps: [
        BreathingStep(
          actionText: "Inhale...",
          durationSeconds: 4,
          targetScale: 1.0,
        ),
        BreathingStep(
          actionText: "Hold...",
          durationSeconds: 7,
          targetScale: 1.0,
        ),
        BreathingStep(
          actionText: "Exhale...",
          durationSeconds: 8,
          targetScale: 0.2,
        ),
      ],
    ),
    BreathingTechnique(
      name: "Physiological Sigh",
      description:
          "Two quick inhales followed by one long exhale. Rapid mental reset.",
      steps: [
        BreathingStep(
          actionText: "Deep Inhale...",
          durationSeconds: 3,
          targetScale: 0.7,
        ),
        BreathingStep(
          actionText: "Sniff in!",
          durationSeconds: 1,
          targetScale: 1.0,
        ),
        BreathingStep(
          actionText: "Sigh out...",
          durationSeconds: 6,
          targetScale: 0.2,
        ),
      ],
    ),
  ];

  late BreathingTechnique _selectedTechnique;
  int _selectedDurationMinutes = 1; // 1, 3, or 5

  bool _isPlaying = false;
  int _currentStepIndex = 0;
  int _secondsRemaining = 0;
  int _stepSecondsRemaining = 0;

  Timer? _sessionTimer;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _selectedTechnique = _techniques[0];

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _orbAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _orbController, curve: Curves.easeInOut));
    _orbController.value = 0.3; // Starting scale
  }

  void _startBreathingSession() {
    setState(() {
      _isPlaying = true;
      _currentStepIndex = 0;
      _secondsRemaining = _selectedDurationMinutes * 60;
      _startStep(_currentStepIndex);
    });

    // Overall session timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _endSession(completed: true);
      }
    });
  }

  void _startStep(int stepIndex) {
    _stepTimer?.cancel();
    if (!_isPlaying) return;

    final step = _selectedTechnique.steps[stepIndex];
    _stepSecondsRemaining = step.durationSeconds;

    // Trigger initial haptic feedback
    if (widget.appState.hapticEnabled) {
      if (step.actionText.contains("Hold")) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    // Configure animation
    final double endVal = step.targetScale;

    _orbController.animateTo(
      endVal,
      duration: Duration(seconds: step.durationSeconds),
      curve: Curves.easeInOut,
    );

    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_stepSecondsRemaining > 1) {
        setState(() {
          _stepSecondsRemaining--;
        });
      } else {
        // Move to next step
        setState(() {
          _currentStepIndex =
              (_currentStepIndex + 1) % _selectedTechnique.steps.length;
          _startStep(_currentStepIndex);
        });
      }
    });
  }

  void _endSession({required bool completed}) {
    _sessionTimer?.cancel();
    _stepTimer?.cancel();
    _orbController.stop();

    if (completed) {
      widget.appState.completeBreathingSession();
      if (widget.appState.hapticEnabled) {
        HapticFeedback.vibrate();
      }
      _showCompletionDialog();
    }

    setState(() {
      _isPlaying = false;
      _orbController.value = 0.3;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E2435)
              : const Color(0xFFF9F7F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                "Beautiful Session",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You just showed up for yourself. Your nervous system is learning that you are safe.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _stepTimer?.cancel();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Breathing Sanctuary",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isPlaying)
            TextButton(
              onPressed: () => _endSession(completed: false),
              child: const Text(
                "Stop",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _isPlaying
              ? _buildActiveSessionView(isDark, primaryColor)
              : _buildSelectionView(isDark, primaryColor),
        ),
      ),
    );
  }

  Widget _buildSelectionView(bool isDark, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          "Choose a technique",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        // Techniques selection list
        Expanded(
          child: ListView.builder(
            itemCount: _techniques.length,
            itemBuilder: (context, index) {
              final tech = _techniques[index];
              final isSelected = _selectedTechnique == tech;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTechnique = tech;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withOpacity(0.08)
                          : (isDark
                                ? Colors.white.withOpacity(0.03)
                                : Colors.white.withOpacity(0.7)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? primary
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05)),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? primary : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tech.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tech.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black.withOpacity(0.6),
                                  height: 1.4,
                                ),
                              ),
                            ],
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

        // Session Duration selector
        const SizedBox(height: 16),
        Text(
          "Select duration",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        Row(
          children: [1, 3, 5].map((min) {
            final isSel = _selectedDurationMinutes == min;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDurationMinutes = min;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel
                          ? primary
                          : (isDark
                                ? Colors.white.withOpacity(0.03)
                                : Colors.white.withOpacity(0.8)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel
                            ? primary
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    child: Text(
                      "$min min",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSel
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _startBreathingSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Start Session",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActiveSessionView(bool isDark, Color primary) {
    final step = _selectedTechnique.steps[_currentStepIndex];
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _selectedTechnique.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Timer display
        Text(
          "$minutes:${seconds.toString().padLeft(2, '0')}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 50),

        // Animated Orb
        AnimatedBuilder(
          animation: _orbAnimation,
          builder: (context, child) {
            return Center(
              child: Container(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _BreathingOrbPainter(
                    scale: _orbAnimation.value,
                    color: primary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 50),

        // Phase text
        Text(
          step.actionText,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),

        // Count down for current step
        Text(
          "$_stepSecondsRemaining",
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white30 : Colors.black.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 60),

        // Small indicator progress bars of the cycle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_selectedTechnique.steps.length, (idx) {
            final isCurrent = idx == _currentStepIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isCurrent
                    ? primary
                    : (isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _BreathingOrbPainter extends CustomPainter {
  final double scale;
  final Color color;

  _BreathingOrbPainter({required this.scale, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.3 * scale;

    // Glowing halos
    for (int i = 3; i > 0; i--) {
      final paintGlow = Paint()
        ..color = color.withOpacity(0.07 / i)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * i * scale);
      canvas.drawCircle(center, baseRadius * (1.0 + (i * 0.2)), paintGlow);
    }

    // Orb shader
    final paintOrb = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, color.withOpacity(0.8), color.withOpacity(0.2)],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawCircle(center, baseRadius, paintOrb);
  }

  @override
  bool shouldRepaint(covariant _BreathingOrbPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.color != color;
  }
}
