import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();

    test('should not be initialized to begin', () {
      expect(provider.isInitialized, false);
    });

    test('cannot logout if initialized', () {
      expect(provider.logOut(), throwsA(const TypeMatcher<ProviderNotInitializedException>()));
    });

    test('can initialize mock provider', () async{
      await provider.initialize();
      expect(provider.isInitialized, true);
    });
    
    test('user should be null before creation', () {
      expect(provider.currentUser, null);
    });

    test('should be able to initialize in less than 2 seconds', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    }, timeout: const Timeout(Duration(seconds: 2)));

    test('createUser function should delegate to logIn function', () async {
      final invalidEmailUser = provider.createUser(email: 'foo@bar.com', password: 'password');
      final invalidPasswordUser = provider.createUser(email: 'bar@foo.com', password: '123456');
      final missingEmailUser = provider.createUser(email: '', password: 'password');
      final missingPasswordUser = provider.createUser(email: 'bar@foo.com', password: '');
      
      expect(invalidEmailUser, throwsA(const TypeMatcher<UserNotFoundAuthException>()));
      expect(invalidPasswordUser, throwsA(const TypeMatcher<InvalidPasswordAuthException>()));
      expect(missingEmailUser, throwsA(const TypeMatcher<MissingEmailAuthException>()));
      expect(missingPasswordUser, throwsA(const TypeMatcher<MissingPasswordAuthException>()));
      
      final user = await provider.createUser(email: 'bar@foo.com', password: 'password');
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('logged in user should be able to get verified', () async{
      await provider.sendEmailVerification();
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.isEmailVerified, true);
    });

    test('should be able to log out an log in again', () async {
      await provider.logOut();
      expect(provider.currentUser, isNull);
      await provider.logIn(email: 'bar@foo.com', password: 'password');
      expect(provider.currentUser, isNotNull);
    });
  });
}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser(
      {required String email, required String password}) async {
    if (!isInitialized) throw ProviderNotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn(
      {required String email, required String password}) async {
    if (!isInitialized) throw ProviderNotInitializedException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == '123456') throw InvalidPasswordAuthException();
    if (email.isEmpty) throw MissingEmailAuthException();
    if (password.isEmpty) throw MissingPasswordAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = const AuthUser(isEmailVerified: false);
    return Future.value(_user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw ProviderNotInitializedException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw ProviderNotInitializedException();
    if (_user == null) throw UserNotLoggedInAuthException();
    _user = const AuthUser(isEmailVerified: true);
  }
}

class ProviderNotInitializedException implements Exception {}
