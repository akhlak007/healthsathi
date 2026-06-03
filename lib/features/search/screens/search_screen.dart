// lib/features/search/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../timeline/providers/timeline_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Clinicians & Centers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Text Field
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search records, meds, or doctors...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredRecords.length} FOUND',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.primary, fontFamily: 'JetBrains Mono'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: AppColors.outlineVariant.withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          Text('No records found', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Refine your search query and retry.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.grey.shade100, width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withOpacity(0.08),
                                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.doctorName.isNotEmpty
                                            ? record.doctorName
                                            : (record.recordType.isNotEmpty ? record.recordType : 'Medical Record'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record.recordType.isNotEmpty ? record.recordType : 'General',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11.5),
                                      ),
                                      const Divider(height: 16, thickness: 0.5),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.outline),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              record.hospitalName.isNotEmpty ? record.hospitalName : 'Unknown Location',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: AppColors.outline, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${record.date.day}/${record.date.month}/${record.date.year}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => context.push('/record/${record.id}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    minimumSize: Size.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
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
