import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:io_page/main.dart';
import 'package:provider/provider.dart';

// Note class
class Note {
  final String? title;
  final String content;
  final bool pinned;
  String? id;
  final String? timestamp;

  // Constructor with named parameters
  Note({
    this.title,
    required this.content,
    required this.pinned,
    this.id,
    this.timestamp,
  });

  // map to firestore document
  Map<String, dynamic> toFirestore(FirebaseFirestore firestore, String uid) {
    final Map<String, dynamic> data = {
      'title': title,
      'content': content,
      'pinned': pinned,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // get a new id if note is new
    if (id == null) {
      final CollectionReference<Map<String, dynamic>> notesCollection =
          firestore.collection('users').doc().collection('notes');
      final DocumentReference<Map<String, dynamic>> newDocRef =
          notesCollection.doc();
      id = newDocRef.id;

      return {
        'path': newDocRef.path,
        'data': data,
      };
    } else {
      // Existing note, update with the provided ID
      final DocumentReference<Map<String, dynamic>> noteRef =
          firestore.doc(id!);

      return {
        'path': noteRef.path,
        'data': data,
      };
    }
  }

  // factory constructor to create Note from firestore document
  factory Note.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Note(
      title: data?['title'],
      content: data?['content'],
      pinned: data?['pinned'],
      id: snapshot.id,
      timestamp: data?['timestamp'].toString(),
    );
  }
}

// Single note widget
class NoteWidget extends StatelessWidget {
  final Note note;
  final Function deleteNote;
  final Function pinNote;

  NoteWidget(this.note, this.deleteNote, this.pinNote);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: IconButton(
          // show different icon based on pinned status
          icon: note.pinned
              ? Icon(Icons.push_pin)
              : Icon(Icons.push_pin_outlined),
          onPressed: () {
            pinNote();
          },
        ),
        title: Text(note.title!),
        subtitle: Text(note.content),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            deleteNote();
          },
        ),
      ),
    );
  }
}

// Notes grid widget using stream builder
class NotesGrid extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String uid;

  NotesGrid({required this.firestore, required this.uid});

  // delete note by id
  deleteNoteById(String id, BuildContext context) {
    // ask for confirmation before deleting
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete note?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                firestore
                    .collection('users')
                    .doc(uid)
                    .collection('notes')
                    .doc(id)
                    .delete();
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading');
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No notes yet'),
          );
        }

        final notes = snapshot.data!.docs.map((doc) {
          return Note.fromFirestore(doc, null);
        }).toList();

        // build grid view
        return GridView.builder(
          itemCount: notes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemBuilder: (context, index) {
            final note = notes[index];
            return GestureDetector(
              onTap: () {
                print('open note');
              },
              child: NoteWidget(
                note,
                () {
                  print('delete note');
                  deleteNoteById(note.id!, context);
                },
                () {
                  firestore
                      .collection('users')
                      .doc(uid)
                      .collection('notes')
                      .doc(note.id)
                      .update({
                    'pinned': !note.pinned,
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}
