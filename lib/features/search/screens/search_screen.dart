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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search records, meds, or ...',
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
            const SizedBox(height: 22),

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
                        final title = record.doctorName.isNotEmpty
                            ? record.doctorName
                            : (record.recordType.isNotEmpty ? record.recordType : 'Medical Record');
                        final category = record.recordType.isNotEmpty ? record.recordType : 'Medical Record';
                        final hospital = record.hospitalName.isNotEmpty ? record.hospitalName : 'City General Hospital';
                        final dateStr =
                            '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x060F172A),
                                blurRadius: 10,
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
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                                    ),
                                    child: const Icon(Icons.person_rounded, color: Color(0xFF003D9B), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                            fontSize: 12.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
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
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF059669)),
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
