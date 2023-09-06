import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/utils/dialogs/password_reset_email_sent_dialog.dart';
import 'package:mynotes/utils/dialogs/show_error_dialog.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _textController;

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateForgotPassword) {
          if (state.hasSentEmail) {
            _textController.clear();
            await showPasswordResetEmailSendDialog(context);
          }

          if (state.exception != null) {
            await showErrorDialog(
                context, 'We could not process your request. Check your email');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forgot password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                  'If you forgot your password, please enter your email address'),
              TextField(
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                controller: _textController,
                decoration: const InputDecoration(hintText: 'Enter your email'),
              ),
              TextButton(onPressed: () {
                final email = _textController.text;
                context.read<AuthBloc>().add(AuthEventForgotPassword(email: email));
              }, child: const Text('Send password reset link')),
              TextButton(onPressed: () {
                context.read<AuthBloc>().add(const AuthEventLogOut());
              }, child: const Text('Back to login view'))
            ],
          ),
        ),
      ),
    );
  }
}
