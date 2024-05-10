import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../WidgetsCom/bottom_navigation_bar.dart';

class LinkViewPage extends StatelessWidget {
  const LinkViewPage({Key? key});

  @override
  Widget build(BuildContext context) {
    // Create a TextEditingController
    TextEditingController textEditingController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0054FF),
        title: const Text(
          'Link View Page',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // Background color for the body
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// QR image section ///
            Align(
              alignment: FractionalOffset.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0), // top padding between app bar and QR
                child: Column(
                  children: [
                    Image.asset(
                      'lib/images/qrcode.png',
                      width: 220, // Adjust width
                      height: 220, // Adjust height
                    ),
                    const SizedBox(height: 20), // Add spacing
                  ],
                ),
              ),
            ),
            /// QR image section end ///

            /// Title Label///
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Payment Link",
                style: TextStyle(fontSize: 16, color: Colors.black), // Text Style
              ),
            ),
            const SizedBox(height: 5),
            // Title Input Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: textEditingController, // Assign the TextEditingController to the TextFormField
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/checkout?product=example_product&price=19.99&currency=USD',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      // Copy link functionality
                      String text = textEditingController.text; // Get the text from the text field
                      if (text.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Link copied to clipboard'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10), // Add spacing
            // Share Link Button
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  // Share link functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0054FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Share Link',
                  style: TextStyle(color: Colors.white),
                ),
              ),
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
            ///End of the Transaction ///
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }
}
