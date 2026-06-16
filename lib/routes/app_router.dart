import 'package:go_router/go_router.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/profile/screens/profile_setup_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/add_family_member_screen.dart';
import '../features/profile/screens/family_profiles_screen.dart';
import '../features/profile/screens/privacy_security_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/timeline/screens/timeline_screen.dart';
import '../features/upload/screens/upload_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/medicine_reminders/presentation/screens/reminder_center_screen.dart';
import '../features/records/presentation/screens/record_detail_screen.dart';
import '../features/records/presentation/screens/record_edit_screen.dart';
import '../features/chat/screens/ai_chat_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/change_password_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String editProfile = '/edit-profile';
  static const String addFamilyMember = '/add-family-member';
  static const String familyProfiles = '/family-profiles';
  static const String privacySecurity = '/privacy-security';
  static const String home = '/home';
  static const String timeline = '/timeline';
  static const String upload = '/upload';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String reminderCenter = '/reminder-center';
  static const String recordDetail = '/record';
  static const String recordEdit = '/record-edit';
  static const String aiChat = '/ai-chat';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: otp,
        builder: (context, state) => OtpScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: addFamilyMember,
        builder: (context, state) => const AddFamilyMemberScreen(),
      ),
      GoRoute(
        path: privacySecurity,
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
      GoRoute(
        path: familyProfiles,
        builder: (context, state) => const FamilyProfilesScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: timeline,
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: upload,
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: reminderCenter,
        builder: (context, state) => const ReminderCenterScreen(),
      ),
      GoRoute(
        path: '$recordDetail/:recordId',
        builder: (context, state) {
          final recordId = state.pathParameters['recordId'] ?? '';
          return RecordDetailScreen(recordId: recordId);
        },
      ),
      GoRoute(
        path: '$recordEdit/:recordId',
        builder: (context, state) {
          final recordId = state.pathParameters['recordId'] ?? '';
          return RecordEditScreen(recordId: recordId);
        },
      ),
      GoRoute(
        path: aiChat,
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  );
}
