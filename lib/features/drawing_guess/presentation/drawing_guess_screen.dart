import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_state.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../subscription/application/subscription_gate.dart';
import '../../subscription/presentation/subscription_screen.dart';

class DrawingGuessScreen extends StatefulWidget {
  const DrawingGuessScreen({super.key});

  @override
  State<DrawingGuessScreen> createState() => _DrawingGuessScreenState();
}

class _DrawingGuessScreenState extends State<DrawingGuessScreen> {
  static const Color _gwynArmorColor = Color(0xFF59616B);

  final GlobalKey _drawingKey = GlobalKey();
  final List<_DrawingStroke> _strokes = [];
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _gwynUiScrollController = ScrollController();
  final List<_GuessChatMessage> _guessChatMessages = [];
  late final AudioPlayer _musicPlayer;

  Color _selectedColor = const Color(0xFF2F3A4A);
  double _strokeWidth = 7;
  String? _guess;
  bool _isGuessing = false;
  bool _isReplying = false;
  bool _musicEnabled = false;
  bool _freeGuessUsedThisSession = false;

  bool get _hasDrawing => _strokes.any((stroke) => stroke.points.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _musicPlayer = AudioPlayer(playerId: 'drawing_guess_music');
  }

  void _startStroke(DragStartDetails details) {
    HapticFeedback.selectionClick();
    setState(() {
      _guess = null;
      _guessChatMessages.clear();
      _strokes.add(
        _DrawingStroke(
          color: _selectedColor,
          width: _strokeWidth,
          points: [details.localPosition],
        ),
      );
    });
  }

  void _updateStroke(DragUpdateDetails details) {
    if (_strokes.isEmpty) return;

    setState(() {
      _strokes.last.points.add(details.localPosition);
    });
  }

