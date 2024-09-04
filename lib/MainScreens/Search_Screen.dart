import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  bool isSearchFocused = false;
  int currentIndex = 4; // Set initial index to SearchPage

  @override
  void initState() {
    super.initState();
    // Listen to focus changes
    searchFocusNode.addListener(() {
      setState(() {
        isSearchFocused = searchFocusNode.hasFocus;
      });
    });

    // Listen to text changes to reset the position when input is cleared
    searchController.addListener(() {
      if (searchController.text.isEmpty) {
        setState(() {
          isSearchFocused = false; // Move back to center when text is cleared
        });
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

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
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: DarkModeHandler.getBackgroundColor(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                top: isSearchFocused ? 20 : MediaQuery.of(context).size.height * 0.3,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300), // Adjust width here
                  child: SearchInputFb1(
                    searchController: searchController,
                    focusNode: searchFocusNode,
                    hintText: 'Search...', // Customize hint text as needed
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Add the BottomNavigationBarWithFab
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

class SearchInputFb1 extends StatelessWidget {
  final TextEditingController searchController;
  final String hintText;
  final FocusNode focusNode;

  const SearchInputFb1({
    required this.searchController,
    required this.hintText,
    required this.focusNode,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          offset: const Offset(12, 26),
          blurRadius: 50,
          spreadRadius: 0,
          color: Colors.grey.withOpacity(.1),
        ),
      ]),
      child: TextField(
        controller: searchController,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        onTap: () {
          searchController.clear(); // Clear text on tap
        },
        onChanged: (value) {
          // Handle search input changes if needed
        },
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xffFF5A60)),
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black.withOpacity(.75)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 1.0),
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
        ),
      ),
    );
  }
}
