import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/state/app_state.dart';
import '../../breathing/presentation/breathing_screen.dart';
import '../../drawing_guess/presentation/drawing_guess_screen.dart';
import '../../grounding/presentation/grounding_screen.dart';
import '../../sanctuary/presentation/leaf_exercise_screen.dart';
import '../../subscription/application/subscription_gate.dart';

class PanicMoodScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final ValueChanged<int>? onDestinationSelected;

  const PanicMoodScreen({super.key, this.onBack, this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return _MoodScreenContent(
      emoticonIndex: 1,
      onBack: onBack,
      onDestinationSelected: onDestinationSelected,
    );
  }
}

class NotOkMoodScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final ValueChanged<int>? onDestinationSelected;

  const NotOkMoodScreen({super.key, this.onBack, this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return _MoodScreenContent(
      emoticonIndex: 2,
      onBack: onBack,
      onDestinationSelected: onDestinationSelected,
    );
  }
}

class SurvivingMoodScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final ValueChanged<int>? onDestinationSelected;

  const SurvivingMoodScreen({
    super.key,
    this.onBack,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _MoodScreenContent(
      emoticonIndex: 3,
      onBack: onBack,
      onDestinationSelected: onDestinationSelected,
    );
  }
}

class _MoodScreenContent extends StatefulWidget {
  final int emoticonIndex;
  final VoidCallback? onBack;
  final ValueChanged<int>? onDestinationSelected;

  const _MoodScreenContent({
    required this.emoticonIndex,
    this.onBack,
    this.onDestinationSelected,
  });

  @override
  State<_MoodScreenContent> createState() => _MoodScreenContentState();
}

class _MoodScreenContentState extends State<_MoodScreenContent> {
  static const _moodRealityHintText =
      '(click to edit) I am July Summers. I live in upstate New York. My parents love me. I have a brother named Jim. I have a funny cat Whiskey. I love myself, no matter what';

  late final TextEditingController _realityTextController;
  late final AppState _appState;
  Timer? _saveDebounce;

  String get _moodLabel {
    switch (widget.emoticonIndex) {
      case 1:
        return '';
      case 2:
        return '';
      case 3:
        return '';
      default:
        return 'Your mood';
    }
  }

  String get _headerTitle {
    switch (widget.emoticonIndex) {
      case 2:
        return 'I feel anxious';
      case 3:
        return 'I am surviving';
      default:
        return 'I need to calm down';
    }
  }

