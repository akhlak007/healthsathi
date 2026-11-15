import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../../../core/widgets/medical_illustrations.dart';
import '../../../../core/widgets/app_logo_loader.dart';
import '../../profile/providers/active_profile_provider.dart';
import '../../profile/widgets/profile_switcher_bottom_sheet.dart';
import '../../medicine_reminders/domain/models/medicine_reminder_model.dart';
import '../../medicine_reminders/providers/medicine_reminder_provider.dart';
import '../../medicine_reminders/presentation/screens/reminder_center_screen.dart';
import '../../medicine_reminders/services/local_notification_service.dart';
import '../../timeline/providers/timeline_provider.dart';
import '../../notifications/providers/notification_provider.dart';

class TodayDose {
  final MedicineReminderModel reminder;
  final String timeStr;
  final int timeIndex;
  final DateTime dateTime;
  final bool isTaken;

  TodayDose({
    required this.reminder,
    required this.timeStr,
    required this.timeIndex,
    required this.dateTime,
    required this.isTaken,
  });
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'HS';
    if (parts.length == 1) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final activeProfileId = ref.watch(activeProfileProvider);

    if (uid == null) {
      return const Scaffold(body: Center(child: AppLogoLoader(size: 64)));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: activeProfileId == 'self'
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('familyProfiles')
              .doc(activeProfileId)
              .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isSelf = activeProfileId == 'self';

        final name = data?['name'] ?? (isSelf ? 'User' : 'Family Member');
        final bloodGroup = data?['bloodGroup'] ?? 'Not Set';
        final rawAllergies = data?['allergies'];
        final allergies = rawAllergies is List
            ? rawAllergies.join(', ')
            : (rawAllergies?.toString() ?? '');

        final rawImageUrl =
            isSelf ? (data?['profileImage']) : (data?['photoUrl']);
        final hasCustomPhoto = rawImageUrl != null &&
            rawImageUrl != 'default' &&
            !rawImageUrl.contains('ui-avatars.com');

        final initials = _getInitials(name);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          endDrawer: _buildDrawer(
            context: context,
            name: name,
            profileImageUrl: rawImageUrl ?? '',
            hasCustomPhoto: hasCustomPhoto,
            initials: initials,
            bloodGroup: bloodGroup,
            patientId: data != null
                ? (data['patientId'] as String?) ?? 'Generating...'
                : 'Generating...',
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 16,
            toolbarHeight: 68,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => showProfileSwitcher(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF003D9B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: hasCustomPhoto
                        ? ClipOval(
                            child: rawImageUrl.startsWith('data:')
                                ? Image.memory(
                                    base64Decode(
                                        rawImageUrl.split(',').last),
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    rawImageUrl,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                          )
                        : Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'HealthSathi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF003D9B),
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'আপনার স্বাস্থ্য, আপনার হাতে',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount =
                      ref.watch(unreadNotificationCountProvider);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF1E293B),
                          size: 26,
                        ),
                        onPressed: () => context.push('/notifications'),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 13,
                          right: 14,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF1E293B),
                    size: 27,
                  ),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Doctor Hero Illustration with Soft Sky Backdrop
                  Center(
                    child: SizedBox(
                      height: 148,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Organic Soft Blue Backdrop Curve
                          Container(
                            width: 200,
                            height: 138,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCEBFE),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(100),
                                topRight: Radius.circular(100),
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                          ),
                          // Friendly Doctor Character
                          const Positioned(
                            bottom: 0,
                            child: DoctorHeroWidget(
                              width: 140,
                              height: 135,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Rounded Pill Search Bar
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search records, medicines, or doctors',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. "Digitize Your Health Records" Hero Banner
                  Container(
                    height: 165,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withOpacity(0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Background soft decorative orb
                        Positioned(
                          right: -25,
                          top: -25,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Left Text & Upload Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 120, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Digitize Your\nHealth Records',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Upload prescriptions, lab\nreports and keep them safe.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () => context.push('/upload'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Upload Now',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right Document Graphics with Green Upload Badge
                        const Positioned(
                          right: 14,
                          bottom: 14,
                          child: DocumentsIllustrationWidget(size: 96),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Side-by-Side Bento Quick Stats Cards
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Blood Group Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.water_drop_rounded,
                                    color: Color(0xFF1D4ED8),
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Blood Group',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bloodGroup,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF003D9B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Allergies Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F8F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    color: Color(0xFF059669),
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Allergies',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  allergies.isEmpty ? 'None Reported' : allergies,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. "Quick Actions" Section Header & 3x2 Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/timeline'),
                        child: const Text(
                          'View All →',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF003D9B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.02,
                    children: [
                      _buildActionCard(
                        icon: Icons.post_add_rounded,
                        iconColor: const Color(0xFF1D4ED8),
                        bgColor: const Color(0xFFEFF6FF),
                        label: 'Add Record',
                        onTap: () => context.push('/upload'),
                      ),
                      _buildActionCard(
                        icon: Icons.document_scanner_outlined,
                        iconColor: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                        label: 'Scan OCR',
                        onTap: () => context.push('/upload'),
                      ),
                      _buildActionCard(
                        icon: Icons.medication_outlined,
                        iconColor: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                        label: 'My Medicines',
                        onTap: () => context.push('/reminder-center'),
                      ),
                      _buildActionCard(
                        icon: Icons.calendar_month_outlined,
                        iconColor: const Color(0xFF1D4ED8),
                        bgColor: const Color(0xFFEFF6FF),
                        label: 'Timeline',
                        onTap: () => context.go('/timeline'),
                      ),
                      _buildActionCard(
                        icon: Icons.contact_phone_outlined,
                        iconColor: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFFEF2F2),
                        label: 'Emergency\nContacts',
                        onTap: () => context.push('/emergency'),
                      ),
                      _buildActionCard(
                        icon: Icons.share_location_rounded,
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFECFDF5),
                        label: 'Share Location',
                        onTap: () => context.push('/emergency'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 6. Emergency Help Banner
                  GestureDetector(
                    onTap: () => context.push('/emergency'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFECDD3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.airport_shuttle_rounded,
                              color: Color(0xFFE11D48),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Emergency Help',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF9F1239),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Call ambulance or emergency contact',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFFBE123C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF9F1239),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 7. Hospital QR Check-In Banner (Preserved)
                  GestureDetector(
                    onTap: () => context.push('/hospital-checkin'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFA7F3D0),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF006C4B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xFF006C4B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hospital QR Check-In',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Scan reception QR to receive reports directly',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006C4B),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Scan QR',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 8. Today's Medicines Section (Preserved)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Medicines',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ReminderCenterScreen(),
                          ));
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF003D9B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ref.watch(medicineRemindersProvider).when(
                    data: (reminders) {
                      final activeReminders = reminders
                          .where((r) =>
                              r.isActive &&
                              r.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                          .toList();

                      final now = DateTime.now();
                      final todayDoses = <TodayDose>[];

                      for (final reminder in activeReminders) {
                        final todayStart = DateTime(now.year, now.month, now.day);
                        final reminderStart = DateTime(reminder.startDate.year,
                            reminder.startDate.month, reminder.startDate.day);
                        final reminderEnd = DateTime(reminder.endDate.year,
                            reminder.endDate.month, reminder.endDate.day);

                        if (todayStart.isBefore(reminderStart) ||
                            todayStart.isAfter(reminderEnd)) {
                          continue;
                        }

                        for (int i = 0; i < reminder.times.length; i++) {
                          final timeStr = reminder.times[i];
                          final parts = timeStr.split(' ');
                          if (parts.length < 2) continue;
                          final timeParts = parts[0].split(':');
                          if (timeParts.length < 2) continue;
                          var hour = int.parse(timeParts[0]);
                          final minute = int.parse(timeParts[1]);
                          if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
                          if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;

                          final doseDateTime =
                              DateTime(now.year, now.month, now.day, hour, minute);
                          final isTaken = ref
                              .read(medicineTakenStatusProvider.notifier)
                              .isTaken(reminder.id, doseDateTime, timeStr);

                          todayDoses.add(TodayDose(
                            reminder: reminder,
                            timeStr: timeStr,
                            timeIndex: i,
                            dateTime: doseDateTime,
                            isTaken: isTaken,
                          ));
                        }
                      }

                      todayDoses.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                      if (todayDoses.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'No medicines scheduled for today.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontFamily: 'Inter',
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: todayDoses.take(3).map((dose) {
                          final reminder = dose.reminder;
                          final isTaken = dose.isTaken;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isTaken
                                        ? const Color(0xFFD1FAE5)
                                        : const Color(0xFFFFECE5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    reminder.type.name == 'medicine'
                                        ? Icons.medication_rounded
                                        : Icons.calendar_month_rounded,
                                    color: isTaken
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF95B32),
                                    size: 20,
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
                                          fontFamily: 'Inter',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isTaken
                                              ? Colors.grey
                                              : const Color(0xFF1E293B),
                                          decoration: isTaken
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        reminder.dosage.isNotEmpty
                                            ? reminder.dosage
                                            : reminder.instruction,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      dose.timeStr,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        if (!isTaken) {
                                          final uid = FirebaseAuth
                                              .instance.currentUser?.uid;
                                          if (uid != null) {
                                            await ref
                                                .read(medicineTakenStatusProvider
                                                    .notifier)
                                                .markAsTaken(
                                                    reminder.id,
                                                    dose.dateTime,
                                                    dose.timeStr);
                                            await LocalNotificationService()
                                                .cancelEscalations(
                                                    reminder.id,
                                                    dose.timeIndex,
                                                    dose.dateTime);
                                            await LocalNotificationService()
                                                .logNotificationToFirestore(
                                              title: '💊 Medicine Taken',
                                              message:
                                                  'You have marked ${reminder.medicineName} (${reminder.dosage}) as taken.',
                                              type: 'medication',
                                              createdAt: DateTime.now(),
                                              isRead: true,
                                            );
                                          }
                                        } else {
                                          await ref
                                              .read(medicineTakenStatusProvider
                                                  .notifier)
                                              .markAsUntaken(
                                                  reminder.id,
                                                  dose.dateTime,
                                                  dose.timeStr);
                                        }
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isTaken
                                              ? const Color(0xFF10B981)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isTaken
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFCBD5E1),
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: isTaken
                                              ? Colors.white
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: AppLogoLoader(size: 48)),
                    error: (err, stack) =>
                        const Center(child: Text('Error loading reminders')),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF003D9B),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
            onPressed: () => context.push('/ai-chat'),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: const AppBottomNavBar(activeIndex: 0),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer({
    required BuildContext context,
    required String name,
    required String profileImageUrl,
    required bool hasCustomPhoto,
    required String initials,
    required String bloodGroup,
    required String patientId,
  }) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF003D9B),
                    backgroundImage: hasCustomPhoto
                        ? (profileImageUrl.startsWith('data:')
                            ? MemoryImage(base64Decode(
                                    profileImageUrl.split(',').last))
                                as ImageProvider
                            : NetworkImage(profileImageUrl))
                        : null,
                    child: !hasCustomPhoto
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Patient ID: $patientId',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text(
                              'Blood Group: ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF003D9B),
                              ),
                            ),
                            Text(
                              bloodGroup,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF003D9B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildDrawerItem(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Personal Info',
                    onTap: () {
                      context.pop();
                      context.push('/edit-profile');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.group_rounded,
                    title: 'Family Profiles',
                    onTap: () {
                      context.pop();
                      context.push('/family-profiles');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.medical_information_rounded,
                    title: 'Medicine Reminders',
                    onTap: () {
                      context.pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ReminderCenterScreen(),
                      ));
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Hospital Check-In',
                    onTap: () {
                      context.pop();
                      context.push('/hospital-checkin');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      context.pop();
                      context.push('/settings');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003D9B) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF475569),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
