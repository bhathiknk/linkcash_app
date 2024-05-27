import 'package:flutter/material.dart';
import 'MainScreens/Home_Screen.dart';
import 'WidgetsCom/dark_mode_handler.dart';
import 'MainScreens/Welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DarkModeHandler.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      initialRoute: WelcomeScreen.routeName,
      routes: {
        WelcomeScreen.routeName: (context) => MyHomePage(),
      },
    );
  }
}
