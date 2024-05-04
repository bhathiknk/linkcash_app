import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Track the selected index

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Link Cash'),
      ),
      body: Container(
        color: Color(0xFF0054FF),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  height: 200,
                ),
                const Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      SizedBox(width: 10), // Add some space between the icon and text
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.waving_hand_rounded, size: 20),
                    ],
                  ),
                ),
                const Positioned(
                  top: 30, // Adjust the position as needed
                  left: 20,
                  child: Text(
                    'Bhathika Nilesh',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
