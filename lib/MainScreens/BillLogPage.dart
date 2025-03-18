import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';

class BillLogPage extends StatefulWidget {
  const BillLogPage({Key? key}) : super(key: key);

  @override
  _BillLogPageState createState() => _BillLogPageState();
}

class _BillLogPageState extends State<BillLogPage> {
  bool _isLoading = false;
  List<dynamic> _bills = [];

  @override
  void initState() {
    super.initState();
    _fetchAllBills();
  }

  Future<void> _fetchAllBills() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/bills'));
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

  @override
  Widget build(BuildContext context) {
    final Color brightBlueColor = const Color(0xFF0054FF);
    final Color whiteColor = const Color(0xFFFFFFFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Bills"),
        backgroundColor: brightBlueColor,
        foregroundColor: whiteColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
          ? const Center(child: Text("No bills found."))
          : ListView.builder(
        itemCount: _bills.length,
        itemBuilder: (ctx, idx) {
          final bill = _bills[idx];
          // Each bill might have { "billId", "customerName", "total", "pin", ... }
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text("Customer: ${bill["customerName"]}"),
              subtitle: Text("Total: ${bill["total"]} | PIN: ${bill["pin"]}"),
              trailing: Text("#${bill["billId"]}"),
            ),
          );
        },
      ),
    );
  }
}
