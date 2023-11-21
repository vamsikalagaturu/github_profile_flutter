import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

FirebaseAuth _auth = FirebaseAuth.instance;

class File {
  // name of the file
  final String name;
  // path of the file
  final String path;
  // file type
  final String type;

  // constructor
  File(this.name, this.path, this.type);
}

// directory class that parses a json file and creates a list of directories and files
class Directory {
  // name of the directory
  final String name;
  // path of the directory
  final String path;
  // parent
  final String parent;
  // auth required
  final bool authRequired;
  // src of the directory
  final String dataSrc;
  // children containing files and directories
  final Children children;

  // constructor
  Directory(this.name, this.path, this.parent, this.authRequired, this.dataSrc,
      this.children);

  // ovveride print method
  @override
  String toString() {
    return 'Directory{name: $name, path: $path, authRequired: $authRequired, dataSrc: $dataSrc}';
  }

  // get children (directories and files) as a list of strings
  List<String> getChildren() {
    // create a list of strings
    List<String> childrenNames = [];

    // loop through the children
    for (final childDir in children.directories) {
      // add the name of the directory to the list
      // check if directory requires auth
      if (childDir.authRequired && _auth.currentUser == null) {
        continue;
      }
      childrenNames.add('${childDir.name}/');
    }

    for (final childFile in children.files) {
      // add the name of the file to the list
      childrenNames.add(childFile.name);
    }

    // return the list of strings
    return childrenNames;
  }

  // check if file or directory exists in children
  bool hassDirectory(String name) {
    // loop through the children
    for (final childDir in children.directories) {
      // if the name of the directory matches the name
      if (childDir.name == name) {
        // return true
        return true;
      }
    }

    // return false
    return false;
  }

  bool hasFile(String name) {
    // loop through the children
    for (final childFile in children.files) {
      // if the name of the file matches the name
      if (childFile.name == name) {
        // return true
        return true;
      }
    }

    // return false
    return false;
  }


}

class Children {
  final List<Directory> directories;
  final List<File> files;

  Children(this.directories, this.files);
}

// class to parse the json file and create a list of directories and files
class DirsParser {
  Map<String, dynamic> directoryStructure;

  // constructor
  DirsParser({required this.directoryStructure});

  // parse the json file and create a list of directories and files
  static Future<DirsParser> fromJsonFile(String path) async {
    // Read the JSON file from the assets directory
    final jsonString = await rootBundle.loadString(path);

    // Decode the JSON data into a Dart object
    final data = jsonDecode(jsonString);

    final homeData = data["dirs"];

    // parse the json data and create a list of directories and files
    return DirsParser(directoryStructure: homeData);
  }

  // _parse method
  List<Directory> parse(Map<String, dynamic> data, {String parent = ''}) {
    // create a list of directories
    List<Directory> dirs = [];

    // loop through the data
    for (final dirEntry in data.entries) {
      final dirName = dirEntry.key;
      final dirPath = dirEntry.value['path'];
      final dirAuth = dirEntry.value['auth'];
      final dirDataSrc = dirEntry.value['dataSrc'];

      Children dirChildren = Children([], []);

      if (dirDataSrc == "local") {
        // parse children
        final children = dirEntry.value['children'];
        final childDirs = children['dirs'];
        final childFiles = children['files'];

        // create a list of files
        List<File> files = [];
        if (childFiles != null) {
          for (final file in childFiles.entries) {
            files.add(File(file.key, file.value['path'], file.value['type']));
          }
        }

        // create a list of child directories recursively
        List<Directory> childDirectories = [];
        if (childDirs != null) {
          childDirectories = parse(childDirs, parent: dirName);
        }

        // add the files and child directories to the list of children
        dirChildren.directories.addAll(childDirectories);
        dirChildren.files.addAll(files);
      } else {
        dirChildren = Children([], []);
      }

      // create a directory object
      final dir = Directory(dirName, dirPath, parent, dirAuth, dirDataSrc, dirChildren);

      // add the directory to the list of directories
      dirs.add(dir);
    }

    // return the list of directories
    return dirs;
  }
}
