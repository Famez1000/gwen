import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';

class AnxietyPersonaScreen extends StatefulWidget {
  final AppState appState;

  const AnxietyPersonaScreen({super.key, required this.appState});

  @override
  State<AnxietyPersonaScreen> createState() => _AnxietyPersonaScreenState();
}

class _AnxietyPersonaScreenState extends State<AnxietyPersonaScreen> {
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _imageBase64;
  Future<void> _saveQueue = Future<void>.value();
  int _pendingSaves = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.appState.anxietyPersonaName,
    );
    _descriptionController = TextEditingController(
      text: widget.appState.anxietyPersonaDescription,
    );
    _imageBase64 = widget.appState.anxietyPersonaImageBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 700,
        maxHeight: 700,
        imageQuality: 82,
      );
      if (image == null) return;
      final encoded = base64Encode(await image.readAsBytes());
      if (!mounted) return;
      setState(() => _imageBase64 = encoded);
      _saveAutomatically();
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.code == 'channel-error'
          ? 'Adding a picture needs a full app restart after this update.'
          : 'Could not open your photo library. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add that picture.')),
      );
    }
  }

  void _saveAutomatically() {
    final name = _nameController.text;
    final description = _descriptionController.text;
    final imageBase64 = _imageBase64;

    setState(() {
      _pendingSaves++;
      _saving = true;
    });

    _saveQueue = _saveQueue.then((_) async {
      await widget.appState.setAnxietyPersona(
        name: name,
        description: description,
        imageBase64: imageBase64,
      );
      _pendingSaves--;
      if (!mounted) return;
      setState(() => _saving = _pendingSaves > 0);
    });
  }

  Uint8List? get _imageBytes {
    if (_imageBase64.isEmpty) return null;
    try {
      return base64Decode(_imageBase64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your anxiety persona'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'Separate yourself from anxious thoughts',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Give anxiety its own character. When it appears, you can recognize it as a familiar visitor—not as who you are.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            GlassCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Semantics(
                      button: true,
                      label: 'Choose a picture for your anxiety persona',
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                color: color.withAlpha(isDark ? 38 : 24),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: color.withAlpha(120),
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _imageBytes == null
                                  ? Icon(
                                      Icons.add_a_photo_rounded,
                                      color: color,
                                      size: 46,
                                    )
                                  : Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                            ),
                            Positioned(
                              right: -7,
                              bottom: -7,
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: color,
                                child: const Icon(
                                  Icons.photo_library_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('anxiety-persona-name'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 30,
                    onChanged: (_) => _saveAutomatically(),
                    decoration: const InputDecoration(
                      labelText: 'Persona name',
                      hintText: 'For example, Anxious Harry',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('anxiety-persona-description'),
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 240,
                    onChanged: (_) => _saveAutomatically(),
                    decoration: const InputDecoration(
                      labelText: 'Describe this persona',
                      hintText: 'What do they say, predict, or make you feel?',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _nameController.text.trim().isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_nameController.text.trim()),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: color.withAlpha(isDark ? 28 : 20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withAlpha(75)),
                      ),
                      child: Text(
                        '“Oh, it’s good old ${_nameController.text.trim()} again.”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Row(
                key: ValueKey(_saving),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.cloud_done_rounded, color: color, size: 17),
                  const SizedBox(width: 7),
                  Text(
                    _saving ? 'Saving...' : 'Saved automatically',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
