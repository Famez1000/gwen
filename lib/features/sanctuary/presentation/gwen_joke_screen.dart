import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/gemini_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';

class GwenJokeScreen extends StatefulWidget {
  const GwenJokeScreen({super.key});

  @override
  State<GwenJokeScreen> createState() => _GwenJokeScreenState();
}

class _GwenJokeScreenState extends State<GwenJokeScreen> {
  String? _joke;
  bool _isLoading = false;

  Future<void> _tellJoke() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _joke = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final joke = await GeminiService.instance.generateRelaxingJoke(
        recentJokes: appState.recentGwenJokes,
      );
      if (!mounted) return;
      await appState.rememberGwenJoke(joke);
      if (!mounted) return;
      setState(() => _joke = joke);
    } catch (error) {
      debugPrint('[GwenJokeScreen] Joke generation failed: $error');
      if (!mounted) return;
      setState(
        () => _joke =
            'I asked my stress to take a number. It said it was already holding all of them, so I gave it a chair and we both sat down.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gwen\'s Joke Corner',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          children: [
            Center(
              child: CircleAvatar(
                radius: 74,
                backgroundColor: primaryColor.withAlpha(31),
                backgroundImage: const AssetImage('assets/images/gwen_funny.png'),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Let me tell you a joke.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'A small laugh can loosen the grip of a tense moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.4,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _isLoading ? null : _tellJoke,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sentiment_satisfied_alt_rounded),
              label: Text(_isLoading ? 'Finding a gentle joke...' : 'Tell me'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            if (_joke != null) ...[
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _joke!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _isLoading ? null : _tellJoke,
                child: const Text('Tell me another one'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
