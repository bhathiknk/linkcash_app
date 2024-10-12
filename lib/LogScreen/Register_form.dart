import 'package:flutter/material.dart';
import '../MainScreens/Home_Screen.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow scrolling when the keyboard is visible
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          "Register",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        centerTitle: true, // Center the title in the AppBar
      ),
      body: Container(
        color: const Color(0xffffffff), // Background color for the body
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center, // Center the image
                child: Image.asset(
                  'lib/images/logo-no-background.png', // Path to your image
                  width: 300, // Adjust the width as needed
                  height: 300, // Adjust the height as needed
                  fit: BoxFit.contain, // Adjust the fit property as needed
                ),
              ),
            ),

            Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter, // Aligns the container at the bottom
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0054FF),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    height: 550, // Explicitly set the height to 750
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start, // Align to the top
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 1),
                            const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildLabelWithTextField(
                              label: 'Username',
                              hint: 'Enter your username',
                            ),
                            const SizedBox(height: 10),
                            _buildLabelWithTextField(
                              label: 'Email',
                              hint: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 10),
                            _buildLabelWithTextField(
                              label: 'Password',
                              hint: 'Enter your password',
                              obscureText: true,
                            ),
                            const SizedBox(height: 10),
                            _buildLabelWithTextField(
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              obscureText: true,
                            ),
                            const SizedBox(height: 20), // Adjust vertical spacing
                            _buildRegisterButton(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Builds a combined label and input field aligned properly
  Widget _buildLabelWithTextField({
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 5),
        _buildTextField(
          hint: hint,
          obscureText: obscureText,
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  // Builds a label for input fields
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  // Builds a text input field
  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextFormField(
        obscureText: obscureText,
        style: TextStyle(color: DarkModeHandler.getInputTypeTextColor()),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: DarkModeHandler.getInputTextColor(),
            fontWeight: FontWeight.normal, // Set font weight to normal
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
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

  // Builds the register button
  Widget _buildRegisterButton(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to MyHomePage after register button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF83B6B9),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Register',
          style: TextStyle(color: Colors.white), // Text color
        ),
      ),
    );
  }
}
