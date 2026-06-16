import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification_model.dart';
import '../providers/notification_provider.dart';
import '../../medicine_reminders/domain/models/medicine_reminder_model.dart';

/// A utility class to push real in-app notifications from various app events.
/// Call these methods wherever relevant events occur (reminder added, login, upload, etc.)
class NotificationHelper {
  /// Generate a notification when a medicine reminder is created
  static void onReminderAdded(WidgetRef ref, MedicineReminderModel reminder) {
    final notification = AppNotificationModel(
      id: 'reminder_added_${reminder.id}',
      title: 'Reminder Set: ${reminder.medicineName}',
      content:
          '${reminder.dosage} • ${reminder.instruction}\nScheduled at: ${reminder.times.join(", ")}',
      type: NotificationType.medication,
      createdAt: DateTime.now(),
    );
    ref.read(appNotificationProvider.notifier).addNotification(notification);
  }

  /// Generate a notification when a medicine reminder fires (is due now)
  static void onReminderDue(WidgetRef ref, MedicineReminderModel reminder) {
    final notification = AppNotificationModel(
      id: 'reminder_due_${reminder.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Medication Due: ${reminder.medicineName}',
      content:
          'Time to take ${reminder.medicineName} – ${reminder.dosage}.\n${reminder.instruction}',
      type: NotificationType.medication,
      createdAt: DateTime.now(),
    );
    ref.read(appNotificationProvider.notifier).addNotification(notification);
  }

  /// Generate a notification when user successfully logs in
  static void onLoginSuccess(WidgetRef ref, {String method = 'Email'}) {
    final notification = AppNotificationModel(
      id: 'login_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Login Session Verified',
      content:
          'Successfully authenticated via $method. Your secure health ledger is now accessible.',
      type: NotificationType.login,
      createdAt: DateTime.now(),
    );
    ref.read(appNotificationProvider.notifier).addNotification(notification);
  }

  /// Generate a notification when a document/record is uploaded
  static void onDocumentUploaded(WidgetRef ref, String documentName) {
    final notification = AppNotificationModel(
      id: 'upload_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Document Uploaded',
      content: '"$documentName" has been securely uploaded to your health records.',
      type: NotificationType.upload,
      createdAt: DateTime.now(),
    );
    ref.read(appNotificationProvider.notifier).addNotification(notification);
  }

  /// Generate a notification for appointment reminders
  static void onAppointmentReminder(
      WidgetRef ref, MedicineReminderModel reminder) {
    final notification = AppNotificationModel(
      id: 'appointment_${reminder.id}',
      title: 'Upcoming Appointment',
      content:
          '${reminder.medicineName}\n${reminder.instruction}\nScheduled: ${reminder.times.join(", ")}',
      type: NotificationType.appointment,
      createdAt: DateTime.now(),
    );
    ref.read(appNotificationProvider.notifier).addNotification(notification);
  }

  /// Generate a notification for vaccination reminders
  static void onVaccinationReminder(
      WidgetRef ref, MedicineReminderModel reminder) {
    final notification = AppNotificationModel(
      id: 'vaccination_${reminder.id}',
      title: 'Vaccination Reminder',
      content:
          '${reminder.medicineName} – ${reminder.dosage}\n${reminder.instruction}',
      type: NotificationType.vaccination,
      createdAt: DateTime.now(),
    );
    ref.read(appNotificationProvider.notifier).addNotification(notification);
  }

  /// Generate a general-purpose notification
  static void pushGeneral(WidgetRef ref, String title, String content) {
    final notification = AppNotificationModel(
      id: 'general_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      type: NotificationType.general,
      createdAt: DateTime.now(),
    );
    ref.read(appNotificationProvider.notifier).addNotification(notification);
  }
}
