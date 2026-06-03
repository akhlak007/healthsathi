import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../family/domain/entities/family_profile.dart';
import '../../family/data/models/family_profile_model.dart';

final familyProfilesStreamProvider = StreamProvider.autoDispose<List<FamilyProfile>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('familyProfiles')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => FamilyProfileModel.fromJson(doc.data()))
          .toList());
});

class FamilyProfilesScreen extends ConsumerStatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  ConsumerState<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends ConsumerState<FamilyProfilesScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _deleteMember(FamilyProfile member) async {
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to remove ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('familyProfiles')
            .doc(member.profileId)
            .delete();
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} removed successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyProfilesAsync = ref.watch(familyProfilesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            const Text(
              'Family Members',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF003D9B),
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 26),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEFF2FE), height: 1.0),
        ),
      ),
      body: familyProfilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF003D9B))),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load family members.', style: TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 8),
              Text(err.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        data: (profiles) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section
                const Text(
                  'Family Profiles',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage and access health records for your family members in one place.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Add Family Member Dashed Button
                GestureDetector(
                  onTap: () {
                    context.push('/add-family-member');
                  },
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: const Color(0xFFB0C4DE),
                      strokeWidth: 1.5,
                      gap: 6,
                    ),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0052CC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Add Family Member',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0052CC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Family Profiles List
                if (profiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.family_restroom_rounded, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'No family members added yet.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap above to add your first member.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFB0BEC5),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...profiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 350 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildFamilyCard(member),
                      ),
                    );
                  }),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 4),
    );
  }

  Widget _buildFamilyCard(FamilyProfile member) {
    final name = member.name;
    final relation = member.relationship;
    final imageUrl = member.photoUrl;

    ImageProvider? imageProvider;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:')) {
        imageProvider = MemoryImage(base64Decode(imageUrl.split(',').last));
      } else {
        imageProvider = NetworkImage(imageUrl);
      }
    }

    // Relation badge color
    Color pillBg;
    Color pillText;
    final relationLower = relation.toLowerCase();

    if (relationLower.contains('spouse') || relationLower.contains('wife') || relationLower.contains('husband')) {
      pillBg = const Color(0xFFD1FAE5);
      pillText = const Color(0xFF059669);
    } else if (relationLower.contains('son') || relationLower.contains('daughter') || relationLower.contains('child')) {
      pillBg = const Color(0xFFDBEAFE);
      pillText = const Color(0xFF2563EB);
    } else if (relationLower.contains('mother') || relationLower.contains('father') || relationLower.contains('parent')) {
      pillBg = const Color(0xFFFCE7F3);
      pillText = const Color(0xFFDB2777);
    } else if (relationLower.contains('brother') || relationLower.contains('sister') || relationLower.contains('sibling')) {
      pillBg = const Color(0xFFFEF3C7);
      pillText = const Color(0xFFD97706);
    } else {
      pillBg = const Color(0xFFE0E7FF);
      pillText = const Color(0xFF4338CA);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD8F0), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D9B).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5EDFF),
                  border: Border.all(color: const Color(0xFFCBD8F0), width: 2),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: imageProvider == null
                    ? const Center(child: Icon(Icons.person_rounded, color: Color(0xFF003D9B), size: 26))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        relation,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: pillText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Three dot menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 8,
                offset: const Offset(0, 40),
                onSelected: (value) {
                  if (value == 'edit') {
                    // Navigate to edit family member screen
                    // context.push('/edit-family-member', extra: member);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit member feature coming soon')),
                    );
                  } else if (value == 'delete') {
                    _deleteMember(member);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                         Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                         SizedBox(width: 10),
                         Text('Edit Member', style: TextStyle(fontFamily: 'Inter', fontSize: 13.5)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text('Remove', style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 14),
          
          // Details (Blood Group)
          _buildDetailRow(Icons.water_drop_outlined, 'Blood Group: ${member.bloodGroup}', const Color(0xFF64748B), iconColor: const Color(0xFF1E3A8A)),
          
          const SizedBox(height: 18),
          
          // Switch to Profile (disabled for now as per instructions)
          /*
          Center(
            child: SizedBox(
              width: 180,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.switch_account_outlined, size: 16),
                label: const Text(
                  'Switch to Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0052CC),
                  side: const BorderSide(color: Color(0xFF0052CC), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                ),
              ),
            ),
          ),
          */
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color color, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor ?? const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({this.color = Colors.black, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ));

    var pathMetrics = path.computeMetrics();
    for (var pathMetric in pathMetrics) {
      double extractPathLength = 0.0;
      while (extractPathLength < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(extractPathLength, extractPathLength + gap),
          paint,
        );
        extractPathLength += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
