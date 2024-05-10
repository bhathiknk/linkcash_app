import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int selectedIndex = 0; // Track the selected button index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0054FF),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white, // Set text color to white
          ),
        ),
        centerTitle: true, // Center the title
      ),
      body: Container(
        color: Color(0xFFE3F2FD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10.0), // Added padding to create space
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedIndex = 0; // Update the selected index
                            });
                            // Handle "All" button press
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedIndex == 0 ? Color(0xFF0054FF) : null,
                          ),
                          child: Text(
                            'All',
                            style: TextStyle(
                              color: selectedIndex == 0 ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedIndex = 1; // Update the selected index
                            });
                            // Handle "Unread" button press
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedIndex == 1 ? Color(0xFF0054FF) : null,
                          ),
                          child: Text(
                            'Unread',
                            style: TextStyle(
                              color: selectedIndex == 1 ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20), // Added space between containers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0), // Added margin
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 3), // position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notification Title",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Notification Details",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 1,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
