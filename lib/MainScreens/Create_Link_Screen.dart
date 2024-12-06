import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding
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
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool isConnected = true; // Tracks the internet connection status

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results as ConnectivityResult);
    });
  }

  // Checks the initial connectivity status
  Future<void> _checkConnectivity() async {
    var connectivityResults = await _connectivityService.checkInitialConnectivity();
    _updateConnectionStatus(connectivityResults as ConnectivityResult);
  }

  // Updates the connection status based on the result
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  // Save the payment link by calling the backend API
  Future<void> _saveLink(BuildContext context) async {
    final String apiUrl = "http://10.0.2.2:8080/api/payment-details/save"; // Replace with your backend URL

    // Retrieve the logged-in user's User_ID from secure storage
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? userId = await secureStorage.read(key: 'User_ID');

    // Ensure the User_ID is available
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User is not logged in!")),
      );
      return;
    }


    // Prepare the payload
    final Map<String, dynamic> payload = {
      "paymentDetailUserId": int.parse(userId), // Use the logged User_ID
      "title": titleController.text,
      "description": descriptionController.text,
      "amount": double.tryParse(amountController.text) ?? 0.0,
      "expireAfter": selectedOption ?? "Unlimited",
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {

        final responseData = jsonDecode(response.body);

        // Extract paymentDetailId from the response
        final int savedPaymentDetailsId = responseData['id'] ?? responseData['paymentDetailId']; // Adjust the key to match your API response

        print("Link created successfully: $responseData");

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Link created successfully!")),
        );

        // Navigate to the LinkViewPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LinkViewPage(paymentDetailId: savedPaymentDetailsId),
          ),
        );
      } else {
        print("Failed to create link: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create link!")),
        );
      }
    } catch (e) {
      print("Error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred while creating link!")),
      );
    }
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
              _buildTextField(controller: titleController, hint: 'Enter title...'),
              const SizedBox(height: 20),
              _buildLabel("Description"),
              _buildTextField(controller: descriptionController, hint: 'Enter description...', maxLines: 5),
              const SizedBox(height: 20),
              _buildLabel("Amount"),
              _buildTextField(
                controller: amountController,
                hint: 'Enter amount...',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildLabel("Expire After"),
              _buildDropdownButton(),
              const SizedBox(height: 20),
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
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: DarkModeHandler.getInputTypeTextColor()),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
        onChanged: (newValue) {
          setState(() {
            selectedOption = newValue;
          });
        },
      ),
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

  // Builds the "Save Link" button
  Widget _buildSaveLinkButton(BuildContext context) {
    return Center(
      child: GradientButtonFb4(
        text: 'Create Link',
        onPressed: () => _saveLink(context),
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
