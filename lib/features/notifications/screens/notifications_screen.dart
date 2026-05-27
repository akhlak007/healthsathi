import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    final notifications = [
      {
        'title': 'Daily Medication Reminder',
        'content': 'Time to take Napa Extend 665mg - 1 Tab Post Lunch.',
        'time': '30 mins ago',
        'type': 'medication',
      },
      {
        'title': 'Dengue Outbreak Near Dhanmondi',
        'content': 'Health Advisory: Clean open stagnant water containers inside flower pots. Sleep under mosquito netting.',
        'time': '3 hours ago',
        'type': 'alert',
      },
      {
        'title': 'Secure Login Session Verified',
        'content': 'Successfully scanned biometric fingerprint to unlock secure clinical ledger credentials.',
        'time': '1 day ago',
        'type': 'security',
      }
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinical Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notify = notifications[index];
          IconData icon;
          Color color;
          
          if (notify['type'] == 'medication') {
            icon = Icons.medication_rounded;
            color = AppColors.secondary;
          } else if (notify['type'] == 'alert') {
            icon = Icons.warning_amber_rounded;
            color = AppColors.error;
          } else {
            icon = Icons.security_rounded;
            color = AppColors.primary;
          }

          return Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notify['title']!, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notify['time']!, 
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
                          notify['content']!, 
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
          );
        },
      ),
    );
  }
}
