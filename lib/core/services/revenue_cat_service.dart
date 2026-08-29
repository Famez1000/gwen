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
      final configuration = PurchasesConfiguration(apiKey);
      if (!useRevenueCatPaywalls) {
        configuration.purchasesAreCompletedBy = PurchasesAreCompletedByMyApp(
          storeKitVersion: StoreKitVersion.storeKit2,
        );
      }
      await Purchases.configure(configuration);
      _configured = true;

      _customerInfoListener = (customerInfo) {
        unawaited(_applyCustomerInfo(customerInfo));
      };
      Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);
      if (!useRevenueCatPaywalls) await Purchases.syncPurchases();
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

  /// Sends a purchase handled by the app's custom StoreKit/Play Billing UI to
  /// RevenueCat and returns the server-validated entitlement state. A null
  /// result means validation is unavailable for this build/platform.
  Future<bool?> syncExternalPurchase({
    required String productIdentifier,
    required bool isNewPurchase,
  }) async {
    if (!_configured) return null;

    try {
      if (isNewPurchase && defaultTargetPlatform == TargetPlatform.iOS) {
        await Purchases.recordPurchase(productIdentifier);
      } else {
        await Purchases.syncPurchases();
      }
      return await refreshSubscriptionStatus();
    } catch (error, stackTrace) {
      debugPrint('RevenueCat purchase validation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _appState?.setStoreSubscriptionActive(false);
      return false;
    }
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
