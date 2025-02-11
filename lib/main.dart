import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'WidgetsCom/dark_mode_handler.dart';
import 'MainScreens/Welcome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  await DarkModeHandler.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
