import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/services/global_sound_service.dart';
import 'package:gwen/core/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sound defaults off and persists the global setting', () async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();

    expect(appState.soundEnabled, isFalse);
    expect(GlobalSoundService.instance.isEnabled, isFalse);

    await appState.setSoundEnabled(true);

    expect(appState.soundEnabled, isTrue);
    expect(GlobalSoundService.instance.isEnabled, isTrue);

    final restoredState = AppState();
    await restoredState.init();
    expect(restoredState.soundEnabled, isTrue);
  });
}
