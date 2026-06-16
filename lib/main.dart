import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app.dart';
import 'core/config/env_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/config/env_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'features/medicine_reminders/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env before any service initialisation.
  await dotenv.load(fileName: '.env');
  // Validate all required keys exist — fails fast with a clear error message.
  EnvConfig.validate();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Enable Firestore offline persistence
        FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);

    // Activate App Check — required to protect Firebase services used by the app.
    // In debug mode we use the debug provider (prints a token to logcat that
    // you register once in the Firebase console under App Check → Apps).
    // In release mode we use Play Integrity (no extra setup required).
    final bool enableAppCheck = dotenv.env['APP_CHECK_ENABLED'] == 'true';
    if (!kIsWeb && enableAppCheck) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
      );
    }
  } catch (e) {
    print('Firebase initialization error (ignored if duplicate-app): $e');
  }

  // Configure Statusbar and Navigation overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Bind portrait configurations for optimal mobile rendering
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) async {
    // Initialize medicine reminder service (adds notifications scheduling support)
    final notifService = LocalNotificationService();
    await notifService.initialize();
    await notifService.requestPermissions();
    final prefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const HealthSathiApp(),
      ),
    );
  });
}
