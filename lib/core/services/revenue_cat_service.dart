import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../state/app_state.dart';

const bool useRevenueCatPaywalls = bool.fromEnvironment(
  'USE_REVENUECAT_PAYWALLS',
  defaultValue: false,
);

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  static const String _testApiKey = String.fromEnvironment(
    'REVENUECAT_TEST_API_KEY',
    defaultValue: 'test_MhGchhcCwHSrkOiJRrQUWNdulDl',
  );
  static const String _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const String _iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const String entitlementIdentifier = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
  );

  bool _configured = false;
  AppState? _appState;
  CustomerInfoUpdateListener? _customerInfoListener;

  bool get isConfigured => _configured;

  Future<void> initialize(AppState appState) async {
    if (!useRevenueCatPaywalls) return;
    if (_configured) return;
    if (!_isSupportedPlatform) return;

    _appState = appState;
    final apiKey = kReleaseMode ? _productionApiKey : _testApiKey;
    if (apiKey.isEmpty) {
      await appState.setStoreSubscriptionActive(false);
      debugPrint(
        'RevenueCat is disabled: provide the platform public SDK key with '
        '--dart-define.',
      );
      return;
    }

    try {
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;

      _customerInfoListener = (customerInfo) {
        unawaited(_applyCustomerInfo(customerInfo));
      };
      Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);
      await refreshSubscriptionStatus();
    } catch (_) {
      _configured = false;
      await appState.setStoreSubscriptionActive(false);
      rethrow;
    }
  }

  Future<bool> refreshSubscriptionStatus() async {
    if (!_configured) return false;
    final customerInfo = await Purchases.getCustomerInfo();
    return _applyCustomerInfo(customerInfo);
  }

  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    final customerInfo = await Purchases.restorePurchases();
    return _applyCustomerInfo(customerInfo);
  }

  Future<bool> _applyCustomerInfo(CustomerInfo customerInfo) async {
    final activeEntitlements = customerInfo.entitlements.active;
    final isActive = entitlementIdentifier.isEmpty
        ? activeEntitlements.isNotEmpty
        : activeEntitlements.containsKey(entitlementIdentifier);
    await _appState?.setStoreSubscriptionActive(isActive);
    return isActive;
  }

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _productionApiKey =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosApiKey : _androidApiKey;
}
