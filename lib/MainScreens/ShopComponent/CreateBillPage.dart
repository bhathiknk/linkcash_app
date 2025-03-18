import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  List<Map<String, dynamic>> billItems = [];
  List<dynamic> allProducts = [];
  String customerName = "";
  int? tempItemId;
  String tempItemName = "";
  double tempItemPrice = 0.0;
  int tempQuantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchProductsByShopId();
  }

  Future<void> _fetchProductsByShopId() async {
    final FlutterSecureStorage storage = const FlutterSecureStorage();
    String? shopId = await storage.read(key: 'SHOP_ID');

    if (shopId == null) {
      _showError("Shop ID not found in secure storage.");
      return;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/items/shop/$shopId'));
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
      tempItemId = null;
      tempItemName = "";
      tempItemPrice = 0.0;
      tempQuantity = 1;
    });
  }

  void _removeItem(int index) {
    setState(() {
      billItems.removeAt(index);
    });
  }

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

  double get totalAmount {
    double sum = 0.0;
    for (var item in billItems) {
      sum += (item["price"] as double) * (item["quantity"] as int);
    }
    return sum;
  }

  Future<void> _createBill() async {
    if (billItems.isEmpty) {
      _showError("Please add at least one item.");
      return;
    }
    setState(() => _isLoading = true);

    final body = {
      "shopId": widget.shopId,
      "customerName": customerName,
      "items": billItems.map((item) {
        return {
          "itemId": item["itemId"],
          "quantity": item["quantity"],
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
          SnackBar(content: Text("Bill created! PIN: ${data['pin']}")),
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
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
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
                          icon: const Icon(Icons.add, color: Colors.white),
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
