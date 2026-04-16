import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

/// Wrapper around SharedPreferences for persisting app settings.
class PreferencesService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Onboarding
  Future<bool> isOnboardingSeen() async {
    final p = await prefs;
    return p.getBool(AppConstants.prefOnboardingSeen) ?? false;
  }

  Future<void> setOnboardingSeen(bool value) async {
    final p = await prefs;
    await p.setBool(AppConstants.prefOnboardingSeen, value);
  }

  // Animation Speed
  Future<double> getAnimationSpeed() async {
    final p = await prefs;
    return p.getDouble(AppConstants.prefAnimationSpeed) ??
        AppConstants.defaultAnimationSpeed;
  }

  Future<void> setAnimationSpeed(double value) async {
    final p = await prefs;
    await p.setDouble(AppConstants.prefAnimationSpeed, value);
  }

  // Notifications
  Future<bool> isNotificationsEnabled() async {
    final p = await prefs;
    return p.getBool(AppConstants.prefNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final p = await prefs;
    await p.setBool(AppConstants.prefNotificationsEnabled, value);
  }

  // Dark Mode
  Future<bool> isDarkMode() async {
    final p = await prefs;
    return p.getBool(AppConstants.prefDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await prefs;
    await p.setBool(AppConstants.prefDarkMode, value);
  }
}
