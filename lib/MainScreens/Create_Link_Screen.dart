import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class LinkPage extends StatelessWidget {
  const LinkPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0054FF),
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // Background color for the body
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity, // To match parent width
              height: 50.0, // Adjust height as needed
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none, // Remove border
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20), // Adjust height as needed
            SizedBox(
              width: double.infinity, // To match parent width
              height: 50.0, // Adjust height as needed
              child: ElevatedButton(
                onPressed: () {
                  // Handle create link button press
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0054FF), // Set button background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Set button border radius
                  ),
                ),
                child: const Text(
                  'Create Link',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ), // Adjust button text style
              ),
            ),
            SizedBox(height: 20), // Add spacing between button and text
            const Padding(
              padding: EdgeInsets.only(left: 8.0), // Add left padding
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Link History',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    8, // Number of items in the list
                        (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Container(
                        width: double.infinity, // Set a fixed width
                        height: 100, // Set a fixed height
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 2), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Image.asset('lib/images/pay-15.png'), // Add image
                              SizedBox(width: 70), // Add spacing between image and text
                              const Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Link Title",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Adjust font size and style
                                      textAlign: TextAlign.center, // Align text to the center
                                    ),
                                    SizedBox(height: 8), // Add spacing between title and other text
                                    // Add other text widgets here
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),




          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
