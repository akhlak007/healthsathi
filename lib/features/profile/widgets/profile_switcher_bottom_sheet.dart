import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/active_profile_provider.dart';

class ProfileSwitcherBottomSheet extends ConsumerWidget {
  const ProfileSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfileId = ref.watch(activeProfileProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const SizedBox();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Switch Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Self Profile
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, snapshot) {
              String name = 'Self';
              String profileImageUrl = 'default';
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['name'] ?? data['fullName'] ?? 'Self';
                profileImageUrl = data['profileImage'] ?? 'default';
              }
              
              return _buildProfileItem(
                context: context,
                ref: ref,
                profileId: 'self',
                name: '$name (Self)',
                imageUrl: profileImageUrl,
                isActive: activeProfileId == 'self',
              );
            }
          ),

          // Family Profiles Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('familyProfiles')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              final profiles = snapshot.data!.docs;
              return Column(
                children: profiles.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Family Member';
                  final relation = data['relationship'] ?? '';
                  final imageUrl = data['photoUrl'];
                  final profileId = doc.id;
                  
                  return _buildProfileItem(
                    context: context,
                    ref: ref,
                    profileId: profileId,
                    name: '$name ($relation)',
                    imageUrl: imageUrl,
                    isActive: activeProfileId == profileId,
                  );
                }).toList(),
              );
            },
          ),
          
          const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
          
          // Add Family Member
          InkWell(
            onTap: () {
              Navigator.pop(context);
              context.push('/add-family-member');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Add Family Member',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required BuildContext context,
    required WidgetRef ref,
    required String profileId,
    required String name,
    required String? imageUrl,
    required bool isActive,
  }) {
    ImageProvider? imageProvider;
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'default') {
      if (imageUrl.startsWith('data:')) {
        imageProvider = MemoryImage(base64Decode(imageUrl.split(',').last));
      } else {
        imageProvider = NetworkImage(imageUrl);
      }
    } else {
       imageProvider = NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=003D9B&color=fff');
    }

    return InkWell(
      onTap: () {
        ref.read(activeProfileProvider.notifier).setActiveProfile(profileId);
        Navigator.pop(context);
      },
      child: Container(
        color: isActive ? const Color(0xFFF0F5FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: isActive ? const Color(0xFF003D9B) : const Color(0xFFE2E8F0),
                  width: isActive ? 2 : 1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF003D9B) : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF003D9B), size: 24),
          ],
        ),
      ),
    );
  }
}

void showProfileSwitcher(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ProfileSwitcherBottomSheet(),
  );
}
