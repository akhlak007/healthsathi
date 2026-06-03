import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/repositories/ocr_record_repository.dart';
import '../domain/entities/ocr_record.dart';
import '../../profile/providers/active_profile_provider.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final ocrRecordRepositoryProvider = Provider<FirebaseOcrRecordRepository>((ref) {
  return FirebaseOcrRecordRepository();
});

// ---------------------------------------------------------------------------
// Upload status enum
// ---------------------------------------------------------------------------

enum UploadStatus {
  idle,
  picking,
  compressing,
  cropping,
  processing,
  extracting,
  reviewing,
  uploading,
  saving,
  success,
  error,
}

// ---------------------------------------------------------------------------
// Upload state
// ---------------------------------------------------------------------------

class UploadState {
  final UploadStatus status;
  final String? imagePath;
  final String? pdfPath;
  final String ocrText;
  final String doctorName;
  final String hospitalName;
  final DateTime? date;
  final List<String> medicines;
  final String notes;
  final String recordType;
  final String? errorMessage;
  final String? imageUrl;

  const UploadState({
    this.status = UploadStatus.idle,
    this.imagePath,
    this.pdfPath,
    this.ocrText = '',
    this.doctorName = '',
    this.hospitalName = '',
    this.date,
    this.medicines = const [],
    this.notes = '',
    this.recordType = 'Prescription',
    this.errorMessage,
    this.imageUrl,
  });

  UploadState copyWith({
    UploadStatus? status,
    String? imagePath,
    String? pdfPath,
    String? ocrText,
    String? doctorName,
    String? hospitalName,
    DateTime? date,
    List<String>? medicines,
    String? notes,
    String? recordType,
    String? errorMessage,
    String? imageUrl,
  }) {
    return UploadState(
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      pdfPath: pdfPath ?? this.pdfPath,
      ocrText: ocrText ?? this.ocrText,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      date: date ?? this.date,
      medicines: medicines ?? this.medicines,
      notes: notes ?? this.notes,
      recordType: recordType ?? this.recordType,
      errorMessage: errorMessage ?? this.errorMessage,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

// ---------------------------------------------------------------------------
// Upload notifier
// ---------------------------------------------------------------------------

class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier(this._repository, this._activeProfileId) : super(const UploadState());

  final FirebaseOcrRecordRepository _repository;
  final String _activeProfileId;
  final ImagePicker _imagePicker = ImagePicker();

  // ---- File picking ----------------------------------------------------

  Future<void> pickFromCamera() async {
    try {
      state = state.copyWith(status: UploadStatus.picking);
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) {
        state = state.copyWith(status: UploadStatus.idle);
        return;
      }
      state = state.copyWith(
        status: UploadStatus.processing,
        imagePath: photo.path,
        pdfPath: null,
      );
      await performOcr();
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Camera error: $e',
      );
    }
  }

