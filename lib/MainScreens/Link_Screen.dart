import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import 'Create_Link_Screen.dart';

class LinkPage extends StatelessWidget {
  const LinkPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0054FF),
        title: const Text(
          'Payment Link',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      ///body start///
      body: Container(
        color: const Color(0xFFE3F2FD), // Background color for the body
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///Search Bar Start///
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2), // position of shadow
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            ///Search Bar End///

            ///Create Link Button start///
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50.0, // Adjust height as needed
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateLinkPage()), // Navigate to CreateLinkPage
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0054FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
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
            ///Create Link Button End///

            ///'Saved Link History' Text start///
            SizedBox(height: 20), // Add spacing between button and text
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
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
            ///'Saved Link History' Text end///

            ///Container start///
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    8, // Number of items in the list
                        (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Container(
                        width: double.infinity,
                        height: 100,
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
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Image.asset('lib/images/pay-15.png'),
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
            ///Container start///
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
