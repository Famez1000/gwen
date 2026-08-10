import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../core/services/global_sound_service.dart';

class HikeScreen extends StatefulWidget {
  const HikeScreen({super.key});

  @override
  State<HikeScreen> createState() => _HikeScreenState();
}

class _HikeScreenState extends State<HikeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _baseZoomDuration = Duration(seconds: 30);
  static const _showZoomSpeedControl = false;

  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnimation;
  late final AudioPlayer _forestPlayer;
  bool _isPreparingImage = false;
  bool _isImageReady = false;
  bool _isSoundOn = false;
  bool _hasStartedSound = false;
  bool _isChangingSound = false;
  double _zoomSpeed = 1;
  int _soundOperationId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _forestPlayer = AudioPlayer(playerId: 'hike_forest_player');
    GlobalSoundService.instance.enabled.addListener(_applyGlobalSound);
    _zoomController = AnimationController(
      vsync: this,
      duration: _baseZoomDuration,
    );
    _zoomAnimation = Tween<double>(
      begin: 1,
      end: 1.35,
    ).animate(_zoomController);
    if (GlobalSoundService.instance.isEnabled) {
      unawaited(_setForestSound(true));
    }
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
    GlobalSoundService.instance.enabled.removeListener(_applyGlobalSound);
    WidgetsBinding.instance.removeObserver(this);
    _forestPlayer.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _applyGlobalSound() {
    unawaited(_setForestSound(GlobalSoundService.instance.isEnabled));
  }

  Future<void> _toggleForestSound() async {
    await _setForestSound(!_isSoundOn);
  }

  Future<void> _setForestSound(bool shouldTurnOn) async {
    if (_isChangingSound) return;
    final operationId = ++_soundOperationId;
    setState(() => _isChangingSound = true);

    try {
      if (!shouldTurnOn) {
        await _forestPlayer.pause();
      } else if (_hasStartedSound) {
        await _forestPlayer.resume();
      } else {
        await _forestPlayer.setReleaseMode(ReleaseMode.loop);
        await _forestPlayer.play(AssetSource('sounds/forest.mp3'), volume: 0.5);
        _hasStartedSound = true;
      }

      if (operationId != _soundOperationId) {
        if (shouldTurnOn) {
          await _forestPlayer.stop();
          _hasStartedSound = false;
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isSoundOn = shouldTurnOn;
          _isChangingSound = false;
        });
      }
    } catch (error) {
      debugPrint('[HikeScreen] Forest audio failed: $error');
      if (!mounted || operationId != _soundOperationId) return;
      setState(() => _isChangingSound = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play the forest sound.')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;

    _soundOperationId++;
    _hasStartedSound = false;
    if (mounted && (_isSoundOn || _isChangingSound)) {
      setState(() {
        _isSoundOn = false;
        _isChangingSound = false;
      });
    } else {
      _isSoundOn = false;
      _isChangingSound = false;
    }
    unawaited(
      _forestPlayer.stop().catchError((Object error) {
        debugPrint('[HikeScreen] Could not stop hidden-app audio: $error');
      }),
    );
  }

  void _setZoomSpeed(double speed) {
    final wasAnimating = _zoomController.isAnimating;
    final currentProgress = _zoomController.value;
    setState(() => _zoomSpeed = speed);
    _zoomController.duration = Duration(
      milliseconds: (_baseZoomDuration.inMilliseconds / speed).round(),
    );
    if (wasAnimating) _zoomController.forward(from: currentProgress);
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showZoomSpeedControl) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(105),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Zoom speed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Slider(
                                  value: _zoomSpeed,
                                  min: 0.5,
                                  max: 2,
                                  divisions: 6,
                                  label: '${_zoomSpeed.toStringAsFixed(2)}×',
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white38,
                                  onChanged: _setZoomSpeed,
                                ),
                              ),
                              SizedBox(
                                width: 42,
                                child: Text(
                                  '${_zoomSpeed.toStringAsFixed(2)}×',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
