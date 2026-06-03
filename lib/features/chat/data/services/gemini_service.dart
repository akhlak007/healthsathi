import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/gemini_config.dart';

class GeminiService {
  static const String _systemPrompt = """
You are HealthSathi AI Assistant.

You are not a doctor.

Your role is to:
- Explain medical reports in simple language
- Explain prescriptions and lab results
- Answer general health education questions

Rules:
- Never diagnose diseases
- Never prescribe medicine
- Never give emergency certainty
- Always suggest consulting a licensed doctor
- If symptoms seem serious, recommend urgent medical care
""";

  final Map<String, dynamic> _generationConfig = {
    "temperature": 0.2,
    "response_mime_type": "application/json",
    "response_schema": {
      "type": "OBJECT",
      "properties": {
        "summary": {"type": "STRING"},
        "key_points": {
          "type": "ARRAY",
          "items": {"type": "STRING"}
        },
        "simple_explanation": {"type": "STRING"},
        "possible_meaning": {"type": "STRING"},
        "recommendation": {"type": "STRING"}
      },
      "required": ["summary", "key_points", "simple_explanation", "possible_meaning", "recommendation"]
    }
  };

  final Map<String, dynamic> _systemInstruction = {
    "parts": [
      {"text": _systemPrompt}
    ]
  };

  Future<Map<String, dynamic>> sendTextMessage(String message) async {
    return _sendRequest({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": message}
          ]
        }
      ],
      "system_instruction": _systemInstruction,
      "generationConfig": _generationConfig
    });
  }

  Future<Map<String, dynamic>> sendImageMessage(String base64Image, String prompt, String mimeType) async {
    return _sendRequest({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": mimeType,
                "data": base64Image
              }
            }
          ]
        }
      ],
      "system_instruction": _systemInstruction,
      "generationConfig": _generationConfig
    });
  }

  Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> body) async {
    final url = Uri.parse('${GeminiConfig.baseUrl}/gemini-2.0-flash:generateContent?key=${GeminiConfig.apiKey}');
    
    Exception? lastError;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            throw Exception('AI returned no response. Please try again.');
          }
          final contentText = candidates[0]['content']['parts'][0]['text'];
          // Try to parse as structured JSON
          try {
            return jsonDecode(contentText) as Map<String, dynamic>;
          } catch (_) {
            // Fallback: return the raw text as summary
            return {
              'summary': contentText,
              'key_points': <String>[],
              'simple_explanation': contentText,
              'possible_meaning': '',
              'recommendation': 'Please consult a licensed doctor for medical advice.',
            };
          }
        } else {
          final errorBody = response.body;
          lastError = Exception('API error ${response.statusCode}: $errorBody');
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
      if (attempt < 1) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ?? Exception('Unknown error occurred');
  }
}
