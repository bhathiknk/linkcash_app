import 'package:flutter/material.dart';
import 'package:linkcash_app/WidgetsCom/dark_mode_handler.dart';
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
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white, // Set text color to white
          ),
        ),
        centerTitle: true, // Center the title
      ),
      body: Container(
        color: DarkModeHandler.getBackgroundColor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 10.0), // Added padding to create space
              child: Container(
                color: DarkModeHandler.getTopContainerColor(),
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
                  color: DarkModeHandler.getMainContainersColor(),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff000000).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: Offset(2, 2), // changes position of shadow
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
                        color: DarkModeHandler.getMainContainersTextColor(),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Notification Details",
                      style: TextStyle(
                        fontSize: 16,
                        color: DarkModeHandler.getMainContainersTextColor(),
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
