import 'package:flutter/foundation.dart';

/// Keeps active audio screens in sync with the app-wide sound preference.
class GlobalSoundService {
  GlobalSoundService._();

  static final GlobalSoundService instance = GlobalSoundService._();

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  bool get isEnabled => enabled.value;

  void setEnabled(bool value) {
    if (enabled.value == value) return;
    enabled.value = value;
  }
}
