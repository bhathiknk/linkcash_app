import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PayoutDTO {
  final String payoutId;
  final int amount; // In pence/cents
  final String currency;
  final String status;
  final DateTime? arrivalDate;

  PayoutDTO({
    required this.payoutId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.arrivalDate,
  });

  factory PayoutDTO.fromJson(Map<String, dynamic> json) {
    // arrivalDate could be epoch or string
    final rawArrival = json['arrivalDate'];
    DateTime? parsedDate;
    if (rawArrival != null) {
      if (rawArrival is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawArrival * 1000, isUtc: true);
      } else if (rawArrival is String) {
        // Try parsing as epoch int or ISO date
        final epochTry = int.tryParse(rawArrival);
        if (epochTry != null) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(epochTry * 1000, isUtc: true);
        } else {
          parsedDate = DateTime.tryParse(rawArrival);
        }
      }
    }

    // Convert "amount" (could be string or int)
    final rawAmount = json['amount'];
    int parsedAmount;
    if (rawAmount is int) {
      parsedAmount = rawAmount;
    } else if (rawAmount is String) {
      parsedAmount = int.parse(rawAmount);
    } else {
      parsedAmount = 0;
    }

    return PayoutDTO(
      payoutId: json['payoutId'] ?? '',
      amount: parsedAmount,
      currency: json['currency'] ?? '',
      status: json['status'] ?? '',
      arrivalDate: parsedDate,
    );
  }
}

class PayoutHistoryPage extends StatefulWidget {
  final String userId;
  const PayoutHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<PayoutHistoryPage> createState() => _PayoutHistoryPageState();
}

class _PayoutHistoryPageState extends State<PayoutHistoryPage> {
  bool _isLoading = false;
  List<PayoutDTO> _payouts = [];

  @override
  void initState() {
    super.initState();
    _fetchPayoutHistory();
  }

  Future<void> _fetchPayoutHistory() async {
    setState(() => _isLoading = true);

    final url = 'http://10.0.2.2:8080/api/stripe/payouts/${widget.userId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        final payouts = data.map((jsonItem) => PayoutDTO.fromJson(jsonItem)).toList();

        // Sort by arrivalDate descending (latest first).
        // If arrivalDate is null, we treat it as older.
        payouts.sort((a, b) {
          final aDate = a.arrivalDate?.millisecondsSinceEpoch ?? 0;
          final bDate = b.arrivalDate?.millisecondsSinceEpoch ?? 0;
          return bDate.compareTo(aDate);
        });

        setState(() {
          _payouts = payouts;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch payouts: ${response.body}")),
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
    return Scaffold(
      // An AppBar with a little style
      appBar: AppBar(
        title: const Text("Payout History"),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: const  Color(0xFFE3F2FD), // A subtle background color
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payouts.isEmpty
          ? const Center(child: Text("No payouts found."))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // The first item is the "most recent" payout if sorted descending.
    final PayoutDTO latestPayout = _payouts.first;
    final List<PayoutDTO> olderPayouts =
    _payouts.length > 1 ? _payouts.sublist(1) : [];

    return SingleChildScrollView(
      child: Column(
        children: [
          // A top card highlighting the last payout
          _buildLastPayoutCard(latestPayout),
          // A title row for "All Payouts"
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 14, right: 14),
            child: Row(
              children: const [
                Text(
                  "Previous Payouts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // A list of older payouts
          if (olderPayouts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "No older payouts found",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: olderPayouts.length,
              itemBuilder: (context, index) {
                return _buildPayoutListTile(olderPayouts[index]);
              },
            ),
        ],
      ),
    );
  }

  /// A special card showing the latest payout in a more prominent style
  Widget _buildLastPayoutCard(PayoutDTO payout) {
    final double convertedAmount = payout.amount / 100.0;
    final dateStr = payout.arrivalDate != null
        ? "${payout.arrivalDate!.toLocal()}"
        : "N/A";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last Payout",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          // Payout amount
          Text(
            "£${convertedAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          // Payout ID
          Text(
            "Payout ID: ${payout.payoutId}",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          // Payout status & date
          Text(
            "Status: ${payout.status}",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            "Arrival: $dateStr",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// A list tile for older payouts
  Widget _buildPayoutListTile(PayoutDTO payout) {
    final double convertedAmount = payout.amount / 100.0;
    final arrivalStr = payout.arrivalDate != null
        ? payout.arrivalDate!.toLocal().toString()
        : "N/A";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        title: Text(
          "£${convertedAmount.toStringAsFixed(2)} - ${payout.status}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "PayoutID: ${payout.payoutId}\nArrival: $arrivalStr",
          style: const TextStyle(fontSize: 14),
        ),
        isThreeLine: true,
        leading: const Icon(Icons.payments, color: Colors.deepPurple),
      ),
    );
  }
}
