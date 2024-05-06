import 'package:flutter/material.dart';

import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      ///App bar ///
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF0054FF),
        title: const Text(
          'Link Cash',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Container(
        color: Color(0xFFE3F2FD),//background colour
        child: Column(
          children: [
            Stack(
              children: [
                ///Top White Container///
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


                ///'Welcome Back' text///
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


                ///'Bhathika Nilesh' text///
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


                ///Notification icon///
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(Icons.notifications, size: 25, color: Colors.grey),
                ),


                ///balance show container///
                Positioned(
                  top: 80, // Adjust the position as needed
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1), // changes position of shadow
                        ),
                      ],
                    ),

                    ///Balance text and value///
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


            ///calendar container///
            const SizedBox(height: 10), // space between the white container and the calendar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: MediaQuery.of(context).size.width - 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CalendarWidget(),
            ),

            /// 'Transactions' text///
            const SizedBox(height: 20), // Add some space between the white calendar  container and the Transaction text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(), // Add flexible space to push the text to the left
                ],
              ),
            ),


            /// Transactions show container///
            Expanded(
              child: Container(
                width: double.infinity, // Make container full width
                padding: const EdgeInsets.all(5), // Add padding to the container
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      5, // Number of SizedBox to duplicate
                          (index) => Column(
                        children: [
                          const SizedBox(
                            height: 20, // Add space between SizedBox widgets
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10), // Adjust the border radius
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3), // Shadow color
                                  spreadRadius: 1, // Spread radius
                                  blurRadius: 1, // Blur radius
                                  offset: Offset(0, 3), // Shadow offset
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 10, // Adjust the width
                              height: 100, // Adjust the height
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align content horizontally
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center, // Align content vertically
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          "Payment Link Title",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.0,top: 8.0),
                                        child: Text(
                                          "Bhathika",
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "\$300",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
