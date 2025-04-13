import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  User? currentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<RegisterStatus> registerWithEmailPassword(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return RegisterStatus.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return RegisterStatus.weakPassword;
        case 'email-already-in-use':
          return RegisterStatus.emailAlreadyUsed;
        case 'invalid-email':
          return RegisterStatus.invalidEmail;
        case 'network-request-failed':
          return RegisterStatus.noInternet;
        default:
          return RegisterStatus.unknownError;
      }
    } catch (e) {
      return RegisterStatus.unknownError;
    }
  }

  Future<SignInStatus> signInWithEmailPassword(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      return SignInStatus.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return SignInStatus.userNotFound;
        case 'wrong-password':
          return SignInStatus.wrongPassword;
        case 'invalid-email':
          return SignInStatus.invalidEmail;
        case 'network-request-failed':
          return SignInStatus.noInternet;
        case _:
          return SignInStatus.unknownError;
      }
    } catch (e) {
      return SignInStatus.unknownError;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

enum RegisterStatus {
  success,
  weakPassword,
  emailAlreadyUsed,
  invalidEmail,
  noInternet,
  unknownError
}

enum SignInStatus {
  success,
  userNotFound,
  wrongPassword,
  invalidEmail,
  noInternet,
  unknownError
}