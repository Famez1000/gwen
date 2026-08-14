import 'package:flutter/material.dart';

import '../../../core/services/revenue_cat_service.dart';
import 'legacy_subscription_screen.dart';
import 'revenue_cat_subscription_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  final bool isOnboardingPaywall;

  const SubscriptionScreen({super.key, this.isOnboardingPaywall = false});

  @override
  Widget build(BuildContext context) {
    if (useRevenueCatPaywalls) {
      return RevenueCatSubscriptionScreen(
        isOnboardingPaywall: isOnboardingPaywall,
      );
    }

    return LegacySubscriptionScreen(isOnboardingPaywall: isOnboardingPaywall);
  }
}
