import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:io_page/assets/icons/custom_icons_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dirs.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dirs.dart';
import 'two_link_manipulator.dart';
import 'notes.dart';
import 'custom_search_bar.dart';
import 'help.dart';

import 'app_state.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

void main() async {
  // set the url strategy for web
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  // initialize firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
      // use provider and change notifier
      ChangeNotifierProvider(
    create: (context) => MyAppState(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  GoRouter router() {
    return GoRouter(
      // set the initial path
      initialLocation: '/',

      // redirect from / to /home/
      redirect: (context, state) {
        print('Redirecting to: ${state.location}');

        if (state.location == '/home' || state.location == '/') {
          return '/';
        }

        // if path is /notes check if user is logged in
        if (state.location == '/notes') {
          if (_auth.currentUser != null) {
            return state.location;
          } else {
            return '/404';
          }
        }
        return state.location;
      },

      // set the path to home page
      routes: _routes(),

      // set the path to unknown page
      errorPageBuilder: (context, state) {
        return MaterialPage(
            child: MyNextPage('404', resultWidget: Container(), show404: true));
      },
    );
  }

  List<GoRoute> _routes() => [
        GoRoute(
          name: '404',
          path: '/404',
          pageBuilder: (context, state) {
            return MaterialPage(
                child: MyNextPage('404',
                    resultWidget: Container(), show404: true));
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
                name: 'notes',
                path: 'notes',
                pageBuilder: (context, state) {
                  return MaterialPage(
                    child: NotesPage(
                        firestore: _firestore, uid: _auth.currentUser!.uid),
                  );
                },
              ),
            ]),
        GoRoute(
          path: '/home:command',
          pageBuilder: (context, state) {
            print('command: ${state.pathParameters['command']}');
            if (state.pathParameters['command'] == ':help') {
              return MaterialPage(
                  child: MyNextPage('help', resultWidget: Help()));
            } else if (state.pathParameters['command'] == ':ls') {
              // get the dirs
              var lsRes = context.read<MyAppState>().currentDir.getChildren();
              return MaterialPage(
                  child: MyNextPage('ls', resultWidget: CustomText(lsRes)));
            }
            return MaterialPage(
                child: MyNextPage(state.pathParameters['command'],
                    resultWidget:
                        Center(child: Text(state.pathParameters['command']!))));
          },
        ),
      ];

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
        routerConfig: router());
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

// Custom text widget
class CustomText extends StatelessWidget {
  // constructor
  const CustomText(this.text, {Key? key}) : super(key: key);

  // text
  final dynamic text;

  @override
  Widget build(BuildContext context) {
    print(text);
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
          // handle single string and list of strings
          text is String ? text : text.join('\t'),
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
  MyNextPage(this.path,
      {required this.resultWidget, this.show404 = false, Key? key})
      : super(key: key);

  // path
  final String? path;
  // show404
  final bool show404;
  // result widget
  final Widget resultWidget;

  // 404 widget
  Widget get error404Widget => Center(
        child: CustomText(
          '404: Page not found',
          key: const Key('404'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // check if path doesnt end with /
    String nPath = path!;
    if (path!.contains('ls')) {
      // delete the string after :
      nPath = '~';
    } else if (path == '/') {
      nPath = '~';
    } else {
      nPath = '~/$nPath';
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
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              width: 300,
              child: show404 ? error404Widget : resultWidget,
            ),
          ),
        ],
      )),
    );
  }
}
