import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class HikeScreen extends StatefulWidget {
  const HikeScreen({super.key});

  @override
  State<HikeScreen> createState() => _HikeScreenState();
}

class _HikeScreenState extends State<HikeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnimation;
  late final AudioPlayer _forestPlayer;
  bool _isPreparingImage = false;
  bool _isImageReady = false;
  bool _isSoundOn = false;
  bool _hasStartedSound = false;
  bool _isChangingSound = false;

  @override
  void initState() {
    super.initState();
    _forestPlayer = AudioPlayer(playerId: 'hike_forest_player');
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _zoomAnimation = Tween<double>(
      begin: 1,
      end: 1.35,
    ).animate(_zoomController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isPreparingImage) return;

    _isPreparingImage = true;
    precacheImage(const AssetImage('assets/images/hike.jpg'), context).then((
      _,
    ) {
      if (!mounted) return;
      setState(() => _isImageReady = true);
      _zoomController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _forestPlayer.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _toggleForestSound() async {
    if (_isChangingSound) return;
    setState(() => _isChangingSound = true);

    try {
      if (_isSoundOn) {
        await _forestPlayer.pause();
      } else if (_hasStartedSound) {
        await _forestPlayer.resume();
      } else {
        await _forestPlayer.setReleaseMode(ReleaseMode.loop);
        await _forestPlayer.play(AssetSource('sounds/forest.mp3'), volume: 0.5);
        _hasStartedSound = true;
      }

      if (mounted) {
        setState(() {
          _isSoundOn = !_isSoundOn;
          _isChangingSound = false;
        });
      }
    } catch (error) {
      debugPrint('[HikeScreen] Forest audio failed: $error');
      if (!mounted) return;
      setState(() => _isChangingSound = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play the forest sound.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isImageReady)
            ClipRect(
              child: AnimatedBuilder(
                animation: _zoomAnimation,
                child: Image.asset(
                  'assets/images/hike.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                builder: (context, child) => Transform.scale(
                  scale: _zoomAnimation.value,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0x55000000),
                ],
                stops: [0, 0.32, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withAlpha(90),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: _isSoundOn
                        ? 'Mute forest sound'
                        : 'Play forest sound',
                    onPressed: _isChangingSound ? null : _toggleForestSound,
                    icon: Icon(
                      _isSoundOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withAlpha(90),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black.withAlpha(60),
                      disabledForegroundColor: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Take a walk in nature',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
