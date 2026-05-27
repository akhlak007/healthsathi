import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthState {
  final bool isBiometricAvailable;
  final bool isAuthenticated;
  final String errorMessage;
  final bool isSupported;
  final List<BiometricType> availableBiometrics;

  LocalAuthState({
    required this.isBiometricAvailable,
    required this.isAuthenticated,
    required this.errorMessage,
    required this.isSupported,
    required this.availableBiometrics,
  });

  LocalAuthState copyWith({
    bool? isBiometricAvailable,
    bool? isAuthenticated,
    String? errorMessage,
    bool? isSupported,
    List<BiometricType>? availableBiometrics,
  }) {
    return LocalAuthState(
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage ?? this.errorMessage,
      isSupported: isSupported ?? this.isSupported,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
    );
  }
}

class LocalAuthNotifier extends StateNotifier<LocalAuthState> {
  final LocalAuthentication _auth = LocalAuthentication();

  LocalAuthNotifier()
      : super(LocalAuthState(
          isBiometricAvailable: false,
          isAuthenticated: false,
          errorMessage: '',
          isSupported: false,
          availableBiometrics: [],
        )) {
    checkBiometrics();
  }

  Future<void> checkBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      List<BiometricType> availableBiometrics = [];
      if (canCheckBiometrics) {
        availableBiometrics = await _auth.getAvailableBiometrics();
      }
      
      state = state.copyWith(
        isSupported: isSupported,
        isBiometricAvailable: canCheckBiometrics && availableBiometrics.isNotEmpty,
        availableBiometrics: availableBiometrics,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      state = state.copyWith(errorMessage: '', isAuthenticated: false);
      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
      state = state.copyWith(isAuthenticated: didAuthenticate);
      return didAuthenticate;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isAuthenticated: false);
      return false;
    }
  }

  void lockApp() {
    state = state.copyWith(isAuthenticated: false);
  }
}

final localAuthProvider = StateNotifierProvider<LocalAuthNotifier, LocalAuthState>((ref) {
  return LocalAuthNotifier();
});
