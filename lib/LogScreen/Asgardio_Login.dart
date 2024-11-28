import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For toast notifications
import 'package:http/http.dart' as http; // For API calls
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // For JSON decoding
import '../MainScreens/Home_Screen.dart';

class AsgardeoLoginPage extends StatefulWidget {
  @override
  _AsgardeoLoginPageState createState() => _AsgardeoLoginPageState();
}

class _AsgardeoLoginPageState extends State<AsgardeoLoginPage> {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  bool _isLoginInProgress = false;

  final String clientId = "egRM9OOT5YJvbNWa17QKvXNi450a";
  final String redirectUri = "linkcash://callback";
  final String discoveryUrl =
      "https://api.asgardeo.io/t/silixis/oauth2/token/.well-known/openid-configuration";
  final List<String> scopes = ["openid", "profile", "email"];

  // Login Function
  // Login Function
  Future<void> _login() async {
    if (_isLoginInProgress) return;

    setState(() {
      _isLoginInProgress = true;
    });

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUri,
          discoveryUrl: discoveryUrl,
          scopes: scopes,
          promptValues: ['login'], // Correct way to enforce login prompt
        ),
      );

      if (result != null) {
        Map<String, dynamic> idTokenClaims = JwtDecoder.decode(result.idToken!);

        // Extract user details
        final String? asgardeoUserId = idTokenClaims['sub'];
        final String? email = idTokenClaims['email'];
        final String? givenName = idTokenClaims['given_name'];

        // Send user data to the backend to ensure it's saved if new
        await _sendDataToBackend(asgardeoUserId!, email!, givenName!);

        // Show login success and navigate to the home page
        Fluttertoast.showToast(
          msg: "Login successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(
              givenName: givenName ?? "User",
            ),
          ),
        );
      } else {
        setState(() {
          _isLoginInProgress = false;
        });
        Fluttertoast.showToast(
          msg: "Login failed.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      setState(() {
        _isLoginInProgress = false;
      });

      Fluttertoast.showToast(
        msg: "Error during login: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      print("Login error: $e");
    }
  }



  // Redirect to Asgardeo Sign-Up
  Future<void> _signUp() async {
    final signUpUrl =
        "https://accounts.asgardeo.io/t/silixis/accountrecoveryendpoint/register.do?client_id=$clientId&redirect_uri=$redirectUri";

    try {
      Fluttertoast.showToast(
        msg: "Redirecting to Asgardeo Sign-Up page...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      if (await canLaunch(signUpUrl)) {
        await launch(signUpUrl, forceSafariVC: false, forceWebView: false);

        // Inform the user to log in after signing up
        Fluttertoast.showToast(
          msg: "After signing up, please log in to complete the process.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Could not open the sign-up page.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error redirecting to sign-up page: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // Send Data to Backend
  Future<void> _sendDataToBackend(String asgardeoUserId, String email, String givenName) async {
    final String apiUrl = "http://10.0.2.2:8080/api/users/signup";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "asgardeoUserId": asgardeoUserId,
          "email": email,
          "givenName": givenName,
        }),
      );

      if (response.statusCode == 200) {
        print("User saved or already exists.");
      } else {
        print("Backend Error: ${response.body}");
      }
    } catch (e) {
      print("Error sending data to backend: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0054FF), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome to LinkCash",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Securely log in or sign up to access your account.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _isLoginInProgress
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    color: Color(0xFF0054FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "OR",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Color(0xFF0054FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
