import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveProfileNotifier extends StateNotifier<String> {
  static const _key = 'active_profile_id';

  ActiveProfileNotifier() : super('self') {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProfile = prefs.getString(_key);
    if (savedProfile != null && savedProfile.isNotEmpty) {
      state = savedProfile;
    }
  }

  Future<void> setActiveProfile(String profileId) async {
    state = profileId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profileId);
  }

  String getActiveProfile() {
    return state;
  }
}

final activeProfileProvider = StateNotifierProvider<ActiveProfileNotifier, String>((ref) {
  return ActiveProfileNotifier();
});
