import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../data/services/gemini_service.dart';
import '../domain/models/chat_message.dart';
import '../../profile/providers/active_profile_provider.dart';
import '../../../core/services/cloudinary_service.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  final OpenRouterService _openRouter = OpenRouterService();
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
      final response = await _openRouter.sendTextMessage(text);
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
      // Mark error on placeholder with user-friendly message
      String errorMessage = _formatErrorMessage(e.toString());
      final errMsg = ChatMessage(
        id: userDoc.id,
        text: errorMessage,
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
    final Uint8List bytes = await picked.readAsBytes();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

    print('[Cloudinary] Preparing to upload chat image: $fileName');
    final cloudinary = CloudinaryService();

    String? downloadUrl;
    try {
      downloadUrl = await cloudinary.uploadFile(
        bytes: bytes,
        fileName: fileName,
        isPdf: false,
      );
      print('[Cloudinary] Chat image upload successful. URL: $downloadUrl');
    } catch (e) {
      print('[Cloudinary Error] Failed to upload chat image: $e');

      final errMsg = ChatMessage(
        id: '',
        text: 'Error uploading image. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        hasError: true,
      );
      state = [...state, errMsg];
      await _chatCollection.add(errMsg.toMap());
      return;
    }

    if (downloadUrl == null) {
      final errMsg = ChatMessage(
        id: '',
        text: 'Error uploading image. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        hasError: true,
      );
      state = [...state, errMsg];
      await _chatCollection.add(errMsg.toMap());
      return;
    }

    final userMsg = ChatMessage(
      id: '',
      text: '',
      imageUrl: downloadUrl,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];
    final userDoc = await _chatCollection.add(userMsg.toMap());

    final loadingMsg = ChatMessage(
      id: '',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [...state, loadingMsg];

    try {
      final response = await _openRouter.sendImageMessage(
        downloadUrl,
        'Please analyze this medical image and explain the visible medical findings.',
      );
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
        imageUrl: downloadUrl,
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

  String _formatErrorMessage(String errorText) {
    // Parse error and provide user-friendly messages
    if (errorText.contains('No internet connection') || errorText.contains('Failed host lookup')) {
      return '🌐 Connection Error\n\nPlease check your internet connection and try again.';
    } else if (errorText.contains('API key is invalid')) {
      return '🔑 Configuration Error\n\nAPI key is invalid. Please contact support.';
    } else if (errorText.contains('Rate limit exceeded')) {
      return '⏱️ Rate Limited\n\nToo many requests. Please wait a moment and try again.';
    } else if (errorText.contains('timed out')) {
      return '⏳ Slow Network\n\nRequest took too long. Please check your connection and try again.';
    } else if (errorText.contains('Connection error')) {
      return '🔌 Connection Problem\n\nCouldn\'t connect to the server. Try again later.';
    } else {
      return '⚠️ Error\n\nSomething went wrong. Please try again.';
    }
  }
}
