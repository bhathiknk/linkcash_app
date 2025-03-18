import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'dart:async';

import '../../config.dart';

class BillLogPage extends StatefulWidget {
  const BillLogPage({Key? key}) : super(key: key);

  @override
  _BillLogPageState createState() => _BillLogPageState();
}

class _BillLogPageState extends State<BillLogPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<dynamic> _bills = [];

  Timer? _timer; // for live countdown
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _fetchBillsByShopId();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Trigger rebuild every second to update countdown
  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  // Fetch bills using the SHOP_ID from secure storage
  Future<void> _fetchBillsByShopId() async {
    setState(() => _isLoading = true);

    final FlutterSecureStorage storage = const FlutterSecureStorage();
    String? shopId = await storage.read(key: 'SHOP_ID');
    if (shopId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No SHOP_ID found in storage.")),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/api/bills/shop/$shopId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _bills = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching bills: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // If `expiresAt` is in the past => expired
  bool _isExpired(dynamic bill) {
    final expiresAtString = bill["expiresAt"] ?? "";
    if (expiresAtString.isEmpty) return false;
    try {
      final expiresAt = DateTime.parse(expiresAtString);
      return DateTime.now().isAfter(expiresAt);
    } catch (_) {
      return false;
    }
  }

  // Build tab content: active (expired=false) or expired (expired=true)
  Widget _buildBillList(bool expired) {
    final filtered = _bills.where((b) => _isExpired(b) == expired).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          expired ? "No expired bills." : "No active bills.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, idx) {
        final bill = filtered[idx];
        final createdAt = bill["createdAt"] ?? "";
        final expiresAt = bill["expiresAt"] ?? "";

        // parse expiresAt
        DateTime? expireTime;
        try {
          expireTime = DateTime.parse(expiresAt);
        } catch (_) {
          expireTime = null;
        }
        final bool isExpired = expireTime == null ? true : DateTime.now().isAfter(expireTime);

        // Countdown widget
        Widget countdownWidget;
        if (isExpired) {
          countdownWidget = const Text(
            "Expired",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          );
        } else {
          final duration = expireTime!.difference(DateTime.now());
          countdownWidget = Row(
            children: [
              const Icon(Icons.timer, size: 20, color: Colors.blue),
              const SizedBox(width: 6),
              SlideCountdown(
                duration: duration,
                separatorType: SeparatorType.title,
                separatorStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          );
        }

        return Card(
          color: Colors.white, // Bill card background
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),

            title: Text(
              "Customer: ${bill["customerName"]}",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // total + icon
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 20, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        "Total: \$${bill["total"] ?? '0'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // created row
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(
                        "Created: $createdAt",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // expires row
                  Row(
                    children: [
                      const Icon(Icons.event_busy, size: 20, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        "Expires: $expiresAt",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // countdown or expired
                  countdownWidget,
                ],
              ),
            ),
            trailing: Text(
              "PIN: ${bill["pin"] ?? 'N/A'}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 18,
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Full page background => Color(0xFFE3F2FD)
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text("Shop Bills"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar: black text, underline
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Expired"),
              ],
            ),
          ),

          // The TabBarView
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                // Active bills
                _buildBillList(false),
                // Expired bills
                _buildBillList(true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
