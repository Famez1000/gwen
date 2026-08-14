# Gwyn

A new Flutter project.

## Firebase

The mobile app does not currently initialize Firebase. Firebase App Check can
be added later together with new, platform-restricted client configuration.
Generated `firebase_options.dart` and `google-services.json` files remain
ignored and must not be committed.

## RevenueCat

Subscription access and paywalls are managed by RevenueCat. Debug builds use
the RevenueCat Test Store. RevenueCat paywalls are currently disabled by
default, so normal builds continue to use the existing store paywall. Enable
RevenueCat explicitly with `USE_REVENUECAT_PAYWALLS=true`:

```powershell
flutter build appbundle --release `
  --dart-define=USE_REVENUECAT_PAYWALLS=true `
  --dart-define=REVENUECAT_ANDROID_API_KEY=goog_your_public_sdk_key `
  --dart-define=REVENUECAT_ENTITLEMENT_ID=your_entitlement_id
```

The RevenueCat project must have a current Offering with a published paywall,
packages connected to the store products, and products attached to the chosen
entitlement. Never use a `test_` API key in a store release.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
