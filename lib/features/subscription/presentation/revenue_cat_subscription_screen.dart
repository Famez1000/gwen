import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/services/revenue_cat_service.dart';
import '../../../core/state/app_state.dart';
import '../../chat/presentation/chat_screen.dart';
import 'onboarding_paywall_result.dart';

class RevenueCatSubscriptionScreen extends StatefulWidget {
  final bool isOnboardingPaywall;

  const RevenueCatSubscriptionScreen({
    super.key,
    this.isOnboardingPaywall = false,
  });

  @override
  State<RevenueCatSubscriptionScreen> createState() =>
      _RevenueCatSubscriptionScreenState();
}

class _RevenueCatSubscriptionScreenState
    extends State<RevenueCatSubscriptionScreen> {
  bool _isPresenting = true;
  String? _errorMessage;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _presentPaywall());
  }

  Future<void> _presentPaywall() async {
    if (!mounted) return;
    setState(() {
      _isPresenting = true;
      _errorMessage = null;
      _message = null;
    });

    final revenueCat = RevenueCatService.instance;
    if (!revenueCat.isConfigured) {
      setState(() {
        _isPresenting = false;
        _errorMessage =
            'Subscriptions are not configured for this build. Add the '
            'RevenueCat public SDK key and try again.';
      });
      return;
    }

    try {
      final result = await RevenueCatUI.presentPaywall();
      final isActive = await revenueCat.refreshSubscriptionStatus();
      if (!mounted) return;

      if (result == PaywallResult.purchased && isActive) {
        await _finishSuccessfulPurchase();
        return;
      }

      if (result == PaywallResult.error) {
        setState(() {
          _isPresenting = false;
          _errorMessage =
              'RevenueCat could not display or complete the paywall. '
              'Please try again.';
        });
        return;
      }

      setState(() {
        _isPresenting = false;
        _message = isActive
            ? 'Your Gwyn Plus subscription is active.'
            : 'Choose a plan, or continue with the free version.';
      });
    } catch (error) {
      debugPrint('RevenueCat paywall failed: $error');
      if (!mounted) return;
      setState(() {
        _isPresenting = false;
        _errorMessage = 'Could not load subscriptions. Please try again.';
      });
    }
  }

  Future<void> _finishSuccessfulPurchase() async {
    if (widget.isOnboardingPaywall) {
      Navigator.of(context).pop(OnboardingPaywallResult.subscribed);
      return;
    }

    final appState = context.read<AppState>();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(appState: appState)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isOnboardingPaywall,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isOnboardingPaywall,
          title: const Text('Gwyn Plus'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _errorMessage == null && _message == null
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 18),
                      Text('Loading subscription optionsâ€¦'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _errorMessage == null
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        size: 42,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage ?? _message!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        FilledButton(
                          onPressed: _isPresenting ? null : _presentPaywall,
                          child: const Text('Try again'),
                        )
                      else if (widget.isOnboardingPaywall)
                        FilledButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(OnboardingPaywallResult.continueFree),
                          child: const Text('Continue with free version'),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
