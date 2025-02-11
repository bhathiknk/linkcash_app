import 'package:flutter/material.dart';
import 'package:linkcash_app/WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

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
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: DarkModeHandler.getBackgroundColor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Container(
                color: DarkModeHandler.getTopContainerColor(),
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0), // Added horizontal padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5.0), // Adjust horizontal padding
                        child: SizedBox(
                          height: 45, // Set a consistent height if needed
                          width: 150, // Set a consistent width if needed
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: selectedIndex == 0
                                  ? const Color(
                                      0xFF83B6B9) // Color for selected button
                                  : const Color(
                                      0xFFB0BEC5), // Lighter color for unselected button
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedIndex = 0;
                              });
                              // Handle "All" button press
                            },
                            child: const Text(
                              'All',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 8), // Adjust space between buttons if needed
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5.0), // Adjust horizontal padding
                        child: SizedBox(
                          height: 45, // Set a consistent height if needed
                          width: 150, // Set a consistent width if needed
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: selectedIndex == 1
                                  ? const Color(
                                      0xFF83B6B9) // Color for selected button
                                  : const Color(
                                      0xFFB0BEC5), // Lighter color for unselected button
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedIndex = 1;
                              });
                              // Handle "Unread" button press
                            },
                            child: const Text(
                              'Unread',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Added space between containers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DarkModeHandler.getMainContainersColor(),
                  borderRadius: BorderRadius.circular(10.0),
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
                    const SizedBox(height: 10),
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
