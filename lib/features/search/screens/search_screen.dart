// lib/features/search/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../timeline/providers/timeline_provider.dart';
import '../../profile/widgets/profile_switcher_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const ['All', 'Prescriptions', 'Lab Reports', 'Bills'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTitle(String raw, String category) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return _formatCategory(category);
    }
    final lower = clean.toLowerCase();
    if (lower.startsWith('dr ') || lower.startsWith('dr. ')) {
      final namePart = clean.substring(clean.indexOf(' ') + 1).trim();
      final words = namePart.split(' ').where((w) => w.isNotEmpty).map((w) {
        return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
      }).join(' ');
      return 'Dr. $words';
    }
    if (lower == 'prescription' || lower == 'lab_report') {
      return _formatCategory(clean);
    }
    return clean.split(' ').where((w) => w.isNotEmpty).map((w) {
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _formatCategory(String raw) {
    if (raw.trim().isEmpty) return 'Medical Record';
    return raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  ({IconData icon, Color color, Color bg, Color border}) _getCategoryStyle(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('lab') || lower.contains('test') || lower.contains('report')) {
      return (
        icon: Icons.biotech_rounded,
        color: const Color(0xFF0D9488),
        bg: const Color(0xFFF0FDFA),
        border: const Color(0xFFCCFBF1),
      );
    } else if (lower.contains('presc') || lower.contains('med') || lower.contains('rx')) {
      return (
        icon: Icons.medication_rounded,
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFEFF6FF),
        border: const Color(0xFFDBEAFE),
      );
    } else if (lower.contains('bill') || lower.contains('invoice') || lower.contains('pay')) {
      return (
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFD97706),
        bg: const Color(0xFFFFFBEB),
        border: const Color(0xFFFDE68A),
      );
    }
    return (
      icon: Icons.medical_services_rounded,
      color: const Color(0xFF003D9B),
      bg: const Color(0xFFEEF2FF),
      border: const Color(0xFFE0E7FF),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userInitials = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'AJ';

    final recordsAsync = ref.watch(timelineRecordsProvider);
    final records = recordsAsync.valueOrNull ?? [];

    final filteredRecords = records.where((r) {
      // 1. Filter by category pill if not 'All'
      if (_selectedFilter == 'Prescriptions') {
        final t = r.recordType.toLowerCase();
        if (!t.contains('presc') && !t.contains('med')) return false;
      } else if (_selectedFilter == 'Lab Reports') {
        final t = r.recordType.toLowerCase();
        if (!t.contains('lab') && !t.contains('report') && !t.contains('test')) return false;
      } else if (_selectedFilter == 'Bills') {
        final t = r.recordType.toLowerCase();
        if (!t.contains('bill') && !t.contains('invoice')) return false;
      }

      // 2. Filter by search query
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final doctor = r.doctorName.toLowerCase();
      final hospital = r.hospitalName.toLowerCase();
      final type = r.recordType.toLowerCase();
      final notes = r.notes.toLowerCase();
      final text = r.ocrText.toLowerCase();
      final meds = r.medicines.join(' ').toLowerCase();
      return doctor.contains(query) ||
          hospital.contains(query) ||
          type.contains(query) ||
          notes.contains(query) ||
          text.contains(query) ||
          meds.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        toolbarHeight: 68,
        title: Row(
          children: [
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
                  'Digital Clinicians & Centers',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => showProfileSwitcher(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF003D9B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  userInitials.isNotEmpty ? userInitials : 'AJ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Title
            const Text(
              'Digital Clinicians & Centers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search records, meds, clinicians...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF003D9B),
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick Category Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final filter = _filters[i];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF003D9B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF003D9B) : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF003D9B).withOpacity(0.22),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Results Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Search Results',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                  ),
                  child: Text(
                    '${filteredRecords.length} FOUND',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      color: Color(0xFF1D4ED8),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Results List
            Expanded(
              child: filteredRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF003D9B)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No records found',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Refine your search query and retry.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredRecords.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        final displayTitle = _formatTitle(record.doctorName, record.recordType);
                        final displayCategory = _formatCategory(record.recordType);
                        final style = _getCategoryStyle(record.recordType);
                        final hospital = record.hospitalName.isNotEmpty ? record.hospitalName : 'City General Hospital';
                        final dateStr =
                            '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x060F172A),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Category-themed Icon
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: style.bg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: style.border, width: 1.2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(style.icon, color: style.color, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Badge Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: style.bg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: style.border, width: 0.8),
                                          ),
                                          child: Text(
                                            displayCategory,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: style.color,
                                              fontSize: 11,
                                              letterSpacing: 0.1,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () => context.push('/record/${record.id}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003D9B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'View',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 14),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      hospital,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF059669)),
                                      const SizedBox(width: 5),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF059669),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (record.medicines.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.medication_liquid_rounded, size: 14, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Meds: ${record.medicines.join(', ')}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 3),
    );
  }
}
