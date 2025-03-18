import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'BillLogPage.dart';

class CreateBillPage extends StatefulWidget {
  final int shopId;  // The shop ID passed from ShopPage

  const CreateBillPage({Key? key, required this.shopId}) : super(key: key);

  @override
  _CreateBillPageState createState() => _CreateBillPageState();
}

class _CreateBillPageState extends State<CreateBillPage> {
  bool _isLoading = false;

  // We store items in a list of maps: { "itemId": int, "itemName": String, "quantity": int }
  List<Map<String, dynamic>> billItems = [
    {"itemId": null, "itemName": "", "quantity": 1}
  ];

  // We'll fetch the available products from /api/items
  List<dynamic> allProducts = [];
  String customerName = ""; // For the "customerName" field

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
  }

  // Fetch all items from backend to display in dropdown
  Future<void> _fetchAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/items'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          allProducts = data; // each item: { "itemId", "itemName", "price", "stock", ... }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching items: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Add a new row to the billItems
  void _addNewItem() {
    setState(() {
      billItems.add({"itemId": null, "itemName": "", "quantity": 1});
    });
  }

  // Remove an item row
  void _removeItem(int index) {
    setState(() {
      billItems.removeAt(index);
    });
  }

  // Show a search + list for picking an item
  // On selection, store itemId + itemName in billItems[index
  void _selectProduct(int index) async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return ProductSearchBottomSheet(products: allProducts);
      },
    );
    if (selected != null) {
      setState(() {
        billItems[index]["itemId"] = selected["itemId"];
        billItems[index]["itemName"] = selected["itemName"];
      });
    }
  }

  // POST request to create a new bill
  Future<void> _createBill() async {
    setState(() => _isLoading = true);

    // Build JSON body
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
        // Navigate to BillLogPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BillLogPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating bill: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildItemRow(int index) {
    final item = billItems[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Item ${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // SELECT PRODUCT
            InkWell(
              onTap: () => _selectProduct(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item["itemId"] == null
                      ? "Select a product"
                      : "${item["itemName"]}",
                ),
              ),
            ),
            const SizedBox(height: 8),

            // QUANTITY
            TextField(
              decoration: const InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final qty = int.tryParse(value) ?? 1;
                billItems[index]["quantity"] = qty;
              },
            ),
            const SizedBox(height: 8),

            // Remove button (if more than 1 item)
            if (billItems.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color brightBlueColor = const Color(0xFF0054FF);
    final Color whiteColor = const Color(0xFFFFFFFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Bill"),
        backgroundColor: brightBlueColor,
        foregroundColor: whiteColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // CUSTOMER NAME
            TextField(
              decoration: const InputDecoration(labelText: "Customer Name"),
              onChanged: (value) => customerName = value,
            ),
            const SizedBox(height: 16),

            // ITEM LIST
            Expanded(
              child: ListView.builder(
                itemCount: billItems.length,
                itemBuilder: (context, index) {
                  return _buildItemRow(index);
                },
              ),
            ),
            const SizedBox(height: 12),

            // ADD ITEM + CREATE BILL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addNewItem,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Item"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brightBlueColor,
                    foregroundColor: whiteColor,
                  ),
                ),
                ElevatedButton(
                  onPressed: _createBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brightBlueColor,
                    foregroundColor: whiteColor,
                  ),
                  child: const Text("Create Bill"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// A bottom sheet that displays all products with a search bar
class ProductSearchBottomSheet extends StatefulWidget {
  final List products; // from /api/items

  const ProductSearchBottomSheet({Key? key, required this.products})
      : super(key: key);

  @override
  _ProductSearchBottomSheetState createState() =>
      _ProductSearchBottomSheetState();
}

class _ProductSearchBottomSheetState extends State<ProductSearchBottomSheet> {
  String searchQuery = "";
  @override
  Widget build(BuildContext context) {
    // Filter by search query
    final filtered = widget.products.where((p) {
      final name = (p["itemName"] ?? "").toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search product",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),
          // PRODUCT LIST
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No products found."))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final product = filtered[idx];
                return ListTile(
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
