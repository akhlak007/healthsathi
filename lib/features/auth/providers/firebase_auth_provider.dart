import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/patient_id_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final patientIdServiceProvider = Provider<PatientIdService>((ref) {
  return PatientIdService(ref.watch(firestoreProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  AuthNotifier(this._auth, this._firestore) : super(const AsyncData(null));

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      
      if (credential.user != null) {
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'uid': credential.user!.uid,
            'name': name,
            'email': email,
            'profileImage': 'default',
            'bio': '',
            'createdAt': DateTime.now().toIso8601String(),
          });

          // Generate unique Patient ID for the new user
          try {
            final patientIdService = PatientIdService(_firestore);
            await patientIdService.ensurePatientId(credential.user!.uid);
          } catch (pidError) {
            print('Patient ID generation deferred: $pidError');
          }
        } catch (firestoreError) {
          // Catch Firestore errors (e.g. database not created, network offline)
          // so that the sign-up process itself is not aborted.
          // Firestore has offline capabilities and will sync when possible.
          print('Firestore error during user document creation, continuing: $firestoreError');
        }
      }

      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Sign up failed', StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Login failed', StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await Future.wait([
        _auth.signOut(),
        GoogleSignIn().signOut(),
      ]);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Failed to send password reset email', StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = const AsyncLoading();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in');
      }
      final email = user.email;
      if (email == null) {
        throw Exception('User email is not available');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Password update failed', StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      rethrow;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});
