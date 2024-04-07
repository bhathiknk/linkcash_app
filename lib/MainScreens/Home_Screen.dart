import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container( // Card Container
            margin: EdgeInsets.only(top: 90, left: 10, right: 10), // Added margin
            width: double.infinity, // Full width
            height: 140.0, // Reduced height
            child: Card(
              elevation: 5,
              shadowColor: Colors.black,
              color: Color(0xFF002FA7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Your Balance',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                  Text(
                    '\$1000', // Replace this with your balance value
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
            child: Stack(
              children: [
                // Your page content goes here
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70.0, // Fixed height or adjust as needed
        child: BottomNavigationBarWithFab(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
