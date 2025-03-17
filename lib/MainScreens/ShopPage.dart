import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';


class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  // Colors
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color lightTealColor = const Color(0xFF83B6B9);
  final Color lightBlueColor = const Color(0xFFE3F2FD);
  final Color brightBlueColor = const Color(0xFF0054FF);

  // State
  bool _isLoading = false;
  bool _hasShop = false;
  Map<String, dynamic>? _shopData;

  // Registration form controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkShopRegistration();
  }

  /// 1) Check if user has a shop
  Future<void> _checkShopRegistration() async {
    setState(() => _isLoading = true);

    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? userId = await secureStorage.read(key: 'User_ID');

    if (userId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User is not logged in!")),
      );
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/api/shops/user/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Shop exists
        final data = jsonDecode(response.body);
        setState(() {
          _hasShop = true;
          _shopData = data;
          _isLoading = false;
        });
      } else {
        // No shop or error => user not registered
        setState(() {
          _hasShop = false;
          _isLoading = false;
        });
        // Show the popup to register
        Future.delayed(Duration.zero, () => _showRegistrationDialog());
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error checking shop registration: $e")),
      );
    }
  }

  /// 2) Popup dialog that asks user to register shop
  void _showRegistrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user must register or close manually
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Register Your Shop"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _shopNameController,
                  decoration: InputDecoration(
                    labelText: "Shop Name",
                    fillColor: lightBlueColor,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: "Shop Address",
                    fillColor: lightBlueColor,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // user can close if they want
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brightBlueColor,
                foregroundColor: whiteColor,
              ),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                await _registerShop();
              },
              child: const Text("Register"),
            ),
          ],
        );
      },
    );
  }

  /// 3) Register the shop using the fields from the popup
  Future<void> _registerShop() async {
    setState(() => _isLoading = true);

    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? userId = await secureStorage.read(key: 'User_ID');

    if (userId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User is not logged in!")),
      );
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/api/shops/create');
      final body = {
        "userId": userId,
        "shopName": _shopNameController.text.trim(),
        "address": _addressController.text.trim(),
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Successfully created
        final data = jsonDecode(response.body);
        setState(() {
          _hasShop = true;
          _shopData = data;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop registered successfully!")),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error registering shop: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// 4) Main Shop Dashboard if user has a shop
  Widget _buildShopDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "Welcome to Your Shop!",
            style: TextStyle(
              color: brightBlueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (_shopData != null) ...[
            Text(
              "Shop Name: ${_shopData!['shopName']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Address: ${_shopData!['address']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Shop QR Code: ${_shopData!['shopQrCode'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Divider(color: brightBlueColor),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brightBlueColor,
              foregroundColor: whiteColor,
            ),
            onPressed: () {
              // Navigate to "Create Bill" page or implement your logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Create Bill clicked (not implemented)")),
              );
            },
            child: const Text("Create Bill"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: lightTealColor,
        title: const Text("Shop Page"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasShop
          ? _buildShopDashboard()
          : const Center(
        child: Text("No shop found. Please register."),
      ),
      // We show a fallback message if user didn't register and closed the popup
      // or no data was found. The popup will appear automatically once on load.
    );
  }
}
