import 'dart:async';
import 'dart:js';
import 'dart:math' as math;
import 'dart:ui';

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
                '{ Vamsi Kalagaturu } [ $path ]',
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
    } else {
      context.pushNamed('404');
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
  // ls command
  if (value.startsWith('ls')) {
    return 'ls';
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

// animate a two link manipulator robot
class TwoLinkManipulator extends StatefulWidget {
  // set canvas width and height to parent widget width and height

  // constructor
  TwoLinkManipulator({Key? key}) : super(key: key);

  @override
  TwoLinkManipulatorState createState() => TwoLinkManipulatorState();
}

class TwoLinkManipulatorState extends State<TwoLinkManipulator>
    with SingleTickerProviderStateMixin {
  // animation controller
  late AnimationController _controller;
  late Animation<double> _animation;

  double _angle1 = 0;
  double _angle2 = 0;

  double _cursorX = 0;
  double _cursorY = 0;

  double _link1Length = 90;
  double _link2Length = 50;
  double _angle1Min = 0;
  double _angle1Max = math.pi * 2;
  double _angle2Min = -math.pi;
  double _angle2Max = math.pi;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateCursorPosition(PointerEvent event, BuildContext context) {
    setState(() {
      _cursorX = event.localPosition.dx;
      _cursorY = event.localPosition.dy;
    });
    print('as cursorX: $_cursorX, cursorY: $_cursorY');
    _animateToCursor(context);
  }

  // translate the cursor position to the manipulator world with origin at the center of the canvas
  Offset _translateCursorPosition(width, height) {
    print('cursorX: $_cursorX, cursorY: $_cursorY');
    return Offset(
      _cursorX - width / 2,
      _cursorY - height / 2,
    );
  }

  void _animateToCursor(BuildContext context) {
    // get size of the parent widget
    final size = context.size;

    // animate the manipulator from the previous position to the current position
    final initialAngle1 = _angle1;
    final initialAngle2 = _angle2;

    Offset ik = _calculateInverseKinematics(size?.width, size?.height);

    final targetAngle1 = ik.dx;
    final targetAngle2 = ik.dy;

    _controller.reset();

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller)
      ..addListener(() {
        setState(() {
          _angle1 = lerpDouble(
            initialAngle1,
            targetAngle1,
            _animation.value,
          )!;
          _angle2 = lerpDouble(
            initialAngle2,
            targetAngle2,
            _animation.value,
          )!;
        });
      });

    _controller.forward();
  }

  Offset _calculateInverseKinematics(width, height) {
    Offset cursorPosition = _translateCursorPosition(width, height);

    double angle1 = math.atan2(cursorPosition.dy, cursorPosition.dx);
    double angle2 = 0;

    double distance = cursorPosition.distance;
    double distanceSquared = distance * distance;

    double link1LengthSquared = _link1Length * _link1Length;
    double link2LengthSquared = _link2Length * _link2Length;

    double cosAngle2 =
        (distanceSquared - link1LengthSquared - link2LengthSquared) /
            (2 * _link1Length * _link2Length);

    if (cosAngle2 < -1 || cosAngle2 > 1) {
      return Offset(angle1, angle2);
    }

    angle2 = math.acos(cosAngle2);

    double sinAngle2 = math.sin(angle2);

    double k1 = _link1Length + _link2Length * cosAngle2;

    double k2 = _link2Length * sinAngle2;

    angle1 = math.atan2(cursorPosition.dy * k1 - cursorPosition.dx * k2,
        cursorPosition.dx * k1 + cursorPosition.dy * k2);

    return Offset(angle1, angle2);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return MouseRegion(
        onHover: (event) => _updateCursorPosition(event, context),
        cursor: SystemMouseCursors.none,
        child: GestureDetector(
          onTap: () => {
            _updateCursorPosition,
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: ManipulatorPainter(
              angle1: _angle1,
              angle2: _angle2,
              cursorX: _cursorX,
              cursorY: _cursorY,
              link1Length: _link1Length,
              link2Length: _link2Length,
              angle1Min: _angle1Min,
              angle1Max: _angle1Max,
              angle2Min: _angle2Min,
              angle2Max: _angle2Max,
            ),
          ),
        ),
      );
    });
  }
}

class ManipulatorPainter extends CustomPainter {
  final double angle1;
  final double angle2;
  final double cursorX;
  final double cursorY;
  final double link1Length;
  final double link2Length;
  final double angle1Min;
  final double angle1Max;
  final double angle2Min;
  final double angle2Max;

  ManipulatorPainter(
      {required this.angle1,
      required this.angle2,
      required this.cursorX,
      required this.cursorY,
      required this.link1Length,
      required this.link2Length,
      required this.angle1Min,
      required this.angle1Max,
      required this.angle2Min,
      required this.angle2Max});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw reachable workspace shade
    final shadePaint = Paint()..color = Colors.blue.withOpacity(0.2);

    // draw a hollow circle to represent the reachable workspace with
    // inner radius = link1Length - link2Length
    // outer radius = link1Length + link2Length

    final double innerRadius = link1Length - link2Length;
    final double outerRadius = link1Length + link2Length;

    final shadeTransparentPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.2);

    // draw the inner circle with transparent paint
    canvas.drawCircle(
      center,
      innerRadius,
      shadeTransparentPaint,
    );

    // draw the outer circle
    canvas.drawCircle(
      center,
      outerRadius,
      shadePaint,
    );

    // Draw links
    final link1Paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final link2Paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final x1 = center.dx + link1Length * math.cos(angle1);
    final y1 = center.dy + link1Length * math.sin(angle1);
    final link1End = Offset(x1, y1);

    final x2 = x1 + link2Length * math.cos(angle1 + angle2);
    final y2 = y1 + link2Length * math.sin(angle1 + angle2);
    final link2End = Offset(x2, y2);

    canvas.drawLine(center, link1End, link1Paint);
    canvas.drawLine(link1End, link2End, link2Paint);

    // Draw cursor
    final cursorPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(
        PointMode.points, [Offset(cursorX, cursorY)], cursorPaint);
  }

  @override
  bool shouldRepaint(ManipulatorPainter oldDelegate) {
    return oldDelegate.angle1 != angle1 ||
        oldDelegate.angle2 != angle2 ||
        oldDelegate.cursorX != cursorX ||
        oldDelegate.cursorY != cursorY;
  }
}
