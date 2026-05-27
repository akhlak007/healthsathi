import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/widgets/clinical_widgets.dart';

class FamilyProfilesScreen extends ConsumerStatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  ConsumerState<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends ConsumerState<FamilyProfilesScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> _familyProfiles = [];
  String _userName = 'User';
  String _profileImageUrl = 'default';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? 'User';
          _profileImageUrl = data['profileImage'] ?? 'default';
          if (data['familyProfiles'] != null) {
            _familyProfiles = List<Map<String, dynamic>>.from(data['familyProfiles']);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMember(Map<String, dynamic> member) async {
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to remove ${member['name']}?'),
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
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'familyProfiles': FieldValue.arrayRemove([member]),
        });
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member['name']} removed successfully'),
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
    final avatarImage = _profileImageUrl == 'default'
        ? NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(_userName)}&background=003D9B&color=fff')
        : (_profileImageUrl.startsWith('data:')
            ? MemoryImage(base64Decode(_profileImageUrl.split(',').last)) as ImageProvider
            : NetworkImage(_profileImageUrl));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: avatarImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'e HealthSathi',
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
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF334155),
              size: 26,
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF334155),
              size: 28,
            ),
            onPressed: () {
               context.go('/home');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEFF2FE), height: 1.0),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF003D9B)))
        : SingleChildScrollView(
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
                    context.push('/add-family-member').then((_) => _loadData());
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
                if (_familyProfiles.isEmpty)
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
                  ..._familyProfiles.asMap().entries.map((entry) {
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
          ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 4),
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> member) {
    final name = member['name'] ?? 'Unknown';
    final relation = member['relation'] ?? 'Relative';
    final imageUrl = member['imageUrl'];
    
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

    // Build detail rows based on relation
    List<Widget> details = [];
    if (relationLower.contains('spouse') || relationLower.contains('wife') || relationLower.contains('husband')) {
      details = [
        _buildDetailRow(Icons.calendar_today_rounded, 'Last checkup: Oct 12, 2023', const Color(0xFF64748B)),
        const SizedBox(height: 6),
        _buildDetailRow(Icons.vaccines_outlined, 'Up to date on vaccinations', const Color(0xFF64748B)),
      ];
    } else if (relationLower.contains('son') || relationLower.contains('child') || relationLower.contains('daughter')) {
      details = [
        _buildDetailRow(Icons.calendar_today_rounded, 'Last checkup: Nov 05, 2023', const Color(0xFF64748B)),
        const SizedBox(height: 6),
        _buildDetailRow(Icons.warning_amber_rounded, 'Allergy: Peanuts', const Color(0xFFDC2626), iconColor: const Color(0xFFDC2626)),
      ];
    } else if (relationLower.contains('mother') || relationLower.contains('father') || relationLower.contains('parent')) {
      details = [
        _buildDetailRow(Icons.monitor_heart_outlined, 'Vitals: Blood Pressure Stable', const Color(0xFF64748B)),
        const SizedBox(height: 6),
        _buildDetailRow(Icons.medication_outlined, 'Daily meds tracked', const Color(0xFF64748B)),
      ];
    } else {
      details = [
        _buildDetailRow(Icons.calendar_today_rounded, 'No recent checkup', const Color(0xFF94A3B8)),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD8F0), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D9B).withValues(alpha: 0.04),
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
                  if (value == 'delete') {
                    _deleteMember(member);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 10),
                        Text('View Records', style: TextStyle(fontFamily: 'Inter', fontSize: 13.5)),
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
          
          // Details
          ...details,
          const SizedBox(height: 18),
          
          // View Records Button
          Center(
            child: SizedBox(
              width: 180,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text(
                  'View Records',
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

    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
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
