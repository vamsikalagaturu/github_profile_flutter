import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:unique_name_generator/unique_name_generator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Vamsi Kalagaturu',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
        // handle the unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (_) => PageNotFound());
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var ung = UniqueNameGenerator(
    dictionaries: [adjectives, animals],
    style: NameStyle.capital,
    separator: '',
  );

  var current = '';

  MyAppState() {
    current = ung.generate();
  }

  void getNext() {
    current = ung.generate();
    notifyListeners();
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var robotName = appState.current;

    IconData icon = Icons.copy;

    // style for the text
    var style = Theme.of(context).textTheme.bodyLarge!.copyWith(
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );

    // copy the name to clipboard
    void copyName() async {
      Clipboard.setData(ClipboardData(text: robotName)).then((_){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Name copied to clipboard")));
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('The page is still under development, meanwhile enjoy this '
                  'random robot name generator :)', style: style),
            SizedBox(height: 10),
            BigCard(robotName: robotName),
            SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  child: Text('Generate'),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    copyName();
                  },
                  icon: Icon(icon),
                  label: Text('Copy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PageNotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Center(
        child: Text('Dude, this page doesn\'t exist!'),
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.robotName,
  }) : super(key: key);

  final String robotName;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(robotName, style: style),
      ),
    );
  }
}
