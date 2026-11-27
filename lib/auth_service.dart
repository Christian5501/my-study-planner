import 'package:firebase_auth/firebase_auth.dart';

// Handles Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Checks whether a user is signed in.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registers a new user using email and password.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Signs in an existing user.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Signs out the current user.
  Future<void> logout() {
    return _auth.signOut();
  }
}
