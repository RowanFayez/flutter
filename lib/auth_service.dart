import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createAccount(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null && user.emailVerified) {
        return user;
      } else {
        throw Exception('Email not verified');
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<User?> signInWithEmailLink(String email, String emailLink) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      User? user = userCredential.user;

      if (user != null) {
        return user;
      } else {
        throw Exception('Failed to sign in with email link');
      }
    } catch (e) {
      throw Exception('Failed to sign in with email link: $e');
    }
  }
  void listenAuthStateChanges() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is not signed in
        print('User is currently signed out.');
      } else {
        // User is signed in
        print('User is signed in: ${user.email}');
      }
    });
  }
}

