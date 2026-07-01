import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../gad7/presentation/gad7_screen.dart';

class ReflectionScreen extends StatefulWidget {
  final AppState appState;

  const ReflectionScreen({Key? key, required this.appState}) : super(key: key);

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _journalController = TextEditingController();
  final Set<String> _selectedTriggers = {};
  
  // Voice Recording Simulation States
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late AnimationController _waveController;
  bool _hasRecordedVoice = false;

  final List<String> _triggerTags = [
    "work",
    "relationships",
    "finances",
    "loneliness",
    "overstimulation",
    "uncertainty",
    "sleep",
    "caffeine",
    "health"
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _toggleTrigger(String tag) {
    setState(() {
      if (_selectedTriggers.contains(tag)) {
        _selectedTriggers.remove(tag);
      } else {
        _selectedTriggers.add(tag);
      }
    });
    if (widget.appState.hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _hasRecordedVoice = false;
    });
    _waveController.repeat(reverse: true);
    if (widget.appState.hapticEnabled) {
      HapticFeedback.selectionClick();
    }

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
      // Cap recording at 30 seconds
      if (_recordingSeconds >= 30) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _waveController.stop();
    setState(() {
      _isRecording = false;
      _hasRecordedVoice = _recordingSeconds > 1;
    });
    if (widget.appState.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void _saveReflection() {
    final note = _journalController.text.trim();
    if (note.isEmpty && !_hasRecordedVoice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a reflection or record a voice note.")),
      );
      return;
    }

    final String finalNote = _hasRecordedVoice
        ? "$note (Recorded voice note: $_recordingSeconds seconds)".trim()
        : note;

    widget.appState.addReflection(
      finalNote,
      _selectedTriggers.toList(),
    );

    // Reset fields
    _journalController.clear();
    setState(() {
      _selectedTriggers.clear();
      _hasRecordedVoice = false;
      _recordingSeconds = 0;
    });

    if (widget.appState.hapticEnabled) {
      HapticFeedback.vibrate();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reflection saved successfully. Take a deep breath."),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  void dispose() {
    _journalController.dispose();
    _recordingTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Reflection", style: TextStyle(fontWeight: FontWeight.w500)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inspirational text
              Text(
                "Letting it out",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(letterSpacing: 1.0),
              ),
              const SizedBox(height: 4),
              Text(
                "Acknowledge your space.",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Trigger Selectors Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "What elements triggered your anxiety today?",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _triggerTags.map((tag) {
                        final isSelected = _selectedTriggers.contains(tag);
                        return FilterChip(
                          label: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black.withOpacity(0.8)),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (_) => _toggleTrigger(tag),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Micro Journaling Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Write one sentence about what you need right now:",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _journalController,
                        maxLines: 3,
                        maxLength: 140,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        decoration: const InputDecoration(
                          hintText: "e.g., 'I need a few minutes of quiet and a warm glass of tea.'",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          counterText: "",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Voice Note Card
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          color: _isRecording ? Colors.redAccent : primaryColor,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Voice Note Option",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                "Speak freely. It will be saved locally in your logs.",
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Voice wave animation
                    if (_isRecording) ...[
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Container(
                            height: 36,
                            alignment: Alignment.center,
                            child: CustomPaint(
                              painter: _SoundWavePainter(
                                value: _waveController.value,
                                color: Colors.redAccent,
                              ),
                              child: Container(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Recording: $_recordingSeconds seconds (Tap again to stop)",
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ] else if (_hasRecordedVoice) ...[
                      const Icon(Icons.check_circle, color: Colors.teal, size: 30),
                      const SizedBox(height: 6),
                      Text(
                        "Voice Note Recorded ($_recordingSeconds s)",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Recording Action Button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? Colors.redAccent.withOpacity(0.15)
                              : primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRecording ? Colors.redAccent : primaryColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: _isRecording ? Colors.redAccent : primaryColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Save button
              ElevatedButton(
                onPressed: _saveReflection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  "Save Reflection",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GAD7Screen(appState: widget.appState))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  "GAD-7 analysis",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  final double value;
  final Color color;

  _SoundWavePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    final int lineCount = 15;
    final double spacing = width / (lineCount + 1);

    for (int i = 0; i < lineCount; i++) {
      final double x = spacing * (i + 1);
      // Math to make wave dynamic
      final double waveHeight = height * 0.7 * (0.3 + 0.7 * sin(value * pi * 2 + i * 0.5).abs());
      final double yStart = (height - waveHeight) / 2;
      final double yEnd = yStart + waveHeight;

      canvas.drawLine(Offset(x, yStart), Offset(x, yEnd), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
