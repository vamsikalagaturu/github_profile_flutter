import 'dart:async';
import 'dart:js';
import 'dart:js_util';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:io_page/assets/icons/custom_icons_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dirs.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'two_link_manipulator.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

void main() {
  // set the url strategy for web
  usePathUrlStrategy();
  runApp(
      // use provider and change notifier
      ChangeNotifierProvider(
    create: (context) => MyAppState(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  GoRouter router(var dirs) {
    return GoRouter(
      // set the initial path
      initialLocation: '/',

      // redirect from / to /home/
      redirect: (context, state) {
        print('Redirecting to: ${state.location}');

        if (state.location == '/home' || state.location == '/') {
          return '/';
        }

        return state.location;
      },

      // set the path to home page
      routes: _routes(dirs),

      // set the path to unknown page
      errorPageBuilder: (context, state) {
        return MaterialPage(child: MyNextPage('404', show404: true));
      },
    );
  }

  List<GoRoute> _routes(dirs) => [
        GoRoute(
          name: '404',
          path: '/404',
          pageBuilder: (context, state) {
            return MaterialPage(child: MyNextPage('404', show404: true));
          },
        ),
        GoRoute(
            name: 'home',
            path: '/',
            pageBuilder: (context, state) {
              return MaterialPage(child: MyHomePage());
            },
            routes: [
              GoRoute(
                path: ':command',
                pageBuilder: (context, state) {
                  return MaterialPage(
                      child: MyNextPage(state.pathParameters['command']));
                },
              ),
              // watch for changes in dirs
              for (var dir in dirs)
                GoRoute(
                  name: dir['name'],
                  path: dir['path'],
                  pageBuilder: (context, state) {
                    return MaterialPage(child: MyNextPage(state.path));
                  },
                ),
            ]),
      ];

  @override
  Widget build(BuildContext context) {
    var dirs = context.read<MyAppState>().dirs;
    return MaterialApp.router(
        title: 'Vamsi Kalagaturu',
        theme: ThemeData(
          useMaterial3: true,
          // use dark theme
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
        ),
        routerConfig: router(dirs));
  }
}

// app state class
class MyAppState extends ChangeNotifier {
  MyAppState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  String _name = 'Vamsi Kalagaturu';

  Future<void> init() async {
    // initialize firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        _loggedIn = false;
      } else {
        _loggedIn = true;
        print('User is signed in!');
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

  // print documents in home collection
  Future<void> printDocs() async {
    final QuerySnapshot<Map<String, dynamic>> docs =
        await _firestore.collection('home').get();
    for (var doc in docs.docs) {
      print('${doc.id}, ${doc.data()}');
    }
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

// home page widget with the search bar
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold is a layout for
    // the major Material Components.
    return Scaffold(
      // use hero widget for CustomSearchBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: 'searchBar',
              child: CustomSearchBar('~'),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
                constraints: BoxConstraints(
                  minWidth: 300,
                  minHeight: 300,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 94, 95, 96),
                  borderRadius: BorderRadius.circular(10),
                ),
                // set height and width of the container dynamically
                height: 300,
                width: 300,
                child: TwoLinkManipulator()),
          ],
        ),
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  CustomSearchBar(this.path, {super.key});

  final String path;

  // focus node for the text field
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    // return material widget
    return SizedBox(
      // set the width
      width: MediaQuery.of(context).size.width * 0.8,
      // set the height
      height: 100,
      child: Column(
        // align items to the left
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // add the text widget to show the text to the left
          UnconstrainedBox(
            // align left
            alignment: Alignment.centerLeft,
            child: Container(
              // set the padding
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
              // decoration
              decoration: BoxDecoration(
                // set the border radius
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                // set the text
                '{ ${context.watch<MyAppState>()._name} } [ $path ]',
                // set the style
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      // set the color with the color set in the theme
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
              ),
            ),
          ),
          SizedBox(height: 5),
          Material(
            // set the color with the color set in the theme
            color: Theme.of(context).colorScheme.secondaryContainer,
            // set the elevation
            elevation: 10,
            // set the border radius
            borderRadius: BorderRadius.circular(10),
            // ripple effect
            child: InkWell(
              // set the onTap
              onTap: () {},
              // border radius
              borderRadius: BorderRadius.circular(10),
              // ripple color
              splashColor: Theme.of(context).colorScheme.onSecondary,
              // set the child
              child: Container(
                // set the padding
                padding: const EdgeInsets.symmetric(horizontal: 10),
                // border radius
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                // set the height
                height: 50,
                // set the child
                child: Row(
                  children: [
                    // add the text
                    Text(
                      '\$',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                    // add the vertical space
                    SizedBox(width: 10),
                    // add the input field
                    Expanded(
                      child: RawKeyboardListener(
                        focusNode: _focusNode,
                        // detect tab key press
                        onKey: (event) {
                          // check if the tab key is pressed
                          if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
                            print('tab pressed');
                            // keep the focus on the text field
                            _focusNode.requestFocus();
                          }
                        },
                        // set the child
                        child: TextField(
                          focusNode: FocusNode(canRequestFocus: true),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(bottom: 1),
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                          // on submit call the function
                          onSubmitted: (value) {
                            // call the function
                            _onSubmitted(context, value);
                          },
                          // while typing, detect tab key press
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SearchBar onSubmitted function
_onSubmitted(BuildContext context, String value) {
  // check if the value is empty
  if (value.isEmpty) {
    // show the snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Need Help? Try typing "help"'),
      ),
    );
  } else {
    // interpret the command
    final path = interpretCommand(value, context);

    print('path is $path');

    List dirs = context.read<MyAppState>().dirs;

    bool isPath = false;

    for (var dir in dirs) {
      if (dir['name'] == path) {
        isPath = true;
        break;
      }
    }

    if (isPath) {
      context.pushNamed(path);
    } else if (path.contains('ls')) {
      context.push('/home:ls');
    } else if (path == 'sudo su') {
      // display modal
      _showLoginModal(context, 'vamsik8919@gmail.com');
    } else if (path.startsWith('user_login_')) {
      // display modal
      _showLoginModal(context, path.split('_')[2]);
    } else {
      context.pushNamed('404');
    }
  }
}

void _showLoginModal(BuildContext context, String email) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: 200,
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // add the text
              Text(
                'Enter Password',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              // add the vertical space
              SizedBox(height: 10),
              // add the input field
              SizedBox(
                width: 200,
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  autofocus: true,
                  // on submit call the function
                  onSubmitted: (value) {
                    // call the function
                    _onUserLoginDataSubmitted(context, email, value)
                        .then((value) {
                      if (value) {
                        // close the modal
                        Navigator.pop(context);
                      } else {
                        // show the snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Wrong Password'),
                          ),
                        );
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// on user login data submitted
Future<bool> _onUserLoginDataSubmitted(
    BuildContext context, String email, String password) async {
  // try to login the user
  try {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    // if login is successful then close the modal
    if (credential.user != null) {
      // close the modal
      return true;
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided for that user.');
    }
    return false;
  }
  return false;
}

// interpret the command method and returns List containing result widget and isPath
String interpretCommand(String value, BuildContext context) {
  // check if the value starts with cd
  if (value.startsWith('cd')) {
    // get the path
    String path = value.substring(2).trim();
    // check if the path is empty
    if (path.isEmpty) {
      // update the path in appstate
      context.read<MyAppState>().updateCurrentPath('~');
      return '~';
    } else if (path == '..') {
      // update the path in appstate
      context.read<MyAppState>().updateCurrentPath(path, goBack: true);
      path = context.read<MyAppState>().currentPath;
      return path;
    } else if (path == '../..') {
      // update the path in appstate
      context.read<MyAppState>().updateCurrentPath(path, goBack: true);
      context.read<MyAppState>().updateCurrentPath(path, goBack: true);
      path = context.read<MyAppState>().currentPath;
      return path;
    } else if (path == '../../..') {
      // update the path in appstate
      context.read<MyAppState>().updateCurrentPath(path, goBack: true);
      context.read<MyAppState>().updateCurrentPath(path, goBack: true);
      context.read<MyAppState>().updateCurrentPath(path, goBack: true);
      path = context.read<MyAppState>().currentPath;
      return path;
    } else if (path.startsWith('~/')) {
      context.read<MyAppState>().updateCurrentPath(path);
      return path;
    } else if (path.endsWith('/')) {
      // update the path in appstate
      context.read<MyAppState>().updateCurrentPath(path, append: true);
      return path;
    } else {
      // don't update the path in appstate
      return path;
    }
  }
  // ls command
  if (value.startsWith('ls')) {
    return 'ls';
  }
  // sudo su command
  if (value.startsWith('sudo su')) {
    return 'sudo su';
  }
  // for other users
  if (value.startsWith('su -')) {
    var email = value.substring(4).trim();
    return 'user_login_$email';
  }
  // check if the value is help
  if (value == 'help') {
    //  update the path in appstate
    context.read<MyAppState>().updateCurrentPath('');
    return '';
  } else {
    // update the path in appstate
    context.read<MyAppState>().updateCurrentPath('');
    return '';
  }
}

// Custom text widget
class CustomText extends StatelessWidget {
  // constructor
  const CustomText(this.text, {Key? key}) : super(key: key);

  // text
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        // set the padding
        padding: const EdgeInsets.all(5),
        // decoration
        decoration: BoxDecoration(
          // set the color with the color set in the theme
          color: Theme.of(context).colorScheme.tertiaryContainer,
          // set the border radius
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: BoxConstraints(
          // set the width
          minWidth: MediaQuery.of(context).size.width * 0.5,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          // set the height
          minHeight: MediaQuery.of(context).size.height * 0.5,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        // set the child
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ),
    );
  }
}

// on back press method
Future<bool> onBackPress(BuildContext context) async {
  // get the current path
  print('inside onBackPress');
  final currentPath = context.read<MyAppState>().currentPath;
  // check if the current path is home
  if (currentPath == '~') {
    // exit the app
    return true;
  } else {
    // update the path in appstate
    context.read<MyAppState>().updateCurrentPath(currentPath, goBack: true);
    // return false
    return false;
  }
}

// MyNextPage widget class that takes the result widget
class MyNextPage extends StatelessWidget {
  // constructor
  MyNextPage(this.path, {this.show404 = false, Key? key}) : super(key: key);

  // path
  final String? path;
  // show404
  final bool show404;

  @override
  Widget build(BuildContext context) {
    // check if path doesnt end with /
    print('path from MyNextPage: $path');
    String nPath = path!;
    String cPath = path!;
    if (path!.contains('ls')) {
      List dirs = context.read<MyAppState>().dirs;
      // get names of all the dirs and make a string
      String dirNames = '';
      for (var dir in dirs) {
        dirNames += dir['name'] + '/\t';
      }
      cPath = 'ls: $dirNames';
      // delete the string after :
      nPath = nPath.substring(0, nPath.indexOf(':')).replaceFirst('home', '~');
    } else if (path == '/') {
      nPath = '~';
      cPath = '~';
    } else {
      nPath = '~/$nPath';
      cPath = '~/$nPath';
    }
    return WillPopScope(
      onWillPop: () => onBackPress(context),
      child: Scaffold(
          // body is the majority of the screen.
          body: CustomScrollView(
        slivers: [
          // add the app bar
          SliverAppBar(
            // remove back button when routed from CustomSearchBar
            automaticallyImplyLeading: false,
            forceMaterialTransparency: true,
            // pin the search bar to the top when scrolled
            pinned: true,
            // set the title with Hero widget
            title: Hero(
              tag: 'searchBar',
              child: CustomSearchBar(nPath),
            ),
            centerTitle: true,
            // toolbar height
            toolbarHeight: 100,
          ),
          // add the result widget
          SliverFillRemaining(
            child: SizedBox(
                // set height to 80% of screen height
                height: 0.8 * MediaQuery.of(context).size.height,
                // set width to 80% of screen width
                width: 0.8 * MediaQuery.of(context).size.width,
                // set the child
                child: CustomText(cPath)),
          ),
        ],
      )),
    );
  }
}

