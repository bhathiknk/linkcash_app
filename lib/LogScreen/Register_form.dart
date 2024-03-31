import 'package:flutter/material.dart';
import 'background.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        body: Stack(
          children: [
            Background(),
            _buildRegisterForm(), // Call the method to build the register form
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 350),
            child: const Text(
              "Register",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 250, // Adjusted height to accommodate all fields
            child: Stack(
              children: [
                Container(
                  height: 250, // Adjusted height to accommodate all fields
                  margin: const EdgeInsets.only(
                    right: 70,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(100),
                      bottomRight: Radius.circular(100),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 32),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintStyle: TextStyle(fontSize: 15),
                            border: InputBorder.none,
                            icon: Icon(Icons.email_rounded),
                            hintText: "Email",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 32),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintStyle: TextStyle(fontSize: 15),
                            border: InputBorder.none,
                            icon: Icon(Icons.account_circle_rounded),
                            hintText: "Username",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 32),
                        child: const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            hintStyle: TextStyle(fontSize: 15),
                            border: InputBorder.none,
                            icon: Icon(Icons.lock_rounded),
                            hintText: "Password",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 32),
                        child: const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            hintStyle: TextStyle(fontSize: 15),
                            border: InputBorder.none,
                            icon: Icon(Icons.lock_rounded),
                            hintText: "Confirm Password",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 15),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green[200]!.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xff1bccba),
                          Color(0xff22e2ab),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Navigate to LoginScreen when clicked
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 16, top: 24),
                  child: const Text(
                    "Log In",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff000000),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
