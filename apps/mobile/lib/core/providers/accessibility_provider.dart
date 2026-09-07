import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _reduceAnimations = false;
  bool _screenReaderHints = true;
  SharedPreferences? _prefs;

  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get reduceAnimations => _reduceAnimations;
  bool get screenReaderHints => _screenReaderHints;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _textScale = _prefs!.getDouble('access_text_scale') ?? 1.0;
    _highContrast = _prefs!.getBool('access_high_contrast') ?? false;
    _reduceAnimations = _prefs!.getBool('access_reduce_animations') ?? false;
    _screenReaderHints = _prefs!.getBool('access_screen_reader') ?? true;
    try { notifyListeners(); } catch (_) {}
  }

  Future<void> setTextScale(double value) async {
    _textScale = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setDouble('access_text_scale', value);
    try { notifyListeners(); } catch (_) {}
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('access_high_contrast', value);
    try { notifyListeners(); } catch (_) {}
  }

  Future<void> setReduceAnimations(bool value) async {
    _reduceAnimations = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('access_reduce_animations', value);
    try { notifyListeners(); } catch (_) {}
  }

  Future<void> setScreenReaderHints(bool value) async {
    _screenReaderHints = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('access_screen_reader', value);
    try { notifyListeners(); } catch (_) {}
  }
}
