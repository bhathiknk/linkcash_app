import 'package:flutter/material.dart';
import 'models.dart';

class BillDetailPage extends StatelessWidget {
  final ShopTransactionHistory history;
  const BillDetailPage({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFF0054FF);
    final Color accentColor = const Color(0xFF83B6B9);
    final Color bgColor = const Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Bill #${history.billId}',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionCard(
              icon: Icons.store,
              title: "Shop Information",
              color: mainColor,
              content: [
                _infoRow("Shop", history.shopName),
                _infoRow("Address", history.shopAddress),
              ],
            ),
            const SizedBox(height: 18),
            _sectionCard(
              icon: Icons.receipt_long,
              title: "Bill Summary",
              color: accentColor,
              content: [
                _infoRow("Customer", history.customerName),
                _infoRow("Status", history.billStatus),
                _infoRow("Created", history.transactionCreatedAt.toLocal().toString()),
                if (history.billExpiresAt != null)
                  _infoRow("Expires", history.billExpiresAt!.toLocal().toString()),
                _infoRow("Stripe Txn ID", history.stripeTransactionId),
              ],
            ),
            const SizedBox(height: 18),
            _sectionCard(
              icon: Icons.shopping_cart,
              title: "Items Purchased",
              color: Colors.green,
              content: history.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('${item.quantity} × £${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Total Amount: £${history.billTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(2, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
