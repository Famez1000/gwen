import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/global_sound_service.dart';

class GwynPuzzleScreen extends StatefulWidget {
  const GwynPuzzleScreen({super.key});

  @override
  State<GwynPuzzleScreen> createState() => _GwynPuzzleScreenState();
}

class _GwynPuzzleScreenState extends State<GwynPuzzleScreen>
    with SingleTickerProviderStateMixin {
  static const _gridSize = 4;
  static const _tileCount = _gridSize * _gridSize;
  static const _blankTile = _tileCount - 1;
  static const _imageAsset = 'assets/images/gwyn-puzzle.png';

  final Random _random = Random();
  late List<int> _tiles;
  late final AudioPlayer _musicPlayer;
  late final AudioPlayer _victoryPlayer;
  late final AnimationController _confettiController;
  ui.Image? _puzzleImage;
  int _moves = 0;
  bool _completionDialogShowing = false;
  bool _exampleImageExpanded = false;
  bool _soundEnabled = false;
  bool _musicLoaded = false;

  @override
  void initState() {
    super.initState();
    _musicPlayer = AudioPlayer(playerId: 'gwyn_puzzle_music');
    _victoryPlayer = AudioPlayer(playerId: 'gwyn_puzzle_victory');
    GlobalSoundService.instance.enabled.addListener(_applyGlobalSound);
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _tiles = List<int>.generate(_tileCount, (index) => index);
    _shuffle();
    unawaited(_loadPuzzleImage());
    if (GlobalSoundService.instance.isEnabled) {
      unawaited(_setSoundEnabled(true));
    }
  }

  Future<void> _loadPuzzleImage() async {
    final imageData = await rootBundle.load(_imageAsset);
    final codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    codec.dispose();

    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _puzzleImage = frame.image);
  }

  @override
  void dispose() {
    GlobalSoundService.instance.enabled.removeListener(_applyGlobalSound);
    _puzzleImage?.dispose();
    _musicPlayer.dispose();
    _victoryPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _applyGlobalSound() {
    unawaited(_setSoundEnabled(GlobalSoundService.instance.isEnabled));
  }

  void _shuffle() {
    final tiles = List<int>.generate(_tileCount, (index) => index);
    var blankIndex = _blankTile;
    var previousBlankIndex = -1;

    for (var step = 0; step < 240; step++) {
      final neighbors = _neighborIndexes(
        blankIndex,
      ).where((index) => index != previousBlankIndex).toList();
      final nextIndex = neighbors[_random.nextInt(neighbors.length)];
      tiles[blankIndex] = tiles[nextIndex];
      tiles[nextIndex] = _blankTile;
      previousBlankIndex = blankIndex;
      blankIndex = nextIndex;
    }

    if (_isSolved(tiles)) {
      final nextIndex = _neighborIndexes(blankIndex).first;
      tiles[blankIndex] = tiles[nextIndex];
      tiles[nextIndex] = _blankTile;
    }

    if (mounted) {
      setState(() {
        _tiles = tiles;
        _moves = 0;
      });
    } else {
      _tiles = tiles;
      _moves = 0;
    }
  }

  List<int> _neighborIndexes(int index) {
    final row = index ~/ _gridSize;
    final column = index % _gridSize;
    final neighbors = <int>[];

    if (row > 0) neighbors.add(index - _gridSize);
    if (row < _gridSize - 1) neighbors.add(index + _gridSize);
    if (column > 0) neighbors.add(index - 1);
    if (column < _gridSize - 1) neighbors.add(index + 1);
    return neighbors;
  }

  void _moveTile(int tile) {
    final tileIndex = _tiles.indexOf(tile);
    final blankIndex = _tiles.indexOf(_blankTile);
    if (!_neighborIndexes(blankIndex).contains(tileIndex)) return;

    setState(() {
      _tiles[blankIndex] = tile;
      _tiles[tileIndex] = _blankTile;
      _moves++;
    });

    if (_isSolved(_tiles)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletionDialog();
      });
    }
  }

  bool _isSolved(List<int> tiles) {
    for (var index = 0; index < tiles.length; index++) {
      if (tiles[index] != index) return false;
    }
    return true;
  }

  Future<void> _showCompletionDialog() async {
    if (_completionDialogShowing) return;
    _completionDialogShowing = true;
    if (_soundEnabled) unawaited(_playVictorySound());
    unawaited(_confettiController.forward(from: 0));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) => CustomPaint(
                  painter: _PuzzleConfettiPainter(
                    progress: _confettiController.value,
                  ),
                ),
              ),
            ),
          ),
          AlertDialog(
            title: const Text('Puzzle complete!'),
            content: Text('You restored Gwyn in $_moves moves.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _shuffle();
                },
                child: const Text('Play again'),
              ),
            ],
          ),
        ],
      ),
    );

    _completionDialogShowing = false;
  }

  Future<void> _playVictorySound() async {
    try {
      for (final playbackRate in const [0.85, 1.1, 1.4]) {
        await _victoryPlayer.play(
          AssetSource('sounds/bubble_pop.wav'),
          volume: 0.65,
        );
        await _victoryPlayer.setPlaybackRate(playbackRate);
        await Future<void>.delayed(const Duration(milliseconds: 125));
      }
    } catch (error) {
      debugPrint('[GwynPuzzleScreen] Victory sound failed: $error');
    }
  }

  Future<void> _toggleSound() async {
    await _setSoundEnabled(!_soundEnabled);
  }

  Future<void> _setSoundEnabled(bool shouldEnable) async {
    if (mounted) setState(() => _soundEnabled = shouldEnable);

    try {
      if (!shouldEnable) {
        await _musicPlayer.pause();
        return;
      }

      if (_musicLoaded) {
        await _musicPlayer.resume();
      } else {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        if (!_soundEnabled) return;
        await _musicPlayer.play(AssetSource('sounds/puzzle.mp3'), volume: 0.55);
        _musicLoaded = true;
      }

      if (!_soundEnabled) await _musicPlayer.pause();
    } catch (error) {
      debugPrint('[GwynPuzzleScreen] Music failed: $error');
      if (mounted && _soundEnabled) {
        setState(() => _soundEnabled = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gwyn Puzzle'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _soundEnabled ? 'Mute' : 'Turn sound on',
            onPressed: _toggleSound,
            icon: Icon(
              _soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _exampleImageExpanded
                  ? Semantics(
                      button: true,
                      label: 'Shrink example image',
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _exampleImageExpanded = false),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.asset(_imageAsset, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Enlarge example image',
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _exampleImageExpanded = true),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                _imageAsset,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Restore Gwyn’s picture',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Tap a tile next to the empty space to slide it.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = constraints.maxWidth;
                  final tileSize = boardSize / _gridSize;

                  return Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(24),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: primaryColor.withAlpha(60)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        _buildBlankSlot(tileSize),
                        for (var tile = 0; tile < _blankTile; tile++)
                          _buildTile(tile: tile, tileSize: tileSize),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Moves: $_moves',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _shuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Shuffle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankSlot(double tileSize) {
    final blankIndex = _tiles.indexOf(_blankTile);
    final row = blankIndex ~/ _gridSize;
    final column = blankIndex % _gridSize;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      left: column * tileSize,
      top: row * tileSize,
      width: tileSize,
      height: tileSize,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.black12),
          ),
        ),
      ),
    );
  }

  Widget _buildTile({required int tile, required double tileSize}) {
    final currentIndex = _tiles.indexOf(tile);
    final row = currentIndex ~/ _gridSize;
    final column = currentIndex % _gridSize;

    return AnimatedPositioned(
      key: ValueKey(tile),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      left: column * tileSize,
      top: row * tileSize,
      width: tileSize,
      height: tileSize,
      child: Semantics(
        button: true,
        label: 'Puzzle tile ${tile + 1}',
        child: InkWell(
          onTap: () => _moveTile(tile),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: _puzzleImage == null
                  ? const ColoredBox(color: Colors.white)
                  : CustomPaint(
                      painter: _PuzzleTilePainter(
                        image: _puzzleImage!,
                        tile: tile,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PuzzleConfettiPainter extends CustomPainter {
  static const _colors = [
    Color(0xFFFFC857),
    Color(0xFFFF6B8A),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFF9B5DE5),
    Color(0xFFFF8C42),
  ];

  final double progress;

  const _PuzzleConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final random = Random(4831);
    for (var index = 0; index < 80; index++) {
      final delay = random.nextDouble() * 0.18;
      final particleProgress = ((progress - delay) / (1 - delay)).clamp(
        0.0,
        1.0,
      );
      if (particleProgress <= 0) continue;

      final startX = size.width * 0.5 + (random.nextDouble() - 0.5) * 24;
      final horizontalTravel =
          (random.nextDouble() * 2 - 1) * size.width * 0.72;
      final upwardTravel = size.height * (0.28 + random.nextDouble() * 0.2);
      final gravity = size.height * (1.08 + random.nextDouble() * 0.32);
      final easedProgress = Curves.easeOut.transform(particleProgress);
      final sway =
          sin(particleProgress * pi * (2 + random.nextDouble() * 3)) * 12;
      final x = startX + horizontalTravel * easedProgress + sway;
      final y =
          size.height * 0.2 -
          upwardTravel * particleProgress +
          gravity * particleProgress * particleProgress;
      final opacity = particleProgress < 0.82
          ? 1.0
          : (1 - particleProgress) / 0.18;
      final color = _colors[index % _colors.length].withAlpha(
        (opacity * 255).round(),
      );
      final width = 6.0 + random.nextDouble() * 6;
      final height = 3.0 + random.nextDouble() * 5;

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(particleProgress * pi * (2 + random.nextDouble() * 5));
      if (index.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: width, height: height),
            const Radius.circular(2),
          ),
          Paint()..color = color,
        );
      } else {
        canvas.drawCircle(Offset.zero, width * 0.42, Paint()..color = color);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PuzzleConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PuzzleTilePainter extends CustomPainter {
  final ui.Image image;
  final int tile;

  const _PuzzleTilePainter({required this.image, required this.tile});

  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 4;
    final sourceWidth = image.width / gridSize;
    final sourceHeight = image.height / gridSize;
    final sourceColumn = tile % gridSize;
    final sourceRow = tile ~/ gridSize;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        sourceColumn * sourceWidth,
        sourceRow * sourceHeight,
        sourceWidth,
        sourceHeight,
      ),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _PuzzleTilePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.tile != tile;
  }
}
