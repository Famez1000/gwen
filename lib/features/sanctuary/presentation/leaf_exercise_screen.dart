import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class LeafExerciseScreen extends StatefulWidget {
  const LeafExerciseScreen({super.key});

  @override
  State<LeafExerciseScreen> createState() => _LeafExerciseScreenState();
}

class _LeafExerciseScreenState extends State<LeafExerciseScreen> {
  late final VideoPlayerController _videoController;
  late final Future<void> _videoInit;
  bool _soundEnabled = false;
  bool _loopEnabled = true;
  double _playbackSpeed = 0.75;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    _videoController = VideoPlayerController.asset(
      'assets/videos/falling_leafs_1.mp4',
    );
    _videoInit = _videoController.initialize().then((_) {
      _videoController
        ..setLooping(true)
        ..setVolume(0)
        ..setPlaybackSpeed(_playbackSpeed)
        ..play();
      if (mounted) setState(() {});
    });
    _videoController.addListener(_refresh);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _videoController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _togglePlayback() {
    if (!_videoController.value.isInitialized) return;

    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
  }

  void _toggleSound() {
    if (!_videoController.value.isInitialized) return;

    setState(() => _soundEnabled = !_soundEnabled);
    _videoController.setVolume(_soundEnabled ? 1 : 0);
  }

  void _toggleLoop() {
    if (!_videoController.value.isInitialized) return;

    setState(() => _loopEnabled = !_loopEnabled);
    _videoController.setLooping(_loopEnabled);
  }

  void _setPlaybackSpeed(double speed) {
    if (!_videoController.value.isInitialized) return;

    setState(() => _playbackSpeed = speed);
    _videoController.setPlaybackSpeed(speed);
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSpeed(double speed) {
    return speed == speed.roundToDouble()
        ? speed.toStringAsFixed(0)
        : speed.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Leaf Exercise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF101725)
                    : const Color(0xFFEAF6F2),
              ),
            ),
          ),
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _videoInit,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: FutureBuilder<void>(
                future: _videoInit,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done ||
                      !_videoController.value.isInitialized) {
                    return const SizedBox.shrink();
                  }

                  return _LeafVideoControls(
                    controller: _videoController,
                    isDark: isDark,
                    soundEnabled: _soundEnabled,
                    loopEnabled: _loopEnabled,
                    playbackSpeed: _playbackSpeed,
                    onPlayPause: _togglePlayback,
                    onToggleSound: _toggleSound,
                    onToggleLoop: _toggleLoop,
                    onSpeedChanged: _setPlaybackSpeed,
                    formatTime: _formatTime,
                    formatSpeed: _formatSpeed,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeafVideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isDark;
  final bool soundEnabled;
  final bool loopEnabled;
  final double playbackSpeed;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleSound;
  final VoidCallback onToggleLoop;
  final ValueChanged<double> onSpeedChanged;
  final String Function(Duration duration) formatTime;
  final String Function(double speed) formatSpeed;

  const _LeafVideoControls({
    required this.controller,
    required this.isDark,
    required this.soundEnabled,
    required this.loopEnabled,
    required this.playbackSpeed,
    required this.onPlayPause,
    required this.onToggleSound,
    required this.onToggleLoop,
    required this.onSpeedChanged,
    required this.formatTime,
    required this.formatSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final position = value.position > duration ? duration : value.position;
    final maxSeconds = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final currentSeconds = position.inMilliseconds
        .clamp(0, maxSeconds.toInt())
        .toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withAlpha(150)
            : Colors.white.withAlpha(210),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(36)
              : Colors.black.withAlpha(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 92 : 32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4, bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatTime(position)} / ${formatTime(duration)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  PopupMenuButton<double>(
                    tooltip: 'Playback speed',
                    initialValue: playbackSpeed,
                    onSelected: onSpeedChanged,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      PopupMenuItem(value: 0.75, child: Text('0.75x')),
                      PopupMenuItem(value: 1, child: Text('1x')),
                      PopupMenuItem(value: 1.25, child: Text('1.25x')),
                      PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    ],
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(20)
                            : Colors.black.withAlpha(10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          '${formatSpeed(playbackSpeed)}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: loopEnabled ? 'Loop on' : 'Loop off',
                  onPressed: onToggleLoop,
                  icon: Icon(
                    loopEnabled
                        ? Icons.repeat_rounded
                        : Icons.repeat_one_rounded,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: currentSeconds,
                    min: 0,
                    max: maxSeconds,
                    onChanged: (value) {
                      controller.seekTo(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
                IconButton.filled(
                  tooltip: value.isPlaying ? 'Pause' : 'Play',
                  onPressed: onPlayPause,
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  tooltip: soundEnabled ? 'Mute' : 'Sound off',
                  onPressed: onToggleSound,
                  icon: Icon(
                    soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
