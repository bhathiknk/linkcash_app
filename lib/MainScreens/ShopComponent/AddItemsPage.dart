import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config.dart';

class AddItemsPage extends StatefulWidget {
  const AddItemsPage({Key? key}) : super(key: key);

  @override
  _AddItemsPageState createState() => _AddItemsPageState();
}

class _AddItemsPageState extends State<AddItemsPage> {
  bool _isLoading = false;
  List<dynamic> _shopItems = [];
  List<dynamic> _filteredItems = [];
  int? _shopId;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchShopIdAndItems();
  }

  Future<void> _fetchShopIdAndItems() async {
    setState(() => _isLoading = true);

    final FlutterSecureStorage storage = const FlutterSecureStorage();
    String? shopIdStr = await storage.read(key: 'SHOP_ID');
    if (shopIdStr == null) {
      setState(() => _isLoading = false);
      _showError("No SHOP_ID found in secure storage.");
      return;
    }
    _shopId = int.tryParse(shopIdStr);

    if (_shopId == null) {
      setState(() => _isLoading = false);
      _showError("Invalid SHOP_ID in storage.");
      return;
    }

    await _fetchItemsByShopId();
  }

  Future<void> _fetchItemsByShopId() async {
    if (_shopId == null) return;
    final url = Uri.parse('$baseUrl/api/items/shop/$_shopId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _shopItems = data;
          _filteredItems = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError("Error fetching items: ${response.body}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Error fetching items: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _shopItems;
      } else {
        _filteredItems = _shopItems.where((item) {
          final name = (item["itemName"] ?? "").toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = "";
      _filteredItems = _shopItems;
    });
  }

  void _showItemFormBottomSheet({Map<String, dynamic>? existingItem}) {
    // Same _showItemFormBottomSheet function you already have (keep it)
    // ... (use your existing function here)
  }

  Future<void> _createItem({required String name, required double price, required int stock}) async {
    // Use your existing _createItem function
  }

  Future<void> _updateItem({required int itemId, required String name, required double price, required int stock}) async {
    // Use your existing _updateItem function
  }

  Future<void> _deleteItem(int itemId) async {
    // Use your existing _deleteItem function
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Items"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔎 Search Bar
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search items...",
                      border: InputBorder.none,
                    ),
                    onChanged: _filterItems,
                    controller: TextEditingController.fromValue(
                      TextEditingValue(
                        text: _searchQuery,
                        selection: TextSelection.collapsed(offset: _searchQuery.length),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSearch,
                  ),
              ],
            ),
          ),
          // Item List
          Expanded(child: _buildItemsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0054FF),
        onPressed: () => _showItemFormBottomSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_filteredItems.isEmpty) {
      return const Center(
        child: Text(
          "No items found.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: _filteredItems.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                item["itemName"] ?? "N/A",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                "Price: \$${item["price"]} | Stock: ${item["stock"]}",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showItemFormBottomSheet(existingItem: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteItem(item["itemId"]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
