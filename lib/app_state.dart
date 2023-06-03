import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'notes.dart' show Note;

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// app state class
class MyAppState extends ChangeNotifier {
  MyAppState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  String _name = 'Vamsi Kalagaturu';
  String _email = '';

  String get name => _name;
  String get email => _email;

  late CollectionReference<Note> uNotesRef;

  void init() {
    print('init called');
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        _loggedIn = false;
      } else {
        _loggedIn = true;
        print('User is signed in!');
        _email = user.email!;
        // docref for user notes
        uNotesRef = _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('notes')
            .withConverter<Note>(
              fromFirestore: Note.fromFirestore,
              toFirestore: (note, options) =>
                  note.toFirestore(_firestore, _auth.currentUser!.uid),
            );
        // get the user name from firestore and update the name
        _firestore.collection('users').doc(user.uid).get().then((doc) {
          if (doc.exists) {
            _name = doc.data()!['name'];
            print('user name: $_name');
            notifyListeners();
          } else {
            print('cant find username!');
          }
        });
      }
      notifyListeners();
    });

    // print documents in home collection
    printDocs();
  }

  // function to update user name
  bool updateName(String name) {
    bool success = false;
    _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'name': name})
        .then((value) => {
              print('name updated to $name'),
              _name = name,
              notifyListeners(),
              success = true,
            })
        .onError((error, stackTrace) => {
              print('Failed to update name: $error'),
              success = false,
            });
    return success;
  }

  // variable to store the current path
  String _currentPath = '~/';

  bool show404 = false;

  // getter for current path
  String get currentPath => _currentPath;

  List dirs = [
    {'name': 'about', 'path': 'about'},
    {'name': 'projects', 'path': 'projects'},
    {'name': 'contact', 'path': 'contact'}
  ];

  // define the controller for the text field of terminal
  final TextEditingController _terminalTextController = TextEditingController();

  TextEditingController get terminalTextController => _terminalTextController;

  // print documents in home collection
  Future<void> printDocs() async {
    final QuerySnapshot<Map<String, dynamic>> docs =
        await _firestore.collection('home').get();
    for (var doc in docs.docs) {
      print('${doc.id}, ${doc.data()}');
    }
  }

  // create a new note
  Future<void> createNewNote(Note newNote) async {
    await uNotesRef.add(newNote);
  }

  // update a note
  Future<void> updateNote(Note note) async {
    await uNotesRef
        .doc(note.id)
        .update(note.toFirestore(_firestore, _auth.currentUser!.uid));
  }

  // get all notes
  Stream<List<Note>> getNotes() {
    return uNotesRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // function to update the current path
  void updateCurrentPath(String path,
      {bool append = false, bool goBack = false}) {
    // update the current path
    if (append) {
      // remove current path string from path
      path = path.replaceAll(_currentPath, '');
      if (!_currentPath.endsWith('/')) {
        // remove whatever is after the last /
        _currentPath =
            _currentPath.substring(0, _currentPath.lastIndexOf('/') + 1);
        _currentPath = '$_currentPath$path';
      } else {
        _currentPath = '$_currentPath$path';
      }
    }
    if (goBack) {
      if (_currentPath != '~' && _currentPath != '~/') {
        if (_currentPath.endsWith('/')) {
          // get second last index of /
          // remove last /
          _currentPath =
              _currentPath.substring(0, _currentPath.lastIndexOf('/'));
          // remove whatever is after the last /
          _currentPath =
              _currentPath.substring(0, _currentPath.lastIndexOf('/') + 1);
        } else {
          _currentPath =
              _currentPath.substring(0, _currentPath.lastIndexOf('/') + 1);
        }
      }
    }
    if (!append && !goBack && path != '') {
      _currentPath = path;
    }
    // notify the listeners
    notifyListeners();
  }
}
