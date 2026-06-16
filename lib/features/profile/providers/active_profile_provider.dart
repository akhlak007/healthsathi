import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;

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

final activeProfileNameProvider = FutureProvider<String>((ref) async {
  final activeProfileId = ref.watch(activeProfileProvider);
  final user = firebase_auth.FirebaseAuth.instance.currentUser;
  if (user == null) return 'Self';
  try {
    final doc = activeProfileId == 'self'
        ? await cloud_firestore.FirebaseFirestore.instance.collection('users').doc(user.uid).get()
        : await cloud_firestore.FirebaseFirestore.instance.collection('users').doc(user.uid).collection('familyProfiles').doc(activeProfileId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        return data['name'] ?? data['fullName'] ?? (activeProfileId == 'self' ? 'Self' : 'Family Member');
      }
    }
  } catch (e) {
    print('Error loading active profile name: $e');
  }
  return activeProfileId == 'self' ? 'Self' : 'Family Member';
});

