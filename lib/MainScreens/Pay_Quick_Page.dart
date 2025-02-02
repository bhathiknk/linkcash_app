import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/gradient_button_fb4.dart';

class PayQuickPage extends StatefulWidget {
  const PayQuickPage({Key? key}) : super(key: key);

  @override
  _PayQuickPageState createState() => _PayQuickPageState();
}

class _PayQuickPageState extends State<PayQuickPage> {
  // Controllers for the three input fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  bool isConnected = true;
  String? paymentLink; // Stores the generated payment link

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityService.connectivityStream.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.first);
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await _connectivityService.checkInitialConnectivity();
    _updateConnectionStatus(connectivityResult as ConnectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  // Generate a dummy payment link based on the provided Title, Description and Amount.
  Future<void> _generatePayQuickLink(BuildContext context) async {
    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final String amount = amountController.text.trim();

    // Validate that all fields are filled
    if (title.isEmpty || description.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    // Generate a dummy payment link (you can adjust the format as needed)
    setState(() {
      paymentLink =
      "https://dummy-payment-link.com/?title=${Uri.encodeComponent(title)}&description=${Uri.encodeComponent(description)}&amount=$amount";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Link generated successfully!")),
    );
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: DarkModeHandler.getAppBarColor(),
      title: const Text(
        "Pay Quick",
        style: TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Enter Title"),
              _buildTextField(
                  controller: titleController,
                  hint: 'Enter title...',
                  keyboardType: TextInputType.text),
              const SizedBox(height: 15),
              _buildLabel("Enter Description"),
              _buildTextField(
                  controller: descriptionController,
                  hint: 'Enter description...',
                  keyboardType: TextInputType.text),
              const SizedBox(height: 15),
              _buildLabel("Enter Amount"),
              _buildTextField(
                  controller: amountController,
                  hint: 'Enter amount...',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildGenerateButton(context),
              if (paymentLink != null) _buildPaymentLinkDisplay(), // Display payment link after generation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: DarkModeHandler.getMainContainersTextColor()),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: DarkModeHandler.getInputTypeTextColor()),
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

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: DarkModeHandler.getMainContainersColor(),
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  Widget _buildGenerateButton(BuildContext context) {
    return Center(
      child: GradientButtonFb4(
        text: 'Generate Payment Link',
        onPressed: () => _generatePayQuickLink(context),
      ),
    );
  }

  Widget _buildPaymentLinkDisplay() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Text(
            "Payment Link:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DarkModeHandler.getMainContainersTextColor()),
          ),
          const SizedBox(height: 5),
          SelectableText(
            paymentLink!,
            style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBarWithFab(
      currentIndex: 0, // Adjust index based on navigation
      onTap: (index) {
        // Handle navigation if needed
      },
    );
  }
}
