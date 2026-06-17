import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
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
      recordType: recordType == _sentinel ? this.recordType : recordType as String?,
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
  TimelineFilter _filter = const TimelineFilter();

  // ─── Helpers ───────────────────────────────────────────────────────────────

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

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // ─── Filter Logic ──────────────────────────────────────────────────────────

  List<OcrRecord> _applyFilter(List<OcrRecord> records) {
    var result = records.toList();

    // Filter by type
    if (_filter.recordType != null) {
      result = result
          .where((r) => r.recordType.toLowerCase() == _filter.recordType!.toLowerCase())
          .toList();
    }

    // Filter by date range
    if (_filter.dateRange != null) {
      final from = _filter.dateRange!.from;
      final to = _filter.dateRange!.to.add(const Duration(days: 1));
      result = result
          .where((r) => r.date.isAfter(from.subtract(const Duration(days: 1))) && r.date.isBefore(to))
          .toList();
    }

    // Sort
    result.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _filter.sortOrder == SortOrder.newest ? -cmp : cmp;
    });

    return result;
  }

  // ─── Filter Bottom Sheet ───────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        currentFilter: _filter,
        onApply: (filter) {
          setState(() => _filter = filter);
        },
        onClear: () {
          setState(() => _filter = const TimelineFilter());
        },
        categoryLabel: _categoryLabel,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(timelineRecordsProvider);
    final textTheme = Theme.of(context).textTheme;

    final activeFilterCount = [
      if (_filter.recordType != null) 1,
      if (_filter.dateRange != null) 1,
      if (_filter.sortOrder != SortOrder.newest) 1,
    ].length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Clinical History Ledger',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: _filter.isActive ? AppColors.primary : AppColors.primary,
                ),
                onPressed: _showFilterSheet,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: recordsAsync.when(
        loading: () => _buildLoadingShimmer(),
        error: (err, stack) => _buildErrorState(context, err),
        data: (allRecords) {
          final records = _applyFilter(allRecords);

          if (allRecords.isEmpty) {
            return _buildEmptyState(context, textTheme);
          }

          if (records.isEmpty) {
            return _buildNoResultsState(context);
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
                  color: AppColors.primary.withValues(alpha: 0.06),
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

  // ─── NO RESULTS (after filter) ───────────────────────────────────
  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'No records match your filters',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting or clearing your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.filter_list_off_rounded),
              label: const Text('Clear Filters'),
              onPressed: () => setState(() => _filter = const TimelineFilter()),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ERROR STATE ─────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
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
              style: const TextStyle(
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
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateKey,
                      style: const TextStyle(
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
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Records in this group
            ...groupRecords.asMap().entries.map((entry) {
              final _ = entry.key;  // index not used; kept for asMap() pattern
              final record = entry.value;
              final color = _categoryColor(record.recordType);

              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline connector
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
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
                        ],
                      ),
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
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
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
                                          if (record.recordLabel.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              record.recordLabel,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          if (record.doctorName.isNotEmpty)
                                            Text(
                                              record.doctorName,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                color.withValues(alpha: 0.16)),
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
                                      const Icon(Icons.location_on_outlined,
                                          size: 13, color: AppColors.outline),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          record.hospitalName,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.onSurfaceVariant),
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
                                  style: const TextStyle(
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
                                        .map((m) => ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 150),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.06),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '💊 $m',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: color,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
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
                );
            }),
          ],
        );
      },
    );
  }
}

// ─── Filter Bottom Sheet Widget ───────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final TimelineFilter currentFilter;
  final ValueChanged<TimelineFilter> onApply;
  final VoidCallback onClear;
  final String Function(String) categoryLabel;

  const _FilterSheet({
    required this.currentFilter,
    required this.onApply,
    required this.onClear,
    required this.categoryLabel,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedType;
  late SortOrder _sortOrder;
  DateTime? _fromDate;
  DateTime? _toDate;

  static const _types = <(String, String, IconData, Color)>[
    ('prescription', 'Prescription', Icons.medication_rounded, AppColors.primary),
    ('test_report', 'Test Report', Icons.biotech_rounded, Colors.amber),
    ('vaccination', 'Vaccination', Icons.vaccines_rounded, Colors.teal),
    ('doctor_visit', 'Doctor Visit', Icons.local_hospital_rounded, Color(0xFF7B2D8E)),
    ('pdf_report', 'PDF Report', Icons.picture_as_pdf_rounded, Color(0xFFEA7A2B)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentFilter.recordType;
    _sortOrder = widget.currentFilter.sortOrder;
    _fromDate = widget.currentFilter.dateRange?.from;
    _toDate = widget.currentFilter.dateRange?.to;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          // Ensure toDate is not before fromDate
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          if (_fromDate != null && _fromDate!.isAfter(_toDate!)) {
            _fromDate = _toDate;
          }
        }
      });
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return 'Select';
    return '${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }

  void _apply() {
    DateRange? range;
    if (_fromDate != null && _toDate != null) {
      range = DateRange(_fromDate!, _toDate!);
    } else if (_fromDate != null) {
      range = DateRange(_fromDate!, DateTime.now());
    } else if (_toDate != null) {
      range = DateRange(DateTime(2000), _toDate!);
    }

    widget.onApply(TimelineFilter(
      recordType: _selectedType,
      dateRange: range,
      sortOrder: _sortOrder,
    ));
    Navigator.pop(context);
  }

  void _clear() {
    widget.onClear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                TextButton(
                  onPressed: _clear,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Record Type ──────────────────────────────────────────────────
            const Text(
              'RECORD TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final isSelected = _selectedType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = isSelected ? null : t.$1;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? t.$4.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? t.$4 : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.$3, size: 14, color: isSelected ? t.$4 : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          t.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? t.$4 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Date Range ───────────────────────────────────────────────────
            const Text(
              'DATE RANGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DatePickerButton(
                    label: 'From',
                    value: _fmtDate(_fromDate),
                    hasValue: _fromDate != null,
                    onTap: () => _pickDate(isFrom: true),
                    onClear: () => setState(() => _fromDate = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerButton(
                    label: 'To',
                    value: _fmtDate(_toDate),
                    hasValue: _toDate != null,
                    onTap: () => _pickDate(isFrom: false),
                    onClear: () => setState(() => _toDate = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Sort Order ───────────────────────────────────────────────────
            const Text(
              'SORT BY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SortChip(
                    label: 'Newest First',
                    icon: Icons.arrow_downward_rounded,
                    selected: _sortOrder == SortOrder.newest,
                    onTap: () => setState(() => _sortOrder = SortOrder.newest),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SortChip(
                    label: 'Oldest First',
                    icon: Icons.arrow_upward_rounded,
                    selected: _sortOrder == SortOrder.oldest,
                    onTap: () => setState(() => _sortOrder = SortOrder.oldest),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Apply button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerButton({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: hasValue ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: hasValue ? AppColors.primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? AppColors.primary : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
