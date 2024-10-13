import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<TransactionHistoryPage> {
  int currentIndex = 4; // Set initial index to SearchPage

  void _onBottomNavTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      backgroundColor: DarkModeHandler.getBackgroundColor(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Adding padding around the white container
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // Shadow position
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding inside the white container
              child: _buildTransactionList(), // Display all transactions inside a single container
            ),
          ),
        ),
      ),
      // Add the BottomNavigationBarWithFab
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // List of transactions inside the white container
  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionItem(
          icon: Icons.directions_bus,
          title: 'Transport for London',
          description: 'Travel charge for Friday, 20 Sep',
          amount: '8.20',
        ),
        Divider(color: Colors.grey[300], thickness: 1), // Divider between transactions
        TransactionItem(
          icon: Icons.shopping_cart,
          title: 'Amazon',
          description: 'Online shopping',
          amount: '3.75',
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        TransactionItem(
          icon: Icons.directions_bus,
          title: 'Transport for London',
          description: 'Travel charge for Thursday, 19 Sep',
          amount: '8.20',
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        TransactionItem(
          icon: Icons.directions_bus,
          title: 'Transport for London',
          description: 'Travel charge for Wednesday, 18 Sep',
          amount: '8.20',
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        TransactionItem(
          icon: Icons.monetization_on,
          title: 'Cash Deposit',
          description: 'Post Office deposit',
          amount: '59.00',
          isPositive: true,
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        TransactionItem(
          icon: Icons.shopping_cart,
          title: 'Amazon',
          description: 'Declined, insufficient funds',
          amount: '31.83',
        ),
      ],
    );
  }
}

// Transaction Item Widget
class TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String amount;
  final bool isPositive; // to indicate if the transaction is a credit or debit

  const TransactionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.amount,
    this.isPositive = false, // default to debit (negative)
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(
                  icon,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DarkModeHandler.getMainContainersTextColor(),
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            (isPositive ? "+ " : "- ") + amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
