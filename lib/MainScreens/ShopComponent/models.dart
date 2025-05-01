class ShopTransactionHistory {
  final int transactionId;
  final String stripeTransactionId;
  final double amount;
  final DateTime transactionCreatedAt;

  final int billId;
  final String billStatus;
  final double billTotal;
  final DateTime? billExpiresAt;

  final String customerName;
  final List<BillItem> items;
  final int totalItems;

  final String shopName;
  final String shopAddress;

  ShopTransactionHistory({
    required this.transactionId,
    required this.stripeTransactionId,
    required this.amount,
    required this.transactionCreatedAt,
    required this.billId,
    required this.billStatus,
    required this.billTotal,
    this.billExpiresAt,
    required this.customerName,
    required this.items,
    required this.totalItems,
    required this.shopName,
    required this.shopAddress,
  });

  factory ShopTransactionHistory.fromJson(Map<String, dynamic> json) {
    return ShopTransactionHistory(
      transactionId: json['transactionId'] as int,
      stripeTransactionId: json['stripeTransactionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionCreatedAt: DateTime.parse(json['transactionCreatedAt'] as String),
      billId: json['billId'] as int,
      billStatus: json['billStatus'] as String,
      billTotal: (json['billTotal'] as num).toDouble(),
      billExpiresAt: json['billExpiresAt'] != null
          ? DateTime.parse(json['billExpiresAt'] as String)
          : null,
      customerName: json['customerName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => BillItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalItems: json['totalItems'] as int,
      shopName: json['shopName'] as String,
      shopAddress: json['shopAddress'] as String,
    );
  }
}

class BillItem {
  final int itemId;
  final String itemName;
  final double price;
  final int quantity;

  BillItem({
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.quantity,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      itemId: json['itemId'] as int,
      itemName: json['itemName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}
