import 'package:firebase_core/firebase_core.dart';
import 'package:mynotes/firebase_options.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException;

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = currentUser;

      return user ?? (throw UserNotFoundAuthException());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'missing-email':
          throw MissingEmailAuthException();
        case 'missing-password':
          throw MissingPasswordAuthException();
        case 'invalid-email':
          throw InvalidEmailAuthException();
        case 'weak-password':
          throw WeakPasswordAuthException();
        case 'email-already-in-use':
          throw AccountAlreadyExistsAuthException();
        default:
          throw UnknownAuthException();
      }
    } catch (e) {
      throw UnknownAuthException();
    }
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? AuthUser.fromFirebase(user) : null;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = currentUser;

      return user ?? (throw UserNotFoundAuthException());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'missing-email':
          throw MissingEmailAuthException();
        case 'missing-password':
          throw MissingPasswordAuthException();
        case 'invalid-email':
          throw InvalidEmailAuthException();
        case 'user-not-found':
          throw UserNotFoundAuthException();
        case 'wrong-password':
          throw InvalidPasswordAuthException();
        default:
          throw UnknownAuthException();
      }
    } catch (e) {
      throw UnknownAuthException();
    }
  }

  @override
  Future<void> logOut() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        throw UnknownAuthException();
      }
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      } catch (e) {
        throw UnknownAuthException();
      }
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'firebase_auth/invalid-email':
          throw InvalidEmailAuthException();
        case 'firebase_auth/user-not-found':
          throw UserNotFoundAuthException();
        default:
          throw UnknownAuthException();
      }
    } catch (e) {
      throw UnknownAuthException();
    }
  }
}
