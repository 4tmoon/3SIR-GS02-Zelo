import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _skipOnboardingKey = 'skip_onboarding';

  Future<bool> shouldSkipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipOnboardingKey) ?? false;
  }

  Future<void> saveSkipOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipOnboardingKey, value);
  }
}
