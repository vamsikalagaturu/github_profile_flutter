import 'dart:js';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:io_page/assets/icons/custom_icons_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dirs.dart';

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

GoRouter router(context) {
  // print the current path
  print('Current dirs : ${Provider.of<MyAppState>(context, listen: false).dirs}');

  List dirs = Provider.of<MyAppState>(context, listen: false).dirs;

  return GoRouter(
    // set the initial path
    initialLocation: '/',

    // redirect from / to /home/
    redirect: (context, state) => state.location == '/home' ? '/' : null,

    // set the path to home page
    routes: [
      GoRoute(
          name: 'home',
          path: '/',
          pageBuilder: (context, state) {
            return MaterialPage(child: MyHomePage());
          },
          routes: [
            for (var dir in dirs)
              GoRoute(
                name: dir['name'],
                path: dir['path'],
                pageBuilder: (context, state) {
                  return MaterialPage(child: MyNextPage(state.path));
                },
              ),
          ]),
      GoRoute(
        path: '/404',
        pageBuilder: (context, state) {
          return MaterialPage(child: MyNextPage('/404', show404: true));
        },
      ),
    ],

    // set the path to unknown page
    errorPageBuilder: (context, state) {
      return MaterialPage(child: MyNextPage('/404', show404: true));
    },
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        title: 'Vamsi Kalagaturu',
        theme: ThemeData(
          useMaterial3: true,
          // use dark theme
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
        ),
        routerConfig: router(context));
  }
}

// app state class
class MyAppState extends ChangeNotifier {
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

  // function to add a new directory
  void addDir(String name, String path) {
    dirs.add({'name': name, 'path': path});
    notifyListeners();
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
        child: Hero(
          tag: 'searchBar',
          child: CustomSearchBar('~'),
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
              padding: const EdgeInsets.all(5),
              // decoration
              decoration: BoxDecoration(
                // set the color with the color set in the theme
                // color: Theme.of(context).colorScheme.tertiaryContainer,
                // set the border radius
                borderRadius: BorderRadius.circular(10),
              ),
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '{ ',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    TextSpan(
                      text: 'Vamsi Kalagaturu',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    TextSpan(
                      text: ' } ',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    TextSpan(
                      text: ' [ ',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    TextSpan(
                      text: path,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    TextSpan(
                      text: ' ]',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
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
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
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
                            contentPadding: const EdgeInsets.only(bottom: 3),
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

    // get the current path
    final currentPath = context.read<MyAppState>().currentPath;

    // if path is ~ then show the home page
    if (path == '~') {
      // go to home page
      context.pushReplacementNamed('home');
    } else if (path.startsWith('/')) {
    } else if (path.startsWith('~/')) {
    } else if (!path.contains('mkdir_')) {
      context.pushNamed(path);
      // context.pushNamed('next', pathParameters: {'path': currentPath});
    }
  }
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
  // mkdir command
  if (value.startsWith('mkdir')) {
    // get the path
    String path = value.substring(5).trim();
    // check if the path is empty
    if (path.isEmpty) {
      // show the snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('mkdir: missing operand'),
        ),
      );
      // don't update the path in appstate
      return '';
    } else {
      // update the path in appstate
      context.read<MyAppState>().addDir(path, path);
      return 'mkdir_$path';
    }
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
        child: Text(
          text,
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
    String nPath = path!;
    if (!path!.endsWith('/')) {
      // remove the string after the last /
      nPath = path!.substring(0, path!.lastIndexOf('/') + 1);
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
                child: CustomText('result widget: $path')),
          ),
        ],
      )),
    );
  }
}
