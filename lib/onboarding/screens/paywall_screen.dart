import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/onboarding_answers.dart';
import '../state/onboarding_state.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/subscription/presentation/onboarding_paywall_result.dart';

enum SubscriptionPlan { annual, monthly }

/// Onboarding paywall with an explicit free-version continuation. Swap in your
/// actual RevenueCat / StoreKit
/// offering IDs and prices where marked below.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.annual;

  /// Builds a benefit headline tied to the user's screen 3-6 answers,
  /// instead of a generic feature list.
  String _headlineFor(OnboardingAnswers answers) {
    if (answers.struggles.contains(AnxietyStruggle.panicAttacks)) {
      return 'Unlimited breathing exercises\nfor your panic attacks';
    }
    if (answers.struggles.contains(AnxietyStruggle.sleepAnxiety)) {
      return 'Fall asleep faster\nwith unlimited sleep tools';
    }
    if (answers.struggles.contains(AnxietyStruggle.overthinking)) {
      return 'Quiet the overthinking\nwhenever it strikes';
    }
    return 'Unlimited tools for calmer days';
  }

  Future<void> _startTrial(BuildContext context) async {
    // TODO: wire up your purchase flow, e.g. via RevenueCat:
    // final result = await Purchases.purchasePackage(selectedPackage);
    final result = await Navigator.of(context).push<OnboardingPaywallResult>(
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(isOnboardingPaywall: true),
      ),
    );
    if (context.mounted && result != null) await _finishOnboarding(context);
  }

  Future<void> _finishOnboarding(BuildContext context) {
    return context.read<OnboardingState>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final answers = context.watch<OnboardingState>().answers;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  // Small, gray, easy-to-miss dismiss — never make this
                  // visually compete with the CTA below.
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  onPressed: () => _finishOnboarding(context),
                  child: const Text('Continue with free version'),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _headlineFor(answers),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),
              _PlanOption(
                label: 'Annual',
                // TODO: pull real price from your store offering
                priceLabel: '€39.99/year (€3.33/mo)',
                badge: 'BEST VALUE',
                selected: _selectedPlan == SubscriptionPlan.annual,
                onTap: () =>
                    setState(() => _selectedPlan = SubscriptionPlan.annual),
              ),
              const SizedBox(height: 12),
              _PlanOption(
                label: 'Monthly',
                priceLabel: '€8.99/month',
                selected: _selectedPlan == SubscriptionPlan.monthly,
                onTap: () =>
                    setState(() => _selectedPlan = SubscriptionPlan.monthly),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _startTrial(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Free Trial',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '3-day free trial, then billed as selected. Cancel anytime.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String label;
  final String priceLabel;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.label,
    required this.priceLabel,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    priceLabel,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
          ],
        ),
      ),
    );
  }
}
