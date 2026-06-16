import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../config/ai_config.dart';

class OpenRouterService {
  static const String _systemPrompt = """
You are HealthSathi AI Assistant.

You are not a doctor.

Your role is to:
- Explain medical reports
- Explain prescriptions
- Explain laboratory values
- Answer health education questions

Rules:
- Never diagnose diseases
- Never prescribe medicine
- Never guarantee medical outcomes
- Encourage consultation with licensed doctors
- Recommend urgent care for serious symptoms

Return only valid JSON with this structure:
{
  "summary": "",
  "key_findings": [],
  "simple_explanation": "",
  "recommendation": ""
}

If structured output fails, return plain text in the "summary" field and keep the other fields safe.
Use simple language and avoid medical jargon where possible.
""";

  Future<Map<String, dynamic>> sendTextMessage(String message) async {
    final messages = [
      {
        'role': 'system',
        'content': [
          {'type': 'text', 'text': _systemPrompt}
        ]
      },
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': message}
        ]
      }
    ];

    return _sendRequest(messages);
  }

  Future<Map<String, dynamic>> sendImageMessage(String imageUrl, String prompt) async {
    final messages = [
      {
        'role': 'system',
        'content': [
          {'type': 'text', 'text': _systemPrompt}
        ]
      },
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {'type': 'image_url', 'image_url': imageUrl}
        ]
      }
    ];

    return _sendRequest(messages);
  }

  Future<Map<String, dynamic>> _sendRequest(List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('${AIConfig.baseUrl}/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AIConfig.apiKey}',
      'HTTP-Referer': 'https://healthsathi.app', // Required by OpenRouter for CORS
      'X-Title': 'HealthSathi', // Required by OpenRouter for CORS
    };

    final body = {
      'model': AIConfig.model,
      'messages': messages,
      'temperature': 0.2,
      'max_tokens': 1024,
      'top_p': 0.95,
    };

    Exception? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('[OpenRouter] Attempt ${attempt + 1}/3: Connecting to ${url.host}');
        
        final response = await http
            .post(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30));

        print('[OpenRouter] Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = data['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) {
            throw Exception('AI returned no response. Please try again.');
          }

          final firstChoice = choices.first as Map<String, dynamic>;
          final message = firstChoice['message'] as Map<String, dynamic>?;
          final rawContent = message?['content'];
          final contentText = _extractText(rawContent);

          String cleanedText = contentText.trim();
          if (cleanedText.startsWith('```json')) {
            cleanedText = cleanedText.substring(7);
          } else if (cleanedText.startsWith('```')) {
            cleanedText = cleanedText.substring(3);
          }
          if (cleanedText.endsWith('```')) {
            cleanedText = cleanedText.substring(0, cleanedText.length - 3);
          }
          cleanedText = cleanedText.trim();

          try {
            final parsed = jsonDecode(cleanedText) as Map<String, dynamic>;
            return _normalizeResponse(parsed, contentText);
          } catch (_) {
            return _normalizeResponse({
              'summary': contentText,
              'key_findings': <String>[],
              'simple_explanation': contentText,
              'recommendation': 'Please consult a licensed doctor for medical advice.',
            }, contentText);
          }
        } else if (response.statusCode == 401) {
          throw Exception('API key is invalid or expired. Please check your OpenRouter account.');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please wait and try again in a few moments.');
        } else if (response.statusCode >= 500) {
          throw Exception('OpenRouter server error (${response.statusCode}). Try again in a moment.');
        } else {
          final errorBody = response.body;
          print('[OpenRouter] Error response: $errorBody');
          lastError = Exception('OpenRouter API error ${response.statusCode}: $errorBody');
        }
      } on SocketException catch (e) {
        print('[OpenRouter] Socket error (attempt ${attempt + 1}): ${e.message}');
        lastError = Exception('Network connection failed: ${e.message}. Check your internet connection.');
      } on http.ClientException catch (e) {
        print('[OpenRouter] Client error (attempt ${attempt + 1}): ${e.message}');
        lastError = Exception('Connection error: ${e.message}');
      } on TimeoutException {
        print('[OpenRouter] Timeout (attempt ${attempt + 1})');
        lastError = Exception('Request timed out (30s). Your network may be slow or the service is unreachable.');
      } catch (e) {
        print('[OpenRouter] Unexpected error (attempt ${attempt + 1}): $e');
        lastError = e is Exception ? e : Exception(e.toString());
      }

      if (attempt < 2) {
        final delaySeconds = (attempt + 1) * 2; // 2s, 4s backoff
        print('[OpenRouter] Retrying in ${delaySeconds}s...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    print('[OpenRouter] All retries exhausted. Final error: $lastError');
    throw lastError ?? Exception('Unknown error occurred');
  }

  String _extractText(dynamic rawContent) {
    if (rawContent is String) {
      return rawContent;
    }
    if (rawContent is List) {
      for (final element in rawContent) {
        if (element is Map<String, dynamic> && element['type'] == 'text' && element['text'] is String) {
          return element['text'] as String;
        }
      }
    }
    if (rawContent is Map<String, dynamic> && rawContent['text'] is String) {
      return rawContent['text'] as String;
    }
    return '';
  }

  Map<String, dynamic> _normalizeResponse(Map<String, dynamic> parsed, String rawText) {
    return {
      'summary': parsed['summary']?.toString() ?? rawText,
      'key_findings': parsed['key_findings'] is List
          ? List<String>.from(parsed['key_findings'])
          : parsed['key_points'] is List
              ? List<String>.from(parsed['key_points'])
              : <String>[],
      'simple_explanation': parsed['simple_explanation']?.toString() ?? rawText,
      'recommendation': parsed['recommendation']?.toString() ?? 'Please consult a licensed doctor for medical advice.',
      'possible_meaning': parsed['possible_meaning']?.toString() ?? '',
      'raw_text': rawText,
    };
  }

  /// Diagnostic method to test connection to OpenRouter API
  Future<String> testConnection() async {
    try {
      print('[OpenRouter] Testing connection to ${AIConfig.baseUrl}...');
      
      // Try a simple HEAD request first
      final url = Uri.parse(AIConfig.baseUrl);
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${AIConfig.apiKey}',
          'HTTP-Referer': 'https://healthsathi.app',
          'X-Title': 'HealthSathi',
        },
      ).timeout(const Duration(seconds: 10));

      print('[OpenRouter] Test connection status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 404 || response.statusCode == 401) {
        return '✅ Connection successful! API is reachable (status: ${response.statusCode})';
      } else if (response.statusCode == 429) {
        return '⚠️ Rate limited. Wait a moment and try again.';
      } else {
        return '❌ Server error (${response.statusCode}). Try again later.';
      }
    } on SocketException catch (e) {
      return '❌ DNS/Network error: ${e.message}\n\nMake sure:\n- You have internet\n- No VPN/firewall blocking api.openrouter.ai\n- Try restarting your network';
    } on TimeoutException {
      return '❌ Connection timeout (10s). Network is too slow or server unreachable.';
    } on http.ClientException catch (e) {
      return '❌ Connection failed: ${e.message}';
    } catch (e) {
      return '❌ Test failed: $e';
    }
  }
}
