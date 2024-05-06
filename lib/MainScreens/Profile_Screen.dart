import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = false; // Initially set to false for light mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF0054FF),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: Color(0xFFE3F2FD), // Background color
        child: Column(
          children: [
            Stack(
              children: [
                // Top White Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  height: 200,
                ),

                // Notification icon
                Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(Icons.edit, size: 25, color: Colors.grey),
                ),

                // Profile Image Container
                Positioned(
                  top: 30, // Adjust the top position as needed
                  left: MediaQuery.of(context).size.width / 2 - 50, // Center horizontally
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'lib/images/coverimage.jpg', // Profile image path
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Text underneath profile image
                Positioned(
                  top: 140, // Adjust the top position as needed
                  left: MediaQuery.of(context).size.width / 2 - 70, // Center horizontally
                  child: Column(
                    children: [
                      Text(
                        'Bhathika Niles',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'bhathika@gmail.com',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // On/Off Switch Button
                Positioned(
                  top: 5,
                  left: 5,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isDarkMode = !isDarkMode; // Toggle the mode
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 600),
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black : Colors.blue[300], // Toggle color based on mode
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.grey : Colors.transparent,
                            blurRadius: 5,
                            spreadRadius: 2,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded, // Toggle icon based on mode
                            size: 25,
                            color: Colors.yellow,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isDarkMode ? 'Dark Mode' : 'Light Mode', // Toggle text based on mode
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Added list of containers
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                5, // Number of items in the list
                    (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    height: 80,
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
                  ),
                ),
              ),
            ),

            SizedBox(height: 10), // Add spacing between button and text
            const Padding(
              padding: EdgeInsets.only(left: 15.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(left: 15.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),

      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 3,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
