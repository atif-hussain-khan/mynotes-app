import 'package:flutter/material.dart';
import 'package:mynotes/utils/dialogs/generic_dialog.dart';

Future<void> cannotShareEmptyNoteDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Sharing',
    content: 'You cannot share an empty note',
    optionsBuilder: () => {
      'OK': null,
    },
  ).then((value) => value ?? false);
}