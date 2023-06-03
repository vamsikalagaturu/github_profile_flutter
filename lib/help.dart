import 'package:flutter/material.dart';

var helpText = "Available commands:\n"
    "help : show this help\n"
    "cd dir_name : change directory\n"
    "su - email : login as user\n"
    "sudo passwd reset : reset password\n"
    "logout : logout\n"
    "sudo usermod -l new_name : change username\n"
    "touch : create a new instance of a widget in current context\n";

// help widget to show text
class Help extends StatelessWidget {
  const Help({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(helpText));
  }
}
