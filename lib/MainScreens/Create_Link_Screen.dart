import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/gradient_button_fb4.dart';
import 'Link_View_Screen.dart';

class CreateLinkPage extends StatefulWidget {
  const CreateLinkPage({Key? key}) : super(key: key);

  @override
  _CreateLinkPageState createState() => _CreateLinkPageState();
}

class _CreateLinkPageState extends State<CreateLinkPage> {
  String? selectedOption; // Selected option from dropdown
  String? imagePath; // Stores the selected image path
  bool isConnected = true; // Tracks the internet connection status

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
  }

  // Checks the initial connectivity status
  Future<void> _checkConnectivity() async {
    var connectivityResult = await _connectivityService.checkInitialConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  // Updates the connection status based on the result
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: DarkModeHandler.getBackgroundColor(),
      body: isConnected ? _buildMainContent() : NoInternetUI(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      resizeToAvoidBottomInset: true,
    );
  }

  // Builds the app bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: DarkModeHandler.getAppBarColor(),
      title: const Text(
        "Create Link",
        style: TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

  // Builds the main content of the screen
  Widget _buildMainContent() {
    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Title"),
              _buildTextField(hint: 'Enter title...'),
              SizedBox(height: 20),
              _buildLabel("Description"),
              _buildTextField(hint: 'Enter description...', maxLines: 5),
              SizedBox(height: 20),
              _buildLabel("Amount"),
              _buildTextField(hint: 'Enter amount...', keyboardType: TextInputType.number),
              SizedBox(height: 20),
              _buildLabel("Expire After"),
              _buildDropdownButton(),
              SizedBox(height: 15),
              _buildImagePicker(),
              SizedBox(height: 20),
              _buildSaveLinkButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // Builds a label for input fields
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: DarkModeHandler.getMainContainersTextColor()),
      ),
    );
  }

  // Builds a text input field
  Widget _buildTextField({required String hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            style: TextStyle(color: DarkModeHandler.getInputTypeTextColor()),
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            ),
          ),
        ],
      ),
    );
  }

  // Decoration for input fields
  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: DarkModeHandler.getMainContainersColor(),
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  // Builds a dropdown button for selecting expiry options
  Widget _buildDropdownButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      decoration: _inputBoxDecoration(),
      child: DropdownButtonFormField<String>(
        value: selectedOption,
        dropdownColor: DarkModeHandler.getMainContainersColor(),
        borderRadius: BorderRadius.circular(10.0),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        ),
        items: _getDropdownItems(),
        onChanged: (newValue) => _handleDropdownChange(newValue),
      ),
    );
  }

  // Handles the change of dropdown selection
  void _handleDropdownChange(String? newValue) {
    setState(() {
      selectedOption = newValue;
      if (newValue == 'One Time Only') {
        _showOneTimeAlertDialog();
      }
    });
  }

  // Shows an alert dialog when "One Time Only" is selected
  void _showOneTimeAlertDialog() {
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Returns the dropdown items
  List<DropdownMenuItem<String>> _getDropdownItems() {
    return <String>['One Hour', 'One Day', 'One Week', 'Unlimited', 'One Time Only'].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(
          value,
          style: TextStyle(color: DarkModeHandler.getCalendarTextColor()),
        ),
      );
    }).toList();
  }

  // Builds the image picker widget
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => imagePath == null ? _showAddImageDialog() : _showChangeRemoveImageDialog(),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),

          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _buildImageContainer(),
              _buildImageLabel(),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the image container to display selected or default image
  Widget _buildImageContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: imagePath != null
          ? Image.file(
        File(imagePath!),
        width: 250,
        height: 150,
        fit: BoxFit.cover,
      )
          : Image.asset(
        'lib/images/coverimage.jpg',
        width: 250,
        height: 160,
        fit: BoxFit.cover,
      ),
    );
  }

  // Builds the label over the image
  Widget _buildImageLabel() {
    return Container(
      width: 250,
      height: 40,
      alignment: Alignment.center,
      padding: EdgeInsets.all(8.0),
      color: Colors.grey.withOpacity(0.7),
      child: Text(
        'Select Cover Image',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Shows dialog to add an image
  void _showAddImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Image Options'),
          content: Text('Do you want to add an image?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => _pickImage(),
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Shows dialog to change or remove the current image
  void _showChangeRemoveImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Image Options'),
          content: Text('Do you want to change or remove the image?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage();
              },
              child: Text('Change'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  imagePath = null;
                });
                Navigator.of(context).pop();
              },
              child: Text('Remove'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Picks an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        imagePath = pickedImage.path;
      });
    }
  }

  // Builds the "Create Link" button
  Widget _buildSaveLinkButton(BuildContext context) {
    return Center(
      child: GradientButtonFb4(
        text: 'Create Link',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LinkViewPage()), // Navigates to Create Link Screen
          );
        },
      ),
    );
  }
  // Builds the bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation if needed
        },
    );

  }
}
