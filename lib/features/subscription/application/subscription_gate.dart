import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/revenue_cat_service.dart';
import '../../../core/state/app_state.dart';
import '../../chat/presentation/chat_screen.dart';
import '../presentation/subscription_screen.dart';

Future<void> openGwynChatOrSubscription(
  BuildContext context, {
  String title = 'Chat with Gwyn',
  String welcomeMessage =
      "Halt! I am Gwyn, your anxiety-support companion. What's bothering you?",
  String? pageContext,
  List<String>? suggestedPrompts,
  bool showGwynHeader = true,
  bool previewBeforeSubscription = false,
  String? previewDialogMessage,
}) async {
  final appState = context.read<AppState>();
  if (RevenueCatService.instance.isConfigured) {
    await RevenueCatService.instance.refreshSubscriptionStatus();
    if (!context.mounted) return;
  }

  final screen = appState.hasActiveSubscription
      ? ChatScreen(
          appState: appState,
          title: title,
          welcomeMessage: welcomeMessage,
          pageContext: pageContext,
          suggestedPrompts: suggestedPrompts,
          showGwynHeader: showGwynHeader,
        )
      : previewBeforeSubscription
      ? ChatScreen(
          appState: appState,
          title: title,
          welcomeMessage: welcomeMessage,
          pageContext: pageContext,
          suggestedPrompts: suggestedPrompts,
          showGwynHeader: showGwynHeader,
          isPreview: true,
          previewDialogMessage: previewDialogMessage,
        )
      : const SubscriptionScreen();

  await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

Future<void> openSubscribedFeatureOrSubscription(
  BuildContext context,
  Widget subscribedScreen,
) async {
  final appState = context.read<AppState>();
  if (RevenueCatService.instance.isConfigured) {
    await RevenueCatService.instance.refreshSubscriptionStatus();
    if (!context.mounted) return;
  }

  final screen = appState.hasActiveSubscription
      ? subscribedScreen
      : const SubscriptionScreen();

  await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
