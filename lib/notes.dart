import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:io_page/app_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'black_hole.dart';
import 'custom_search_bar.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    return {
      'title': title,
      'content': content,
      'pinned': pinned,
      'timestamp': FieldValue.serverTimestamp(),
    };
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
  final Function pinNote;

  NoteWidget(this.note, this.pinNote);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        constraints: BoxConstraints(
          minWidth: 100, // Minimum width
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(note.title!),
                trailing: IconButton(
                  // show pin icon if note is not pinned
                  icon: note.pinned
                      ? Icon(Icons.push_pin_outlined)
                      : Icon(Icons.push_pin),
                  onPressed: () {
                    pinNote();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(note.content),
              ),
            ],
          ),
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

  // update note by id using a modal dialog
  updateNoteById(String id, BuildContext context) {
    // get the note from firestore
    Provider.of<MyAppState>(context, listen: false)
        .uNotesRef
        .doc(id)
        .get()
        .then((doc) {
      // create a new note from firestore document
      final note = doc.data();

      // show modal dialog
      showDialog(
        context: context,
        builder: (context) {
          // text editing controllers
          final titleController = TextEditingController(text: note?.title);
          final contentController = TextEditingController(text: note?.content);

          return AlertDialog(
            title: Text('Update note'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // customize the text field to look like a note
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // horizontal line
                Divider(),
                TextField(
                  controller: contentController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Content',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // update note
                  Note updatedNote = Note(
                    title: titleController.text,
                    content: contentController.text,
                    pinned: note?.pinned ?? false,
                  );
                  _firestore
                      .collection('users')
                      .doc(uid)
                      .collection('notes')
                      .doc(id)
                      .update(updatedNote.toFirestore(firestore, uid));
                  Navigator.pop(context);
                },
                child: Text('Update'),
              ),
            ],
          );
        },
      );
    });
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

        // set cross axis count based on device width
        int crossAxisCount = 4;
        if (MediaQuery.of(context).size.width < 600) {
          crossAxisCount = 2;
        } else if (MediaQuery.of(context).size.width < 900) {
          crossAxisCount = 3;
        } else if (MediaQuery.of(context).size.width < 1200) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = 5;
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(child: Text('Loading'));
        }

        if (snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text('No notes yet'),
            ),
          );
        }

        final notes = snapshot.data!.docs.map((doc) {
          return Note.fromFirestore(doc, null);
        }).toList();

        // build grid view
        return SliverFillRemaining(
          child: GridView.custom(
            shrinkWrap: true,
            padding: EdgeInsets.all(8),
            gridDelegate: SliverWovenGridDelegate.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              pattern: [
                WovenGridTile(1),
                WovenGridTile(
                  5 / 7,
                  crossAxisRatio: 0.9,
                  alignment: AlignmentDirectional.centerEnd,
                ),
              ],
            ),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) {
                final note = notes[index];
                return GestureDetector(
                  onTap: () {
                    updateNoteById(note.id!, context);
                  },
                  child: Draggable<Note>(
                    data: note,
                    // change the feedback widget design
                    feedback: Material(
                      // use custom widget for feedback
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      // use custom widget for feedback
                      child: Container(
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(
                            minHeight: 50,
                            minWidth: 50,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            note.title ?? note.content.substring(0, 10),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          )),
                    ),
                    childWhenDragging: Container(),
                    child: NoteWidget(
                      note,
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
                  ),
                );
              },
              childCount: notes.length,
            ),
          ),
        );
      },
    );
  }
}

// Notes page
class NotesPage extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String uid;

  NotesPage({required this.firestore, required this.uid});

  // method to create a new note
  void createNewNote(BuildContext context) {
    // show modal dialog
    showDialog(
      context: context,
      builder: (context) {
        // text editing controllers
        final titleController = TextEditingController();
        final contentController = TextEditingController();

        return AlertDialog(
          title: Text('Create new note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // customize the text field to look like a note
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // horizontal line
              Divider(),
              TextField(
                controller: contentController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Content',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // add new note to firestore
                final note = Note(
                  title: titleController.text,
                  content: contentController.text,
                  pinned: false,
                );
                Provider.of<MyAppState>(context, listen: false)
                    .createNewNote(note);
                Navigator.pop(context);
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // delete note
  deleteNote(Note note, BuildContext context) {
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
                    .doc(note.id)
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // remove back button when routed from CustomSearchBar
            automaticallyImplyLeading: false,
            forceMaterialTransparency: true,
            // pin the search bar to the top when scrolled
            pinned: true,
            // use custom search bar
            title: Hero(
              tag: 'searchBar',
              child: CustomSearchBar('~/notes',
                  touchMethod: () => createNewNote(context)),
            ),
            centerTitle: true,
            // toolbar height
            toolbarHeight: 100,
          ),
          NotesGrid(
            firestore: firestore,
            uid: uid,
          ),
        ],
      ),
      floatingActionButton: BlackholeButton(onAcceptMethod: deleteNote),
    );
  }
}
