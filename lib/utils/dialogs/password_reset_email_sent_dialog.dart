import 'package:flutter/material.dart';
import 'package:mynotes/utils/dialogs/generic_dialog.dart';

Future<void> showPasswordResetEmailSendDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: 'Password reset',
    content: 'We have sent you a password reset link to your email.',
    optionsBuilder: () => {
      'OK': null,
    },
  );
}
