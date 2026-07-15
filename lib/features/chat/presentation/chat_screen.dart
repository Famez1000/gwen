import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/gemini_service.dart';
import '../../subscription/presentation/subscription_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  final AppState appState;
  final Function(int)? onNavigateToTab;
  final String title;
  final String welcomeMessage;
  final String? pageContext;
  final bool showGwynHeader;
  final List<String>? suggestedPrompts;
  final bool isPreview;
  final String? previewDialogMessage;

  const ChatScreen({
    Key? key,
    required this.appState,
    this.onNavigateToTab,
    this.title = 'Chat with Gwyn',
    this.welcomeMessage =
        "Halt! I am Gwyn, your anxiety-support companion. What's bothering you?",
    this.pageContext,
    this.showGwynHeader = true,
    this.suggestedPrompts,
    this.isPreview = false,
    this.previewDialogMessage,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  static const bool _debugChat = bool.fromEnvironment(
    'DEBUG_CHAT',
    defaultValue: true,
  );
  static const bool _showAiErrors = bool.fromEnvironment(
    'SHOW_AI_ERRORS',
    defaultValue: true,
  );

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<int> _debuggedBubbleIds = {};
  bool _isTyping = false;

  late AnimationController _shakeController;

  static const List<String> _defaultSuggestedPrompts = [
    "I'm feeling panicked",
    "Help me stop overthinking",
    "I need a breathing exercise",
    "Tell me something reassuring",
  ];

  List<String> get _suggestedPrompts =>
      widget.suggestedPrompts ?? _defaultSuggestedPrompts;

  final List<String> _battleCries = [
    "Fear not! Anxiety is just a paper tiger, and I have a very sharp pair of scissors! ✂️",
    "Did you know? If you wiggle your toes and make a fish face, anxiety gets extremely confused. Try it! 🐟",
    "Your brain is currently experiencing 'Spicy Alarm Syndrome'. No actual fires, just a very sensitive toaster! 🍞🔥",
    "Let us slice that worry into tiny, manageable potato chips! 🥔⚔️",
    "If your thoughts are racing, let's make them do three laps and get tired! 🏁🏃‍♂️",
    "I have polished my shield of Self-Care and loaded my Bubble-Wrap Cannons! 🛡️✨",
    "Hold on, let me look at my Scroll of Wisdom... Ah, it says: 'You are awesome. Anxiety is a nerd.' 📜",
    "Breathe in... hold it... now breathe out like you're blowing out a candle on a cake you didn't pay for. 🎂💨",
  ];

  String _currentBattleCry = "Tap my face to draw my Sword of Silliness! ⚔️";

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Welcome messages
    _messages.add(
      ChatMessage(
        text: widget.welcomeMessage,
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
      ),
    );

    if (widget.isPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPreviewDialog();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _playShake() {
    if (widget.appState.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    _shakeController.forward(from: 0.0);
    setState(() {
      _currentBattleCry = _battleCries[Random().nextInt(_battleCries.length)];
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    _debugLog(
      'Sending user message chars=${text.length}, lines=${_lineCount(text)}, preview="${_preview(text)}"',
    );

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    if (widget.isPreview) {
      _sendPreviewResponse(text);
    } else {
      _sendGeminiResponse(text);
    }
  }

  Future<void> _sendPreviewResponse(String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _generateTherapeuticResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = false;
    });
    _scrollToBottom();
    HapticFeedback.selectionClick();
  }

  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> _showPreviewDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chat with Gwyn'),
          content: Text(
            widget.previewDialogMessage ??
                'Here you can chat with Gwyn (using our trained AI system when subscribed). This preview uses standardized responses',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Try preview'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _openSubscription();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendGeminiResponse(String text) async {
    String responseText;

    try {
      final pageContext = widget.pageContext?.trim();
      responseText = pageContext == null || pageContext.isEmpty
          ? await GeminiService.instance.generateGwenResponse(text)
          : await GeminiService.instance.generateContextualGwenResponse(
              userMessage: text,
              pageTitle: widget.title,
              pageContext: pageContext,
            );
      _debugLog(
        'Gemini response received chars=${responseText.length}, lines=${_lineCount(responseText)}, preview="${_preview(responseText)}"',
      );
    } catch (error) {
      _debugLog('Gemini request failed; using local Gwyn fallback: $error');
      final fallbackText = _generateTherapeuticResponse(text);
      responseText = _showAiErrors
          ? 'Gwyn AI could not connect: $error\n\nLocal fallback:\n$fallbackText'
          : fallbackText;
      _debugLog(
        'Fallback response chars=${responseText.length}, lines=${_lineCount(responseText)}, preview="${_preview(responseText)}"',
      );
    }

    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = false;
    });
    _scrollToBottom();
    HapticFeedback.selectionClick();
  }

  void _debugLog(String message) {
    if (_debugChat) {
      debugPrint('[ChatScreen] $message');
    }
  }

  int _lineCount(String value) {
    if (value.isEmpty) return 0;
    return '\n'.allMatches(value).length + 1;
  }

  String _preview(String value, {int maxChars = 500}) {
    final safeValue = value.replaceAll('\n', r'\n');
    if (safeValue.length <= maxChars) return safeValue;
    return '${safeValue.substring(0, maxChars)}...';
  }

  String _generateTherapeuticResponse(String input) {
    final query = input.toLowerCase();
    final trimmedInput = input.trim();

    if (query.contains('panic') ||
        query.contains('scared') ||
        query.contains('breath') ||
        query.contains('can\'t breathe')) {
      return "Panic? By the power of the pool noodle, let's smash it! 🛡️ Combat-breathing mode initiated: Inhale through the nose for 4 counts... hold it like you're guarding a secret treasure... and let it out with a big sigh.\n\nFor more advanced training, tap the Breathe tab below. We will slow that heartbeat down together!";
    }
    if (query.contains('overthink') ||
        query.contains('racing') ||
        query.contains('stop') ||
        query.contains('worry')) {
      return "Ah! The classic 'brain-hamster running on a wheel made of doom'! 🐹 Let's throw some metaphorical cheese on that wheel to stop it.\n\nLet's try a counter-tactical maneuver: Name 3 items in your vicinity that are yellow, or 3 items that look like they could be used as a shield. Let's redirect that brainpower!";
    }
    if (query.contains('reassure') ||
        query.contains('sad') ||
        query.contains('bad') ||
        query.contains('anxious')) {
      return "Acknowledge the fear, but remember: anxiety is just your inner caveman running around screaming because a microwave beeped. 🦖 It is a false alarm!\n\nYou have survived 100% of your hardest days. You are a warrior in training. Let the anxiety storm rage; your shield of resilience is too strong for it to break. This wave will pass, I promise!";
    }
    if (query.contains('lonely') || query.contains('alone')) {
      return "Lonely? Not on my watch! ⚔️ Even if we are separated by screens, we are part of the same legion. Millions of fellow warriors are breathing through anxiety at this very moment.\n\nYou are valued, you are strong, and you are not walking this path alone. What is one small act of kindness we can do for your weary self today?";
    }
    if (query.contains('thank') ||
        query.contains('good') ||
        query.contains('better')) {
      return "Victory! 🏆 Taking a moment to pause and check in is a major triumph. I shall write a ballad in your honor!\n\nWhenever the anxiety goblins start whispering again, tap my avatar or send me a scroll. Keep breathing, brave friend!";
    }

    if (query.contains('sleep') ||
        query.contains('tired') ||
        query.contains('exhausted') ||
        query.contains('insomnia')) {
      return "Sleep trouble is draining. Let us stop forcing rest and make the room feel safer: relax your forehead, unclench your hands, and make your exhale a little longer than your inhale.\n\nIf worries keep appearing, write one tiny note for tomorrow and let that be enough for tonight.";
    }
    if (query.contains('work') ||
        query.contains('school') ||
        query.contains('exam') ||
        query.contains('deadline')) {
      return "That sounds like pressure stacking up. Pick the next smallest useful action, not the whole mountain: one email, one sentence, one page, or five quiet minutes.\n\nYour job right now is not to conquer everything. It is to make the next step visible.";
    }
    if (query.contains('angry') ||
        query.contains('mad') ||
        query.contains('frustrated')) {
      return "Anger can be your nervous system waving a bright flag. Before reacting, plant both feet, loosen your jaw, and name what boundary or need might be underneath it.\n\nYou do not have to push the feeling away. Give it room, then choose the next move slowly.";
    }
    if (query.contains('heart') ||
        query.contains('dizzy') ||
        query.contains('shaking') ||
        query.contains('nauseous')) {
      return "Those body sensations can feel intense. Try orienting first: look around and name three things you can see, then press your feet into the floor.\n\nIf symptoms feel severe, unusual, or unsafe, please contact medical help or a trusted person now. You deserve support quickly.";
    }

    final defaultResponses = [
      'I hear you. ${trimmedInput.isEmpty ? 'That sounds like a lot to hold.' : 'When you say "$trimmedInput", it sounds like your mind wants some steadiness.'}\n\nTry this with me: breathe out slowly, soften your shoulders, and name one thing that is true and safe in this exact moment.',
      "Thank you for telling me. Let us make this smaller for a minute: what is the feeling, where is it in your body, and what would help by just 1 percent?\n\nYou do not need a perfect answer. One gentle next step counts.",
      "Gwyn is here. Let us pause the spiral and come back to the room: feel your feet, notice the light around you, and take one slow breath.\n\nNow choose one kind action for yourself, even if it is tiny.",
    ];
    final selectedIndex =
        trimmedInput.codeUnits.fold<int>(0, (sum, codeUnit) => sum + codeUnit) %
        defaultResponses.length;
    return defaultResponses[selectedIndex];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showGwynHeader)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _playShake,
                        child: AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final double value = _shakeController.value;
                            final double translation =
                                sin(value * 6 * pi) * 8.0 * (1.0 - value);
                            return Transform.translate(
                              offset: Offset(translation, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor.withOpacity(0.5),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                              image: const DecorationImage(
                                image: AssetImage('assets/images/icon.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _currentBattleCry,
                                key: ValueKey<String>(_currentBattleCry),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Chat Message Thread
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, primaryColor, isDark);
                },
              ),
            ),

            // Typing Indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 10),
                child: Row(
                  children: [
                    Text(
                      "Gwyn is typing",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

            // Suggested Prompts
            if (_messages.length <= 2 && !_isTyping)
              Container(
                height: 48,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _suggestedPrompts.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestedPrompts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text(
                          suggestion,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : primaryColor.withOpacity(0.08),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : primaryColor.withOpacity(0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () => _sendMessage(suggestion),
                      ),
                    );
                  },
                ),
              ),

            if (widget.isPreview)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Unlock AI chat with Gwyn'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: _openSubscription,
                  ),
                ),
              ),

            // Message Input bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderRadius: 30,
                blur: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        decoration: InputDecoration(
                          hintText: "Share what is on your mind...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        color: primaryColor,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.12),
                      ),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, Color primary, bool isDark) {
    final alignment = msg.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = msg.isUser
        ? primary.withOpacity(0.18)
        : (isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.95));
    final bubbleTextStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black87,
      fontSize: 15,
      height: 1.4,
    );
    final bubbleBorderRadius = msg.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          );

    final showAvatar = !msg.isUser;

    Widget bubble = LayoutBuilder(
      builder: (context, constraints) {
        final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.82;
        final availableTextWidth = bubbleMaxWidth - 32;
        final textPainter = TextPainter(
          text: TextSpan(text: msg.text, style: bubbleTextStyle),
          textDirection: TextDirection.ltr,
          maxLines: null,
        )..layout(maxWidth: availableTextWidth);
        final bubbleId = Object.hash(msg.text, msg.isUser, msg.timestamp);

        if (_debuggedBubbleIds.add(bubbleId)) {
          _debugLog(
            'Bubble render isUser=${msg.isUser}, chars=${msg.text.length}, explicitLines=${_lineCount(msg.text)}, '
            'computedLines=${textPainter.computeLineMetrics().length}, '
            'rowMaxWidth=${constraints.maxWidth.toStringAsFixed(1)}, '
            'bubbleMaxWidth=${bubbleMaxWidth.toStringAsFixed(1)}, '
            'textMaxWidth=${availableTextWidth.toStringAsFixed(1)}, '
            'textSize=${textPainter.width.toStringAsFixed(1)}x${textPainter.height.toStringAsFixed(1)}, '
            'preview="${_preview(msg.text)}"',
          );
        }

        return Container(
          constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: bubbleBorderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : (msg.isUser
                        ? primary.withOpacity(0.15)
                        : Colors.black.withOpacity(0.03)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SelectableText(
            msg.text,
            maxLines: null,
            style: bubbleTextStyle,
          ),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: msg.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showAvatar) ...[
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/icon.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: bubble,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(
              left: showAvatar ? 48.0 : 8.0,
              right: msg.isUser ? 8.0 : 48.0,
            ),
            child: Text(
              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white30 : Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
