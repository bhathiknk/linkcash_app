import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import 'Create_Link_Screen.dart';

class LinkPage extends StatelessWidget {
  const LinkPage({Key? key});

  @override
  Widget build(BuildContext context) {
    // Define an array of colors for the circles
    List<Color> circleColors = [
      Color(0xFF0012fb),
      Color(0xffff0000),
      Color(0xff28b600),
      Color(0xffff8a00),
      Color(0xff8b00a9),
      Color(0x9b1e1d06)
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Payment Link',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: DarkModeHandler.getBackgroundColor(), // Background color for the body
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: Container(
                decoration: BoxDecoration(
                  color: DarkModeHandler.getMainContainersColor(),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()), // Set hint text color
                      prefixIcon: Icon(Icons.search, color: DarkModeHandler.getInputTextColor()), // Set search icon color
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(top: 12.0),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateLinkPage()),
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
                ),
              ),
            ),
            SizedBox(height: 20),
             Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Link History',
                  style: TextStyle(
                    fontSize: 18,
                    color: DarkModeHandler.getMainContainersTextColor(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    8,
                        (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: 100,
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
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: circleColors[index % circleColors.length], // Get color based on index
                                    shape: BoxShape.rectangle, // Make it rectangle
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff000000).withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 1,
                                        offset: Offset(2, 2), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.attach_money,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                 Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Link Title",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: DarkModeHandler.getMainContainersTextColor(),),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8),
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
