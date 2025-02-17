import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LinkViewPage extends StatefulWidget {
  final int paymentDetailId;
  const LinkViewPage({super.key, required this.paymentDetailId});

  @override
  _LinkViewPageState createState() => _LinkViewPageState();
}

class _LinkViewPageState extends State<LinkViewPage> {
  Map<String, dynamic>? paymentData;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPaymentDetails();
  }

  Future<void> fetchPaymentDetails() async {
    final String apiUrl = "http://10.0.2.2:8080/api/payment-details/view/${widget.paymentDetailId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          paymentData = jsonDecode(response.body);
        });
      } else {
        setState(() {
          errorMessage = "Failed to load payment details.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Details")),
      body: paymentData != null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Title: ${paymentData!['title']}"),
            Text("Description: ${paymentData!['description']}"),
            Text("Amount: £${paymentData!['amount']}"),
            Text("Created At: ${paymentData!['createdAt']}"),
            Text("Expires: ${paymentData!['expireAfter']}"),
            Text("Payment URL: ${paymentData!['paymentUrl']}"),
            const Divider(),
            const Text("Transactions:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate(paymentData!['transactions'].length, (index) {
              var txn = paymentData!['transactions'][index];
              return ListTile(
                title: Text("Txn ID: ${txn['stripeTransactionId']}"),
                subtitle: Text("Amount: £${txn['amount']} | Date: ${txn['createdAt']}"),
              );
            }),
          ],
        ),
      )
          : Center(child: errorMessage.isNotEmpty ? Text(errorMessage) : CircularProgressIndicator()),
    );
  }
}
