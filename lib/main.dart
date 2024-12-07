import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'MainScreens/Home_Screen.dart';
import 'WidgetsCom/dark_mode_handler.dart';
import 'MainScreens/Welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DarkModeHandler.initialize();
  await dotenv.load(fileName: ".env"); // Load the .env file
  runApp(MyApp());
}

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
