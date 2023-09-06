import 'package:bloc/bloc.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
      : super(const AuthStateUninitialized(isLoading: true)) {
    on<AuthEventInitialize>(
      (event, emit) async {
        await provider.initialize();
        final user = provider.currentUser;
        if (user == null) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
        } else if (!user.isEmailVerified) {
          emit(const AuthStateNeedsEmailVerification(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      },
    );

    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(email: email, password: password);
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsEmailVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(exception: e, isLoading: false));
      }
    });

    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });

    on<AuthEventForgotPassword>((event, emit) async {
      emit(const AuthStateForgotPassword(
          exception: null, hasSentEmail: false, isLoading: false));
      if (event.email == null) {
        return;
      }
      emit(const AuthStateForgotPassword(
          exception: null, hasSentEmail: false, isLoading: true));
      try {
        await provider.sendPasswordResetEmail(email: event.email!);
        emit(const AuthStateForgotPassword(
            exception: null, hasSentEmail: true, isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateForgotPassword(
            exception: e, hasSentEmail: false, isLoading: false));
      }
    });

    on<AuthEventLogIn>(
      (event, emit) async {
        final email = event.email;
        final password = event.password;
        emit(const AuthStateLoggedOut(
            exception: null,
            isLoading: true,
            loadingText: 'Logging you in...'));
        try {
          final user = await provider.logIn(
            email: email,
            password: password,
          );
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          if (!user.isEmailVerified) {
            emit(const AuthStateNeedsEmailVerification(isLoading: false));
          } else {
            emit(AuthStateLoggedIn(user: user, isLoading: false));
          }
        } on Exception catch (e) {
          emit(AuthStateLoggedOut(exception: e, isLoading: false));
        }
      },
    );

    on<AuthEventLogOut>(
      (event, emit) async {
        try {
          await provider.logOut();
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
        } on Exception catch (e) {
          emit(AuthStateLoggedOut(exception: e, isLoading: false));
        }
      },
    );

    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(exception: null, isLoading: false));
    });
  }
}
