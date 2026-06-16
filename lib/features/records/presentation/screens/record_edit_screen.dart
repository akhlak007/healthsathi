import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../../upload/domain/entities/ocr_record.dart';
import '../../../profile/providers/active_profile_provider.dart';
import 'record_detail_screen.dart'; // To use recordDetailProvider

class RecordEditScreen extends ConsumerStatefulWidget {
  final String recordId;

  const RecordEditScreen({super.key, required this.recordId});

  @override
  ConsumerState<RecordEditScreen> createState() => _RecordEditScreenState();
}

class _RecordEditScreenState extends ConsumerState<RecordEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isInitialized = false;
  bool _isSaving = false;

  late String _recordType;
  late TextEditingController _labelController;
  late TextEditingController _doctorController;
  late TextEditingController _hospitalController;
  late TextEditingController _ocrTextController;
  late TextEditingController _notesController;
  late DateTime _date;
  late List<String> _medicines;

  final TextEditingController _medicineInputController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _doctorController.dispose();
    _hospitalController.dispose();
    _ocrTextController.dispose();
    _notesController.dispose();
    _medicineInputController.dispose();
    super.dispose();
  }

  void _initializeData(OcrRecord record) {
    if (_isInitialized) return;
    
    _recordType = record.recordType.isNotEmpty ? record.recordType : 'prescription';
    _labelController = TextEditingController(text: record.recordLabel);
    _doctorController = TextEditingController(text: record.doctorName);
    _hospitalController = TextEditingController(text: record.hospitalName);
    _ocrTextController = TextEditingController(text: record.ocrText);
    _notesController = TextEditingController(text: record.notes);
    _date = record.date;
    _medicines = List.from(record.medicines);
    
    _isInitialized = true;
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final activeProfileId = ref.read(activeProfileProvider);
      if (user != null) {
        final collectionRef = activeProfileId == 'self'
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('records')
            : FirebaseFirestore.instance.collection('users').doc(user.uid).collection('familyProfiles').doc(activeProfileId).collection('records');
            
        await collectionRef.doc(widget.recordId).update({
          'recordType': _recordType,
          'recordLabel': _labelController.text.trim(),
          'doctorName': _doctorController.text.trim(),
          'hospitalName': _hospitalController.text.trim(),
          'date': Timestamp.fromDate(_date),
          'ocrText': _ocrTextController.text.trim(),
          'notes': _notesController.text.trim(),
          'medicines': _medicines,
          'updatedAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record updated successfully'), backgroundColor: AppColors.secondary),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating record: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordAsync = ref.watch(recordDetailProvider(widget.recordId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Record', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (record) {
          if (record == null) return const Center(child: Text('Record not found.'));
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _initializeData(record);
            });
          });

          if (!_isInitialized) return const Center(child: CircularProgressIndicator());

          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _recordType,
              decoration: _inputDecoration('Record Type'),
              items: const [
                DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                DropdownMenuItem(value: 'test_report', child: Text('Test Report')),
                DropdownMenuItem(value: 'vaccination', child: Text('Vaccination')),
                DropdownMenuItem(value: 'doctor_visit', child: Text('Doctor Visit')),
                DropdownMenuItem(value: 'pdf_report', child: Text('PDF Report')),
              ],
              onChanged: (val) => setState(() => _recordType = val ?? 'prescription'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _labelController,
              decoration: _inputDecoration('Prescription Tag / Title'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _doctorController,
              decoration: _inputDecoration('Doctor Name'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _hospitalController,
              decoration: _inputDecoration('Hospital / Clinic Name'),
            ),
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: _inputDecoration('Date').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  ),
                  controller: TextEditingController(
                    text: '${_date.day}/${_date.month}/${_date.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Medicines Section
            const Text('Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_medicines.length, (i) {
                return Chip(
                  label: Text(_medicines[i]),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _medicines.removeAt(i)),
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _medicineInputController,
                    decoration: _inputDecoration('Add medicine...'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_medicineInputController.text.trim().isNotEmpty) {
                      setState(() {
                        _medicines.add(_medicineInputController.text.trim());
                        _medicineInputController.clear();
                      });
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // OCR Text
            TextFormField(
              controller: _ocrTextController,
              maxLines: 5,
              decoration: _inputDecoration('Extracted Text (OCR)'),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: _inputDecoration('Notes'),
            ),
            const SizedBox(height: 32),

            ClinicalButton(
              label: _isSaving ? 'Saving...' : 'Save Changes',
              icon: _isSaving ? null : Icons.save_rounded,
              onPressed: _isSaving ? () {} : _saveRecord,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      labelText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
}
