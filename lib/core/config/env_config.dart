import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access point for all environment-variable-backed configuration.
///
/// Call [EnvConfig.validate] once during app startup (after dotenv is loaded)
/// to catch missing variables early with a clear error message.
class EnvConfig {
  EnvConfig._(); // prevent instantiation

  // ─── OpenRouter AI ───────────────────────────────────────────────────────────

  static String get openRouterApiKey =>
      _require('OPENROUTER_API_KEY');

  static String get openRouterBaseUrl =>
      _require('OPENROUTER_BASE_URL');

  static String get openRouterModel =>
      _require('OPENROUTER_MODEL');

  // ─── Cloudinary ──────────────────────────────────────────────────────────────

  static String get cloudinaryCloudName =>
      _require('CLOUDINARY_CLOUD_NAME');

  static String get cloudinaryUploadPreset =>
      _require('CLOUDINARY_UPLOAD_PRESET');

  static String get cloudinaryFolder =>
      _require('CLOUDINARY_FOLDER');

  // ─── Validation ──────────────────────────────────────────────────────────────

  /// List of every key the app requires. Add new keys here as the project grows.
  static const List<String> _requiredKeys = [
    'OPENROUTER_API_KEY',
    'OPENROUTER_BASE_URL',
    'OPENROUTER_MODEL',
    'CLOUDINARY_CLOUD_NAME',
    'CLOUDINARY_UPLOAD_PRESET',
    'CLOUDINARY_FOLDER',
  ];

  /// Validates that all required environment variables are present.
  ///
  /// Call this once after [dotenv.load] in [main]. In debug mode, prints a
  /// descriptive error for each missing key and throws a [StateError] so the
  /// developer can fix the problem immediately. In release mode, missing keys
  /// still throw to prevent silent failures in production.
  static void validate() {
    final missing = _requiredKeys
        .where((key) => (dotenv.env[key] ?? '').trim().isEmpty)
        .toList();

    if (missing.isEmpty) return;

    final message =
        '[EnvConfig] ❌ Missing required environment variable(s): '
        '${missing.join(', ')}. '
        'Make sure your .env file exists at the project root and contains '
        'all keys listed in .env.example.';

    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
    throw StateError(message);
  }

  // ─── Internal helper ─────────────────────────────────────────────────────────

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) {
      final message =
          '[EnvConfig] ❌ Required environment variable "$key" is not set. '
          'Check your .env file.';
      if (kDebugMode) {
        // ignore: avoid_print
        print(message);
      }
      throw StateError(message);
    }
    return value;
  }
}
