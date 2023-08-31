import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Enter your password'),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                final userCredential = await FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                        email: email, password: password);
                print(userCredential);
              } on FirebaseAuthException catch (e) {
                switch (e.code) {
                  case 'missing-email':
                    print('please enter a email');
                  case 'missing-password':
                    print('please enter a password');
                  case 'invalid-email':
                    print('The email address is invalid');
                  case 'user-not-found':
                    print('this user does not exist');
                  case 'wrong-password':
                    print('the password is incorrect');
                  default:
                    print('some other firebase exception occured');
                    print(e.code);
                }
              } catch (e) {
                print('some unknown exception has occured');
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
