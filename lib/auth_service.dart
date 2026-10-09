import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() => _auth.currentUser;

  // ---------------- EMAIL / PASSWORD SIGN UP ----------------
  Future<User?> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = result.user;
      if (user != null) {
        await user.updateDisplayName(username);
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'email',
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Sign up failed';
    }
  }

  // ---------------- EMAIL / PASSWORD SIGN IN ----------------
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  // ---------------- GOOGLE SIGN IN ----------------
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential result;

      if (kIsWeb) {
        // ✅ WEB: Firebase popup (avoids google_sign_in web issues)
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        result = await _auth.signInWithPopup(authProvider);
      } else {
        // ✅ MOBILE: google_sign_in v7+
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance
            .authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        result = await _auth.signInWithCredential(credential);
      }

      final user = result.user;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'uid': user.uid,
            'username': user.displayName ?? 'User',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'provider': 'google',
          });
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Google sign-in failed';
    } catch (e) {
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  // ---------------- SIGN OUT ----------------
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