  void _undoStroke() {
    if (_strokes.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _strokes.removeLast();
      _guess = null;
      _guessChatMessages.clear();
    });
  }

  void _clearDrawing() {
    if (_strokes.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _strokes.clear();
      _guess = null;
      _guessChatMessages.clear();
    });
  }

  Future<void> _askGwyn() async {
    _logGateState('Guess tapped');
    if (!_hasDrawing || _isGuessing) {
      if (!_hasDrawing) {
        _logGateState('Guess blocked: no drawing');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Draw something first.')));
      }
      if (_isGuessing) {
        _logGateState('Guess blocked: already guessing');
      }
      return;
    }

    if (!await _canUseDrawingGuess() || !mounted) {
      _logGateState('Guess stopped by subscription gate');
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() {
      _isGuessing = true;
      _guess = null;
    });

    try {
      final imageBytes = await _captureDrawing();
      final answer = await GeminiService.instance.guessDrawing(imageBytes);
      if (!mounted) return;
      _logGateState('Guess succeeded: marking session free guess used');
      _freeGuessUsedThisSession = true;
      await context.read<AppState>().useDrawingGuessFreeRequest();
      if (!mounted) return;
      _logGateState('Session free guess marked used');
      setState(() {
        _guess = answer;
        _guessChatMessages.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _guess =
            "Gwyn squints dramatically, but couldn't read this sketch yet. Try again with a bolder drawing.",
      );
      debugPrint('[DrawingGuessScreen] Gwyn guess failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isGuessing = false);
      }
    }
  }

  void _openSubscription() {
    openGwynChatOrSubscription(
      context,
      title: 'Draw with Gwyn',
      pageContext:
          'The user opened Gwyn from the drawing guess game after sketching or preparing to sketch something.',
    );
  }

  Future<void> _sendGuessReply() async {
    final guess = _guess;
    final reply = _replyController.text.trim();
    if (guess == null || reply.isEmpty || _isReplying) return;

    _logGateState('Reply tapped');
    if (!await _canUseDrawingReply() || !mounted) {
      _logGateState('Reply stopped by subscription gate');
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    _replyController.clear();
    setState(() {
      _isReplying = true;
      _guessChatMessages.add(_GuessChatMessage(text: reply, isUser: true));
    });

    try {
      final answer = await GeminiService.instance.respondToDrawingGuess(
        guess: guess,
        userReply: reply,
      );
      if (!mounted) return;
      setState(() {
        _guessChatMessages.add(_GuessChatMessage(text: answer, isUser: false));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _guessChatMessages.add(
          const _GuessChatMessage(
            text:
                "Gwyn dropped her magnifying glass for a second. Try sending that again.",
            isUser: false,
          ),
        );
      });
      debugPrint('[DrawingGuessScreen] Gwyn reply failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isReplying = false);
      }
    }
  }

  Future<bool> _canUseDrawingGuess() async {
    final appState = context.read<AppState>();
    _logGateState('Checking guess permission');

    if (appState.hasStoreSubscription) {
      _logGateState('Guess allowed: store subscription');
      return true;
    }

    if (!_freeGuessUsedThisSession) {
      _logGateState('Guess allowed: session free guess not used yet');
      return true;
    }

    _logGateState('Guess blocked: session free guess already used');
    _showSubscriptionScreen();
    return false;
  }

  Future<bool> _canUseDrawingReply() async {
    _logGateState('Checking reply permission');

    if (context.read<AppState>().hasStoreSubscription) {
      _logGateState('Reply allowed: store subscription');
      return true;
    }

    _logGateState('Reply blocked: subscription required');
    _showSubscriptionScreen();
    return false;
  }

  void _showSubscriptionScreen() {
    _logGateState('Opening subscription screen');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> _resetFreeGuessForDebug() async {
    await context.read<AppState>().resetDrawingGuessFreeRequestForDebug();
    _freeGuessUsedThisSession = false;
    if (!mounted) return;
    _logGateState('Debug reset free guess');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug: free Draw & Guess try reset.')),
    );
  }

  void _logGateState(String event) {
    final appState = context.read<AppState>();
    debugPrint(
      '[DrawingGuessGate] $event | '
      'mounted=$mounted, '
      'hasDrawing=$_hasDrawing, '
      'isGuessing=$_isGuessing, '
      'isReplying=$_isReplying, '
      'hasActiveSubscription=${appState.hasActiveSubscription}, '
      'hasStoreSubscription=${appState.hasStoreSubscription}, '
      'hasDebugSubscription=${appState.hasDebugSubscription}, '
      'drawingGuessFreeRequestUsed=${appState.drawingGuessFreeRequestUsed}, '
      'freeGuessUsedThisSession=$_freeGuessUsedThisSession, '
      'strokes=${_strokes.length}, '
      'guessPresent=${_guess != null}',
    );
  }

  Future<Uint8List> _captureDrawing() async {
    final boundary =
        _drawingKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw const GeminiServiceException('Drawing canvas is not ready.');
    }

    final image = await boundary.toImage(pixelRatio: 1.8);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      throw const GeminiServiceException('Could not capture the drawing.');
    }

    return bytes;
  }

  Future<void> _startMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource('sounds/meditation_mandala.mp3'),
        volume: 0.28,
      );
    } catch (error) {
      debugPrint('[DrawingGuessScreen] Music failed: $error');
    }
  }

  void _toggleMusic() {
    HapticFeedback.selectionClick();
    setState(() => _musicEnabled = !_musicEnabled);

    unawaited(
      (_musicEnabled ? _startMusic() : _musicPlayer.pause()).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint('[DrawingGuessScreen] Music toggle failed: $error');
      }),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    _gwynUiScrollController.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Draw & Guess',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Debug: reset free guess',
              onPressed: _resetFreeGuessForDebug,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          IconButton(
            tooltip: _musicEnabled ? 'Pause music' : 'Play music',
            onPressed: _toggleMusic,
            icon: Icon(
              _musicEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: _strokes.isEmpty ? null : _undoStroke,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: _strokes.isEmpty ? null : _clearDrawing,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxGwynPanelHeight = constraints.maxHeight * 0.40;
            final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _ToolBar(
                    selectedColor: _selectedColor,
                    strokeWidth: _strokeWidth,
                    onColorChanged: (color) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColor = color);
                    },
                    onStrokeWidthChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _strokeWidth = value);
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: RepaintBoundary(
                        key: _drawingKey,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: _startStroke,
                          onPanUpdate: _updateStroke,
                          child: CustomPaint(
                            painter: _DrawingPainter(
                              strokes: List<_DrawingStroke>.unmodifiable(
                                _strokes,
                              ),
                              isDark: isDark,
                            ),
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _hasDrawing ? 0 : 1,
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  'Draw anything and let Gwyn guess',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black.withAlpha(100),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxGwynPanelHeight),
                  child: Scrollbar(
                    controller: _gwynUiScrollController,
                    thumbVisibility:
                        _guess != null || _guessChatMessages.isNotEmpty,
                    child: SingleChildScrollView(
                      controller: _gwynUiScrollController,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        18 + bottomSafePadding,
                      ),
                      child: _GwynGuessPanel(
                        isGuessing: _isGuessing,
                        guess: _guess,
                        replyController: _replyController,
                        messages: _guessChatMessages,
                        isReplying: _isReplying,
                        askButtonLabel:
                            context.watch<AppState>().hasStoreSubscription ||
                                _freeGuessUsedThisSession
                            ? "Gwyn's guess"
                            : "Gwyn's guess (1 free)",
                        onAskGwyn: _askGwyn,
                        onGwynImageTap: _openSubscription,
                        onSendReply: _sendGuessReply,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GwynGuessPanel extends StatelessWidget {
  final bool isGuessing;
  final String? guess;
  final TextEditingController replyController;
  final List<_GuessChatMessage> messages;
  final bool isReplying;
  final String askButtonLabel;
  final VoidCallback onAskGwyn;
  final VoidCallback onGwynImageTap;
  final VoidCallback onSendReply;

  const _GwynGuessPanel({
    required this.isGuessing,
    required this.guess,
    required this.replyController,
    required this.messages,
    required this.isReplying,
    required this.askButtonLabel,
    required this.onAskGwyn,
    required this.onGwynImageTap,
    required this.onSendReply,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onGwynImageTap,
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _DrawingGuessScreenState._gwynArmorColor.withAlpha(25),
                  border: Border.all(
                    color: _DrawingGuessScreenState._gwynArmorColor.withAlpha(
                      64,
                    ),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: const Image(
                  image: AssetImage('assets/images/icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryColor.withAlpha(130),
                  disabledForegroundColor: Colors.white70,
                ),
                onPressed: isGuessing ? null : onAskGwyn,
                icon: isGuessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  isGuessing ? 'Gwyn is guessing...' : askButtonLabel,
                ),
              ),
            ),
          ],
        ),
        if (guess != null) ...[
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Text(guess!, style: const TextStyle(height: 1.35)),
          ),
          const SizedBox(height: 12),
          _GuessReplyBox(
            controller: replyController,
            messages: messages,
            isReplying: isReplying,
            onSend: onSendReply,
          ),
        ],
      ],
    );
  }
}

