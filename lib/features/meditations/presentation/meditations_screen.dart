import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/glass_card.dart';

class MeditationsScreen extends StatefulWidget {
  const MeditationsScreen({super.key});

  @override
  State<MeditationsScreen> createState() => _MeditationsScreenState();
}

class _MeditationsScreenState extends State<MeditationsScreen> {
  static const List<_MeditationClip> _clips = [
    _MeditationClip(
      title: 'Sacred Space',
      subtitle: '432 / 369 meditation ambience',
      assetPath: 'sounds/meditation_sacred Space_432_369.mp3',
      color: Color(0xFF6F8FAF),
    ),
    _MeditationClip(
      title: 'Mandala Meditation',
      subtitle: 'Soft background music for drawing or grounding',
      assetPath: 'sounds/meditation_mandala.mp3',
      color: Color(0xFF7F8C6F),
    ),
  ];

  late final AudioPlayer _player;
  late final StreamSubscription<void> _completeSubscription;

  int? _activeIndex;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer(playerId: 'meditations_player');
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _activeIndex = null;
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _completeSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleClip(int index) async {
    final isActiveClip = _activeIndex == index;

    HapticFeedback.selectionClick();
    try {
      if (isActiveClip && _isPlaying) {
        await _player.pause();
        if (mounted) {
          setState(() => _isPlaying = false);
        }
        return;
      }

      if (isActiveClip && !_isPlaying) {
        await _player.resume();
        if (mounted) {
          setState(() => _isPlaying = true);
        }
        return;
      }

      await _player.stop();
      await _player.play(AssetSource(_clips[index].assetPath), volume: 0.35);
      if (mounted) {
        setState(() {
          _activeIndex = index;
          _isPlaying = true;
        });
      }
    } catch (error) {
      debugPrint('[MeditationsScreen] Audio failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play this sound clip.')),
      );
    }
  }

  Future<void> _stopPlayback() async {
    HapticFeedback.selectionClick();
    await _player.stop();
    if (mounted) {
      setState(() {
        _activeIndex = null;
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meditations',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Stop',
            onPressed: _activeIndex == null ? null : _stopPlayback,
            icon: const Icon(Icons.stop_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: _clips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final clip = _clips[index];
            final isActive = _activeIndex == index;

            return _MeditationClipCard(
              clip: clip,
              isActive: isActive,
              isPlaying: isActive && _isPlaying,
              isDark: isDark,
              onTap: () => _toggleClip(index),
            );
          },
        ),
      ),
    );
  }
}

class _MeditationClipCard extends StatelessWidget {
  final _MeditationClip clip;
  final bool isActive;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onTap;

  const _MeditationClipCard({
    required this.clip,
    required this.isActive,
    required this.isPlaying,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: clip.color.withAlpha(isActive ? 54 : 31),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.spa_rounded, color: clip.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clip.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            tooltip: isPlaying ? 'Pause' : 'Play',
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: clip.color.withAlpha(42),
              foregroundColor: clip.color,
            ),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeditationClip {
  final String title;
  final String subtitle;
  final String assetPath;
  final Color color;

  const _MeditationClip({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.color,
  });
}
