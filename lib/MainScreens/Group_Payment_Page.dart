import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard

import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/gradient_button_fb4.dart';

/// A model for the group member that will be part of the final (added) list.
class GroupMember {
  final String memberName;
  double assignedAmount;

  GroupMember({
    required this.memberName,
    required this.assignedAmount,
  });
}

/// A simple helper class to hold the two text controllers for an "in-progress" member row.
class _MemberInputFields {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
}

class GroupPaymentPage extends StatefulWidget {
  const GroupPaymentPage({Key? key}) : super(key: key);

  @override
  _GroupPaymentPageState createState() => _GroupPaymentPageState();
}

class _GroupPaymentPageState extends State<GroupPaymentPage> {
  // Controllers for the main "Group Payment" inputs.
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // Scroll controller to detect scroll changes.
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  String? paymentLink; // Latest created group payment link
  int _linkCounter = 0;

  // Final list of members that have been added.
  final List<GroupMember> _groupMembers = [];

  // A list of "in-progress" rows for new members (not yet added).
  final List<_MemberInputFields> _newMemberRows = [];

  /// Whether the user is currently adding a member (so we lock the plus icon).
  bool _isAddingMember = false;

  @override
  void initState() {
    super.initState();

    // Listen to scroll changes to show/hide the "scroll to top" button.
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
    // Dispose controllers in the pending input rows, too.
    for (var row in _newMemberRows) {
      row.nameController.dispose();
      row.amountController.dispose();
    }
    super.dispose();
  }

  /// Returns true if the user has entered a valid Title, Description, and positive total amount.
  bool _hasValidMainInputs() {
    final title = titleController.text.trim();
    final desc = descriptionController.text.trim();
    final total = double.tryParse(amountController.text.trim()) ?? 0.0;
    return (title.isNotEmpty && desc.isNotEmpty && total > 0);
  }

  /// Invoked when the user taps the plus icon.
  ///  - Ensures main inputs are valid (title/desc/total).
  ///  - Ensures sum of assigned amounts is still less than total.
  ///  - Ensures we are not already adding a member row.
  void _addNewMemberRow() {
    // 1) Check if main fields are valid.
    if (!_hasValidMainInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete Title, Description, and Total."),
        ),
      );
      return;
    }

    final sumAssigned = _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);
    final totalAmount = double.tryParse(amountController.text.trim()) ?? 0.0;

    // 2) Check if sumAssigned already equals or exceeds total.
    if (sumAssigned >= totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot add more members. The total is fully allocated."),
        ),
      );
      return;
    }

    // 3) Only allow one row at a time.
    if (_isAddingMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Finish adding the current member before adding another."),
        ),
      );
      return;
    }

    // If all checks are OK, add a new row.
    setState(() {
      _isAddingMember = true;
      _newMemberRows.add(_MemberInputFields());
    });
  }

  /// Called when the user presses the "Add" button next to a row of text fields.
  /// Moves that row into the final _groupMembers list (if valid), then removes it from _newMemberRows.
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
        const SnackBar(content: Text("Please enter a valid assigned amount (greater than 0).")),
      );
      return;
    }

    final totalAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
    final sumAssigned = _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);

    // Check if adding this member would exceed the total.
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

    // Add to final list.
    setState(() {
      _groupMembers.add(
        GroupMember(memberName: name, assignedAmount: parsedAmount),
      );
      // Remove the row of text fields since it's now added.
      _newMemberRows.removeAt(index);
      _isAddingMember = false;
    });
  }

  /// Delete a final added member by index.
  void _deleteMember(int index) {
    setState(() {
      _groupMembers.removeAt(index);
    });
  }

  /// Creates the group payment link, ensuring the sum of assigned amounts matches the total.
  void _createGroupPaymentLink(BuildContext context) {
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

    // Sum of assigned amounts must match the total if that is desired logic.
    final sumAssigned = _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);
    if ((sumAssigned - totalAmount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "The sum of assigned amounts (\$${sumAssigned.toStringAsFixed(2)}) must equal "
                "the total amount (\$${totalAmount.toStringAsFixed(2)}).",
          ),
        ),
      );
      return;
    }

    // Build the payload for your backend.
    final payload = {
      "userId": 0,
      "title": title,
      "description": description,
      "totalAmount": totalAmount,
      "splitEqually": false, // or remove if not needed
      "members": _groupMembers
          .map(
            (m) => {
          "memberName": m.memberName,
          "assignedAmount": m.assignedAmount,
        },
      )
          .toList(),
    };

    // Simulate a backend call by generating a dummy link.
    _linkCounter++;
    final dummyLink = "https://grouppayment.com/link_$_linkCounter";

    setState(() {
      paymentLink = dummyLink;
      // Optionally clear all inputs.
      titleController.clear();
      descriptionController.clear();
      amountController.clear();
      _groupMembers.clear();
      // Also remove any pending newMemberRows.
      _newMemberRows.clear();
      _isAddingMember = false;
    });

    debugPrint("Payload to send: $payload");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Group Payment created successfully!")),
    );
  }

  // UI building:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
        child: const Icon(Icons.arrow_upward, color: Colors.black),
        backgroundColor: const Color(0xFF83B6B9),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      resizeToAvoidBottomInset: true,
    );
  }

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
    final sumAssigned = _groupMembers.fold(0.0, (prev, m) => prev + m.assignedAmount);
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

            // Main inputs:
            _buildLabel("Enter Title"),
            _buildTextField(
              controller: titleController,
              hint: 'Enter title...',
              keyboardType: TextInputType.text,
              // Rebuild on text change so plus button updates.
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

            // Title row (Members + plus icon).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel("Members"),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF83B6B9), size: 28),
                  // The plus icon is disabled if _isAddingMember is true,
                  // or if sumAssigned >= total, or if main inputs are invalid.
                  onPressed: (!_hasValidMainInputs() || sumAssigned >= totalAmount)
                      ? null
                      : _addNewMemberRow, // Otherwise, call _addNewMemberRow
                ),
              ],
            ),

            // Already added (final) members:
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
                        // Show the final member name and assigned amount with minimal styling.
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

            // "In-progress" new member rows (not yet added).
            // Each row shows Name, Amount, and an "Add" button.
            if (_newMemberRows.isNotEmpty)
              Column(
                children: List.generate(_newMemberRows.length, (index) {
                  return _buildNewMemberRow(index);
                }),
              ),
            const SizedBox(height: 10),

            // Summary.
            Text(
              "Total Assigned: \$${sumAssigned.toStringAsFixed(2)} "
                  "/ Total Amount: \$${totalAmount.toStringAsFixed(2)}",
              style: TextStyle(
                color: assignmentMatches ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Create link button.
            Center(
              child: GradientButtonFb4(
                text: 'Create Group Payment Link',
                onPressed: () => _createGroupPaymentLink(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// A single row of new member text fields + "Add" button.
  /// Displays them inline (no extra containers).
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

  /// Displays the latest created group payment link, if any.
  Widget _buildGroupPaymentLinkSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: paymentLink == null
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
                const SnackBar(content: Text("Group payment link copied to clipboard!")),
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

  Widget _buildLabel(String text) {
    // Minimal label styling.
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

  /// Adds an optional `onChanged` callback to re-check valid input states.
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
      onChanged: onChanged, // <<--- triggers rebuild on user input
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        fillColor: DarkModeHandler.getMainContainersColor(),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBarWithFab(
      currentIndex: 0,
      onTap: (index) {
        // Handle navigation if needed.
      },
    );
  }
}
