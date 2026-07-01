import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/state/app_state.dart';

class GroundingScreen extends StatefulWidget {
  final AppState appState;

  const GroundingScreen({super.key, required this.appState});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  int _currentStep = 5; // 5 to 1
  final List<String> _completedItems = [];
  late List<String> _groundingObjects;
  late List<String> _groundingTouchObjects;
  late List<String> _groundingSoundObjects;
  late List<String> _groundingSmellObjects;
  late List<String> _groundingTasteObjects;

  @override
  void initState() {
    super.initState();
    _groundingObjects = List.of(widget.appState.groundingObjects);
    _groundingTouchObjects = List.of(widget.appState.groundingTouchObjects);
    _groundingSoundObjects = List.of(widget.appState.groundingSoundObjects);
    _groundingSmellObjects = List.of(widget.appState.groundingSmellObjects);
    _groundingTasteObjects = List.of(widget.appState.groundingTasteObjects);
  }

  void _handleItemAdded(String itemName) {
    if (itemName.trim().isEmpty) return;

    setState(() {
      _completedItems.add(itemName);
      if (widget.appState.hapticEnabled) {
        HapticFeedback.lightImpact();
      }

      // Check if current step goals met
      final requiredCount = _currentStep;
      if (_completedItems.length >= requiredCount) {
        // Transition to next step
        if (_currentStep > 1) {
          _currentStep--;
          _completedItems.clear();
        } else {
          // Finished grounding!
          _currentStep = 0; // Completed state
          widget.appState.addAnxietyLog(
            widget.appState.currentAnxietyLevel,
            3,
            ["grounding"],
          );
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _currentStep = 5;
      _completedItems.clear();
    });
  }

  Future<void> _editGroundingItem(int step, int index) async {
    final items = switch (step) {
      5 => _groundingObjects,
      4 => _groundingTouchObjects,
      3 => _groundingSoundObjects,
      2 => _groundingSmellObjects,
      1 => _groundingTasteObjects,
      _ => _groundingObjects,
    };
    final updatedObject = await showDialog<String>(
      context: context,
      builder: (context) =>
          _EditGroundingObjectDialog(initialText: items[index]),
    );

    final trimmed = updatedObject?.trim();
    if (!mounted || trimmed == null || trimmed.isEmpty) return;

    final oldObject = items[index];
    setState(() {
      items[index] = trimmed;
      final completedIndex = _completedItems.indexOf(oldObject);
      if (completedIndex != -1) {
        _completedItems[completedIndex] = trimmed;
      }
    });

    if (step == 5) {
      await widget.appState.updateGroundingObject(index, trimmed);
    } else if (step == 4) {
      await widget.appState.updateGroundingTouchObject(index, trimmed);
    } else if (step == 3) {
      await widget.appState.updateGroundingSoundObject(index, trimmed);
    } else if (step == 2) {
      await widget.appState.updateGroundingSmellObject(index, trimmed);
    } else {
      await widget.appState.updateGroundingTasteObject(index, trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Grounding Sanctuary",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _currentStep == 0
                ? _buildCompletionState(isDark, primaryColor)
                : _buildGroundingStepView(isDark, primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildGroundingStepView(bool isDark, Color primary) {
    final suggestions = switch (_currentStep) {
      5 => _groundingObjects,
      4 => _groundingTouchObjects,
      3 => _groundingSoundObjects,
      2 => _groundingSmellObjects,
      1 => _groundingTasteObjects,
      _ => [],
    };
    final currentCount = _completedItems.length;
    final totalNeeded = _currentStep;

    return Column(
      key: ValueKey<int>(_currentStep),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Sensory awareness",
              style: TextStyle(
                letterSpacing: 1.0,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            Text(
              "Step ${6 - _currentStep} of 5",
              style: TextStyle(fontWeight: FontWeight.w600, color: primary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (6 - _currentStep) / 5.0,
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            valueColor: AlwaysStoppedAnimation(primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 32),

        // Prominent instruction
        Text(
          "Identify $_currentStep ${_getSenseVerb(_currentStep)}:",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _getSenseHelpText(_currentStep),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 30),

        // Visual Items checklist/completion status bubbles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalNeeded, (index) {
            final isDone = index < currentCount;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDone ? primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? primary
                      : (isDark ? Colors.white24 : Colors.black26),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            );
          }),
        ),
        const SizedBox(height: 30),

        // Interactive Suggestion Grid
        Expanded(
          child: GridView.builder(
            itemCount: suggestions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _currentStep == 1 ? 1 : 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              final isUsed = _completedItems.contains(suggestion);
              return GestureDetector(
                onTap: isUsed ? null : () => _handleItemAdded(suggestion),
                onLongPress: () => _editGroundingItem(_currentStep, index),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isUsed
                        ? primary.withAlpha(31)
                        : (isDark ? Colors.white.withAlpha(10) : Colors.white),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isUsed
                          ? primary
                          : (isDark
                                ? Colors.white.withAlpha(20)
                                : Colors.black.withAlpha(15)),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            suggestion,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isUsed
                                  ? primary
                                  : (isDark
                                        ? Colors.white.withAlpha(204)
                                        : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCompletionState(bool isDark, Color primary) {
    return Column(
      key: const ValueKey<int>(0),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.spa_rounded, size: 72, color: primary),
        const SizedBox(height: 24),
        Text(
          "Nervous System Anchored",
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Take a slow breath. Notice your physical body. Roll your shoulders back and relax your jaw. You are completely safe in this moment.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black.withAlpha(153),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: ElevatedButton(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Ground Again"),
          ),
        ),
      ],
    );
  }

  String _getSenseVerb(int step) {
    switch (step) {
      case 5:
        return "things you see";
      case 4:
        return "things you can touch";
      case 3:
        return "things you can hear";
      case 2:
        return "things you can smell";
      default:
        return "thing you can taste";
    }
  }

  String _getSenseHelpText(int step) {
    switch (step) {
      case 5:
        return "Look around the room and select 5 physical objects (long press to edit an item)";
      case 4:
        return "Pay attention to your body. Select 4 physical sensations (long press to edit an item).";
      case 3:
        return "Close your eyes for 5 seconds. Identify 3 distinct sounds (long press to edit an item).";
      case 2:
        return "Inhale deeply. Identify 2 smells in the air or nearby (long press to edit an item).";
      default:
        return "Sip some water or focus on the current taste in your mouth (long press to edit the item).";
    }
  }
}

class _EditGroundingObjectDialog extends StatefulWidget {
  final String initialText;

  const _EditGroundingObjectDialog({required this.initialText});

  @override
  State<_EditGroundingObjectDialog> createState() =>
      _EditGroundingObjectDialogState();
}

class _EditGroundingObjectDialogState
    extends State<_EditGroundingObjectDialog> {
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
      title: const Text('Edit object'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Object',
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
