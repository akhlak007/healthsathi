import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../../../core/widgets/app_logo_loader.dart';
import '../../profile/providers/active_profile_provider.dart';
import '../../profile/widgets/profile_switcher_bottom_sheet.dart';
import '../providers/upload_providers.dart';
import '../../medicine_reminders/presentation/screens/add_reminder_screen.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _medicineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _medicineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadStateProvider);
    final notifier = ref.read(uploadStateProvider.notifier);
    final user = FirebaseAuth.instance.currentUser;
    final userInitials = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'AJ';

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
                  'Store Medical Records',
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
                  userInitials,
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
        actions: [
          if (uploadState.status != UploadStatus.idle)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              onPressed: () => notifier.reset(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildCurrentStep(uploadState, notifier),
        ),
      ),
      bottomNavigationBar: uploadState.status == UploadStatus.idle
          ? const AppBottomNavBar(activeIndex: 2)
          : null,
    );
  }

  Widget _buildCurrentStep(UploadState state, UploadNotifier notifier) {
    switch (state.status) {
      case UploadStatus.idle:
        return _buildUploadSelectorScreen(notifier);
      case UploadStatus.picking:
      case UploadStatus.compressing:
      case UploadStatus.cropping:
        return _buildProcessingLoader(
          key: 'picking',
          title: 'Preparing Image...',
          subtitle: 'Optimizing the image for best OCR results.',
          icon: Icons.crop_rotate_rounded,
        );
      case UploadStatus.processing:
      case UploadStatus.extracting:
        return _buildProcessingLoader(
          key: 'extracting',
          title: 'Extracting Clinical Tokens...',
          subtitle:
              'Running on-device AI to parse clinician entities, drug formulations, frequency, and custom advice.',
          icon: Icons.document_scanner_rounded,
        );
      case UploadStatus.reviewing:
        return _buildOcrResultScreen(state, notifier);
      case UploadStatus.uploading:
      case UploadStatus.saving:
        return _buildProcessingLoader(
          key: 'uploading',
          title: 'Saving to Cloud...',
          subtitle:
              'Uploading your record to secure Cloudinary storage and syncing metadata.',
          icon: Icons.cloud_upload_rounded,
        );
      case UploadStatus.success:
        return _buildSuccessScreen(state, notifier);
      case UploadStatus.error:
        return _buildErrorScreen(state, notifier);
    }
  }

  // ─── UPLOAD SELECTOR ─────────────────────────────────────────────
  Widget _buildUploadSelectorScreen(UploadNotifier notifier) {
    return Column(
      key: const ValueKey('selector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Digitize Record',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Convert your paper prescriptions, lab reports, and medical bills into secure digital records.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),

        // AI Extraction Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // AI Brain Badge with Sparkle
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EDFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 34,
                  color: Color(0xFF003D9B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AI-Powered Extraction',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Our system automatically identifies medications, dates, and doctor names from your uploads.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildIconCard(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                description: 'Scan physical document',
                color: const Color(0xFF1D4ED8),
                bgColor: const Color(0xFFF0F6FF),
                onTap: () => notifier.pickFromCamera(),
              ),
              const SizedBox(height: 14),
              _buildIconCard(
                icon: Icons.image_rounded,
                label: 'Gallery',
                description: 'Choose from phone',
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFF0FDF4),
                onTap: () => notifier.pickFromGallery(),
              ),
              const SizedBox(height: 14),
              _buildIconCard(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Upload PDF',
                description: 'Medical reports, E-prescriptions',
                color: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFF7ED),
                onTap: () => notifier.pickPdf(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Tips Section
        Container(
          padding: const EdgeInsets.all(18),
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
              const Text(
                'TIPS FOR BEST RESULTS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              _buildTipRow(
                icon: Icons.info_outline_rounded,
                text: 'Ensure good lighting without glare on the document surface.',
              ),
              const SizedBox(height: 10),
              _buildTipRow(
                icon: Icons.center_focus_strong_rounded,
                text: 'Hold the camera steadily and align the document within the frame.',
              ),
              const SizedBox(height: 10),
              _buildTipRow(
                icon: Icons.document_scanner_outlined,
                text: 'Keep pages flat and edges clearly visible for high AI accuracy.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── PROCESSING LOADER ───────────────────────────────────────────
  Widget _buildProcessingLoader({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      key: ValueKey(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogoLoader(size: 72),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
                text:
                    'Hold the camera steadily and align the document within the frame.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  // ─── PROCESSING LOADER ───────────────────────────────────────────
  Widget _buildProcessingLoader({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      key: ValueKey(key),
      children: [
        const SizedBox(height: 80),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            return Transform.scale(scale: scale, child: child);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.outline, fontSize: 13, height: 1.45),
          ),
        ),
      ],
    );
  }

  // ─── OCR RESULT / REVIEW SCREEN ──────────────────────────────────
  Widget _buildOcrResultScreen(UploadState state, UploadNotifier notifier) {
    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 8),
            const Text(
              'OCR Extracted Successfully',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Image preview
        if (state.imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(state.imagePath!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        if (state.imagePath != null) const SizedBox(height: 20),

        // OCR text card
        MedicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.text_snippet_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('Extracted OCR Text',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const Divider(height: 24, thickness: 0.6),
              Text(
                state.ocrText.isNotEmpty
                    ? state.ocrText
                    : 'No text could be extracted.',
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Editable fields
        _buildEditableSection(state, notifier),
        const SizedBox(height: 24),

        // Medicines
        _buildMedicinesSection(state, notifier),
        const SizedBox(height: 24),

        // Notes
        MedicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notes',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: state.notes,
                maxLines: 3,
                decoration: _inputDecoration('Add any notes...'),
                onChanged: (val) => notifier.updateField('notes', val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Save button
        ClinicalButton(
          label: 'Save Record to Timeline',
          icon: Icons.cloud_upload_rounded,
          onPressed: () => notifier.uploadAndSave(),
        ),
        const SizedBox(height: 12),
        if (state.medicines.isNotEmpty) ...[
          ClinicalButton(
            label: 'Create Medicine Reminder',
            backgroundColor: const Color(0xFFD1FAE5),
            foregroundColor: const Color(0xFF065F46),
            icon: Icons.notification_add_rounded,
            onPressed: () {
              final medicineName = state.medicines.first;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddReminderScreen(
                  initialMedicineName: medicineName,
                  initialDosage: '1', // Default dosage or extract if available
                ),
              ));
            },
          ),
          const SizedBox(height: 12),
        ],
        ClinicalButton(
          label: 'Scan Again',
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          onPressed: () => notifier.reset(),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildEditableSection(UploadState state, UploadNotifier notifier) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Record Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),

          // Record Type Dropdown
          DropdownButtonFormField<String>(
            value: state.recordType.isNotEmpty ? state.recordType : 'prescription',
            decoration: _inputDecoration('Record Type'),
            items: const [
              DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
              DropdownMenuItem(value: 'test_report', child: Text('Test Report')),
              DropdownMenuItem(value: 'vaccination', child: Text('Vaccination')),
              DropdownMenuItem(value: 'doctor_visit', child: Text('Doctor Visit')),
              DropdownMenuItem(value: 'pdf_report', child: Text('PDF Report')),
            ],
            onChanged: (val) =>
                notifier.updateField('recordType', val ?? 'prescription'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.recordLabel,
            decoration: _inputDecoration('Prescription Tag / Title'),
            onChanged: (val) => notifier.updateField('recordLabel', val),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: state.doctorName,
            decoration: _inputDecoration('Doctor Name'),
            onChanged: (val) => notifier.updateField('doctorName', val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.hospitalName,
            decoration: _inputDecoration('Hospital / Clinic Name'),
            onChanged: (val) => notifier.updateField('hospitalName', val),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                notifier.updateField('date', picked);
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: _inputDecoration('Date').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.primary),
                ),
                controller: TextEditingController(
                  text: state.date != null
                      ? '${state.date!.day}/${state.date!.month}/${state.date!.year}'
                      : '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesSection(UploadState state, UploadNotifier notifier) {
    // _medicineController is a State field — not recreated on rebuild
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medicines',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(state.medicines.length, (i) {
              return Chip(
                label: Text(state.medicines[i],
                    style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => notifier.removeMedicine(i),
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _medicineController,
                  decoration: _inputDecoration('Add medicine...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_medicineController.text.trim().isNotEmpty) {
                    notifier.addMedicine(_medicineController.text.trim());
                    _medicineController.clear();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SUCCESS SCREEN ──────────────────────────────────────────────
  Widget _buildSuccessScreen(UploadState state, UploadNotifier notifier) {
    return Column(
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: 80),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              size: 80, color: AppColors.secondary),
        ),
        const SizedBox(height: 32),
        const Text(
          'Record Saved Successfully!',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Your medical record has been securely uploaded and saved to your clinical timeline.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                height: 1.5),
          ),
        ),
        const SizedBox(height: 48),
        if (state.savedRecordId != null) ...[
          ClinicalButton(
            label: 'View Record',
            icon: Icons.receipt_long_rounded,
            onPressed: () {
              final recordId = state.savedRecordId!;
              notifier.reset();
              context.go('/record/$recordId');
            },
          ),
          const SizedBox(height: 12),
        ],
        ClinicalButton(
          label: 'View Timeline',
          icon: Icons.history_edu_rounded,
          onPressed: () {
            notifier.reset();
            context.go('/timeline');
          },
        ),
        const SizedBox(height: 12),
        ClinicalButton(
          label: 'Upload Another',
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          icon: Icons.add_rounded,
          onPressed: () => notifier.reset(),
        ),
      ],
    );
  }

  // ─── ERROR SCREEN ────────────────────────────────────────────────
  Widget _buildErrorScreen(UploadState state, UploadNotifier notifier) {
    return Column(
      key: const ValueKey('error'),
      children: [
        const SizedBox(height: 80),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.error_rounded, size: 80, color: AppColors.error),
        ),
        const SizedBox(height: 32),
        const Text(
          'Something Went Wrong',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.error),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            state.errorMessage ?? 'An unexpected error occurred. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                height: 1.5),
          ),
        ),
        const SizedBox(height: 48),
        ClinicalButton(
          label: 'Try Again',
          icon: Icons.refresh_rounded,
          onPressed: () => notifier.reset(),
        ),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.outline.withOpacity(0.6), fontSize: 14),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildIconCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
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
      ),
    );
  }

  Widget _buildTipRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F1FE),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 13, color: Color(0xFF003D9B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
