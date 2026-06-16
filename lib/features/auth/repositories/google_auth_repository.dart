import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  GoogleAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // User canceled the sign-in
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await _createUserInFirestoreIfNotExists(userCredential.user);
    
    return userCredential;
  }

  Future<void> _createUserInFirestoreIfNotExists(User? user) async {
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'profileImage': user.photoURL ?? 'default',
          'bio': '',
          'createdAt': DateTime.now().toIso8601String(),
          'authProvider': 'google',
        });
      }
    } catch (e) {
      // Catch Firestore connection/unavailable issues so they do not crash Google Sign-In.
      // Firebase will use the offline cache and sync automatically once online.
      print('Firestore warning during _createUserInFirestoreIfNotExists: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
