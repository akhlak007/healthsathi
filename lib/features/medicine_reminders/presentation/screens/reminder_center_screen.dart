import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/medicine_reminder_provider.dart';
import '../../domain/models/medicine_reminder_model.dart';
import 'add_reminder_screen.dart';

class ReminderCenterScreen extends ConsumerWidget {
  const ReminderCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(medicineRemindersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medicine Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddReminderScreen()),
              );
            },
          )
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return _buildEmptyState(context);
          }
          
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final activeReminders = reminders.where((r) {
            final endDate = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
            return r.isActive && !endDate.isBefore(today);
          }).toList();
          final completedReminders = reminders.where((r) {
            final endDate = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
            return !r.isActive || endDate.isBefore(today);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeReminders.isNotEmpty) ...[
                const Text(
                  'Active Medicines',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 12),
                ...activeReminders.map((r) => _buildReminderCard(context, ref, r)),
                const SizedBox(height: 24),
              ],
              
              if (completedReminders.isNotEmpty) ...[
                const Text(
                  'Completed Medicines',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 12),
                ...completedReminders.map((r) => _buildReminderCard(context, ref, r)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, MedicineReminderModel reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(reminder.endDate.year, reminder.endDate.month, reminder.endDate.day);
    final bool isCompleted = !reminder.isActive || endDate.isBefore(today);
    
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
