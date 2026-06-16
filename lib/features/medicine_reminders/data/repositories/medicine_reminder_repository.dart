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

      await _saveRemindersLocally(activeProfileId, reminders);
      
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
      await _saveRemindersLocally(activeProfileId, reminders);
      return reminders;
    } catch (_) {
      // Fallback to local
      return _getLocalReminders(activeProfileId);
    }
  }

  Stream<List<MedicineReminderModel>> watchReminders(String userId, String activeProfileId) {
    return _getCollectionRef(userId, activeProfileId).snapshots().map((snapshot) {
      final reminders = snapshot.docs
          .map((doc) => MedicineReminderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      _saveRemindersLocally(activeProfileId, reminders);
      return reminders;
    });
  }

  Future<void> addReminder(String userId, String activeProfileId, String profileName, MedicineReminderModel reminder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', userId);
    await _getCollectionRef(userId, activeProfileId).doc(reminder.id).set(reminder.toMap());
    
    // Update local immediately
    final local = await _getLocalReminders(activeProfileId);
    local.add(reminder);
    await _saveRemindersLocally(activeProfileId, local);

    if (reminder.isActive) {
      await _notificationService.scheduleMedicineReminder(reminder: reminder, profileName: profileName);
    }
  }

  Future<void> updateReminder(String userId, String activeProfileId, String profileName, MedicineReminderModel reminder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', userId);
    await _getCollectionRef(userId, activeProfileId).doc(reminder.id).update(reminder.toMap());
    
    // Update local
    final local = await _getLocalReminders(activeProfileId);
    final index = local.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      local[index] = reminder;
      await _saveRemindersLocally(activeProfileId, local);
    }

    await _notificationService.cancelReminder(reminder);
    if (reminder.isActive) {
      await _notificationService.scheduleMedicineReminder(reminder: reminder, profileName: profileName);
    }
  }

  Future<void> deleteReminder(String userId, String activeProfileId, MedicineReminderModel reminder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_uid', userId);
    await _getCollectionRef(userId, activeProfileId).doc(reminder.id).delete();
    
    final local = await _getLocalReminders(activeProfileId);
    local.removeWhere((r) => r.id == reminder.id);
    await _saveRemindersLocally(activeProfileId, local);

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

  Future<void> _saveRemindersLocally(String profileId, List<MedicineReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    await prefs.setStringList('${_localPrefsKey}_$profileId', jsonList);
  }

  Future<List<MedicineReminderModel>> _getLocalReminders(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('${_localPrefsKey}_$profileId') ?? [];
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
    final keys = prefs.getKeys().where((k) => k.startsWith(_localPrefsKey));
    
    for (final key in keys) {
      final jsonList = prefs.getStringList(key) ?? [];
      final profileId = key.replaceAll('${_localPrefsKey}_', '');
      
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
