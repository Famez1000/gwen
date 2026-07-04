import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../chat/presentation/chat_screen.dart';
import '../presentation/subscription_screen.dart';

void openGwenChatOrSubscription(
  BuildContext context, {
  String title = 'Chat with Gwen',
  String welcomeMessage =
      "Halt! I am Gwen, your anxiety-support companion. What's bothering you?",
  String? pageContext,
  List<String>? suggestedPrompts,
}) {
  final appState = context.read<AppState>();
  final screen = appState.hasActiveSubscription
      ? ChatScreen(
          appState: appState,
          title: title,
          welcomeMessage: welcomeMessage,
          pageContext: pageContext,
          suggestedPrompts: suggestedPrompts,
        )
      : const SubscriptionScreen();

  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

void openSubscribedFeatureOrSubscription(
  BuildContext context,
  Widget subscribedScreen,
) {
  final appState = context.read<AppState>();
  final screen = appState.hasActiveSubscription
      ? subscribedScreen
      : const SubscriptionScreen();

  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
