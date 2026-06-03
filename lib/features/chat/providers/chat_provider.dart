import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../data/services/gemini_service.dart';
import '../domain/models/chat_message.dart';
import '../../profile/providers/active_profile_provider.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  final GeminiService _gemini = GeminiService();
  final ImagePicker _picker = ImagePicker();

  ChatNotifier(this.ref) : super([]);

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _activeProfileId => ref.read(activeProfileProvider);
  CollectionReference get _chatCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('familyProfiles')
      .doc(_activeProfileId)
      .collection('chats');

  Future<void> loadHistory() async {
    final snapshot = await _chatCollection.orderBy('timestamp', descending: false).get();
    state = snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> sendText(String text) async {
    // Add user message locally and to Firestore
    final userMsg = ChatMessage(
      id: '',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];
    final userDoc = await _chatCollection.add(userMsg.toMap());

    // Optimistically add a loading AI placeholder
    final loadingMsg = ChatMessage(
      id: '',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [...state, loadingMsg];

    try {
      final response = await _gemini.sendTextMessage(text);
      final aiMsg = ChatMessage(
        id: userDoc.id,
        text: response['summary'] ?? '',
        isUser: false,
        timestamp: DateTime.now(),
        summary: response['summary'],
        keyPoints: List<String>.from(response['key_points'] ?? []),
        simpleExplanation: response['simple_explanation'],
        possibleMeaning: response['possible_meaning'],
        recommendation: response['recommendation'],
      );
      // Replace loading placeholder
      final newList = List<ChatMessage>.from(state);
      newList.removeLast();
      newList.add(aiMsg);
      state = newList;
      await _chatCollection.doc(aiMsg.id).set(aiMsg.toMap());
    } catch (e) {
      // Mark error on placeholder
      final errMsg = ChatMessage(
        id: userDoc.id,
        text: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        hasError: true,
      );
      final newList = List<ChatMessage>.from(state);
      newList.removeLast();
      newList.add(errMsg);
      state = newList;
      await _chatCollection.doc(errMsg.id).set(errMsg.toMap());
    }
  }

  Future<void> sendImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final File file = File(picked.path);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _lookupMimeType(picked.path);

    // Upload original image to Firebase Storage for future reference
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('users/$_uid/$_activeProfileId/chat_images/${DateTime.now().millisecondsSinceEpoch}.png');
    final uploadTask = await storageRef.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Add user message with image
    final userMsg = ChatMessage(
      id: '',
      text: '',
      imageUrl: downloadUrl,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];
    final userDoc = await _chatCollection.add(userMsg.toMap());

    // Loading placeholder
    final loadingMsg = ChatMessage(
      id: '',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [...state, loadingMsg];

    try {
      final response = await _gemini.sendImageMessage(base64Image, 'Explain this medical image', mimeType);
      final aiMsg = ChatMessage(
        id: userDoc.id,
        text: response['summary'] ?? '',
        isUser: false,
        timestamp: DateTime.now(),
        summary: response['summary'],
        keyPoints: List<String>.from(response['key_points'] ?? []),
        simpleExplanation: response['simple_explanation'],
        possibleMeaning: response['possible_meaning'],
        recommendation: response['recommendation'],
        imageUrl: downloadUrl, // keep reference to original image
      );
      final newList = List<ChatMessage>.from(state);
      newList.removeLast();
      newList.add(aiMsg);
      state = newList;
      await _chatCollection.doc(aiMsg.id).set(aiMsg.toMap());
    } catch (e) {
      final errMsg = ChatMessage(
        id: userDoc.id,
        text: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        hasError: true,
      );
      final newList = List<ChatMessage>.from(state);
      newList.removeLast();
      newList.add(errMsg);
      state = newList;
      await _chatCollection.doc(errMsg.id).set(errMsg.toMap());
    }
  }

  String _lookupMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}
