import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../WidgetsCom/bottom_navigation_bar.dart';
import '../../WidgetsCom/dark_mode_handler.dart';
import '../../WidgetsCom/gradient_button_fb4.dart';
import '../../config.dart';
import 'group_payment_history_page.dart';

/// Model for a group member.
class GroupMember {
  final String memberName;
  double assignedAmount;

  GroupMember({
    required this.memberName,
    required this.assignedAmount,
  });
}

/// Helper class to hold the two text controllers for an in-progress member row.
class _MemberInputFields {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
}

class GroupPaymentPage extends StatefulWidget {
  const GroupPaymentPage({super.key});

  @override
  _GroupPaymentPageState createState() => _GroupPaymentPageState();
}

class _GroupPaymentPageState extends State<GroupPaymentPage> {
  // Controllers for main inputs.
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // Scroll controller to detect scroll changes.
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  String? paymentLink; // Latest created group payment link.
  final int _linkCounter = 0;

  // Final list of members.
  final List<GroupMember> _groupMembers = [];

  // List of in-progress new member rows.
  final List<_MemberInputFields> _newMemberRows = [];

  /// Whether a member row is currently being added.
  bool _isAddingMember = false;

  // Instance of secure storage.
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    // Dispose all text controllers for in-progress member rows.
    for (var row in _newMemberRows) {
      row.nameController.dispose();
      row.amountController.dispose();
    }
    super.dispose();
  }

  /// Returns true if the main inputs (Title, Description, and Total Amount) are valid.
  bool _hasValidMainInputs() {
    final title = titleController.text.trim();
    final desc = descriptionController.text.trim();
    final total = double.tryParse(amountController.text.trim()) ?? 0.0;
    return (title.isNotEmpty && desc.isNotEmpty && total > 0);
  }

  /// Called when the user taps the plus icon to add a new member.
  void _addNewMemberRow() {
    if (!_hasValidMainInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please complete Title, Description, and Total.")),
      );
      return;
    }

    final sumAssigned =
        _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);
    final totalAmount = double.tryParse(amountController.text.trim()) ?? 0.0;

    if (sumAssigned >= totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Cannot add more members. The total is fully allocated.")),
      );
      return;
    }

    if (_isAddingMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Finish adding the current member before adding another.")),
      );
      return;
    }

    setState(() {
      _isAddingMember = true;
      _newMemberRows.add(_MemberInputFields());
    });
  }

  /// Called when the user confirms adding a new member.
  void _confirmAddMember(int index) {
    final row = _newMemberRows[index];
    final name = row.nameController.text.trim();
    final amountText = row.amountController.text.trim();

    if (name.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter member name and amount.")),
      );
      return;
    }

    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please enter a valid assigned amount (greater than 0).")),
      );
      return;
    }

    final totalAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
    final sumAssigned =
        _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);

    if (sumAssigned + parsedAmount > totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Cannot assign \$${parsedAmount.toStringAsFixed(2)}, as it exceeds the total amount left.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _groupMembers
          .add(GroupMember(memberName: name, assignedAmount: parsedAmount));
      _newMemberRows.removeAt(index);
      _isAddingMember = false;
    });
  }

  /// Delete an added member by index.
  void _deleteMember(int index) {
    setState(() {
      _groupMembers.removeAt(index);
    });
  }

  /// Creates the group payment link by calling the backend API.
  /// Retrieves the user ID from secure storage and includes it in the payload.
  Future<void> _createGroupPaymentLink(BuildContext context) async {
    // Retrieve user ID from secure storage.
    String? storedUserId = await secureStorage.read(key: 'User_ID');
    if (storedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User is not logged in!")),
      );
      return;
    }
    int userId;
    try {
      userId = int.parse(storedUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Invalid User ID stored!")),
      );
      return;
    }

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final totalText = amountController.text.trim();

    if (title.isEmpty || description.isEmpty || totalText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final totalAmount = double.tryParse(totalText) ?? 0;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid total amount.")),
      );
      return;
    }

    if (_groupMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one member.")),
      );
      return;
    }

    final sumAssigned =
        _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);
    if ((sumAssigned - totalAmount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "The sum of assigned amounts (\$${sumAssigned.toStringAsFixed(2)}) must equal the total amount (\$${totalAmount.toStringAsFixed(2)}).",
          ),
        ),
      );
      return;
    }

    // Build the payload including the userId from secure storage.
    final payload = {
      "userId": userId,
      "title": title,
      "description": description,
      "totalAmount": totalAmount,
      "splitEqually": false,
      "members": _groupMembers
          .map(
            (m) => {
              "memberName": m.memberName,
              "assignedAmount": m.assignedAmount,
            },
          )
          .toList(),
    };

    debugPrint("Payload to send: $payload");

    try {
      // Replace with your actual backend endpoint URL.
      final response = await http.post(
        Uri.parse('$baseUrl/api/group-payments/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assumes that the backend returns the generated payment link under "paymentUrl"
        final String newPaymentLink = responseData['paymentUrl'] ?? "";
        debugPrint("Backend response paymentUrl: '$newPaymentLink'");
        setState(() {
          paymentLink = newPaymentLink;
          // Clear all inputs and member lists.
          titleController.clear();
          descriptionController.clear();
          amountController.clear();
          _groupMembers.clear();
          _newMemberRows.clear();
          _isAddingMember = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group Payment created successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Error creating group payment: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // -------------------- UI Building --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(), // AppBar without a history button.
      backgroundColor: DarkModeHandler.getBackgroundColor(),
      body: _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: const Color(0xFF83B6B9),
              child: const Icon(Icons.arrow_upward, color: Colors.black),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      resizeToAvoidBottomInset: true,
    );
  }

  // AppBar without the history button.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: DarkModeHandler.getAppBarColor(),
      title: const Text(
        "Group Payment",
        style: TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

  Widget _buildMainContent() {
    final sumAssigned =
        _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);
    final totalAmount = double.tryParse(amountController.text) ?? 0.0;
    final assignmentMatches = (sumAssigned - totalAmount).abs() < 0.01;

    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupPaymentLinkSection(),
            const SizedBox(height: 15),
            _buildLabel("Enter Title"),
            _buildTextField(
              controller: titleController,
              hint: 'Enter title...',
              keyboardType: TextInputType.text,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            _buildLabel("Enter Description"),
            _buildTextField(
              controller: descriptionController,
              hint: 'Enter description...',
              keyboardType: TextInputType.text,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 15),
            _buildLabel("Enter Total Amount"),
            _buildTextField(
              controller: amountController,
              hint: 'Enter total amount...',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            // Row with Members title and plus icon.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel("Members"),
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Color(0xFF83B6B9), size: 28),
                  onPressed:
                      (!_hasValidMainInputs() || sumAssigned >= totalAmount)
                          ? null
                          : _addNewMemberRow,
                ),
              ],
            ),
            // Display already added members.
            if (_groupMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "No members added yet.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _groupMembers.length,
                itemBuilder: (context, index) {
                  final member = _groupMembers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0, top: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${member.memberName} - \$${member.assignedAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMember(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 10),
            // In-progress new member rows.
            if (_newMemberRows.isNotEmpty)
              Column(
                children: List.generate(_newMemberRows.length, (index) {
                  return _buildNewMemberRow(index);
                }),
              ),
            const SizedBox(height: 10),
            // Summary.
            Text(
              "Total Assigned: \$${sumAssigned.toStringAsFixed(2)} / Total Amount: \$${totalAmount.toStringAsFixed(2)}",
              style: TextStyle(
                color: assignmentMatches ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Create Group Payment Link button.
            Center(
              child: GradientButtonFb4(
                text: 'Create Group Payment Link',
                onPressed: () => _createGroupPaymentLink(context),
              ),
            ),
            const SizedBox(height: 20),
            // History button using GradientButtonFb4 style.
            Center(
              child: GradientButtonFb4(
                text: 'History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GroupPaymentHistoryPage(),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                textColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds a single row for new member inputs with an "Add" button.
  Widget _buildNewMemberRow(int index) {
    final rowData = _newMemberRows[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildTextField(
              controller: rowData.nameController,
              hint: 'Member name...',
              keyboardType: TextInputType.text,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _buildTextField(
              controller: rowData.amountController,
              hint: 'Amount...',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _confirmAddMember(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF83B6B9),
              foregroundColor: Colors.white,
            ),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// Displays the created group payment link at the top of the white container.
  Widget _buildGroupPaymentLinkSection() {
    // If paymentLink is null or empty, show the default message.
    final bool showDefault = paymentLink == null || paymentLink!.trim().isEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: showDefault
          ? const Text(
              "Your group payment link will appear here after creation.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Group Payment Link:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: DarkModeHandler.getMainContainersTextColor(),
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  paymentLink!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paymentLink!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Group payment link copied to clipboard!")),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text("Copy Link"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }

  /// Builds a label with minimal styling.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: DarkModeHandler.getMainContainersTextColor(),
        ),
      ),
    );
  }

  /// Builds a text field with a hint, styling, and an optional onChanged callback.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: DarkModeHandler.getInputTypeTextColor()),
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        fillColor: DarkModeHandler.getMainContainersColor(),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      ),
    );
  }

  /// Builds the bottom navigation bar.
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBarWithFab(
      currentIndex: 0,
      onTap: (index) {
        // Handle navigation if needed.
      },
    );
  }
}
