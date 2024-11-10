import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For toast notifications
import '../MainScreens/Home_Screen.dart';

class AsgardeoLoginPage extends StatefulWidget {
  @override
  _AsgardeoLoginPageState createState() => _AsgardeoLoginPageState();
}

class _AsgardeoLoginPageState extends State<AsgardeoLoginPage> {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  bool _isLoginInProgress = false;
  String? _givenName;

  // Asgardeo details
  final String clientId = "egRM9OOT5YJvbNWa17QKvXNi450a";
  final String redirectUri = "linkcash://callback";
  final String discoveryUrl =
      "https://api.asgardeo.io/t/silixis/oauth2/token/.well-known/openid-configuration";
  final List<String> scopes = ["openid", "profile", "email"];

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
        ),
      );

      if (result != null) {
        Map<String, dynamic> idTokenClaims = JwtDecoder.decode(result.idToken!);
        String? givenName = idTokenClaims['given_name'];

        setState(() {
          _givenName = givenName;
          _isLoginInProgress = false;
        });

        // Show success toast message and navigate to HomePage
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
              givenName: _givenName ?? "User",
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login to LinkCash"),
        centerTitle: true,
        backgroundColor: Color(0xFF0054FF),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF83B6B9), Color(0xFF0054FF)],
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
                "Securely log in to access your account.",
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Login with Asgardeo",
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
