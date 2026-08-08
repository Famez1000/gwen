import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GwynPuzzleScreen extends StatefulWidget {
  const GwynPuzzleScreen({super.key});

  @override
  State<GwynPuzzleScreen> createState() => _GwynPuzzleScreenState();
}

class _GwynPuzzleScreenState extends State<GwynPuzzleScreen> {
  static const _gridSize = 4;
  static const _tileCount = _gridSize * _gridSize;
  static const _blankTile = _tileCount - 1;
  static const _imageAsset = 'assets/images/gwyn-puzzle.png';

  final Random _random = Random();
  late List<int> _tiles;
  ui.Image? _puzzleImage;
  int _moves = 0;
  bool _completionDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _tiles = List<int>.generate(_tileCount, (index) => index);
    _shuffle();
    unawaited(_loadPuzzleImage());
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
    _puzzleImage?.dispose();
    super.dispose();
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

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
    );

    _completionDialogShowing = false;
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _imageAsset,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
