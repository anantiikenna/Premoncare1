import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _reduceAnimations = false;
  bool _screenReaderHints = true;

  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get reduceAnimations => _reduceAnimations;
  bool get screenReaderHints => _screenReaderHints;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = prefs.getDouble('access_text_scale') ?? 1.0;
    _highContrast = prefs.getBool('access_high_contrast') ?? false;
    _reduceAnimations = prefs.getBool('access_reduce_animations') ?? false;
    _screenReaderHints = prefs.getBool('access_screen_reader') ?? true;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('access_text_scale', value);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('access_high_contrast', value);
    notifyListeners();
  }

  Future<void> setReduceAnimations(bool value) async {
    _reduceAnimations = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('access_reduce_animations', value);
    notifyListeners();
  }

  Future<void> setScreenReaderHints(bool value) async {
    _screenReaderHints = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('access_screen_reader', value);
    notifyListeners();
  }
}
