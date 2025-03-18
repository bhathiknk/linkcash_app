import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'BillLogPage.dart';

class CreateBillPage extends StatefulWidget {
  final int shopId;
  const CreateBillPage({Key? key, required this.shopId}) : super(key: key);

  @override
  _CreateBillPageState createState() => _CreateBillPageState();
}

class _CreateBillPageState extends State<CreateBillPage> {
  bool _isLoading = false;

  // The final list of items we add to the bill
  // Each item: { itemId, itemName, quantity, price }
  List<Map<String, dynamic>> billItems = [];

  // All products from /api/items
  List<dynamic> allProducts = [];

  // For the Bill's customer name
  String customerName = "";

  // For the new item being added:
  int? tempItemId;
  String tempItemName = "";
  double tempItemPrice = 0.0;
  int tempQuantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
  }

  Future<void> _fetchAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/items'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          allProducts = data;
        });
      } else {
        _showError("Error fetching items: ${response.body}");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Add a new item to the bill
  void _addItemToBill() {
    if (tempItemId == null) {
      _showError("Please select a product.");
      return;
    }
    if (tempQuantity < 1) {
      _showError("Quantity must be at least 1.");
      return;
    }

    setState(() {
      billItems.add({
        "itemId": tempItemId,
        "itemName": tempItemName,
        "price": tempItemPrice,
        "quantity": tempQuantity,
      });
      // Reset
      tempItemId = null;
      tempItemName = "";
      tempItemPrice = 0.0;
      tempQuantity = 1;
    });
  }

  // Remove item from list
  void _removeItem(int index) {
    setState(() {
      billItems.removeAt(index);
    });
  }

  // Show bottom sheet to pick a product
  Future<void> _selectProduct() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductSearchBottomSheet(products: allProducts),
    );
    if (selected != null) {
      setState(() {
        tempItemId = selected["itemId"];
        tempItemName = selected["itemName"];
        tempItemPrice = (selected["price"] ?? 0).toDouble();
      });
    }
  }

  // Calculate total
  double get totalAmount {
    double sum = 0.0;
    for (var item in billItems) {
      sum += (item["price"] as double) * (item["quantity"] as int);
    }
    return sum;
  }

  // Create the bill
  Future<void> _createBill() async {
    if (billItems.isEmpty) {
      _showError("Please add at least one item before creating the bill.");
      return;
    }
    setState(() => _isLoading = true);

    final body = {
      "shopId": widget.shopId,
      "customerName": customerName,
      "items": billItems.map((item) {
        return {
          "itemId": item["itemId"] ?? 0,
          "quantity": item["quantity"] ?? 1,
        };
      }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bills/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bill created! Bill ID: ${data['billId']}")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BillLogPage()),
        );
      } else {
        _showError("Error creating bill: ${response.body}");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color brightBlueColor = const Color(0xFF0054FF);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text("Create Bill", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: brightBlueColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Top container for user name, product selection, quantity, add item
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Customer Name
                TextField(
                  decoration: InputDecoration(
                    labelText: "Customer Name",
                    labelStyle: TextStyle(color: Colors.blue[800]),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade50),
                    ),
                  ),
                  onChanged: (value) => customerName = value,
                ),
                const SizedBox(height: 16),

                // Add item section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add an Item",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectProduct,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tempItemId == null
                                ? "Select a product"
                                : "$tempItemName (\$${tempItemPrice.toStringAsFixed(2)})",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        decoration: const InputDecoration(labelText: "Quantity"),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final qty = int.tryParse(value) ?? 1;
                          setState(() => tempQuantity = qty);
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _addItemToBill,
                          icon: const Icon(Icons.add,color: Colors.white),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: brightBlueColor,
                            foregroundColor: Colors.white,
                          ),
                          label: const Text("Add"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Middle expanded container for item list
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildAddedItems(),
            ),
          ),

          // Bottom container with total & create bill button
          Container(
            color: const Color(0xFFE3F2FD),
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Total: \$${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _createBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brightBlueColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(45),
                  ),
                  child: const Text("Create Bill"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the list of added items
  Widget _buildAddedItems() {
    if (billItems.isEmpty) {
      return const Center(
        child: Text("No items added yet.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: billItems.length,
      itemBuilder: (context, index) {
        final item = billItems[index];
        final subTotal = item["price"] * item["quantity"];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item["itemName"]} (x${item["quantity"]})",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text("Each: \$${(item["price"] as double).toStringAsFixed(2)}"),
                    Text("Subtotal: \$${subTotal.toStringAsFixed(2)}"),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.remove_circle, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }
}

// The product search bottom sheet
class ProductSearchBottomSheet extends StatefulWidget {
  final List products;
  const ProductSearchBottomSheet({Key? key, required this.products}) : super(key: key);

  @override
  _ProductSearchBottomSheetState createState() => _ProductSearchBottomSheetState();
}

class _ProductSearchBottomSheetState extends State<ProductSearchBottomSheet> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      final name = (p["itemName"] ?? "").toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search product",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),
          // RESULTS
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No products found."))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final product = filtered[idx];
                return ListTile(
                  leading: const Icon(Icons.inventory_2_rounded, color: Colors.blue),
                  title: Text(product["itemName"] ?? "N/A"),
                  subtitle: Text("Price: ${product["price"]} | Stock: ${product["stock"]}"),
                  onTap: () {
                    Navigator.pop(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
