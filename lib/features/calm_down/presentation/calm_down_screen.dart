import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';

class CalmDownScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onDismiss;
  final VoidCallback onNavigateToGrounding;

  const CalmDownScreen({
    Key? key,
    required this.appState,
    required this.onDismiss,
    required this.onNavigateToGrounding,
  }) : super(key: key);

  @override
  State<CalmDownScreen> createState() => _CalmDownScreenState();
}

class _CalmDownScreenState extends State<CalmDownScreen> {
  // Session timer (2‑minute emergency calm‑down)
  int _secondsLeft = 120;
  Timer? _sessionTimer;

  // Exercise list – Grounding is handled via the callback
  final List<String> _exercises = [
    'Progressive Muscle Relaxation',
    'Grounding',
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_secondsLeft > 0) {
          setState(() {
            _secondsLeft--;
          });
        } else {
          _sessionTimer?.cancel();
          widget.onDismiss();
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  

  void _onExerciseSelected(String exercise) {
    if (exercise == 'Grounding') {
      widget.onNavigateToGrounding();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected exercise: $exercise')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkCalmGradient : AppTheme.breezeGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top Control Panel
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Main Content – Exercise Buttons
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Column(
                        children: _exercises.map((exercise) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ElevatedButton(
                              onPressed: () => _onExerciseSelected(exercise),
                              child: Text(exercise),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.12),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
  }
}
