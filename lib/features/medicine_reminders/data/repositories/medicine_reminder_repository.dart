import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/medicine_reminder_model.dart';
import '../../services/local_notification_service.dart';

class MedicineReminderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalNotificationService _notificationService = LocalNotificationService();
  static const String _localPrefsKey = 'medicine_reminders_local';

  /// Syncs all reminders from Firestore to local storage for offline access
  /// and schedules all active reminders.
  Future<void> syncRemindersToLocal(String userId, String activeProfileId, String profileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_uid', userId);
      final querySnapshot = await _getCollectionRef(userId, activeProfileId).get();
      final reminders = querySnapshot.docs
          .map((doc) => MedicineReminderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      await _saveRemindersLocally(userId, activeProfileId, reminders);
      
      // Reschedule active ones
      await _notificationService.cancelAll();
      for (final reminder in reminders) {
        if (reminder.isActive) {
          await _notificationService.scheduleMedicineReminder(
            reminder: reminder,
            profileName: profileName,
          );
        }
      }
    } catch (e) {
      // If offline, just rely on local
    }
  }

  Future<List<MedicineReminderModel>> getReminders(String userId, String activeProfileId) async {
    try {
      final snapshot = await _getCollectionRef(userId, activeProfileId).get();
      final reminders = snapshot.docs
          .map((doc) => MedicineReminderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      await _saveRemindersLocally(userId, activeProfileId, reminders);
      return reminders;
    } catch (_) {
      // Fallback to local
      return _getLocalReminders(userId, activeProfileId);
    }
  }

  Stream<List<MedicineReminderModel>> watchReminders(
      String userId, String activeProfileId) async* {
    final localReminders = await _getLocalReminders(userId, activeProfileId);
    if (localReminders.isNotEmpty) {
      yield localReminders;
    }

    try {
      await for (final snapshot
          in _getCollectionRef(userId, activeProfileId).snapshots()) {
        final reminders = snapshot.docs
            .map((doc) =>
                MedicineReminderModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        await _saveRemindersLocally(userId, activeProfileId, reminders);
        yield reminders;
      }
    } catch (_) {
      yield await _getLocalReminders(userId, activeProfileId);
    }
  }

  Future<void> addReminder(String userId, String activeProfileId, String profileName, MedicineReminderModel reminder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', userId);
    
    // Update local immediately
    final local = await _getLocalReminders(userId, activeProfileId);
    local.removeWhere((r) => r.id == reminder.id);
    local.add(reminder);
    await _saveRemindersLocally(userId, activeProfileId, local);

    try {
      await _getCollectionRef(userId, activeProfileId).doc(reminder.id).set(reminder.toMap());
    } catch (_) {
      // Keep the local reminder visible and scheduled even when Firestore sync is blocked.
    }

    if (reminder.isActive) {
      await _notificationService.scheduleMedicineReminder(reminder: reminder, profileName: profileName);
    }
  }

  Future<void> updateReminder(String userId, String activeProfileId, String profileName, MedicineReminderModel reminder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', userId);
    
    // Update local
    final local = await _getLocalReminders(userId, activeProfileId);
    final index = local.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      local[index] = reminder;
    } else {
      local.add(reminder);
    }
    await _saveRemindersLocally(userId, activeProfileId, local);

    try {
      await _getCollectionRef(userId, activeProfileId).doc(reminder.id).update(reminder.toMap());
    } catch (_) {
      // Keep local edits visible and scheduled even when Firestore sync is blocked.
    }

    await _notificationService.cancelReminder(reminder);
    if (reminder.isActive) {
      await _notificationService.scheduleMedicineReminder(reminder: reminder, profileName: profileName);
    }
  }

  Future<void> deleteReminder(String userId, String activeProfileId, MedicineReminderModel reminder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', userId);
    
    final local = await _getLocalReminders(userId, activeProfileId);
    local.removeWhere((r) => r.id == reminder.id);
    await _saveRemindersLocally(userId, activeProfileId, local);

    try {
      await _getCollectionRef(userId, activeProfileId).doc(reminder.id).delete();
    } catch (_) {
      // Keep local deletion applied even when Firestore sync is blocked.
    }

    await _notificationService.cancelReminder(reminder);
  }

  CollectionReference _getCollectionRef(String userId, String activeProfileId) {
    // If activeProfileId is 'self', use 'self' as document ID in familyProfiles
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('familyProfiles')
        .doc(activeProfileId)
        .collection('reminders');
  }

  String _scopedLocalPrefsKey(String userId, String profileId) {
    return '${_localPrefsKey}_${userId}_$profileId';
  }

  Future<void> _saveRemindersLocally(
      String userId, String profileId, List<MedicineReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    await prefs.setStringList(_scopedLocalPrefsKey(userId, profileId), jsonList);
  }

  Future<List<MedicineReminderModel>> _getLocalReminders(
      String userId, String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = _scopedLocalPrefsKey(userId, profileId);
    final jsonList = prefs.getStringList(scopedKey) ?? [];
    return jsonList.map((jsonStr) => MedicineReminderModel.fromJson(jsonStr)).toList();
  }

  Future<void> rescheduleRemindersLocally(List<MedicineReminderModel> reminders, String profileName) async {
    await _notificationService.cancelAll();
    for (final reminder in reminders) {
      if (reminder.isActive) {
        await _notificationService.scheduleMedicineReminder(
          reminder: reminder,
          profileName: profileName,
        );
      }
    }
  }

  /// Called on device reboot to restore alarms for all profiles from local storage
  Future<void> restoreAllRemindersOnReboot() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_uid');
    if (userId == null || userId.isEmpty) return;

    final keyPrefix = '${_localPrefsKey}_${userId}_';
    final keys = prefs.getKeys().where((k) => k.startsWith(keyPrefix));
    
    for (final key in keys) {
      final jsonList = prefs.getStringList(key) ?? [];
      final profileId = key.replaceFirst(keyPrefix, '');
      
      for (final jsonStr in jsonList) {
        final reminder = MedicineReminderModel.fromJson(jsonStr);
        if (reminder.isActive) {
          // Profile name might be tricky without a full lookup, but we can default to 'Profile'
          // or ideally store the profile name alongside local reminders if needed.
          // For now, we use a generic string or extract it if stored.
          final profileName = profileId == 'self' ? 'Self' : 'Family Member';
          await _notificationService.scheduleMedicineReminder(reminder: reminder, profileName: profileName);
        }
      }
    }
  }
}
