import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../../upload/domain/entities/ocr_record.dart';
import '../../../profile/providers/active_profile_provider.dart';

final recordDetailProvider = StreamProvider.family<OcrRecord?, String>((ref, recordId) {
  final user = FirebaseAuth.instance.currentUser;
  final activeProfileId = ref.watch(activeProfileProvider);
  if (user == null) return const Stream.empty();

  final collectionRef = activeProfileId == 'self'
      ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('records')
      : FirebaseFirestore.instance.collection('users').doc(user.uid).collection('familyProfiles').doc(activeProfileId).collection('records');

  return collectionRef
      .doc(recordId)
      .snapshots()
      .map((doc) => doc.exists ? OcrRecord.fromJson(doc.data()!, doc.id) : null);
});

class RecordDetailScreen extends ConsumerWidget {
  final String recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(recordDetailProvider(recordId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/timeline');
            }
          },
        ),
        title: const Text('Record Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            onPressed: () => context.push('/record-edit/$recordId'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading record: $err')),
        data: (record) {
          if (record == null) {
            return const Center(child: Text('Record not found or was deleted.'));
          }
          return _buildDetailContent(context, record);
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, OcrRecord record) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / PDF preview
          if (record.imageUrl != null && record.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: record.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 48, color: AppColors.outline),
                ),
              ),
            ),
          
          if (record.pdfUrl != null && record.pdfUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => _openExternalUrl(context, record.pdfUrl!),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.orange),
                    SizedBox(height: 8),
                    Text('PDF Document Attached', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClinicalBadge(
                label: record.recordType.toUpperCase(),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                textColor: AppColors.primary,
              ),
              Text(
                DateFormat('dd MMM yyyy').format(record.date),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.outline),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Metadata Card
          MedicalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person_rounded, 'Doctor', record.doctorName.isNotEmpty ? record.doctorName : 'N/A'),
                const Divider(height: 24),
                _buildInfoRow(Icons.local_hospital_rounded, 'Hospital/Clinic', record.hospitalName.isNotEmpty ? record.hospitalName : 'N/A'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Medicines
          if (record.medicines.isNotEmpty) ...[
            const Text('Prescribed Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: record.medicines.map((m) => Chip(
                label: Text(m, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.secondary.withOpacity(0.08),
                side: BorderSide.none,
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Notes
          if (record.notes.isNotEmpty) ...[
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            MedicalCard(
              backgroundColor: Colors.yellow.shade50,
              child: Text(
                record.notes,
                style: const TextStyle(height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.outline)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text('This will permanently delete this record from your timeline.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      final activeProfileId = ref.read(activeProfileProvider);
      if (user != null) {
        final collectionRef = activeProfileId == 'self'
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('records')
            : FirebaseFirestore.instance.collection('users').doc(user.uid).collection('familyProfiles').doc(activeProfileId).collection('records');
            
        await collectionRef.doc(recordId).delete();
        if (context.mounted) {
          context.pop();
        }
      }
    }
  }
}
