/// All the data collected across the 10 onboarding screens.
/// This is what screen 9/10 use to build the "personalized plan",
/// and what you'll want to pass to your paywall / analytics / backend
/// once onboarding completes.
class OnboardingAnswers {
  // Screen 3 — Problem identification (multi-select)
  Set<AnxietyStruggle> struggles = {};

  // Screen 4 — Frequency / severity (single select)
  AnxietyFrequency? frequency;

  // Screen 5 — Impact question (single select)
  LifeImpact? impact;

  // Screen 6 — Goal selection (single select)
  OnboardingGoal? goal;

  // Screen 7 — Did they complete the breathing exercise?
  bool completedBreathingExercise = false;

  // Screen 8 — Light personal info
  String? firstName;
  bool notificationsEnabled = false;

  /// Human-readable label used on the plan-reveal screen (screen 10)
  /// e.g. "Factoring in: daily panic attacks, sleep disruption…"
  String get planFactorsSummary {
    final parts = <String>[];
    if (frequency != null) parts.add(frequency!.label.toLowerCase());
    if (struggles.isNotEmpty) {
      parts.add(struggles.map((s) => s.label.toLowerCase()).join(', '));
    }
    if (impact != null) parts.add(impact!.label.toLowerCase());
    return parts.join(' • ');
  }

  /// Serialize for sending to your FastAPI backend / analytics once
  /// onboarding is complete.
  Map<String, dynamic> toJson() => {
    'struggles': struggles.map((s) => s.name).toList(),
    'frequency': frequency?.name,
    'impact': impact?.name,
    'goal': goal?.name,
    'completedBreathingExercise': completedBreathingExercise,
    'firstName': firstName,
    'notificationsEnabled': notificationsEnabled,
  };
}

enum AnxietyStruggle {
  panicAttacks('Panic attacks'),
  constantWorry('Constant worry'),
  racingThoughts('Racing thoughts'),
  sleepAnxiety('Sleep anxiety'),
  socialAnxiety('Social anxiety'),
  overthinking('Overthinking');

  final String label;
  const AnxietyStruggle(this.label);
}

enum AnxietyFrequency {
  daily('Daily'),
  fewTimesAWeek('A few times a week'),
  occasionally('Occasionally'),
  situational('Only in specific situations');

  final String label;
  const AnxietyFrequency(this.label);
}

enum LifeImpact {
  sleep('Sleep'),
  workOrFocus('Work or focus'),
  relationships('Relationships'),
  physicalHealth('Physical health'),
  allOfTheAbove('All of the above');

  final String label;
  const LifeImpact(this.label);
}

enum OnboardingGoal {
  copeInTheMoment('Calm down in the moment'),
  understandTriggers('Understand my triggers'),
  buildResilience('Build long-term resilience'),
  allThree('All three');

  final String label;
  const OnboardingGoal(this.label);
}
