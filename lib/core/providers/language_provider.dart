import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class LanguageNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  static const _languageKey = 'selected_language';

  LanguageNotifier(this._prefs) : super(const Locale('en')) {
    _loadLanguage();
  }

  void _loadLanguage() {
    final langCode = _prefs.getString(_languageKey);
    if (langCode != null) {
      state = Locale(langCode);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    await _prefs.setString(_languageKey, languageCode);
    state = Locale(languageCode);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});
