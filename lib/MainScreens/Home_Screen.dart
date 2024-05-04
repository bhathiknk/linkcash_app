import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';

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
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(Icons.notifications, size: 25, color: Colors.grey),
                ),
                Positioned(
                  top: 80, // Adjust the position as needed
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey[350], // Grey color container
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1), // changes position of shadow
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '\$800.00',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 30,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Add some space between the white container and the calendar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: MediaQuery.of(context).size.width - 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CalendarWidget(),
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
