import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification_model.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../medicine_reminders/services/local_notification_service.dart';

const String _notificationsKey = 'app_notifications_list';

class AppNotificationNotifier extends StateNotifier<List<AppNotificationModel>> {
  AppNotificationNotifier() : super([]) {
    _loadFromLocal();
  }

  /// Load saved notifications from SharedPreferences
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_notificationsKey) ?? [];
    final notifications = jsonList
        .map((jsonStr) => AppNotificationModel.fromJson(jsonStr))
        .toList();
    // Sort newest first
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = notifications;
  }

  /// Persist current state to SharedPreferences
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((n) => n.toJson()).toList();
    await prefs.setStringList(_notificationsKey, jsonList);
  }

  /// Add a new notification and persist (or update if already exists)
  Future<void> addNotification(AppNotificationModel notification) async {
    final existingIndex = state.indexWhere((n) => n.id == notification.id);
    if (existingIndex >= 0) {
      if (state[existingIndex].isRead != notification.isRead) {
        final updatedList = List<AppNotificationModel>.from(state);
        updatedList[existingIndex] = notification;
        state = updatedList;
        await _saveToLocal();
      }
      return;
    }
    state = [notification, ...state];
    await _saveToLocal();
  }

  /// Mark a single notification as read (locally and in Firestore if userId provided)
  Future<void> markAsRead(String id, [String? userId]) async {
    state = state.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    await _saveToLocal();

    if (userId != null && userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(id)
            .update({'isRead': true});
      } catch (_) {}
    }
  }

  /// Mark all notifications as read (locally and in Firestore if userId provided)
  Future<void> markAllAsRead([String? userId]) async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _saveToLocal();

    if (userId != null && userId.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String id, [String? userId]) async {
    state = state.where((n) => n.id != id).toList();
    await _saveToLocal();

    if (userId != null && userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }

  /// Clear all notifications
  Future<void> clearAll([String? userId]) async {
    state = [];
    await _saveToLocal();

    if (userId != null && userId.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .get();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  /// Get unread count
  int get unreadCount => state.where((n) => !n.isRead).length;
}

final appNotificationProvider =
    StateNotifierProvider<AppNotificationNotifier, List<AppNotificationModel>>(
  (ref) => AppNotificationNotifier(),
);

/// Convenience provider for unread count (used for badges)
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(appNotificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

/// Real-time stream synchronization from Firestore 'users/{uid}/notifications'
/// into the local AppNotificationNotifier state, with push alerts via LocalNotificationService.
final notificationSyncProvider = Provider<void>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return;

  final notifier = ref.read(appNotificationProvider.notifier);

  final subscription = FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .listen((snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added ||
          change.type == DocumentChangeType.modified) {
        final data = change.doc.data();
        if (data == null) continue;

        final notification = AppNotificationModel.fromMap(data, change.doc.id);
        await notifier.addNotification(notification);

        // If newly added, unread, and not yet alerted:
        if (change.type == DocumentChangeType.added && !notification.isRead) {
          final prefs = await SharedPreferences.getInstance();
          final alertedKey = 'alerted_notif_${notification.id}';
          final alreadyAlerted = prefs.getBool(alertedKey) ?? false;

          if (!alreadyAlerted) {
            await prefs.setBool(alertedKey, true);
            await LocalNotificationService().showNotification(
              id: notification.id.hashCode.abs() % 100000,
              title: notification.title,
              body: notification.content,
              payload: '/notifications',
            );
          }
        }
      } else if (change.type == DocumentChangeType.removed) {
        await notifier.deleteNotification(change.doc.id);
      }
    }
  }, onError: (_) {
    // Fail silently in stream listener
  });

  ref.onDispose(() {
    subscription.cancel();
  });
});
