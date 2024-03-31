import 'package:flutter/material.dart';

import 'Welcome.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      initialRoute: WelcomeScreen.routeName,
      routes: {
        WelcomeScreen.routeName: (context) => WelcomeScreen(),
      },
    );
  }
}
