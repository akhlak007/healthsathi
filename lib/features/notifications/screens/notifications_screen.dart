import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../medicine_reminders/providers/medicine_reminder_provider.dart';
import '../../medicine_reminders/domain/models/medicine_reminder_model.dart';
import '../../medicine_reminders/presentation/screens/add_reminder_screen.dart';
import '../models/app_notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Icons.medication_rounded;
      case NotificationType.appointment:
        return Icons.calendar_month_rounded;
      case NotificationType.vaccination:
        return Icons.vaccines_rounded;
      case NotificationType.login:
        return Icons.security_rounded;
      case NotificationType.upload:
        return Icons.cloud_upload_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return AppColors.secondary;
      case NotificationType.appointment:
        return const Color(0xFF6366F1);
      case NotificationType.vaccination:
        return const Color(0xFF10B981);
      case NotificationType.login:
        return AppColors.primary;
      case NotificationType.upload:
        return const Color(0xFF3B82F6);
      case NotificationType.general:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final notifications = ref.watch(appNotificationProvider);
    final remindersAsync = ref.watch(medicineRemindersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Clinical Notifications',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (notifications.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.onBackground),
                onSelected: (value) {
                  if (value == 'read_all') {
                    ref.read(appNotificationProvider.notifier).markAllAsRead();
                  } else if (value == 'clear_all') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All Notifications'),
                        content: const Text(
                            'Are you sure you want to delete all notifications?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(appNotificationProvider.notifier)
                                  .clearAll();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear all'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Notifications'),
              Tab(text: 'Reminders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationsList(context, ref, notifications, textTheme),
            _buildRemindersTab(context, ref, remindersAsync, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, WidgetRef ref, List<AppNotificationModel> notifications, TextTheme textTheme) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: AppColors.outline.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifications from your reminders,\nlogins and uploads will appear here.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.outline.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notify = notifications[index];
        final icon = _iconForType(notify.type);
        final color = _colorForType(notify.type);

        return Dismissible(
          key: Key(notify.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline,
                color: Colors.red.shade400, size: 24),
          ),
          onDismissed: (_) {
            ref
                .read(appNotificationProvider.notifier)
                .deleteNotification(notify.id);
          },
          child: GestureDetector(
            onTap: () {
              if (!notify.isRead) {
                ref
                    .read(appNotificationProvider.notifier)
                    .markAsRead(notify.id);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: MedicalCard(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.08),
                      radius: 20,
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (!notify.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(
                                            right: 6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        notify.title,
                                        style: TextStyle(
                                          fontWeight: notify.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          fontSize: 13.5,
                                          color: notify.isRead
                                              ? Colors.black54
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeAgo(notify.createdAt),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.outline,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notify.content,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemindersTab(BuildContext context, WidgetRef ref, AsyncValue<List<MedicineReminderModel>> remindersAsync, TextTheme textTheme) {
    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_information_rounded, size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Reminders Yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Add your medicines to get timely reminders and never miss a dose.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Reminder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final activeReminders = reminders.where((r) => r.isActive && r.endDate.isAfter(now)).toList();
        final completedReminders = reminders.where((r) => !r.isActive || r.endDate.isBefore(now)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (activeReminders.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Active Medicines',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
              ),
              ...activeReminders.map((r) => _buildReminderCard(context, ref, r)),
              const SizedBox(height: 24),
            ],
            if (completedReminders.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Completed Medicines',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
              ),
              ...completedReminders.map((r) => _buildReminderCard(context, ref, r)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => Center(child: Text('Error loading reminders: $err')),
    );
  }

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, MedicineReminderModel reminder) {
    final bool isCompleted = !reminder.isActive || reminder.endDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.grey.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    reminder.type.displayName == 'Medicine' ? Icons.medication_rounded : Icons.calendar_month_rounded,
                    color: isCompleted ? Colors.grey : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicineName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey : AppColors.onBackground,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (reminder.dosage.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Dosage: ${reminder.dosage}',
                          style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: reminder.isActive,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(medicineReminderNotifierProvider.notifier).toggleActive(reminder);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reminder.times.join(', '),
                    style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => AddReminderScreen(existingReminder: reminder)),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                      onPressed: () => _confirmDelete(context, ref, reminder),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, MedicineReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete the reminder for ${reminder.medicineName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(medicineReminderNotifierProvider.notifier).deleteReminder(reminder);
    }
  }
}
