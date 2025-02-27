import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For toast notifications
import 'package:http/http.dart' as http; // For API calls
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // For JSON decoding
import '../MainScreens/Home_Screen.dart';
import '../config.dart';

class AsgardeoLoginPage extends StatefulWidget {
  const AsgardeoLoginPage({super.key});

  @override
  _AsgardeoLoginPageState createState() => _AsgardeoLoginPageState();
}

class _AsgardeoLoginPageState extends State<AsgardeoLoginPage> {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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
          promptValues: ['login'],
        ),
      );

      Map<String, dynamic> idTokenClaims = JwtDecoder.decode(result.idToken!);

      final String? asgardeoUserId = idTokenClaims['sub'];
      final String? email = idTokenClaims['email'];
      final String? givenName = idTokenClaims['given_name'];

      final userId =
          await _fetchUserIdFromBackend(asgardeoUserId!, email!, givenName!);

      if (userId != null) {
        await _secureStorage.write(key: 'User_ID', value: userId.toString());
        await _secureStorage.write(
            key: 'Given_Name', value: givenName ?? "User");
        print("User_ID saved: $userId");
      }

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
          builder: (context) => MyHomePage(givenName: givenName ?? "User"),
        ),
      );
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

  // Fetch User_ID from Backend
  Future<int?> _fetchUserIdFromBackend(
      String asgardeoUserId, String email, String givenName) async {
    final String apiUrl = '$baseUrl/api/users/signup'; // Adjust API path if necessary

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
        final responseData = jsonDecode(response.body);
        return responseData['userId']; // Return the User_ID from the response
      } else {
        print("Error fetching User_ID: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error sending data to backend: $e");
      return null;
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
  Future<void> _sendDataToBackend(
      String asgardeoUserId, String email, String givenName) async {
    final String apiUrl = '$baseUrl/api/users/signup';

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
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
