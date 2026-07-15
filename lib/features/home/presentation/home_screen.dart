import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../subscription/application/subscription_gate.dart';
import 'mood_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onBottomDestinationSelected;

  const HomeScreen({super.key, this.onBottomDestinationSelected});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Future<void> _askForName(AppState appState) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NamePromptDialog(initialName: appState.userName),
    );

    if (!mounted || name == null) return;

    await appState.setUserName(name);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Name saved')));
  }

  void _openMood(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => switch (index) {
          1 => PanicMoodScreen(
            onDestinationSelected: widget.onBottomDestinationSelected,
          ),
          2 => NotOkMoodScreen(
            onDestinationSelected: widget.onBottomDestinationSelected,
          ),
          3 => SurvivingMoodScreen(
            onDestinationSelected: widget.onBottomDestinationSelected,
          ),
          _ => PanicMoodScreen(
            onDestinationSelected: widget.onBottomDestinationSelected,
          ),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                GestureDetector(
                  onTap: () {
                    openGwynChatOrSubscription(
                      context,
                      previewBeforeSubscription: true,
                      previewDialogMessage:
                          'Here you can chat with Gwyn using AI. This preview uses built-in example responses so you can see how Gwyn replies before subscribing.',
                    );
                  },
                  child: Image.asset(
                    'assets/images/gwen_relaxed.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedGreeting(
                    userName: appState.userName,
                    onWeGotThisTap: () => _askForName(appState),
                  ),
                ),
                // Smiley icons extracted from assets/images/
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MoodChoice(
                      imageAsset: 'assets/images/em_1.png',
                      label: 'Panic',
                      onTap: () => _openMood(1),
                    ),
                    _MoodChoice(
                      imageAsset: 'assets/images/em_2.png',
                      label: 'Not OK',
                      onTap: () => _openMood(2),
                    ),
                    _MoodChoice(
                      imageAsset: 'assets/images/em_3.png',
                      label: 'Surviving',
                      onTap: () => _openMood(3),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.show_chart_rounded),
                        label: const Text('Progress'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProgressScreen(appState: appState),
                            ),
                          );
                        },
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: const Text('Reminders'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RemindersScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            Positioned(
              top: 6,
              left: 16,
              child: IconButton(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black54,
                ),
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withAlpha(13)
                      : Colors.black.withAlpha(8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(appState: appState),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 6,
              right: 16,
              child: IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black54,
                ),
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withAlpha(13)
                      : Colors.black.withAlpha(8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(appState: appState),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChoice extends StatelessWidget {
  final String imageAsset;
  final String label;
  final VoidCallback onTap;

  const _MoodChoice({
    required this.imageAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imageAsset, width: 64, height: 64),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedGreeting extends StatefulWidget {
  final String userName;
  final VoidCallback? onWeGotThisTap;

  const AnimatedGreeting({super.key, this.userName = '', this.onWeGotThisTap});

  @override
  State<AnimatedGreeting> createState() => _AnimatedGreetingState();
}

class _AnimatedGreetingState extends State<AnimatedGreeting> {
  int _currentIndex = 0;

  List<String> get _lines {
    return ['Gwyn here', "How's it going?"];
  }

  String get _weGotThisLine {
    final trimmedName = widget.userName.trim();
    final namePart = trimmedName.isEmpty ? ', my friend' : ' $trimmedName';
    return 'We got this$namePart';
  }

  @override
  void initState() {
    super.initState();
    _showNext();
  }

  void _showNext() {
    if (_currentIndex < _lines.length - 1) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
        });
        _showNext();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_lines.length, (index) {
        return AnimatedOpacity(
          opacity: _currentIndex >= index ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: index == 0
                ? Column(
                    children: [
                      Text(
                        _lines[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onWeGotThisTap,
                        child: Text(
                          _weGotThisLine,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      _lines[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

class _NamePromptDialog extends StatefulWidget {
  final String initialName;

  const _NamePromptDialog({required this.initialName});

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('How shall I call you?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'She will use this name when speaking with you.',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'Your name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save name')),
      ],
    );
  }
}
