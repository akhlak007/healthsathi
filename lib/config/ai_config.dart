import '../core/config/env_config.dart';

/// Configuration for the OpenRouter AI API.
///
/// Values are loaded from the .env file via [EnvConfig].
/// Do NOT hardcode secrets here.
class AIConfig {
  static String get apiKey => EnvConfig.openRouterApiKey;
  static String get baseUrl => EnvConfig.openRouterBaseUrl;
  static String get model => EnvConfig.openRouterModel;
}
