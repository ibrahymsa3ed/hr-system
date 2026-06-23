import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the selected app locale (en|ar) and persists it. Switching to Arabic
/// flips the whole UI to RTL automatically via MaterialApp's locale.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  static const _key = 'app_locale';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) _locale = Locale(code);
    notifyListeners();
  }

  Future<void> toggle() async {
    _locale = _locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _locale.languageCode);
    notifyListeners();
  }
}
