import 'package:flutter/foundation.dart' show immutable;
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:equatable/equatable.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class AuthStateOnInitialized extends AuthState {
    const AuthStateOnInitialized();
}

class AuthStateRegistering extends AuthState {
    final Exception? exception;
  const AuthStateRegistering(this.exception);
}

class AuthStateLoggedIn extends AuthState {
  final AuthUser user;
  const AuthStateLoggedIn(this.user);
}

class AuthStateNeedsEmailVerification extends AuthState {
  const AuthStateNeedsEmailVerification();
}

class AuthStateLoggedOut extends AuthState with EquatableMixin{
  final Exception? exception;
  final bool isLoading;
  const AuthStateLoggedOut({required this.exception, required this.isLoading});
  
  @override
  List<Object?> get props => [exception, isLoading];
}
