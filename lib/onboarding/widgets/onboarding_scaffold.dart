import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/onboarding_state.dart';

/// Wraps a question screen (screens 3-6) with a consistent progress bar,
/// back button, and padding. Non-question screens (welcome, social proof,
/// exercise, plan reveal, etc.) build their own layout instead — they
/// shouldn't show the quiz progress bar.
class OnboardingScaffold extends StatelessWidget {
  final Widget child;
  final bool showProgress;
  final VoidCallback? onBack;

  const OnboardingScaffold({
    super.key,
    required this.child,
    this.showProgress = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  ),
                  if (showProgress)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 8,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable single-select option tile (used on screens 4, 5, 6).
class OptionTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T> onSelected;

  const OptionTile({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable multi-select option tile (used on screen 3).
class MultiOptionTile<T> extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onToggle;

  const MultiOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom "Continue" CTA button used across nearly every screen.
class ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ContinueButton({
    super.key,
    this.label = 'Continue',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
