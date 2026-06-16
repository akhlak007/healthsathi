import '../core/config/env_config.dart';

/// Configuration for the Cloudinary media storage service.
///
/// Values are loaded from the .env file via [EnvConfig].
/// Do NOT hardcode secrets here.
class CloudinaryConfig {
  static String get cloudName => EnvConfig.cloudinaryCloudName;
  static String get uploadPreset => EnvConfig.cloudinaryUploadPreset;
  static String get folder => EnvConfig.cloudinaryFolder;
}
