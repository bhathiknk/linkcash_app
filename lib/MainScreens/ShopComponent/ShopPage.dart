import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

import '../../WidgetsCom/bottom_navigation_bar.dart';
import '../../config.dart';
import 'AddItemsPage.dart';
import 'BillHistoryPage.dart';
import 'BillLogPage.dart';
import 'CreateBillPage.dart';
import 'ShopTransactionAnalysisPage.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final Color backgroundColor = const Color(0xFFE3F2FD);
  final Color appBarColor = Colors.white;
  final Color brightBlueColor = const Color(0xFF0054FF);
  final Color whiteColor = const Color(0xFFFFFFFF);

  bool _isLoading = false;
  bool _hasShop = false;
  Map<String, dynamic>? _shopData;

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkShopRegistration();
  }

  // Checks if user already has a shop
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
        final data = jsonDecode(response.body);
        setState(() {
          _hasShop = true;
          _shopData = data;
          _isLoading = false;
        });

        // === Store the shopId in secure storage ===
        final shopIdFromData = data["shopId"];
        if (shopIdFromData != null) {
          await secureStorage.write(key: 'SHOP_ID', value: shopIdFromData.toString());
        }

      } else {
        // No shop => prompt registration
        setState(() {
          _hasShop = false;
          _isLoading = false;
        });
        Future.delayed(Duration.zero, () => _showRegistrationDialog());
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error checking shop registration: $e")),
      );
    }
  }

  // Popup dialog to register a new shop
  void _showRegistrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Register Your Shop"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: "Shop Name",
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "Shop Address",
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brightBlueColor,
                foregroundColor: whiteColor,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _registerShop();
              },
              child: const Text("Register"),
            ),
          ],
        );
      },
    );
  }

  // Registers a new shop
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
        final data = jsonDecode(response.body);
        setState(() {
          _hasShop = true;
          _shopData = data;
          _isLoading = false;
        });

        // === Store the new shopId in secure storage ===
        final shopIdFromData = data["shopId"];
        if (shopIdFromData != null) {
          await secureStorage.write(key: 'SHOP_ID', value: shopIdFromData.toString());
        }

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

  // Dashboard if the shop is found
  Widget _buildShopDashboard() {
    final String? qrCodeData = _shopData?['shopQrCode'] as String?;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              "Welcome to Your Shop!",
              style: TextStyle(
                color: brightBlueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Shop QR code
            if (qrCodeData != null && qrCodeData.isNotEmpty)
              QrImageView(
                data: "https://www.linkcash.com/bill/payment/$qrCodeData",
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              )
            else
              const Text("No QR Code available."),


            const SizedBox(height: 20),

            // Shop Info
            if (_shopData != null)
              Card(
                color: whiteColor.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.store, color: brightBlueColor, size: 20),
                        title: const Text(
                          "Shop Name",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        subtitle: Text(
                          _shopData!['shopName'] ?? "N/A",
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black,
                          ),
                        ),
                      ),
                      Divider(color: brightBlueColor.withOpacity(0.3), thickness: 1.2),
                      ListTile(
                        leading: Icon(Icons.location_on, color: brightBlueColor, size: 20),
                        title: const Text(
                          "Address",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        subtitle: Text(
                          _shopData!['address'] ?? "N/A",
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Create Bill button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brightBlueColor,
                foregroundColor: whiteColor,
              ),
              onPressed: () {
                final int shopId = _shopData?['shopId'] ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateBillPage(shopId: shopId),
                  ),
                );
              },
              child: const Text("Create Bill"),
            ),

            const SizedBox(height: 20),

            Divider(color: brightBlueColor.withOpacity(0.3), thickness: 1.2),

            // Action buttons
            _buildActionButtons(),

            const SizedBox(height: 20),


          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          'Add Items',
          Icons.add_shopping_cart,
          AddItemsPage(),
        ),
        _buildActionButton(
          'Show Bills',
          Icons.receipt_long,
          BillLogPage(),
        ),
        _buildActionButton(
          'Shop Statistic',
          Icons.bar_chart_rounded,
          ShopTransactionAnalysisPage(userId: _shopData!['ownerUserId']),
        ),
        _buildActionButton(
          'Bill History',
          Icons.history,
          BillHistoryPage(userId: _shopData!['ownerUserId']),
        ),
      ],
    );
  }


  Widget _buildActionButton(String title, IconData icon, Widget page) {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: 65,
          height: 65,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: brightBlueColor,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => page));
            },
            child: Icon(icon, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: brightBlueColor),
        title: Text(
          "Shop Page",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasShop
          ? _buildShopDashboard()
          : const Center(child: Text("No shop found. Please register.")),

      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 1,
        onTap: (_) {},
      ),
    );
  }
}
