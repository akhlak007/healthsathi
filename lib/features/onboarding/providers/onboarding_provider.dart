import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/language_provider.dart';

// ── Page index (unchanged) ──────────────────────────────────────────────────
final onboardingPageProvider = StateProvider<int>((ref) => 0);

// ── Onboarding completed flag ───────────────────────────────────────────────
const _kOnboardingCompletedKey = 'onboarding_completed';

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs)
      : super(_prefs.getBool(_kOnboardingCompletedKey) ?? false);

  /// Call this when the user taps "Get Started" on the last page.
  Future<void> markCompleted() async {
    await _prefs.setBool(_kOnboardingCompletedKey, true);
    state = true;
  }

  /// Convenience getter used by SplashScreen.
  bool get isCompleted => state;
}

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});
