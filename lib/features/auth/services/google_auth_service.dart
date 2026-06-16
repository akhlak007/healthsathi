import '../repositories/google_auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class GoogleAuthService {
  final GoogleAuthRepository _repository;

  GoogleAuthService(this._repository);

  Future<void> signInWithGoogle() async {
    try {
      final credential = await _repository.signInWithGoogle();
      if (credential == null) {
        throw Exception('Sign in canceled by user');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Firebase Auth failed');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Platform error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }
}
