import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:io_page/assets/icons/custom_icons_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer';

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

}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final scrollController = ScrollController();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: LayoutBuilder(builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SplashScreenWidget(constraints: constraints),
                    Footer(context: context, constraints: constraints),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({
    Key? key,
    required this.context,
    required this.constraints,
  }) : super(key: key);

  final BuildContext context;
  final BoxConstraints constraints;

  copyText(String text) async {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Copied to clipboard")));
    });
  }

  void _sendMailTo() async {
    const emailId = 'vamsikalagaturu@gmail.com';
    final Uri uri = Uri(
      scheme: 'mailto',
      path: emailId,
    );

    if (kIsWeb) {
      // get the platform
      var platform = Theme.of(context).platform;

      if (platform == TargetPlatform.linux ||
          platform == TargetPlatform.windows ||
          platform == TargetPlatform.macOS) {
        await copyText(emailId);
      } else {
        // if the platform is not web, open the mail app
        if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
          await copyText(emailId);
          throw 'Could not launch $uri';
        }
      }
    } else {
      // NOT running on the web! You can check for additional platforms here.
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        await copyText(emailId);
        throw 'Could not launch $uri';
      }
    }
  }

  // flexible widget to show the footer
  Widget _footerItem(String text, IconData icon, {Function? onTap}) {
    return Flexible(
      child: InkWell(
        onTap: onTap as void Function()?,
        child: SizedBox(
          width: constraints.maxWidth / 3,
          height: constraints.maxHeight / 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 25,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              SizedBox(height: 10),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight / 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _footerItem('Github', CustomIcons.github_mark, onTap: () {
            launchUrl(Uri.parse('vamsikalagaturu.github.io'));
          }),
          _footerItem('Email', Icons.email, onTap: () {
            _sendMailTo();
          }),
          _footerItem('LinkedIn', CustomIcons.linkedin_squared, onTap: () {
            launchUrl(
                Uri.parse('https://www.linkedin.com/in/vamsikalagaturu/'));
          }),
          _footerItem('Twitter', CustomIcons.logo_black, onTap: () {
            launchUrl(Uri.parse('https://twitter.com/vamsikalagaturu'));
          }),
        ],
      ),
    );
  }
}

class SplashScreenWidget extends StatelessWidget {
  SplashScreenWidget({
    Key? key,
    required this.constraints,
  }) : super(key: key);

  final BoxConstraints constraints;

  // theme for the Name
  final TextStyle nameStyle = TextStyle(
      color: Colors.white,
      fontSize: 40,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 8, offset: Offset(10, 10))
      ]);

  // theme for the title
  final TextStyle titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 8, offset: Offset(10, 10))
      ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/italy_blur.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              shape: const CircleBorder(side: BorderSide.none),
              elevation: 15,
              shadowColor: Colors.deepOrange,
              child: CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage('assets/images/dp.jpg'),
              ),
            ),
            SizedBox(height: 10),
            Text('Vamsi Kalagaturu', style: nameStyle),
            SizedBox(height: 10),
            Text('Roboticist', style: titleStyle),
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
