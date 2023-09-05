import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';

class FirebaseDatabaseService {
  final notes = FirebaseFirestore.instance.collection('notes');

  FirebaseDatabaseService._sharedInstance();
  static final FirebaseDatabaseService _shared =
      FirebaseDatabaseService._sharedInstance();
  factory FirebaseDatabaseService() => _shared;

  void createNewNote({required String ownerUserId}) async {
    await notes.add({ownerUserIdFieldName: ownerUserId, textFieldName: ''});
  }

  Future<List<CloudNote>> getNotes({required String ownerUserId}) async {
    try {
      return await notes
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .get()
          .then(
            (value) => value.docs.map((doc) {
              return CloudNote(
                documentId: doc.id,
                ownerUserId: doc.data()[ownerUserIdFieldName],
                text: doc.data()[textFieldName],
              );
            }).toList(),
          );
    } catch (e) {
      throw CannotGetAllNotes();
    }
  }

  Stream<List<CloudNote>> allNotes({required String ownerUserId}) =>
      notes.snapshots().map((snapshot) => snapshot.docs
          .map((document) => CloudNote.fromSnapshot(document))
          .where((note) => note.ownerUserId == ownerUserId).toList());

  Future<void> updateNote({required String documentId, required String text}) async {
    try {
      await notes.doc(documentId).update({
        textFieldName: text
      });
    } catch (e) {
      throw CannotUpdateNote();
    }
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CannotDeleteNote();
    }
  }

}