  Future<void> pickFromGallery() async {
    try {
      state = state.copyWith(status: UploadStatus.picking);
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) {
        state = state.copyWith(status: UploadStatus.idle);
        return;
      }
      state = state.copyWith(
        status: UploadStatus.processing,
        imagePath: image.path,
        pdfPath: null,
      );
      await performOcr();
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Gallery error: $e',
      );
    }
  }

  Future<void> pickPdf() async {
    try {
      state = state.copyWith(status: UploadStatus.picking);
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) {
        state = state.copyWith(status: UploadStatus.idle);
        return;
      }
      state = state.copyWith(
        status: UploadStatus.reviewing, // Skip OCR for PDF in V1, go straight to review
        pdfPath: result.files.single.path,
        imagePath: null,
        ocrText: 'PDF Uploaded (OCR not supported for PDFs yet in V1)',
        recordType: 'pdf_report',
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'PDF picker error: $e',
      );
    }
  }

  // ---- OCR & parsing ---------------------------------------------------

  Future<void> performOcr() async {
    if (state.imagePath == null) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'No image selected for OCR.',
      );
      return;
    }

    final textRecognizer = TextRecognizer();
    try {
      state = state.copyWith(status: UploadStatus.extracting);

      final inputImage = InputImage.fromFilePath(state.imagePath!);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;

      // --- Parse fields from OCR text using regex -----------------------
      final doctorName = _extractDoctor(rawText);
      final hospitalName = _extractHospital(rawText);
      final parsedDate = _extractDate(rawText);
      final medicines = _extractMedicines(rawText);

      state = state.copyWith(
        status: UploadStatus.reviewing,
        ocrText: rawText,
        doctorName: doctorName,
        hospitalName: hospitalName,
        date: parsedDate,
        medicines: medicines,
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'OCR extraction failed: $e',
      );
    } finally {
      textRecognizer.close();
    }
  }

  String _extractDoctor(String text) {
    final regex = RegExp(r'Dr\.?\s*([A-Za-z .]+)', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractHospital(String text) {
    final regex = RegExp(
      r'(?:Hospital|Clinic|Center|Medical)\s*[:\-]?\s*([A-Za-z0-9 &.]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  DateTime? _extractDate(String text) {
    final regex = RegExp(r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final raw = match.group(1)!;
    try {
      final parts = raw.split(RegExp(r'[/\-]'));
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        var year = int.parse(parts[2]);
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  List<String> _extractMedicines(String text) {
    final regex = RegExp(
      r'(?:Tab|Cap|Syp|Inj)\.?\s*([A-Za-z0-9 .]+(?:\d+\s*mg)?)',
      caseSensitive: false,
    );
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)?.trim() ?? '').where((s) => s.isNotEmpty).toList();
  }

  // ---- Field editing ---------------------------------------------------

  void updateField(String field, dynamic value) {
    switch (field) {
      case 'doctorName':
        state = state.copyWith(doctorName: value as String);
        break;
      case 'hospitalName':
        state = state.copyWith(hospitalName: value as String);
        break;
      case 'date':
        state = state.copyWith(date: value as DateTime);
        break;
      case 'notes':
        state = state.copyWith(notes: value as String);
        break;
      case 'recordType':
        state = state.copyWith(recordType: value as String);
        break;
      case 'ocrText':
        state = state.copyWith(ocrText: value as String);
        break;
    }
  }

  void addMedicine(String medicine) {
    if (medicine.trim().isEmpty) return;
    state = state.copyWith(medicines: [...state.medicines, medicine.trim()]);
  }

  void removeMedicine(int index) {
    if (index < 0 || index >= state.medicines.length) return;
    final updated = List<String>.from(state.medicines)..removeAt(index);
    state = state.copyWith(medicines: updated);
  }

  // ---- Upload & save ---------------------------------------------------

  Future<void> uploadAndSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'User not authenticated.',
      );
      return;
    }

    try {
      state = state.copyWith(status: UploadStatus.uploading);

      String? downloadUrl;
      final bool isPdf = state.pdfPath != null;
      final String? filePath = isPdf ? state.pdfPath : state.imagePath;

      if (filePath != null) {
        downloadUrl = await _repository.uploadFile(
          userId: user.uid,
          activeProfileId: _activeProfileId,
          filePath: filePath,
          isPdf: isPdf,
        );
      }

      state = state.copyWith(status: UploadStatus.saving);

      final now = DateTime.now();
      final recordId = now.millisecondsSinceEpoch.toString();

      final record = OcrRecord(
        id: recordId,
        recordType: state.recordType,
        doctorName: state.doctorName,
        hospitalName: state.hospitalName,
        date: state.date ?? now,
        ocrText: state.ocrText,
        imageUrl: isPdf ? null : downloadUrl,
        pdfUrl: isPdf ? downloadUrl : null,
        medicines: state.medicines,
        notes: state.notes,
        createdAt: now,
        updatedAt: now,
        timelineVisible: true,
        userId: user.uid,
      );

      await _repository.saveRecord(
        userId: user.uid, 
        activeProfileId: _activeProfileId, 
        record: record,
      );

      state = state.copyWith(
        status: UploadStatus.success,
        imageUrl: downloadUrl,
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Upload failed: $e',
      );
    }
  }

  // ---- Reset -----------------------------------------------------------

  void reset() {
    state = const UploadState();
  }
}

// ---------------------------------------------------------------------------
// StateNotifier provider
// ---------------------------------------------------------------------------

final uploadStateProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  final repository = ref.watch(ocrRecordRepositoryProvider);
  final activeProfileId = ref.watch(activeProfileProvider);
  return UploadNotifier(repository, activeProfileId);
});