  String get _imageAsset {
    switch (widget.emoticonIndex) {
      case 1:
        return 'assets/images/gwen_panic.png';
      case 2:
        return 'assets/images/gwen_not_ok.png';
      case 3:
        return 'assets/images/em_3.png';
      default:
        return 'assets/images/gwen_panic.png';
    }
  }

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _realityTextController = TextEditingController(
      text: _trimTrailingWhitespace(_appState.moodRealityText),
    );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _appState.setMoodRealityText(
      _trimTrailingWhitespace(_realityTextController.text),
    );
    _realityTextController.dispose();
    super.dispose();
  }

  void _saveRealityText(String text) {
    setState(() {});
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _appState.setMoodRealityText(_trimTrailingWhitespace(text));
    });
  }

  String _trimTrailingWhitespace(String text) {
    return text.replaceFirst(RegExp(r'\s+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: _MoodBottomBar(
        onDestinationSelected: (index) =>
            _handleBottomDestination(context, index),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withAlpha(13)
                        : Colors.black.withAlpha(8),
                  ),
                  onPressed: widget.onBack ?? () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _headerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Text(
            //   _supportMessage,
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 14,
            //     height: 1.4,
            //     color: isDark ? Colors.white60 : Colors.black.withAlpha(153),
            //   ),
            // ),
            const SizedBox(height: 18),
            if (widget.emoticonIndex == 1)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _PanicImageTextBox(
                      text: 'Gwen is here with you',
                      isDark: isDark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: GestureDetector(
                      onTap: _openMoodGwen,
                      child: Image.asset(
                        _imageAsset,
                        width: 112,
                        height: 112,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _PanicImageTextBox(
                      text: "Take a slow breath and let's calm down",
                      isDark: isDark,
                    ),
                  ),
                ],
              )
            else
              Center(
                child: GestureDetector(
                  onTap: _openMoodGwen,
                  child: Image.asset(
                    _imageAsset,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            if (_moodLabel.isNotEmpty) ...[
              Text(
                _moodLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
            switch (widget.emoticonIndex) {
              2 => _buildNotOkContent(context, isDark),
              3 => _buildSurvivingContent(context, isDark),
              _ => _buildPanicContent(context, isDark),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildPanicContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        _MoodSectionCard(
          title: 'First step, back to reality',
          trailing: IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () => _showPanicHelp(context),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textLines = _lineCountForText(
                text: _realityTextController.text,
                hintText: _moodRealityHintText,
                maxWidth: constraints.maxWidth - 24,
              );

              return TextField(
                controller: _realityTextController,
                onChanged: _saveRealityText,
                minLines: textLines,
                maxLines: textLines,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: _moodRealityHintText,
                  hintStyle: TextStyle(
                    fontSize: 17,
                    height: 1.45,
                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withAlpha(38)
                          : Colors.black.withAlpha(31),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _FavoriteSongCard(
          onOpenFavoriteSong: _openFavoriteSong,
          onEditFavoriteSongUrl: _editFavoriteSongUrl,
          hasSong: _appState.moodFavoriteSongUrl.isNotEmpty,
        ),
        const SizedBox(height: 16),
        _ExerciseSectionCard(
          title: "Third step, select a soothing exercise",
          actions: [
            _ExerciseIconButton(
              icon: Icons.filter_center_focus_rounded,
              label: 'Grounding',
              onTap: () => _openExercise(GroundingScreen(appState: _appState)),
            ),
            _ExerciseIconButton(
              icon: Icons.air_rounded,
              label: 'Breathing',
              onTap: () => _openExercise(BreathingScreen(appState: _appState)),
            ),
            _ExerciseIconButton(
              icon: Icons.eco_rounded,
              label: 'Leaf',
              onTap: () => _openExercise(const LeafExerciseScreen()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotOkContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        _MoodSectionCard(
          title: 'Start with this truth',
          child: _SupportText(
            text:
                'It is OK not to feel OK. Try making this moment a little softer: unclench your jaw, drop your shoulders, and take a slow breath.',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        _ExerciseSectionCard(
          title: 'Gently distract your mind',
          actions: [
            _ExerciseIconButton(
              icon: Icons.air_rounded,
              label: 'Breathing',
              onTap: () => _openExercise(BreathingScreen(appState: _appState)),
            ),
            _ExerciseIconButton(
              icon: Icons.book_outlined,
              label: 'Journal',
              onTap: () => _goToDestination(2),
            ),
            _ExerciseIconButton(
              icon: Icons.draw_rounded,
              label: 'Draw & Guess',
              onTap: () => _openExercise(const DrawingGuessScreen()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FavoriteSongCard(
          title: 'Add a little comfort',
          onOpenFavoriteSong: _openFavoriteSong,
          onEditFavoriteSongUrl: _editFavoriteSongUrl,
          hasSong: _appState.moodFavoriteSongUrl.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildSurvivingContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        _MoodSectionCard(
          title: 'Only the next tiny step',
          child: _SupportText(
            text:
                'Surviving counts. You do not need a big plan right now. Pick one small thing your body might need, then let that be enough for this moment.',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
        _MoodSectionCard(
          title: 'Basic needs check',
          child: Column(
            children: [
              _NeedLine(icon: Icons.water_drop_rounded, text: 'Drink water'),
              const SizedBox(height: 10),
              _NeedLine(icon: Icons.restaurant_rounded, text: 'Eat something'),
              const SizedBox(height: 10),
              _NeedLine(icon: Icons.bedtime_rounded, text: 'Rest your body'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ExerciseSectionCard(
          title: 'Low energy options',
          actions: [
            _ExerciseIconButton(
              icon: Icons.eco_rounded,
              label: 'Leaf',
              onTap: () => _openExercise(const LeafExerciseScreen()),
            ),
            _ExerciseIconButton(
              icon: Icons.book_outlined,
              label: 'Journal',
              onTap: () => _goToDestination(2),
            ),
            _ExerciseIconButton(
              icon: Icons.lightbulb_outline,
              label: 'Learn',
              onTap: () => _goToDestination(3),
            ),
          ],
        ),
      ],
    );
  }

  int _lineCountForText({
    required String text,
    required String hintText,
    required double maxWidth,
  }) {
    final visibleText = text.isEmpty ? hintText : text;
    final painter = TextPainter(
      text: TextSpan(
        text: visibleText,
        style: const TextStyle(fontSize: 17, height: 1.45),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return painter.computeLineMetrics().length.clamp(1, 8);
  }

  void _handleBottomDestination(BuildContext context, int index) {
    if (index == 0) {
      Navigator.maybePop(context);
      return;
    }

    Navigator.pop(context);
    widget.onDestinationSelected?.call(index);
  }

  void _goToDestination(int index) {
    Navigator.pop(context);
    widget.onDestinationSelected?.call(index);
  }

  Future<void> _openFavoriteSong() async {
    if (_appState.moodFavoriteSongUrl.isEmpty) {
      final saved = await _editFavoriteSongUrl();
      if (!saved) return;
    }

    final uri = _parseFavoriteSongUrl(_appState.moodFavoriteSongUrl);
    if (uri == null) {
      await _editFavoriteSongUrl();
      return;
    }

    final videoId = _youtubeVideoId(uri);
    if (videoId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid YouTube video URL.'),
        ),
      );
      await _editFavoriteSongUrl();
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _FavoriteSongPlayerDialog(videoId: videoId),
    );
  }

  Future<bool> _editFavoriteSongUrl() async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) =>
          _FavoriteSongUrlDialog(initialUrl: _appState.moodFavoriteSongUrl),
    );

    if (!mounted || url == null) return false;

    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      await _appState.setMoodFavoriteSongUrl('');
      return true;
    }

    final uri = _parseFavoriteSongUrl(trimmed);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid YouTube link.')),
      );
      return false;
    }

    await _appState.setMoodFavoriteSongUrl(uri.toString());
    return true;
  }

  Uri? _parseFavoriteSongUrl(String input) {
    final withScheme = input.startsWith(RegExp(r'https?://'))
        ? input
        : 'https://$input';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase();
    final isYoutube =
        host == 'youtube.com' ||
        host == 'www.youtube.com' ||
        host == 'm.youtube.com' ||
        host == 'music.youtube.com' ||
        host == 'youtu.be';

    return isYoutube ? uri : null;
  }

  String? _youtubeVideoId(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'youtu.be') {
      final id = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
      return _normalizeYoutubeId(id);
    }

    final queryId = _normalizeYoutubeId(uri.queryParameters['v']);
    if (queryId != null) return queryId;

    final segments = uri.pathSegments;
    final shortsIndex = segments.indexOf('shorts');
    if (shortsIndex != -1 && shortsIndex + 1 < segments.length) {
      return _normalizeYoutubeId(segments[shortsIndex + 1]);
    }

    final embedIndex = segments.indexOf('embed');
    if (embedIndex != -1 && embedIndex + 1 < segments.length) {
      return _normalizeYoutubeId(segments[embedIndex + 1]);
    }

    return null;
  }

  String? _normalizeYoutubeId(String? id) {
    final normalized = id?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(normalized)
        ? normalized
        : null;
  }

  void _openExercise(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openMoodGwen() {
    openGwenChatOrSubscription(
      context,
      title: _headerTitle,
      pageContext:
          'The user opened Gwen from a mood support screen after choosing their current anxiety state.',
    );
  }

  void _showPanicHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text(
            'Write here your truths, no matter what. That is your name, where you live, your parents loving you, etc. Any moment you panic, read this oud loud to remember these truths.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _ExerciseIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExerciseIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _MoodSectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(13) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FavoriteSongCard extends StatelessWidget {
  final String title;
  final bool hasSong;
  final VoidCallback onOpenFavoriteSong;
  final VoidCallback onEditFavoriteSongUrl;

  const _FavoriteSongCard({
    this.title = 'Second step, play your favorite song',
    required this.hasSong,
    required this.onOpenFavoriteSong,
    required this.onEditFavoriteSongUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _MoodSectionCard(
      title: title,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenFavoriteSong,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        hasSong ? 'Open favorite song' : 'Add favorite song',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Set YouTube song link',
            onPressed: onEditFavoriteSongUrl,
            icon: const Icon(Icons.smart_display_rounded),
          ),
        ],
      ),
    );
  }
}

class _FavoriteSongPlayerDialog extends StatefulWidget {
  final String videoId;

  const _FavoriteSongPlayerDialog({required this.videoId});

  @override
  State<_FavoriteSongPlayerDialog> createState() =>
      _FavoriteSongPlayerDialogState();
}

class _FavoriteSongPlayerDialogState extends State<_FavoriteSongPlayerDialog> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: isDark ? const Color(0xFF0F131E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Favorite song',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          YoutubePlayer(controller: _controller),
        ],
      ),
    );
  }
}

class _ExerciseSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const _ExerciseSectionCard({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return _MoodSectionCard(
      title: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: action,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SupportText extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SupportText({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
      ),
    );
  }
}

class _NeedLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NeedLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(31),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanicImageTextBox extends StatelessWidget {
  final String text;
  final bool isDark;

  const _PanicImageTextBox({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(13) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(13),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}

class _FavoriteSongUrlDialog extends StatefulWidget {
  final String initialUrl;

  const _FavoriteSongUrlDialog({required this.initialUrl});

  @override
  State<_FavoriteSongUrlDialog> createState() => _FavoriteSongUrlDialogState();
}

class _FavoriteSongUrlDialogState extends State<_FavoriteSongUrlDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Favorite song link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Go to YouTube, find your favorite song, tap Share, copy the URL, then paste it here.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'YouTube URL',
              hintText: 'https://youtu.be/...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _MoodBottomBar extends StatelessWidget {
  final ValueChanged<int> onDestinationSelected;

  const _MoodBottomBar({required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(13)
                : Colors.black.withAlpha(13),
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: isDark ? const Color(0xFF0F131E) : Colors.white,
        indicatorColor: Theme.of(context).primaryColor.withAlpha(31),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 66,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.spa_outlined,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            selectedIcon: Icon(
              Icons.spa_rounded,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Cope',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.book_outlined,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            selectedIcon: Icon(
              Icons.book,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.lightbulb_outline,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            selectedIcon: Icon(
              Icons.lightbulb_rounded,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Understand',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.hub_outlined,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            selectedIcon: Icon(
              Icons.hub_rounded,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Heal',
          ),
        ],
      ),
    );
  }
}
