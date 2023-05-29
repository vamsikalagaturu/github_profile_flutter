import 'package:flutter/material.dart';

class File {
  // name of the file
  final String name;
  // path of the file
  final String path;
  // file type
  final String type;
  // file widget
  final Widget widget;

  // constructor
  File(this.name, this.path, this.type, this.widget);
}

// directory class: can contain files and directories
class Directory {
  // name of the directory
  final String name;
  // path of the directory (default is /)
  String path = '/';
  // list of files in the directory
  final List<File> files = [];
  // list of directories in the directory
  final List<Directory> directories = [];

  // constructor
  Directory(this.name, this.path);

  // function to add file to the directory
  void addFile(File file) {
    // add file to the list of files
    files.add(file);
  }

  // function to add directory to the directory
  void addDirectory(Directory directory) {
    // set the path of the directory
    directory.path = '$path/${directory.name}';
    // add directory to the list of directories
    directories.add(directory);
  }

  // function to get file from the directory if it exists else null
  File? getFile(String name) {
    // iterate through the list of files
    for (var file in files) {
      // if the file name is same as the name
      if (file.name == name) {
        // return the file
        return file;
      }
    }
    // return null
    return null;
  }

  // function to get directory from the directory if it exists else null
  Directory? getDirectory(String name) {
    // if name is . return this directory
    if (name == '.') {
      return this;
    }
    // if name contains / at the end remove it
    if (name.endsWith('/')) {
      name = name.substring(0, name.length - 1);
    }
    // iterate through the list of directories
    for (var directory in directories) {
      // if the directory name is same as the name
      if (directory.name == name) {
        // return the directory
        return directory;
      }
    }
    // return null
    return null;
  }

  // function to check if the directory contains a file
  bool containsFile(String name) {
    // iterate through the list of files
    for (var file in files) {
      // if the file name is same as the name
      if (file.name == name) {
        // return true
        return true;
      }
    }
    // return false
    return false;
  }

  // function to check if the directory contains a directory
  bool containsDirectory(String name) {
    // iterate through the list of directories
    for (var directory in directories) {
      // if the directory name is same as the name
      if (directory.name == name) {
        // return true
        return true;
      }
    }
    // return false
    return false;
  }

  // get all files and directory names in the directory
  List<String> getNames() {
    // list of names
    List<String> names = [];
    // iterate through the list of files
    for (var file in files) {
      // add file name to the list of names
      names.add(file.name);
    }
    // iterate through the list of directories
    for (var directory in directories) {
      // add directory name to the list of names and add / to the end
      names.add('${directory.name}/');
    }
    // return the list of names
    return names;
  }

  // getter to get the path of the directory
  String get getPath => path;

  // get directory from path
  Directory? getDirectoryFromPath(String path) {
    // if path is / return this directory
    if (path == '/') {
      return this;
    }
    // if path contains / at the end remove it
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    // split the path by /
    List<String> pathList = path.split('/');
    // if pathList is empty return null
    if (pathList.isEmpty) {
      return null;
    }
    // if pathList has only one element
    if (pathList.length == 1) {
      // iterate through the list of directories
      for (var directory in directories) {
        // if the directory name is same as the name
        if (directory.name == pathList[0]) {
          // return the directory
          return directory;
        }
      }
      // return null
      return null;
    }
    // if pathList has more than one element
    else {
      // iterate through the list of directories
      for (var directory in directories) {
        // if the directory name is same as the name
        if (directory.name == pathList[0]) {
          // return the directory
          return directory.getDirectoryFromPath(pathList.sublist(1).join('/'));
        }
      }
      // return null
      return null;
    }
  }
}
