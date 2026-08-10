import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/state/app_state.dart';
import '../../../core/services/review_prompt_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/personalized_onboarding_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _showOnboardingTrackCard = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _requestingReview = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.appState.emergencyContactName;
    _phoneController.text = widget.appState.emergencyContactPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in contact name and phone number.'),
        ),
      );
      return;
    }

    widget.appState.saveEmergencyContact(name, phone);
    if (widget.appState.hapticEnabled) {
      HapticFeedback.vibrate();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency contact updated.'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Future<void> _confirmTherapistCall() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number first.')),
      );
      return;
    }

    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2435),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            'Call your therapist now?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            phoneNumber,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (shouldCall != true || !mounted) return;

    final callUri = Uri(scheme: 'tel', path: phoneNumber);
    final launched = await launchUrl(
      callUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the phone app for this number.'),
        ),
      );
    }
  }

  Future<void> _selectOnboardingTrack(OnboardingTrack track) async {
    await widget.appState.setOnboardingTrack(track);
    if (mounted) setState(() {});
  }

  void _previewSelectedOnboarding() {
    final isPersonalized =
        widget.appState.onboardingTrack == OnboardingTrack.personalized;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isPersonalized
            ? PersonalizedOnboardingScreen(
                appState: widget.appState,
                isPreview: true,
                onAcceptTerms: () async {},
                onComplete: () async {},
              )
            : OnboardingScreen(
                onAcceptTerms: () async {},
                onNameSubmitted: (_) async {},
                onComplete: () async {
                  if (mounted) Navigator.of(context).pop();
                },
              ),
      ),
    );
  }

  Future<void> _rateApp() async {
    if (_requestingReview) return;
    setState(() => _requestingReview = true);

    final opened = await ReviewPromptService.instance.requestFromSettings();
    if (!mounted) return;
    setState(() => _requestingReview = false);

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating is not available on this device right now.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visual Theme',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildThemeButton(0, 'Forest', primaryColor),
                        const SizedBox(width: 8),
                        _buildThemeButton(1, 'Lavendel', primaryColor),
                        const SizedBox(width: 8),
                        _buildThemeButton(2, 'Dark', primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile.adaptive(
                  value: widget.appState.soundEnabled,
                  onChanged: (enabled) async {
                    await widget.appState.setSoundEnabled(enabled);
                    if (mounted) setState(() {});
                  },
                  secondary: Icon(
                    widget.appState.soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: primaryColor,
                  ),
                  title: const Text(
                    'Sound',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    widget.appState.soundEnabled
                        ? 'On — sounds throughout the app are unmuted'
                        : 'Off — all sounds throughout the app are muted',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Emergency Contact Setup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.phone_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                          onPressed: _confirmTherapistCall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Contact Name',
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Save contact details'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Divider(
                color: isDark ? Colors.white.withAlpha(20) : Colors.black12,
                thickness: 1,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: _requestingReview ? null : _rateApp,
                  icon: _requestingReview
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.star_rate_rounded),
                  label: const Text('Rate this app'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('About this app'),
                ),
              ),
              const SizedBox(height: 20),
              if (_showOnboardingTrackCard) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Onboarding track',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose which onboarding new users see on this device.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildOnboardingTrackButton(
                            OnboardingTrack.classic,
                            'Classic',
                            primaryColor,
                          ),
                          const SizedBox(width: 8),
                          _buildOnboardingTrackButton(
                            OnboardingTrack.personalized,
                            'Personalized',
                            primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _previewSelectedOnboarding,
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Preview selected onboarding'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(int index, String label, Color primary) {
    final isSelected = widget.appState.themeModeIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.appState.setThemeModeIndex(index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primary
                : (isDark
                      ? Colors.white.withAlpha(10)
                      : Colors.white.withAlpha(204)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primary
                  : (isDark
                        ? Colors.white.withAlpha(13)
                        : Colors.black.withAlpha(13)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingTrackButton(
    OnboardingTrack track,
    String label,
    Color primary,
  ) {
    final isSelected = widget.appState.onboardingTrack == track;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _selectOnboardingTrack(track),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primary
                : isDark
                ? Colors.white.withAlpha(10)
                : Colors.white.withAlpha(204),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primary : Colors.black12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.white70
                  : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
