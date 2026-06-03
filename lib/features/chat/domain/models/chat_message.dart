import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String? imageUrl;
  final bool isUser;
  final DateTime timestamp;
  
  // Structured AI response fields
  final String? summary;
  final List<String>? keyPoints;
  final String? simpleExplanation;
  final String? possibleMeaning;
  final String? recommendation;
  
  final bool hasError;

  ChatMessage({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.isUser,
    required this.timestamp,
    this.summary,
    this.keyPoints,
    this.simpleExplanation,
    this.possibleMeaning,
    this.recommendation,
    this.hasError = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      isUser: map['isUser'] ?? true,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      summary: map['summary'],
      keyPoints: map['keyPoints'] != null ? List<String>.from(map['keyPoints']) : null,
      simpleExplanation: map['simpleExplanation'],
      possibleMeaning: map['possibleMeaning'],
      recommendation: map['recommendation'],
      hasError: map['hasError'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      if (summary != null) 'summary': summary,
      if (keyPoints != null) 'keyPoints': keyPoints,
      if (simpleExplanation != null) 'simpleExplanation': simpleExplanation,
      if (possibleMeaning != null) 'possibleMeaning': possibleMeaning,
      if (recommendation != null) 'recommendation': recommendation,
      if (hasError) 'hasError': hasError,
    };
  }
}
