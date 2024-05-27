import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import 'Link_View_Screen.dart';

class CreateLinkPage extends StatefulWidget {
  const CreateLinkPage({Key? key}) : super(key: key);

  @override
  _CreateLinkPageState createState() => _CreateLinkPageState();
}

class _CreateLinkPageState extends State<CreateLinkPage> {
  String? selectedOption;
  String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          "Create Link",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
      backgroundColor: DarkModeHandler.getBackgroundColor(), // Set the background color here
      body: Container(
        color: DarkModeHandler.getBackgroundColor(), // Ensure the container has the same background color
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "Title",
                    style: TextStyle(fontSize: 16, color: DarkModeHandler.getTextColor()),
                  ),
                ),
                // Title Input Field
                Container(
                  decoration: BoxDecoration(
                    color: DarkModeHandler.getCalendarContainerColor(),
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
                      TextFormField(
                        decoration:  InputDecoration(
                          hintText: 'Enter title...',
                          hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()),
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
                    style: TextStyle(fontSize: 16, color: DarkModeHandler.getTextColor()),
                  ),
                ),
                // Description Large Input Field
                Container(
                  decoration: BoxDecoration(
                    color: DarkModeHandler.getCalendarContainerColor(),
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
                      TextFormField(
                        maxLines: 5,
                        decoration:  InputDecoration(
                          hintText: 'Enter description...',
                          hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()),
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
                    style: TextStyle(fontSize: 16, color: DarkModeHandler.getTextColor()),
                  ),
                ),
                // Amount Input Field
                Container(
                  decoration: BoxDecoration(
                    color: DarkModeHandler.getCalendarContainerColor(),
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
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration:  InputDecoration(
                          hintText: 'Enter amount...',
                          hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()),
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
                    style: TextStyle(fontSize: 16, color: DarkModeHandler.getTextColor()),
                  ),
                ),

                // Dropdown Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: DarkModeHandler.getContainersShadowColor(),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(2, 2), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedOption,
                        dropdownColor: Colors.white, // Set the dropdownColor property
                        borderRadius: BorderRadius.circular(10.0),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
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
                                      'If one time selected, link will expire immediately after the payment.',
                                      style: TextStyle(color: Colors.red, fontSize: 18),
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

                SizedBox(height: 15),
                // Image Input
                GestureDetector(
                  onTap: () {
                    if (imagePath == null) {
                      // Show a dialog with option to add an image
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Image Options'),
                            content: Text('Do you want to add an image?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setState(() {
                                      imagePath = pickedFile.path; // Handle adding an image
                                      Navigator.of(context).pop();
                                    });
                                  }
                                },
                                child: Text('Add'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // Show a dialog with options to remove/change image
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Image Options'),
                            content: Text('Do you want to remove or change the image?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    imagePath = null; // Remove the image
                                    Navigator.of(context).pop();
                                  });
                                },
                                child: Text('Remove'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setState(() {
                                      imagePath = pickedFile.path; // Change the image
                                      Navigator.of(context).pop();
                                    });
                                  }
                                },
                                child: Text('Change'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.6),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter, // Align the children at the bottom
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: imagePath != null
                                ? Image.file(
                              File(imagePath!),
                              width: 250,
                              height: 150, // Increase the height here
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              'lib/images/coverimage.jpg',
                              width: 250,
                              height: 160, // Increase the height here
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            width: 250,
                            height: 40,
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(8.0), // Adjust padding
                            color: Colors.grey.withOpacity(0.7), // Grey color with opacity
                            child: Text(
                              'Select Cover Image',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.only(top: 20.0), // Adjust the top padding here
                  child: Align(
                    alignment: Alignment.center, // Align the button to the center
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LinkViewPage()),
                          );
                        },
                        child: Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0054FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
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
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
