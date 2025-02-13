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
  const CreateLinkPage({super.key});

  @override
  _CreateLinkPageState createState() => _CreateLinkPageState();
}

class _CreateLinkPageState extends State<CreateLinkPage> {
  String? selectedOption; // Selected option from dropdown
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool isConnected = true; // Tracks the internet connection status

  // Validation flags for the input fields
  bool _titleValid = true;
  bool _descriptionValid = true;
  bool _amountValid = true;

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();

    // Listen to connectivity changes
    _connectivityService.connectivityStream
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results as ConnectivityResult);
    });
  }

  // Checks the initial connectivity status
  Future<void> _checkConnectivity() async {
    var connectivityResults =
        await _connectivityService.checkInitialConnectivity();
    _updateConnectionStatus(connectivityResults as ConnectivityResult);
  }

  // Updates the connection status based on the result
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  /// Validates that all required fields are filled.
  /// If a field is empty, its corresponding flag is set to false.
  bool _validateFields() {
    bool valid = true;
    setState(() {
      if (titleController.text.trim().isEmpty) {
        _titleValid = false;
        valid = false;
      } else {
        _titleValid = true;
      }
      if (descriptionController.text.trim().isEmpty) {
        _descriptionValid = false;
        valid = false;
      } else {
        _descriptionValid = true;
      }
      if (amountController.text.trim().isEmpty) {
        _amountValid = false;
        valid = false;
      } else {
        _amountValid = true;
      }
    });
    return valid;
  }

  // Save the payment link by calling the backend API.
  // This method is only called when all fields are filled.
  Future<void> _saveLink(BuildContext context) async {
    // Validate fields first
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? userId = await secureStorage.read(key: 'User_ID');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User is not logged in!")),
      );
      return;
    }

    // Always use the regular API URL (one-time payment branch removed)
    final String apiUrl = "http://10.0.2.2:8080/api/payment-details/save";

    // Prepare the payload, including the expireAfter field from the dropdown
    final Map<String, dynamic> payload = {
      "paymentDetailUserId": int.parse(userId),
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
        print("Link created successfully: $responseData");

        // Extract the ID field from the response
        final int savedPaymentId =
            responseData['id'] ?? responseData['paymentDetailId'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Link created successfully!")),
        );

        // Navigate to the LinkViewPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LinkViewPage(paymentDetailId: savedPaymentId),
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

  // Builds the app bar.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: DarkModeHandler.getAppBarColor(),
      title: const Text(
        "Create Regular Link",
        style: TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

  // Builds the main content of the screen.
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
              _buildTextField(
                controller: titleController,
                hint: 'Enter title...',
                hasError: !_titleValid,
                onChanged: (value) {
                  if (value.trim().isNotEmpty && !_titleValid) {
                    setState(() {
                      _titleValid = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildLabel("Description"),
              _buildTextField(
                controller: descriptionController,
                hint: 'Enter description...',
                maxLines: 5,
                hasError: !_descriptionValid,
                onChanged: (value) {
                  if (value.trim().isNotEmpty && !_descriptionValid) {
                    setState(() {
                      _descriptionValid = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildLabel("Amount"),
              _buildTextField(
                controller: amountController,
                hint: 'Enter amount...',
                keyboardType: TextInputType.number,
                hasError: !_amountValid,
                onChanged: (value) {
                  if (value.trim().isNotEmpty && !_amountValid) {
                    setState(() {
                      _amountValid = true;
                    });
                  }
                },
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

  // Builds the dropdown button for "Expire After"
  Widget _buildDropdownButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: _inputBoxDecoration(), // No error needed for dropdown
      child: DropdownButtonFormField<String>(
        value: selectedOption,
        dropdownColor: DarkModeHandler.getMainContainersColor(),
        borderRadius: BorderRadius.circular(10.0),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        ),
        // Dropdown options without "One Time Only"
        items: <String>['One Hour', 'One Day', 'One Week', 'Unlimited']
            .map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(color: DarkModeHandler.getCalendarTextColor()),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            selectedOption = newValue;
          });
        },
      ),
    );
  }

  // Builds the "Create Link" button.
  Widget _buildSaveLinkButton(BuildContext context) {
    return Center(
      child: GradientButtonFb4(
        text: 'Create Link',
        onPressed: () => _saveLink(context),
      ),
    );
  }

  // Builds the bottom navigation bar.
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBarWithFab(
      currentIndex: 2,
      onTap: (index) {
        // Handle navigation if needed
      },
    );
  }

  // Builds a label for a field.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 16, color: DarkModeHandler.getMainContainersTextColor()),
      ),
    );
  }

  // Builds a text field with an optional error indicator.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool hasError = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: _inputBoxDecoration(hasError: hasError),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: DarkModeHandler.getInputTypeTextColor()),
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        ),
      ),
    );
  }

  // Returns the input box decoration. If [hasError] is true, a red border is added.
  BoxDecoration _inputBoxDecoration({bool hasError = false}) {
    return BoxDecoration(
      color: DarkModeHandler.getMainContainersColor(),
      borderRadius: BorderRadius.circular(10.0),
      border: hasError ? Border.all(color: Colors.red, width: 2.0) : null,
    );
  }
}
