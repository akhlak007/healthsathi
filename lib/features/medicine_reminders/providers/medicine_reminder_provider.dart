import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/language_provider.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/active_profile_provider.dart';
import '../data/repositories/medicine_reminder_repository.dart';
import '../domain/models/medicine_reminder_model.dart';

final medicineReminderRepositoryProvider = Provider((ref) => MedicineReminderRepository());

final activeProfileNameProvider = Provider<String>((ref) {
  // In a real scenario, we might want to fetch the actual name from a profile object.
  // Since we only have the ID here, we use a placeholder or check if it's 'self'.
  // Assuming the user's name is handled elsewhere, we'll provide a basic string.
  final activeProfileId = ref.watch(activeProfileProvider);
  return activeProfileId == 'self' ? 'Self' : 'Family Member'; // Ideally, fetch from a profile map
});

final medicineRemindersProvider = StreamProvider<List<MedicineReminderModel>>((ref) {
  final activeProfileId = ref.watch(activeProfileProvider);
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final uid = authUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
  
  if (uid == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(medicineReminderRepositoryProvider);
  final profileName = ref.watch(activeProfileNameProvider);
  
  // Trigger initial sync and scheduling
  repository.syncRemindersToLocal(uid, activeProfileId, profileName);
  
  return repository.watchReminders(uid, activeProfileId);
});

class MedicineReminderNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MedicineReminderNotifier(this._ref) : super(const AsyncData(null));

  MedicineReminderRepository get _repository => _ref.read(medicineReminderRepositoryProvider);
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _activeProfileId => _ref.read(activeProfileProvider);
  String get _profileName => _ref.read(activeProfileNameProvider);

  Future<void> addReminder(MedicineReminderModel reminder) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.addReminder(_uid!, _activeProfileId, _profileName, reminder);
      _ref.invalidate(medicineRemindersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateReminder(MedicineReminderModel reminder) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.updateReminder(_uid!, _activeProfileId, _profileName, reminder);
      _ref.invalidate(medicineRemindersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteReminder(MedicineReminderModel reminder) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.deleteReminder(_uid!, _activeProfileId, reminder);
      _ref.invalidate(medicineRemindersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleActive(MedicineReminderModel reminder) async {
    final updated = reminder.copyWith(isActive: !reminder.isActive);
    await updateReminder(updated);
  }
}

final medicineReminderNotifierProvider = StateNotifierProvider<MedicineReminderNotifier, AsyncValue<void>>((ref) {
  return MedicineReminderNotifier(ref);
});

class NotificationSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationSettings({
    required this.soundEnabled,
    required this.vibrationEnabled,
  });
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final SharedPreferences _prefs;
  final Ref _ref;

  NotificationSettingsNotifier(this._prefs, this._ref)
      : super(NotificationSettings(
          soundEnabled: _prefs.getBool('reminder_sound_enabled') ?? true,
          vibrationEnabled: _prefs.getBool('reminder_vibration_enabled') ?? true,
        ));

  Future<void> toggleSound(bool enabled) async {
    await _prefs.setBool('reminder_sound_enabled', enabled);
    state = NotificationSettings(
      soundEnabled: enabled,
      vibrationEnabled: state.vibrationEnabled,
    );
    await _reschedule();
  }

  Future<void> toggleVibration(bool enabled) async {
    await _prefs.setBool('reminder_vibration_enabled', enabled);
    state = NotificationSettings(
      soundEnabled: state.soundEnabled,
      vibrationEnabled: enabled,
    );
    await _reschedule();
  }

  Future<void> _reschedule() async {
    final remindersAsync = _ref.read(medicineRemindersProvider);
    remindersAsync.whenData((reminders) async {
      final repository = _ref.read(medicineReminderRepositoryProvider);
      final profileName = _ref.read(activeProfileNameProvider);
      await repository.rescheduleRemindersLocally(reminders, profileName);
    });
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationSettingsNotifier(prefs, ref);
});

class MedicineTakenStatusNotifier extends StateNotifier<Map<String, bool>> {
  final SharedPreferences _prefs;

  MedicineTakenStatusNotifier(this._prefs) : super({});

  String _getKey(String reminderId, DateTime date, String timeStr) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return 'med_taken_${reminderId}_${dateStr}_$timeStr';
  }

  bool isTaken(String reminderId, DateTime date, String timeStr) {
    final key = _getKey(reminderId, date, timeStr);
    if (state.containsKey(key)) {
      return state[key]!;
    }
    final val = _prefs.getBool(key) ?? false;
    // Defer state update to avoid modifying provider during widget build.
    Future.microtask(() {
      if (mounted && !state.containsKey(key)) {
        state = {...state, key: val};
      }
    });
    return val;
  }

  Future<void> markAsTaken(String reminderId, DateTime date, String timeStr) async {
    final key = _getKey(reminderId, date, timeStr);
    await _prefs.setBool(key, true);
    state = {...state, key: true};
  }

  Future<void> markAsUntaken(String reminderId, DateTime date, String timeStr) async {
    final key = _getKey(reminderId, date, timeStr);
    await _prefs.setBool(key, false);
    state = {...state, key: false};
  }
}

final medicineTakenStatusProvider =
    StateNotifierProvider<MedicineTakenStatusNotifier, Map<String, bool>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MedicineTakenStatusNotifier(prefs);
});
