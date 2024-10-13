import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package

import '../MainScreens/Home_Screen.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import 'Register_form.dart';
import 'login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents input fields from moving when the keyboard appears
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          "Login",
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
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0054FF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  height: 550, // Adjust height as needed
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start, // Align to the top
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Sign In',
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
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 20), // Adjust vertical spacing
                        _buildSignUpButton(context),
                        const SizedBox(height: 10), // Add space between sign-up button and text
                        const Text(
                          'Create an account?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>  RegisterPage()),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              color:Color(0xFF83B6B9), // Change text color to blue for link
                            ),
                          ),
                        ),
                      ],
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 5),
        _buildTextField(hint: hint, obscureText: obscureText),
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

  Widget _buildSignUpButton(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to MyHomePage after sign up button is pressed
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
          'Sign In',
          style: TextStyle(color: Colors.white), // Text color
        ),
      ),
    );
  }
}
