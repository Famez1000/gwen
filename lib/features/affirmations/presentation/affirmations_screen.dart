import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.63);

  int _selectedCategoryIndex = 0;
  int _currentAffirmationIndex = 0;
  late final AppState _appState;
  late List<List<String>> _affirmations;

  static const List<List<String>> _defaultAffirmations = [
    [
      'This moment is uncomfortable, but it is temporary.',
      'I can slow down and meet this one breath at a time.',
      'My body is trying to protect me, and I can respond gently.',
      'I do not need to solve everything right now.',
    ],
    [
      'I have handled hard moments before.',
      'I can be scared and still choose my next small step.',
      'My thoughts are not orders. They are passing signals.',
      'I am allowed to take up space exactly as I am.',
    ],
    [
      'My shoulders can soften. My jaw can unclench.',
      'Each exhale gives my nervous system room to settle.',
      'I am safe enough to pause.',
      'There is nothing I need to force in this breath.',
    ],
  ];

  List<_AffirmationCategory> get _categories => [
    _AffirmationCategory(
      title: 'Right Now',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFF6FA8DC),
      affirmations: _affirmations[0],
    ),
    _AffirmationCategory(
      title: 'Self Trust',
      icon: Icons.favorite_rounded,
      color: Color(0xFF8B85A8),
      affirmations: _affirmations[1],
    ),
    _AffirmationCategory(
      title: 'Calm Body',
      icon: Icons.spa_rounded,
      color: Color(0xFF7FC8B2),
      affirmations: _affirmations[2],
    ),
  ];

  _AffirmationCategory get _selectedCategory =>
      _categories[_selectedCategoryIndex];

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _affirmations = _appState.getAffirmations(_defaultAffirmations);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _currentAffirmationIndex = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _copyCurrentAffirmation() {
    final affirmation =
        _selectedCategory.affirmations[_currentAffirmationIndex];
    Clipboard.setData(ClipboardData(text: affirmation));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Affirmation copied')));
  }

  Future<void> _editAffirmation(int index) async {
    final updatedText = await showDialog<String>(
      context: context,
      builder: (context) => _EditAffirmationDialog(
        initialText: _selectedCategory.affirmations[index],
      ),
    );

    final trimmed = updatedText?.trim();
    if (!mounted || trimmed == null || trimmed.isEmpty) return;

    setState(() {
      _affirmations[_selectedCategoryIndex][index] = trimmed;
      _currentAffirmationIndex = index;
    });
    await _appState.updateAffirmation(
      defaultAffirmations: _defaultAffirmations,
      categoryIndex: _selectedCategoryIndex,
      affirmationIndex: index,
      text: trimmed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Affirmations',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Text(
            //   'Gentle reminders',
            //   style: Theme.of(
            //     context,
            //   ).textTheme.bodyMedium?.copyWith(letterSpacing: 1.0),
            // ),
            const SizedBox(height: 4),
            Text(
              'Strengthen your belief system',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 22),
            _buildCategorySelector(isDark),
            const SizedBox(height: 24),
            SizedBox(
              height: 182,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _selectedCategory.affirmations.length,
                onPageChanged: (index) {
                  setState(() => _currentAffirmationIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _AffirmationCard(
                      affirmation: _selectedCategory.affirmations[index],
                      color: _selectedCategory.color,
                      onTap: () => _editAffirmation(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _selectedCategory.affirmations.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentAffirmationIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentAffirmationIndex == index
                        ? primaryColor
                        : (isDark ? Colors.white12 : Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Try reading it slowly three times: once in your head, once in a whisper, and once while exhaling.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _copyCurrentAffirmation,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy affirmation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return SizedBox(
      height: 92,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final itemWidth =
              (constraints.maxWidth - (spacing * (_categories.length - 1))) /
              _categories.length;

          return Row(
            children: List.generate(_categories.length, (index) {
              final category = _categories[index];
              final isSelected = index == _selectedCategoryIndex;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == _categories.length - 1 ? 0 : spacing,
                ),
                child: GestureDetector(
                  onTap: () => _selectCategory(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color.withAlpha(isDark ? 61 : 46)
                          : (isDark
                                ? Colors.white.withAlpha(10)
                                : Colors.white.withAlpha(153)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? category.color
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category.icon, color: category.color, size: 26),
                        const SizedBox(height: 8),
                        Text(
                          category.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  final String affirmation;
  final Color color;
  final VoidCallback onTap;

  const _AffirmationCard({
    required this.affirmation,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        color: color.withAlpha(isDark ? 36 : 28),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.format_quote_rounded, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              affirmation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: color.withAlpha(178),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAffirmationDialog extends StatefulWidget {
  final String initialText;

  const _EditAffirmationDialog({required this.initialText});

  @override
  State<_EditAffirmationDialog> createState() => _EditAffirmationDialogState();
}

class _EditAffirmationDialogState extends State<_EditAffirmationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
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
      title: const Text('Edit affirmation'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Affirmation',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
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

class _AffirmationCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> affirmations;

  const _AffirmationCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.affirmations,
  });
}
