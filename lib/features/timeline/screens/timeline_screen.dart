import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../providers/timeline_provider.dart';
import '../../upload/domain/entities/ocr_record.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  Color _categoryColor(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'prescription':
        return AppColors.primary;
      case 'test_report':
        return Colors.amber.shade800;
      case 'vaccination':
        return Colors.teal;
      case 'doctor_visit':
        return const Color(0xFF7B2D8E);
      case 'pdf_report':
        return const Color(0xFFEA7A2B);
      default:
        return AppColors.primary;
    }
  }

  String _categoryLabel(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'prescription':
        return 'Prescription';
      case 'test_report':
        return 'Test Report';
      case 'vaccination':
        return 'Vaccination';
      case 'doctor_visit':
        return 'Doctor Visit';
      case 'pdf_report':
        return 'PDF Report';
      default:
        return recordType;
    }
  }

  IconData _categoryIcon(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'prescription':
        return Icons.medication_rounded;
      case 'test_report':
        return Icons.biotech_rounded;
      case 'vaccination':
        return Icons.vaccines_rounded;
      case 'doctor_visit':
        return Icons.local_hospital_rounded;
      case 'pdf_report':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(timelineRecordsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Clinical History Ledger',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded,
                color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Filter functionality coming in next update.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: recordsAsync.when(
        loading: () => _buildLoadingShimmer(),
        error: (err, stack) => _buildErrorState(context, err, ref),
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptyState(context, textTheme);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(timelineRecordsProvider);
            },
            child: _buildTimelineList(context, records, textTheme),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 1),
    );
  }

  // ─── LOADING SHIMMER ─────────────────────────────────────────────
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  shape: BoxShape.circle),
              child: const Icon(Icons.history_edu_rounded,
                  size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('No diagnostic entries',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'Scan paper prescriptions or reports to initiate your clinical health ledger.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium),
            const SizedBox(height: 32),
            ClinicalButton(
              label: 'Upload First Record',
              icon: Icons.add_rounded,
              isFullWidth: false,
              onPressed: () => context.go('/upload'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ERROR STATE ─────────────────────────────────────────────────
  Widget _buildErrorState(
      BuildContext context, Object err, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load records',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error)),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ClinicalButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              onPressed: () => ref.invalidate(timelineRecordsProvider),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TIMELINE LIST ───────────────────────────────────────────────
  Widget _buildTimelineList(
      BuildContext context, List<OcrRecord> records, TextTheme textTheme) {
    // Group by date
    final Map<String, List<OcrRecord>> grouped = {};
    for (final record in records) {
      final dateKey =
          '${record.createdAt.day} ${_monthName(record.createdAt.month)}, ${record.createdAt.year}';
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    final groupKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = groupKeys[groupIndex];
        final groupRecords = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Records in this group
            ...groupRecords.asMap().entries.map((entry) {
              final i = entry.key;
              final record = entry.value;
              final isLast =
                  i == groupRecords.length - 1 && groupIndex == groupKeys.length - 1;
              final color = _categoryColor(record.recordType);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline connector
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4),
                              color: AppColors.outlineVariant
                                  .withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: GestureDetector(
                          onTap: () =>
                              context.go('/record/${record.id}'),
                          child: MedicalCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                          _categoryIcon(record.recordType),
                                          size: 18,
                                          color: color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _categoryLabel(
                                                record.recordType),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                          if (record.doctorName.isNotEmpty)
                                            Text(
                                              record.doctorName,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                color.withOpacity(0.16)),
                                      ),
                                      child: Text(
                                        _categoryLabel(record.recordType),
                                        style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: color),
                                      ),
                                    ),
                                  ],
                                ),

                                // Thumbnail or PDF indicator
                                if (record.imageUrl != null &&
                                    record.imageUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: record.imageUrl!,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          Container(
                                        height: 100,
                                        color:
                                            Colors.grey.shade100,
                                        child: const Center(
                                            child:
                                                CircularProgressIndicator(
                                                    strokeWidth:
                                                        2)),
                                      ),
                                      errorWidget:
                                          (_, __, ___) =>
                                              Container(
                                        height: 100,
                                        color:
                                            Colors.grey.shade100,
                                        child: const Icon(
                                            Icons
                                                .broken_image_rounded,
                                            color:
                                                AppColors.outline),
                                      ),
                                    ),
                                  ),
                                ] else if (record.pdfUrl != null &&
                                    record.pdfUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.orange.shade100),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.picture_as_pdf_rounded,
                                            size: 28,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'PDF Attached',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                if (record.hospitalName.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 13, color: AppColors.outline),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          record.hospitalName,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors
                                                  .onSurfaceVariant),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const Divider(
                                    height: 16, thickness: 0.5),

                                // Preview text
                                Text(
                                  record.ocrText.isNotEmpty
                                      ? (record.ocrText.length > 120
                                          ? '${record.ocrText.substring(0, 120)}...'
                                          : record.ocrText)
                                      : 'No extracted text available.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Medicines chips
                                if (record.medicines.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: record.medicines
                                        .take(3)
                                        .map((m) => Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration:
                                                  BoxDecoration(
                                                color: color
                                                    .withOpacity(
                                                        0.06),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            12),
                                              ),
                                              child: Text(
                                                '💊 $m',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: color,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
