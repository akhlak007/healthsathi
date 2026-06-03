import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../emergency/screens/emergency_screen.dart';
import '../../profile/providers/active_profile_provider.dart';
import '../../profile/widgets/profile_switcher_bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final activeProfileId = ref.watch(activeProfileProvider);
    
    if (uid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot>(
      stream: activeProfileId == 'self' 
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : FirebaseFirestore.instance.collection('users').doc(uid).collection('familyProfiles').doc(activeProfileId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isSelf = activeProfileId == 'self';

        final name = data?['name'] ?? (isSelf ? 'User' : 'Family Member');
        final emailOrRelation = isSelf ? (data?['email'] ?? '') : (data?['relationship'] ?? 'Family Member');
        final bloodGroup = data?['bloodGroup'] ?? 'Not Set';
        final bioOrBlood = isSelf ? (data?['bio'] ?? '') : 'Blood Group: $bloodGroup';
        final rawAllergies = data?['allergies'];
        final allergies = rawAllergies is List ? rawAllergies.join(', ') : (rawAllergies?.toString() ?? '');
        
        final rawImageUrl = isSelf ? (data?['profileImage']) : (data?['photoUrl']);
        final profileImageUrl = rawImageUrl == 'default' || rawImageUrl == null
            ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=003D9B&color=fff'
            : rawImageUrl;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          endDrawer: _buildDrawer(
            context: context,
            name: name,
            profileImageUrl: profileImageUrl,
            bloodGroup: bloodGroup,
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 20,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => showProfileSwitcher(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: profileImageUrl.startsWith('data:')
                            ? MemoryImage(base64Decode(profileImageUrl.split(',').last)) as ImageProvider
                            : NetworkImage(profileImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'e HealthSathi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF003D9B),
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF334155),
                  size: 26,
                ),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF334155),
                    size: 28,
                  ),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: const Color(0xFFEFF2FE),
                height: 1.0,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // 1. Header Display Typography
                  Text(
                    'Salam, $name',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emailOrRelation,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF003D9B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (bioOrBlood.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bioOrBlood,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Your health journey is looking stable today.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 2. Pill Search Field
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FE),
                      borderRadius: BorderRadius.circular(27),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            onChanged: (val) {},
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.5,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search records, meds, or doctors...',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF94A3B8),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Side-by-Side Bento Quick Stats Cards
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Blood Group Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            constraints: const BoxConstraints(minHeight: 154),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5EDFF),
                              borderRadius: BorderRadius.circular(24),
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
                                    color: Color(0xFF1E3A8A),
                                    size: 16,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'Blood Group',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    color: Color(0xFF3F51B5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  bloodGroup,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: bloodGroup.length > 3 ? 24 : 34,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E3A8A),
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Allergies Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            constraints: const BoxConstraints(minHeight: 154),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5EEAD4),
                              borderRadius: BorderRadius.circular(24),
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
                                    color: Color(0xFF115E59),
                                    size: 16,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'Allergies',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  allergies.isEmpty ? 'None\nReported' : allergies,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF064E3B),
                                    height: 1.1,
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

                  // 4. "Digitize your first record" Card with graphics
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -15,
                          child: SizedBox(
                            width: 90,
                            height: 90,
                            child: CustomPaint(
                              painter: DocumentIllustrationPainter(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Digitize your first record',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 19.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const SizedBox(
                                width: 250,
                                child: Text(
                                  'Snap a photo of your prescription or lab report to keep it safe.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/upload'),
                                icon: const Icon(
                                  Icons.camera_enhance_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Upload Now',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003D9B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 5. Next Reminder Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Next Reminder',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.4,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Viewing scheduling database...')),
                          );
                        },
                        child: const Text(
                          'View Schedule',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            color: Color(0xFF003D9B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Medication Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            color: Color(0xFFF95B32),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atorvastatin',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '20mg • After dinner',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '9:00 PM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 6. Health Timeline Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Health Timeline',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.4,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/timeline'),
                        child: const Text(
                          'Full History',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            color: Color(0xFF003D9B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Timeline Cards Stacked vertically
                  _buildTimelineItem(
                    date: 'Nov 12, 2023',
                    badgeText: 'REPORT',
                    badgeBg: const Color(0xFFD1FAE5),
                    badgeColor: const Color(0xFF065F46),
                    title: 'Comprehensive Blood Test',
                    summary: 'Normal cholesterol levels, slight Vitamin D deficiency.',
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    date: 'Oct 28, 2023',
                    badgeText: 'VISIT',
                    badgeBg: const Color(0xFFEFF6FF),
                    badgeColor: const Color(0xFF1E40AF),
                    title: 'General Checkup',
                    summary: 'Visit with Dr. Rahman. Blood pressure: 120/80.',
                    isFirst: false,
                    isLast: true,
                  ),
                  const SizedBox(height: 24),

                  // 7. Emergency Help Crimson Banner
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFECDD3),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Emergency Help',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF9F1239),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Call ambulance or emergency contact',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: Color(0xFFBE123C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EmergencyScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE11D48),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '✳', // Neat high contrast star/medical cross symbol
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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

  Widget _buildDrawer({
    required BuildContext context,
    required String name,
    required String profileImageUrl,
    required String bloodGroup,
  }) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: profileImageUrl.startsWith('data:')
                        ? MemoryImage(base64Decode(profileImageUrl.split(',').last)) as ImageProvider
                        : NetworkImage(profileImageUrl),
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
                        const Text(
                          'Patient ID: e S-8821',
                          style: TextStyle(
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
                                color: Color(0xFF0052CC),
                              ),
                            ),
                            Text(
                              bloodGroup,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0052CC),
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
                    //isSelected: true,
                    onTap: () {
                      context.pop();
                      context.push('/family-profiles');
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
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      context.pop();
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
          color: isSelected ? const Color(0xFF0052CC) : Colors.transparent,
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

  Widget _buildTimelineItem({
    required String date,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String title,
    required String summary,
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isFirst ? const Color(0xFF003D9B) : const Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFD8E3FB).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final rect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 25, 60, 75),
      const Radius.circular(8),
    );
    canvas.save();
    canvas.rotate(0.08);
    canvas.drawRRect(rect1, paint1);
    canvas.restore();

    final paint2 = Paint()
      ..color = const Color(0xFFC4D2FF).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final rect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(25, 10, 52, 68),
      const Radius.circular(8),
    );
    canvas.save();
    canvas.rotate(-0.06);
    canvas.drawRRect(rect2, paint2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
