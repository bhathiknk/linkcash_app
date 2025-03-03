import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

/// The top-level response from the backend.
class PayoutHistoryResponse {
  final int totalAmount; // sum of all payouts in pence
  final List<PayoutDTO> payouts;

  PayoutHistoryResponse({
    required this.totalAmount,
    required this.payouts,
  });

  factory PayoutHistoryResponse.fromJson(Map<String, dynamic> json) {
    // parse totalAmount
    final rawTotal = json['totalAmount'];
    int parsedTotal = 0;
    if (rawTotal is int) {
      parsedTotal = rawTotal;
    } else if (rawTotal is String) {
      parsedTotal = int.parse(rawTotal);
    }

    // parse payouts array
    final payoutList = json['payouts'] as List<dynamic>;
    final payouts = payoutList.map((item) => PayoutDTO.fromJson(item)).toList();

    return PayoutHistoryResponse(
      totalAmount: parsedTotal,
      payouts: payouts,
    );
  }
}

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
    // Parse arrivalDate, which might be int (epoch) or string
    final rawArrival = json['arrivalDate'];
    DateTime? parsedDate;
    if (rawArrival != null) {
      if (rawArrival is int) {
        parsedDate =
            DateTime.fromMillisecondsSinceEpoch(rawArrival * 1000, isUtc: true);
      } else if (rawArrival is String) {
        final epochTry = int.tryParse(rawArrival);
        if (epochTry != null) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(
              epochTry * 1000, isUtc: true);
        } else {
          parsedDate = DateTime.tryParse(rawArrival);
        }
      }
    }

    // Parse 'amount' (could be int or string)
    final rawAmount = json['amount'];
    int parsedAmount = 0;
    if (rawAmount is int) {
      parsedAmount = rawAmount;
    } else if (rawAmount is String) {
      parsedAmount = int.parse(rawAmount);
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

  PayoutHistoryResponse? _payoutHistory; // entire response from backend
  List<PayoutDTO> get _payouts => _payoutHistory?.payouts ?? [];
  int get _totalAmount => _payoutHistory?.totalAmount ?? 0;

  @override
  void initState() {
    super.initState();
    _fetchPayoutHistory();
  }

  Future<void> _fetchPayoutHistory() async {
    setState(() => _isLoading = true);

    final url = '$baseUrl/api/stripe/payouts/${widget.userId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parsedHistory = PayoutHistoryResponse.fromJson(data);

        // Sort the payouts by arrivalDate descending
        parsedHistory.payouts.sort((a, b) {
          final aDate = a.arrivalDate?.millisecondsSinceEpoch ?? 0;
          final bDate = b.arrivalDate?.millisecondsSinceEpoch ?? 0;
          return bDate.compareTo(aDate);
        });

        setState(() {
          _payoutHistory = parsedHistory;
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
    final double totalPounds = _totalAmount / 100.0; // e.g. convert pence -> GBP

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payout History"),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payoutHistory == null
          ? const Center(child: Text("No payout data found."))
          : Column(
        children: [
          // 1) The top "Total Payout" card:
          _buildTotalPayoutCard(totalPounds),
          // 2) The rest of the page content (latest payout + older)
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// A gradient card showing the total payout amount in a nice style.
  Widget _buildTotalPayoutCard(double totalPounds) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0007CC), Color(0xFF03098A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Payouts",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "£${totalPounds.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // If no payouts in the list, show a message
    if (_payouts.isEmpty) {
      return const Center(child: Text("No payouts found."));
    }

    final latestPayout = _payouts.first;
    final olderPayouts = _payouts.length > 1 ? _payouts.sublist(1) : <PayoutDTO>[];

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildLastPayoutCard(latestPayout),
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
          olderPayouts.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "No older payouts found",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          )
              : ListView.builder(
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

  Widget _buildLastPayoutCard(PayoutDTO payout) {
    final double convertedAmount = payout.amount / 100.0;
    final dateStr =
    payout.arrivalDate != null ? payout.arrivalDate!.toLocal().toString() : "N/A";

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
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 4),
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
          Text(
            "£${convertedAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Payout ID: ${payout.payoutId}",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildPayoutListTile(PayoutDTO payout) {
    final double convertedAmount = payout.amount / 100.0;
    final arrivalStr =
    payout.arrivalDate != null ? payout.arrivalDate!.toLocal().toString() : "N/A";

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