class _GuessReplyBox extends StatelessWidget {
  final TextEditingController controller;
  final List<_GuessChatMessage> messages;
  final bool isReplying;
  final VoidCallback onSend;

  const _GuessReplyBox({
    required this.controller,
    required this.messages,
    required this.isReplying,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (messages.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 132),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? primaryColor.withAlpha(38)
                            : isDark
                            ? Colors.white.withAlpha(18)
                            : Colors.white.withAlpha(190),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        message.text,
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: messages.isEmpty
                        ? 'Tell Gwyn if she was close...'
                        : 'Any response?',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(12)
                        : Colors.white.withAlpha(190),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send',
                onPressed: isReplying ? null : onSend,
                icon: isReplying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  final Color selectedColor;
  final double strokeWidth;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;

  const _ToolBar({
    required this.selectedColor,
    required this.strokeWidth,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
  });

  static const List<Color> _colors = [
    Color(0xFF2F3A4A),
    Color(0xFF6FA8DC),
    Color(0xFF7FC8B2),
    Color(0xFFD96C75),
    Color(0xFFE2A84B),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(12)
            : Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
      ),
      child: Row(
        children: [
          for (final color in _colors) ...[
            _ColorButton(
              color: color,
              isSelected: selectedColor == color,
              onTap: () => onColorChanged(color),
            ),
            const SizedBox(width: 8),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.line_weight_rounded, size: 20),
          Expanded(
            child: Slider(
              value: strokeWidth,
              min: 3,
              max: 16,
              divisions: 13,
              label: strokeWidth.round().toString(),
              onChanged: onStrokeWidthChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Pen color',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 28,
          width: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;
  final bool isDark;

  const _DrawingPainter({required this.strokes, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF24313F), const Color(0xFF1D2733)]
            : [const Color(0xFFFFFBF4), const Color(0xFFEAF5F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(9)
      ..strokeWidth = 1;
    const gridSize = 28.0;
    for (var x = gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          Paint()..color = stroke.color,
        );
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final previous = stroke.points[i - 1];
        final current = stroke.points[i];
        final midpoint = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(
          previous.dx,
          previous.dy,
          midpoint.dx,
          midpoint.dy,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.isDark != isDark;
  }
}

class _DrawingStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  _DrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });
}

class _GuessChatMessage {
  final String text;
  final bool isUser;

  const _GuessChatMessage({required this.text, required this.isUser});
}
