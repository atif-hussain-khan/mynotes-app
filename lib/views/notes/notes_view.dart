import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'dart:developer' as devtools show log;

import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/db/database_service.dart';
import 'package:mynotes/utils/dialogs/show_logout_dialog.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final DatabaseService _databaseService;
  String get userEmail => AuthService.firebase().currentUser!.email;

  @override
  void initState() {
    _databaseService = DatabaseService();
    _databaseService.open();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Your Notes'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(createUpdateNoteRoute);
              },
              icon: const Icon(Icons.add)),
          PopupMenuButton(onSelected: (value) async {
            switch (value) {
              case MenuAction.logout:
                final shouldLogout = await showLogOutDialog(context: context);
                if (shouldLogout) {
                  await AuthService.firebase().logOut();
                  devtools.log('User has logged out');
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                }
            }
          }, itemBuilder: (context) {
            return const [
              PopupMenuItem<MenuAction>(
                  value: MenuAction.logout, child: Text('logout'))
            ];
          })
        ],
      ),
      body: FutureBuilder(
        future: _databaseService.getOrCreateUser(email: userEmail),
        builder: ((context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return StreamBuilder(
                stream: _databaseService.allNotes,
                builder: ((context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      if (snapshot.hasData) {
                        final allNotes = snapshot.data as List<DatabaseNote>;
                        return NotesListView(
                          notes: allNotes,
                          onDeleteNote: (DatabaseNote note) async {
                            _databaseService.deleteNote(id: note.id);
                          },
                          onTapNote: (DatabaseNote note) {
                            Navigator.of(context).pushNamed(
                              createUpdateNoteRoute,
                              arguments: note,
                            );
                          },
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    default:
                      return const CircularProgressIndicator();
                  }
                }),
              );
            default:
              return const CircularProgressIndicator();
          }
        }),
      ),
    );
  }
}
