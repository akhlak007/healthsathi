import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/medicine_reminder_model.dart';
import '../../domain/enums/reminder_type.dart';
import '../../providers/medicine_reminder_provider.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final MedicineReminderModel? existingReminder;
  final String? initialMedicineName;
  final String? initialDosage;

  const AddReminderScreen({
    super.key,
    this.existingReminder,
    this.initialMedicineName,
    this.initialDosage,
  });

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionController;
  
  ReminderType _selectedType = ReminderType.medicine;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  List<TimeOfDay> _reminderTimes = [];
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final rem = widget.existingReminder;
    _nameController = TextEditingController(text: rem?.medicineName ?? widget.initialMedicineName ?? '');
    _dosageController = TextEditingController(text: rem?.dosage ?? widget.initialDosage ?? '');
    _instructionController = TextEditingController(text: rem?.instruction ?? '');
    
    if (rem != null) {
      _selectedType = rem.type;
      _startDate = rem.startDate;
      _endDate = rem.endDate;
      _isActive = rem.isActive;
      _reminderTimes = rem.times.map((t) => _parseTimeOfDay(t)).whereType<TimeOfDay>().toList();
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
      else if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      if (_reminderTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This time is already added.')),
        );
        return;
      }
      setState(() {
        _reminderTimes.add(picked);
        _reminderTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  void _saveReminder() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time.')),
      );
      return;
    }

    final newReminder = MedicineReminderModel(
      id: widget.existingReminder?.id ?? const Uuid().v4(),
      medicineName: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      instruction: _instructionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      times: _reminderTimes.map((t) => _formatTimeOfDay(t)).toList(),
      isActive: _isActive,
      createdAt: widget.existingReminder?.createdAt ?? DateTime.now(),
      type: _selectedType,
    );

    final notifier = ref.read(medicineReminderNotifierProvider.notifier);
    if (widget.existingReminder != null) {
      notifier.updateReminder(newReminder);
    } else {
      notifier.addReminder(newReminder);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingReminder == null ? 'Add Reminder' : 'Edit Reminder', 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<ReminderType>(
              value: _selectedType,
              decoration: _inputDecoration('Reminder Type'),
              items: ReminderType.values.map((e) {
                return DropdownMenuItem(value: e, child: Text(e.displayName));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Name (Medicine/Appointment)'),
              validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: _inputDecoration('Dosage (e.g., 1 Tablet)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionController,
              decoration: _inputDecoration('Instructions (e.g., After Meal)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onBackground)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration('Start Date'),
                      child: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration('End Date'),
                      child: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reminder Times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onBackground)),
                TextButton.icon(
                  onPressed: _pickReminderTime,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Time'),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (_reminderTimes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No times added yet', style: TextStyle(color: AppColors.outline))),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reminderTimes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final time = entry.value;
                  return Chip(
                    label: Text(_formatTimeOfDay(time), style: const TextStyle(fontWeight: FontWeight.bold)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _reminderTimes.removeAt(idx)),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  );
                }).toList(),
              ),
              
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Is Active', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Turn off to pause reminders'),
              value: _isActive,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _isActive = val),
              contentPadding: EdgeInsets.zero,
            ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
