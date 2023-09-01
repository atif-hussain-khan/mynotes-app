import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mynotes/services/db/database_exceptions.dart';
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

class DatabaseService {
  Database? _db;
  List<DatabaseNote> _notes = [];

  final _notesStreamController = StreamController<List<DatabaseNote>>.broadcast();

  Future<DatabaseUser> getOrCreateUser({required String email }) async {
    try {
      return await getUser(email: email);
    } on UserDoesNotExistException{
      return await createUser(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes;
    _notesStreamController.add(allNotes);
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    final db = _getDatabase();
    final dbUser = await getUser(email: owner.email);

    if (dbUser != owner) throw UserIsNotOwnerNoteException();
    const text = '';
    final noteRow = {userIdCol: owner.id, textCol: text};
    final noteId = await db.insert(noteTable, noteRow);
    final newNote = DatabaseNote(id: noteId, userId: owner.id, text: text);
    _notes.add(newNote);
    _notesStreamController.add(_notes);
    return newNote;
  }

  Future<int> deleteNote({required int id, bool deleteAll = false}) async {
    final db = _getDatabase();
    final int numberOfDeletions;
    if (deleteAll) {
      numberOfDeletions = await db.delete(noteTable);
      if (numberOfDeletions > 0) throw CannotDeleteNoteException();
      _notes = [];
      _notesStreamController.add(_notes);
    } else {
      numberOfDeletions = await db.delete(noteTable, where: '$idCol = ?', whereArgs: [id]);
      if (numberOfDeletions != 1) throw CannotDeleteNoteException();
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
    return numberOfDeletions;
  }

  Future<DatabaseNote> getNote({required int id}) async {
    final db = _getDatabase();
    final noteMap = await db.query(noteTable, limit: 1, where: '$idCol = ?', whereArgs: [id]);
    if (noteMap.isEmpty) throw NoteDoesNotExistException();
    final note = DatabaseNote.fromRow(noteMap.first);
    // update local cache (ie. the note in cache might be out of date)
    _notes.removeWhere((note) => note.id == id);
    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
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
    final update = {
      textCol: text
    };
    final updateCount = await db.call().update(noteTable, update);
    if (updateCount == 0) throw CannotUpdateNoteDatabaseException();
    final updatedNote = await getNote(id: note.id);
    _notes.removeWhere((note) => note.id == updatedNote.id);
    _notes.add(updatedNote);
    _notesStreamController.add(_notes);
    return updatedNote;  
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
      await _cacheNotes();
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
