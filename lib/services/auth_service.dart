import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Listen to auth state (Logged In vs Logged Out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        // Create the user profile in Firestore immediately after signup
        await _firestoreService.createUserProfile(cred.user!, email.split('@')[0]);
      }
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}