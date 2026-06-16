import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/google_auth_repository.dart';
import '../services/google_auth_service.dart';

final googleAuthRepositoryProvider = Provider<GoogleAuthRepository>((ref) {
  return GoogleAuthRepository();
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final repository = ref.watch(googleAuthRepositoryProvider);
  return GoogleAuthService(repository);
});

class GoogleAuthNotifier extends StateNotifier<AsyncValue<void>> {
  final GoogleAuthService _service;

  GoogleAuthNotifier(this._service) : super(const AsyncData(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await _service.signInWithGoogle();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final googleAuthProvider = StateNotifierProvider<GoogleAuthNotifier, AsyncValue<void>>((ref) {
  return GoogleAuthNotifier(ref.watch(googleAuthServiceProvider));
});
