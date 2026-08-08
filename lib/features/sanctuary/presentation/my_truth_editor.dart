import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';

Future<void> showMyTruthEditor(BuildContext context, AppState appState) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _MyTruthDialog(appState: appState),
  );
}

class _MyTruthDialog extends StatefulWidget {
  final AppState appState;

  const _MyTruthDialog({required this.appState});

  @override
  State<_MyTruthDialog> createState() => _MyTruthDialogState();
}

class _MyTruthDialogState extends State<_MyTruthDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.appState.moodRealityText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.appState.setMoodRealityText(
      _controller.text.replaceFirst(RegExp(r'\s+$'), ''),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('My Truth'),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 6,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Write the truths that help bring you back to reality.',
            border: OutlineInputBorder(),
          ),
        ),
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
