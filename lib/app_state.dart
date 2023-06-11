import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dirs.dart';
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

  String _defaultName = 'Vamsi Kalagaturu';
  late String _name = _defaultName;
  String _email = '';

  String get name => _name;
  String get email => _email;

  late Directory homeDir;
  
  late Directory _currentDir;
  Directory get currentDir => _currentDir;

  late String _currentPath;
  // getter for current path
  String get currentPath => _currentPath;

  late CollectionReference<Note> uNotesRef;

  void init() async {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _loggedIn = false;
        _name = _defaultName;
      } else {
        _loggedIn = true;
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
            notifyListeners();
          } else {
            _name = '';
            notifyListeners();
          }
        });
      }
      notifyListeners();
    });

    // get stuff from json
    final dirsParser = await DirsParser.fromJsonFile('data/dir_files.json');

    // get dirs
    homeDir = dirsParser.parse(dirsParser.directoryStructure)[0];

    // variable to store the current path
    _currentPath = homeDir.path;
    _currentDir = homeDir;
  }

  // function to update user name
  bool updateName(String name) {
    bool success = false;
    // if a user has a document in users collection update the name
    // if not create a new document and update the name

    if (_auth.currentUser != null) {
      _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'name': name,
      }).then((value) {
        print('name updated successfully!');
        _name = name;
        success = true;
        notifyListeners();
      }).catchError((error) {
        print('Failed to update name: $error');
      });
    }

    return success;
  }

  bool show404 = false;

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
