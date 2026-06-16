import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification_model.dart';

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

  /// Add a new notification and persist
  Future<void> addNotification(AppNotificationModel notification) async {
    // Avoid duplicate IDs
    if (state.any((n) => n.id == notification.id)) return;
    state = [notification, ...state];
    await _saveToLocal();
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    state = state.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    await _saveToLocal();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _saveToLocal();
  }

  /// Delete a single notification
  Future<void> deleteNotification(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _saveToLocal();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    state = [];
    await _saveToLocal();
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
