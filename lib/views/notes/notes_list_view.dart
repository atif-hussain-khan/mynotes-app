import 'package:flutter/material.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utils/dialogs/show_delete_dialog.dart';

typedef NoteCallBack = void Function(CloudNote note);

class NotesListView extends StatelessWidget {
  final List<CloudNote> notes;
  final NoteCallBack onDeleteNote;
  final NoteCallBack onTapNote;

  const NotesListView(
      {super.key, required this.notes, required this.onDeleteNote, required this.onTapNote});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (BuildContext context, int index) {
        final note = notes[index];
        return ListTile(
          onTap: () {
            onTapNote(note);
          },
          title: Text(
            note.text,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) {
                onDeleteNote(note);
              }
            },
          ),
        );
      },
    );
  }
}
