import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsProvider extends ChangeNotifier {
  final PreferencesService _preferencesService;

  bool _onboardingSeen = false;
  double _animationSpeed = 2.0;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _isLoaded = false;

  SettingsProvider({required PreferencesService preferencesService})
      : _preferencesService = preferencesService;

  bool get onboardingSeen => _onboardingSeen;
  double get animationSpeed => _animationSpeed;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  bool get isLoaded => _isLoaded;

  Future<void> loadSettings() async {
    _onboardingSeen = await _preferencesService.isOnboardingSeen();
    _animationSpeed = await _preferencesService.getAnimationSpeed();
    _notificationsEnabled = await _preferencesService.isNotificationsEnabled();
    _darkMode = await _preferencesService.isDarkMode();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setOnboardingSeen(bool value) async {
    _onboardingSeen = value;
    await _preferencesService.setOnboardingSeen(value);
    notifyListeners();
  }

  Future<void> setAnimationSpeed(double value) async {
    _animationSpeed = value;
    await _preferencesService.setAnimationSpeed(value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _preferencesService.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _preferencesService.setDarkMode(value);
    notifyListeners();
  }
}
