import 'package:flutter/foundation.dart';
import '../models/onboarding_answers.dart';

/// Single source of truth for the onboarding flow.
/// Wrap the onboarding root in a provider for OnboardingState (see main.dart)
/// and read or update it from any screen with
/// `context.watch<OnboardingState>()` or `context.read<OnboardingState>()`.
class OnboardingState extends ChangeNotifier {
  final Future<void> Function(OnboardingAnswers answers) onComplete;

  OnboardingState({required this.onComplete});

  final OnboardingAnswers answers = OnboardingAnswers();
  bool _isCompleting = false;
  bool get isCompleting => _isCompleting;

  /// Total number of onboarding screens (used to drive the progress bar).
  /// Screens 1-2 (welcome, social proof) and 7-10 (exercise, info, loading,
  /// reveal) don't need a progress bar — only the question screens (3-6) do.
  static const int totalQuestionScreens = 4;

  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  double get progress => (_currentQuestionIndex + 1) / totalQuestionScreens;

  void advanceQuestion() {
    _currentQuestionIndex = (_currentQuestionIndex + 1).clamp(
      0,
      totalQuestionScreens - 1,
    );
    notifyListeners();
  }

  void retreatQuestion() {
    _currentQuestionIndex = (_currentQuestionIndex - 1).clamp(
      0,
      totalQuestionScreens - 1,
    );
    notifyListeners();
  }

  // --- Screen 3 ---
  void toggleStruggle(AnxietyStruggle struggle) {
    if (answers.struggles.contains(struggle)) {
      answers.struggles.remove(struggle);
    } else {
      answers.struggles.add(struggle);
    }
    notifyListeners();
  }

  // --- Screen 4 ---
  void setFrequency(AnxietyFrequency frequency) {
    answers.frequency = frequency;
    notifyListeners();
  }

  // --- Screen 5 ---
  void setImpact(LifeImpact impact) {
    answers.impact = impact;
    notifyListeners();
  }

  // --- Screen 6 ---
  void setGoal(OnboardingGoal goal) {
    answers.goal = goal;
    notifyListeners();
  }

  // --- Screen 7 ---
  void setBreathingExerciseCompleted(bool completed) {
    answers.completedBreathingExercise = completed;
    notifyListeners();
  }

  // --- Screen 8 ---
  void setFirstName(String name) {
    answers.firstName = name;
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    answers.notificationsEnabled = enabled;
    notifyListeners();
  }

  /// Persist the answers and let the app transition to its authenticated shell.
  Future<void> completeOnboarding() async {
    if (_isCompleting) return;
    _isCompleting = true;
    notifyListeners();
    if (kDebugMode) {
      print('Onboarding complete: ${answers.toJson()}');
    }
    try {
      await onComplete(answers);
    } finally {
      _isCompleting = false;
      notifyListeners();
    }
  }
}
