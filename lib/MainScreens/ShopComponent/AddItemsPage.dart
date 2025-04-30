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

  int? _shopId;

  // For searching items by name
  String _itemSearchQuery = "";
  final TextEditingController _itemSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchShopIdAndItems();
  }

  /// Retrieve the shopId from secure storage, then fetch items.
  Future<void> _fetchShopIdAndItems() async {
    setState(() => _isLoading = true);

    final FlutterSecureStorage storage = const FlutterSecureStorage();
    String? shopIdStr = await storage.read(key: 'SHOP_ID');
    if (shopIdStr == null) {
      setState(() => _isLoading = false);
      _showError("No SHOP_ID found in storage.");
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

  /// Fetch items for the current shop
  Future<void> _fetchItemsByShopId() async {
    if (_shopId == null) return;
    final url = Uri.parse('$baseUrl/api/items/shop/$_shopId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _shopItems = data;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// Show bottom sheet for adding or editing an item
  /// If [existingItem] is null -> create mode; otherwise -> edit mode
  void _showItemFormBottomSheet({Map<String, dynamic>? existingItem}) {
    final isEditMode = existingItem != null;

    final TextEditingController nameCtrl = TextEditingController(
      text: isEditMode ? existingItem!["itemName"] : "",
    );
    final TextEditingController priceCtrl = TextEditingController(
      text: isEditMode ? existingItem!["price"].toString() : "",
    );
    final TextEditingController stockCtrl = TextEditingController(
      text: isEditMode ? existingItem!["stock"].toString() : "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  Text(
                    isEditMode ? "Edit Item" : "Add New Item",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Item Name
                  _buildFormTextField(
                    controller: nameCtrl,
                    label: "Item Name",
                  ),
                  const SizedBox(height: 16),
                  // Price
                  _buildFormTextField(
                    controller: priceCtrl,
                    label: "Price",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  // Stock
                  _buildFormTextField(
                    controller: stockCtrl,
                    label: "Stock",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final priceStr = priceCtrl.text.trim();
                            final stockStr = stockCtrl.text.trim();

                            if (name.isEmpty || priceStr.isEmpty || stockStr.isEmpty) {
                              _showError("Please fill all fields.");
                              return;
                            }

                            final double? price = double.tryParse(priceStr);
                            final int? stock = int.tryParse(stockStr);

                            if (price == null || stock == null) {
                              _showError("Invalid price or stock.");
                              return;
                            }

                            if (_shopId == null) {
                              _showError("Missing shopId. Cannot create/update item.");
                              Navigator.pop(context);
                              return;
                            }

                            if (isEditMode) {
                              final itemId = existingItem!["itemId"];
                              await _updateItem(
                                itemId: itemId,
                                name: name,
                                price: price,
                                stock: stock,
                              );
                            } else {
                              await _createItem(
                                name: name,
                                price: price,
                                stock: stock,
                              );
                            }

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0054FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(45),
                          ),
                          child: Text(isEditMode ? "Update Item" : "Create Item"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Reusable function to build a form text field
  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: InputBorder.none,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// POST /api/items/create
  Future<void> _createItem({
    required String name,
    required double price,
    required int stock,
  }) async {
    setState(() => _isLoading = true);
    final body = {
      "itemName": name,
      "price": price,
      "stock": stock,
      "shopId": _shopId,
    };

    try {
      final url = Uri.parse('$baseUrl/api/items/create');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        _showMessage("Item created successfully.");
        await _fetchItemsByShopId();
      } else {
        _showError("Error: ${response.body}");
      }
    } catch (e) {
      _showError("Error creating item: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// PUT /api/items/{itemId}
  Future<void> _updateItem({
    required int itemId,
    required String name,
    required double price,
    required int stock,
  }) async {
    setState(() => _isLoading = true);
    final body = {
      "itemName": name,
      "price": price,
      "stock": stock,
      "shopId": _shopId,
    };

    try {
      final url = Uri.parse('$baseUrl/api/items/$itemId');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        _showMessage("Item updated successfully.");
        await _fetchItemsByShopId();
      } else {
        _showError("Error: ${response.body}");
      }
    } catch (e) {
      _showError("Error updating item: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// DELETE /api/items/{itemId}
  Future<void> _deleteItem(int itemId) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('$baseUrl/api/items/$itemId');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        _showMessage("Item deleted successfully.");
        await _fetchItemsByShopId();
      } else {
        _showError("Error: ${response.body}");
      }
    } catch (e) {
      _showError("Error deleting item: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Searching
  void _onSearchChanged(String value) {
    setState(() {
      _itemSearchQuery = value.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    setState(() {
      _itemSearchQuery = "";
      _itemSearchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text("Add Items"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _buildItemsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0054FF),
        onPressed: () => _showItemFormBottomSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _itemSearchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Search items...",
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _itemSearchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: _clearSearch,
          )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    final filteredItems = _shopItems.where((item) {
      final name = (item["itemName"] ?? "").toString().toLowerCase();
      return name.contains(_itemSearchQuery);
    }).toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Text(
          "No items found.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
                  const SizedBox(width: 8),
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
