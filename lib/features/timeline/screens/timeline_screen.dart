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
import '../../medicine_reminders/presentation/screens/reminder_center_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/timeline_provider.dart';
import '../../upload/domain/entities/ocr_record.dart';

// ─── Filter State ─────────────────────────────────────────────────────────────

class TimelineFilter {
  final String? recordType; // null = all
  final DateRange? dateRange;
  final SortOrder sortOrder;

  const TimelineFilter({
    this.recordType,
    this.dateRange,
    this.sortOrder = SortOrder.newest,
  });

  bool get isActive =>
      recordType != null || dateRange != null || sortOrder != SortOrder.newest;

  TimelineFilter copyWith({
    Object? recordType = _sentinel,
    Object? dateRange = _sentinel,
    SortOrder? sortOrder,
  }) {
    return TimelineFilter(
      recordType:
          recordType == _sentinel ? this.recordType : recordType as String?,
      dateRange: dateRange == _sentinel ? this.dateRange : dateRange as DateRange?,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static const _sentinel = Object();
}

enum SortOrder { newest, oldest }

class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange(this.from, this.to);
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  // Pill filter selection: 'all', 'reports', 'prescriptions', 'visits'
  String _selectedPill = 'all';
  TimelineFilter _advancedFilter = const TimelineFilter();

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

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]}, ${dt.year}';
  }

  // ─── Filter Logic ──────────────────────────────────────────────────────────

  List<OcrRecord> _filterRecords(List<OcrRecord> records) {
    var result = records.toList();

    // 1. Horizontal Quick Pills
    if (_selectedPill == 'reports') {
      result = result.where((r) {
        final t = r.recordType.toLowerCase();
        return t == 'test_report' || t == 'pdf_report' || t.contains('report') || t.contains('lab');
      }).toList();
    } else if (_selectedPill == 'prescriptions') {
      result = result.where((r) {
        final t = r.recordType.toLowerCase();
        return t == 'prescription' || t.contains('rx') || t.contains('med');
      }).toList();
    } else if (_selectedPill == 'visits') {
      result = result.where((r) {
        final t = r.recordType.toLowerCase();
        return t == 'doctor_visit' || t == 'vaccination' || t.contains('visit') || t.contains('doctor');
      }).toList();
    }

    // 2. Advanced filters (if active)
    if (_advancedFilter.recordType != null) {
      result = result
          .where((r) =>
              r.recordType.toLowerCase() == _advancedFilter.recordType!.toLowerCase())
          .toList();
    }

    if (_advancedFilter.dateRange != null) {
      final from = _advancedFilter.dateRange!.from;
      final to = _advancedFilter.dateRange!.to.add(const Duration(days: 1));
      result = result
          .where((r) =>
              r.date.isAfter(from.subtract(const Duration(days: 1))) &&
              r.date.isBefore(to))
          .toList();
    }

    // Sort
    result.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _advancedFilter.sortOrder == SortOrder.newest ? -cmp : cmp;
    });

    return result;
  }

  // ─── Filter Bottom Sheet ───────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter History Ledger',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPill = 'all';
                      _advancedFilter = const TimelineFilter();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort_rounded, color: Color(0xFF003D9B)),
              title: const Text('Sort Newest First'),
              trailing: _advancedFilter.sortOrder == SortOrder.newest
                  ? const Icon(Icons.check_rounded, color: Color(0xFF003D9B))
                  : null,
              onTap: () {
                setState(() {
                  _advancedFilter = _advancedFilter.copyWith(sortOrder: SortOrder.newest);
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: Color(0xFF003D9B)),
              title: const Text('Sort Oldest First'),
              trailing: _advancedFilter.sortOrder == SortOrder.oldest
                  ? const Icon(Icons.check_rounded, color: Color(0xFF003D9B))
                  : null,
              onTap: () {
                setState(() {
                  _advancedFilter = _advancedFilter.copyWith(sortOrder: SortOrder.oldest);
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final activeProfileId = ref.watch(activeProfileProvider);
    final recordsAsync = ref.watch(timelineRecordsProvider);

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
        final rawImageUrl = isSelf ? (data?['profileImage']) : (data?['photoUrl']);
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
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'HealthSathi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(timelineRecordsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header: "Health Timeline" + "Full History →"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFF003D9B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Health Timeline',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showFilterSheet,
                          child: Row(
                            children: const [
                              Text(
                                'Full History',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF003D9B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF003D9B),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your medical journey, all in one place.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Horizontal Filter Pills: "All", "Reports", "Prescriptions", "Visits"
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill('All', 'all'),
                          const SizedBox(width: 10),
                          _buildFilterPill('Reports', 'reports'),
                          const SizedBox(width: 10),
                          _buildFilterPill('Prescriptions', 'prescriptions'),
                          const SizedBox(width: 10),
                          _buildFilterPill('Visits', 'visits'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Vertical Medical Timeline List
                    recordsAsync.when(
                      data: (allRecords) {
                        final records = _filterRecords(allRecords);

                        if (allRecords.isEmpty) {
                          return _buildEmptyState();
                        }

                        if (records.isEmpty) {
                          return _buildNoResultsState();
                        }

                        return Column(
                          children: List.generate(records.length, (index) {
                            final rec = records[index];
                            final isFirst = index == 0;
                            final isLast = index == records.length - 1;
                            return _buildTimelineItem(
                              record: rec,
                              isFirst: isFirst,
                              isLast: isLast,
                            );
                          }),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: AppLogoLoader(size: 52)),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Could not load records: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Promo Banner: "Keep Your Health History Organized"
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Keep Your Health History\nOrganized',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    height: 1.25,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'All your reports, prescriptions, and visits in one secure place.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const ClipboardIllustrationWidget(size: 84),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(activeIndex: 1),
        );
      },
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _selectedPill == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPill = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003D9B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF003D9B) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF003D9B).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required OcrRecord record,
    required bool isFirst,
    required bool isLast,
  }) {
    final type = record.recordType.toLowerCase();

    // Style parameters based on category
    Color badgeBg;
    Color badgeColor;
    String badgeText;
    IconData icon;
    Color iconColor;
    Color iconBg;
    String defaultTitle;
    String defaultSubtitle;

    if (type == 'test_report' || type == 'pdf_report' || type.contains('report') || type.contains('lab')) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF15803D);
      badgeText = 'LAB REPORT';
      icon = Icons.science_outlined;
      iconColor = const Color(0xFF059669);
      iconBg = const Color(0xFFE8F8F0);
      defaultTitle = 'Lab Report';
      defaultSubtitle = 'Complete Blood Count (CBC)';
    } else if (type == 'prescription' || type.contains('rx')) {
      badgeBg = const Color(0xFFEFF6FF);
      badgeColor = const Color(0xFF1D4ED8);
      badgeText = 'PRESCRIPTION';
      icon = Icons.medication_outlined;
      iconColor = const Color(0xFF1D4ED8);
      iconBg = const Color(0xFFE0EDFF);
      defaultTitle = 'Prescription';
      defaultSubtitle = 'Fever & Cough';
    } else if (type == 'doctor_visit' || type.contains('visit') || type.contains('doctor')) {
      badgeBg = const Color(0xFFF3E8FF);
      badgeColor = const Color(0xFF7E22CE);
      badgeText = 'DOCTOR VISIT';
      icon = Icons.medical_services_outlined;
      iconColor = const Color(0xFF7E22CE);
      iconBg = const Color(0xFFF5EEFD);
      defaultTitle = 'Doctor Visit';
      defaultSubtitle = 'General Checkup';
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      badgeColor = const Color(0xFFB45309);
      badgeText = 'HEALTH RECORD';
      icon = Icons.description_outlined;
      iconColor = const Color(0xFFB45309);
      iconBg = const Color(0xFFFFFBEB);
      defaultTitle = 'Medical Record';
      defaultSubtitle = 'Routine Diagnostic Entry';
    }

    final title = record.recordLabel.isNotEmpty
        ? record.recordLabel
        : defaultTitle;
    final subtitle = record.doctorName.isNotEmpty
        ? 'Dr. ${record.doctorName}'
        : defaultSubtitle;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Vertical Timeline Connector
          SizedBox(
            width: 22,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: isFirst ? 12 : 10,
                  height: isFirst ? 12 : 10,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? const Color(0xFF003D9B)
                        : const Color(0xFF93C5FD),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Timeline Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => context.push('/record/${record.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Category Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(record.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
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
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Icon + Title & Subtitle + Chevron
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              icon,
                              color: iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 22,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: Color(0xFF003D9B),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No records found',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload your prescriptions or lab reports to populate your medical timeline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => context.push('/upload'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add First Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003D9B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_list_off_rounded,
            color: Color(0xFF94A3B8),
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text(
            'No records in this category',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedPill = 'all';
                _advancedFilter = const TimelineFilter();
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF003D9B),
                        ),
                      ),
                      Text(
                        'আপনার স্বাস্থ্য, আপনার হাতে',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF64748B),
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
