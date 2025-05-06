import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  User? currentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<RegisterStatus> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(name);
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

  Future<SignInStatus> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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

  //Sends a password reset email to the specified email address.
  Future<PasswordResetStatus> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return PasswordResetStatus.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return PasswordResetStatus.userNotFound;
        case 'invalid-email':
          return PasswordResetStatus.invalidEmail;
        case 'network-request-failed':
          return PasswordResetStatus.noInternet;
        default:
          return PasswordResetStatus.unknownError;
      }
    } catch (e) {
      return PasswordResetStatus.unknownError;
    }
  }

  Future<void> changePassword(newPassword) async {
    final user = currentUser();
    await user?.updatePassword(newPassword);
  }

  Future<void> changeUsername(newName) async {
    final user = currentUser();
    await user?.updateDisplayName(newName);
  }

  Future<bool> changeUserEmail(newEmail) async {
    try {
      final user = currentUser();
      await user?.verifyBeforeUpdateEmail(newEmail);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteUser() async {
    await currentUser()?.delete();
  }

  Future<String> uploadAndUpdateProfileImage(File imageFile) async {
    final user = currentUser();
    final storageRef = FirebaseStorage.instance.ref().child(
      'profile_pictures/${user?.uid}.jpg',
    );
    final snapShot = await storageRef.putFile(imageFile);
    final newImageUrl = await snapShot.ref.getDownloadURL();
    await currentUser()?.updatePhotoURL(newImageUrl);
    return newImageUrl;
  }

  Future<void> deleteProfileImage() async {
    await currentUser()?.updatePhotoURL(null);
  }

  Future<void> reloadUserData() async {
    currentUser()?.reload();
  }

  //validator function
  String? validateEmail(String? email) {
    if (EmailValidator.validate(email!)) {
      return null;
    }
    return "Gebe eine gültige Email ein.";
  }

  String? validatePasswordField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte Passwort eingeben';
    }
    if (value.length < 6) {
      return 'Passwort mind. 6 Zeichen lang.';
    }
    return null;
  }

  String? validateNameField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name darf nicht leer sein.';
    }
    if (value.length > 25) {
      return 'Name max. 25 Zeichen lang.';
    }
    return null;
  }
}

enum RegisterStatus {
  success,
  weakPassword,
  emailAlreadyUsed,
  invalidEmail,
  noInternet,
  unknownError,
}

enum SignInStatus {
  success,
  userNotFound,
  wrongPassword,
  invalidEmail,
  noInternet,
  unknownError,
}

enum PasswordResetStatus {
  success,
  userNotFound,
  invalidEmail,
  noInternet,
  unknownError,
}
