import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_state.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class CustomSearchBar extends StatelessWidget {
  CustomSearchBar(this.path, {this.touchMethod, super.key});

  final Function? touchMethod;

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
                '{ ${Provider.of<MyAppState>(context).name} } [ $path ]',
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
                          // set the controller
                          controller:
                              Provider.of<MyAppState>(context, listen: false)
                                  .terminalTextController,
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
                            _onSubmitted(context, value, touchMethod);
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
_onSubmitted(BuildContext context, String value, Function? touchMethod) {
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

    if (path == 'notes') {
      context.pushNamed('notes');
    } else if (path.contains('ls')) {
      context.push('/home:ls');
    } else if (path == 'sudo su') {
      // display modal
      _showLoginModal(context, 'vamsik8919@gmail.com');
    } else if (path.startsWith('user_login_')) {
      // display modal
      _showLoginModal(context, path.split('_')[2]);
    } else if (path.startsWith('passwd_reset')) {
      // if the user is logged in, show a popup to notify the user
      if (Provider.of<MyAppState>(context, listen: false).loggedIn) {
        // show the snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to your email!, '
                'Follow the instructions in the email to reset your password'),
          ),
        );
        // send the reset link to the email
        _auth.sendPasswordResetEmail(
            email: Provider.of<MyAppState>(context, listen: false).email);
      } else {
        // display modal
        String email = path.split('_')[3];
        if (email != '') {
          // send the reset link to the email
          _auth.sendPasswordResetEmail(email: email);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('A password reset link is sent to your email!, '
                  'Follow the instructions in the email to reset your password'),
            ),
          );
        }
      }
    } else if (path == 'logout') {
      // logout the user
      _auth.signOut();
      // show the snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully!'),
        ),
      );
    } else if (path.contains('user_update_')) {
      // update the name
      context.read<MyAppState>().updateName(path.split('_')[2]);
    } else if (path == 'touch') {
      touchMethod!();
    } else if (path == 'help') {
      context.push(Uri(path: '/home:help').toString());
    } else {
      context.pushNamed('404');
    }
  }

  // clear the text field
  Provider.of<MyAppState>(context, listen: false)
      .terminalTextController
      .clear();
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
  // touch command
  if (value.startsWith('touch')) {
    return 'touch';
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
  // to reset password
  if (value.startsWith('sudo passwd reset')) {
    // return 'passwd_reset';
    if (value.contains('-u')) {
      var email = value.split(' ')[4];
      return 'passwd_reset_u_$email';
    } else {
      return 'passwd_reset';
    }
  }
  // to logout
  if (value.startsWith('logout')) {
    return 'logout';
  }
  // update user data
  if (value.startsWith('sudo usermod -l')) {
    var uName = value.substring(16).trim();
    return 'user_update_$uName';
  }
  // check if the value is help
  if (value == 'help') {
    //  update the path in appstate
    context.read<MyAppState>().updateCurrentPath('');
    return 'help';
  } else {
    // update the path in appstate
    context.read<MyAppState>().updateCurrentPath('');
    return '';
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
                  // on submit call the function
                  onSubmitted: (value) {
                    // call the function
                    _onUserLoginDataSubmitted(context, email, value)
                        .then((value) {
                      if (value) {
                        // close the modal
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Login Successful! Update your name if not updated.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
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
