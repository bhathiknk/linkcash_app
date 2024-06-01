import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../MainScreens/Home_Screen.dart';
import 'connectivity_service.dart';
import 'login_form.dart'; // Ensure this import matches your actual file structure

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    var initialConnectivityResult = await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = initialConnectivityResult;
      _isInitialCheckComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<ConnectivityResult>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          if (!_isInitialCheckComplete) {
            return Center(child: CircularProgressIndicator());
          } else {
            ConnectivityResult? result = snapshot.data ?? _initialConnectivityResult;
            if (result == ConnectivityResult.none) {
              return _buildNoInternetUI();
            } else {
              return _buildRegisterForm();
            }
          }
        },
      ),
    );
  }

  Widget _buildNoInternetUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            'Please check your internet connection and try again.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      color: const Color(0xFF0054FF), // Background color for the body
      child: Column(
        children: [
          SizedBox(height: 50), // Add some top padding if needed
          Center(
            child: Image.asset(
              'lib/images/signup.png',
              width: 150, // Set the width of the logo
              height: 150, // Set the height of the logo
            ),
          ),
          Expanded(
            child: Container(), // Empty container to fill space
          ),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                height: 550, // Adjust height as needed
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Align to the top
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 1),
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInputField(context, 'Username'),
                      SizedBox(height: 10),
                      _buildInputField(context, 'Email'),
                      SizedBox(height: 10),
                      _buildInputField(context, 'Password', obscureText: true),
                      SizedBox(height: 10),
                      _buildInputField(context, 'Confirm Password', obscureText: true),
                      SizedBox(height: 20), // Adjust vertical spacing
                      _buildSignUpButton(context),
                      SizedBox(height: 10), // Add space between sign up button and text

                      SizedBox(height: 1),
                      Text(
                        'Have an account?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue, // Change text color to blue for link
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
    );
  }

  Widget _buildInputField(BuildContext context, String label, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        TextFormField(
          obscureText: obscureText,
          style: TextStyle(color: Colors.black), // Text color
          cursorColor: Colors.blue, // Cursor color
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Padding
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey), // Border color
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey), // Border color
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue, width: 2), // Focused border color and width
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
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
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        },
        child: Text(
          'Sign Up',
          style: TextStyle(color: Colors.white), // Text color
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
