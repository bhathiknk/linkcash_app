import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class CreateLinkPage extends StatefulWidget {
  const CreateLinkPage({Key? key}) : super(key: key);

  @override
  _CreateLinkPageState createState() => _CreateLinkPageState();
}

class _CreateLinkPageState extends State<CreateLinkPage> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0054FF),
        title: const Text(
          "Create Link",
          style: TextStyle(fontSize: 20, color: Colors.white), // Title Text Style
        ),
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // Background color for the body
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Title",
                style: TextStyle(fontSize: 16, color: Colors.black), // Text Style
              ),
            ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Enter title...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Description Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Description",
                style: TextStyle(fontSize: 16, color: Colors.black), // Text Style
              ),
            ),
            // Description Large Input Field
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Enter description...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Amount Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Amount",
                style: TextStyle(fontSize: 16, color: Colors.black), // Text Style
              ),
            ),
            // Amount Input Field
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter amount...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Expire After Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Expire After",
                style: TextStyle(fontSize: 16, color: Colors.black), // Text Style
              ),
            ),
            SizedBox(height: 10),
            // Dropdown Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedOption,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    ),
                    items: <String>[
                      'One Hour',
                      'One Day',
                      'One Week',
                      'Unlimited',
                      'One Time Only'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedOption = newValue;
                        if (newValue == 'One Time Only') {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Remember'),
                                content: Text(
                                  'If one time selected, link will expire immediately after the payment',
                                  style: TextStyle(color: Colors.red,fontSize: 18), // Set text color to red
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 60),

            // Image Input
            Row(
              mainAxisSize: MainAxisSize.min, // Lock the row size
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Image.asset(
                    'lib/images/coverimage.jpg', // Default image path
                    width: 200,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add onPressed logic for the button
                  },
                  child: Text(
                    'Select Cover Image',
                    style: TextStyle(color: Colors.white), // Text color
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0054FF), // Background color
                  ),
                ),
              ],
            ),

            // Save Button
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5, // Adjust width
                  child: ElevatedButton(
                    onPressed: () {
                      // Add onPressed logic for the save button
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0054FF),
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
