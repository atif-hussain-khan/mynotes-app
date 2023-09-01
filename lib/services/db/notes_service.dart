import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mynotes/services/db/db_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;
import 'package:path/path.dart' show join;

@immutable
class DatabaseUser {
  final int id;
  final String email;

  DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> row)
      : id = row[idCol] as int,
        email = row[emailCol] as String;

  @override
  String toString() => 'Person, id = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;

  DatabaseNote({required this.id, required this.userId, required this.text});

  DatabaseNote.fromRow(Map<String, Object?> row)
      : id = row[idCol] as int,
        userId = row[userIdCol] as int,
        text = row[textCol] as String;

  @override
  String toString() =>
      'Note, id = $id, userId = $userId, text = ${text.substring(0, max(200, text.length - 1))}';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class NotesService {
  Database? _db;

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    final db = _getDatabase();
    final dbUser = await getUser(email: owner.email);

    if (dbUser != owner) throw UserIsNotOwnerNoteException();
    const text = '';
    final noteRow = {userIdCol: owner.id, textCol: text};
    final noteId = await db.insert(noteTable, noteRow);

    return DatabaseNote(id: noteId, userId: owner.id, text: text);
  }

  Future<int> deleteNote({required int id, bool deleteAll = false}) async {
    final db = _getDatabase();
    final int deletedNote;
    if (deleteAll) {
      deletedNote = await db.delete(noteTable);
      if (deletedNote > 0) throw CannotDeleteNoteException();
    } else {
      deletedNote = await db.delete(noteTable, where: '$idCol = ?', whereArgs: [id]);
      if (deletedNote != 1) throw CannotDeleteNoteException();
    }
    return deletedNote;
  }

  Future<DatabaseNote> getNote({required int id}) async {
    final db = _getDatabase();
    final note = await db.query(noteTable, limit: 1, where: '$idCol = ?', whereArgs: [id]);
    if (note.isEmpty) throw NoteDoesNotExistException();
    return DatabaseNote.fromRow(note.first);
  }

  Future<List<DatabaseNote>> getAllNotes() async {
    final db = _getDatabase();
    final notes = await db.query(noteTable);
    if (notes.isEmpty) throw NoteDoesNotExistException();
    return notes.map((note) => DatabaseNote.fromRow(note)).toList();
  }

  Future<DatabaseNote> updateNote({required DatabaseNote note, required String text}) async {
    final db = _getDatabase;
    await getNote(id: note.id);
    final updatedNote = {
      textCol: text
    };
    final updateCount = await db.call().update(noteTable, updatedNote);
    if (updateCount == 0) throw CannotUpdateNoteDatabaseException();
    return await getNote(id: note.id);  
  }

  Database _getDatabase() {
    if (_db == null) throw DatabaseIsNotOpenDatabaseException();
    final db = _db;
    return db!;
  }

  Future<void> _checkUserDoesNotExist({required String email}) async {
    final db = _getDatabase();
    final result = await db.query(
      userTable,
      limit: 1,
      where: '$emailCol = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (result.isNotEmpty) throw UserExistsException();
  }

  Future<void> _checkUserExists({required String email}) async {
    final db = _getDatabase();
    final result = await db.query(
      userTable,
      limit: 1,
      where: '$emailCol = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (result.isEmpty) throw UserDoesNotExistException();
  }

  Future<void> open() async {
    if (_db != null) throw DatabaseIsOpenDatabaseException();

    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      await db.execute(createUserTableQuery);
      await db.execute(createNoteTableQuery);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDirectoryDatabaseException();
    } catch (e) {
      throw UnknownDatabaseException();
    }
  }

  Future<void> close() async {
    final db = _getDatabase();
    await db.close();
    _db = null;
  }

  Future<void> deleteUser({required String email}) async {
    await _checkUserExists(email: email);
    final db = _getDatabase();
    final deletedAccount = await db.delete(
      userTable,
      where: '$emailCol = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedAccount != 1) throw CannotDeleteUserException();
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _checkUserDoesNotExist(email: email);
    final db = _getDatabase();
    final userRow = {emailCol: email.toLowerCase()};
    final userId = await db.insert(userTable, userRow);
    return DatabaseUser(id: userId, email: email);
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _checkUserExists(email: email);
    final db = _getDatabase();
    final result = await db.query(userTable,
        limit: 1, where: '$emailCol = ?', whereArgs: [email.toLowerCase()]);
    return DatabaseUser.fromRow(result.first);
  }
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idCol = 'id';
const emailCol = 'email';
const userIdCol = 'user_id';
const textCol = 'text';
const createUserTableQuery = '''
  CREATE TABLE IF NOT EXISTS "user" (
    "id"	INTEGER NOT NULL UNIQUE,
    "email"	TEXT NOT NULL,
    PRIMARY KEY("id" AUTOINCREMENT)
  )
''';

const createNoteTableQuery = '''
CREATE TABLE IF NOT EXISTS "note" (
  "id"	INTEGER NOT NULL,
  "user_id"	INTEGER NOT NULL,
  "text"	TEXT,
  PRIMARY KEY("id" AUTOINCREMENT),
  FOREIGN KEY("user_id") REFERENCES "user"("id")
)
''';

const getUserQuery = '''

''';
