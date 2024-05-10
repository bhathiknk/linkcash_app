import 'package:flutter/material.dart';

import '../WidgetsCom/bottom_navigation_bar.dart';

class LinkViewPage extends StatelessWidget {
  const LinkViewPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0054FF),
        title: const Text(
          'Link View Page',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFE3F2FD), // Background color body
          ),

          ///QR image section///
          Align(
            alignment: FractionalOffset.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0), // top padding between app bar and QR
              child: Image.asset(
                'lib/images/qrcode.png',
                width: 220, // Adjust width
                height: 220, // Adjust height
              ),
            ),
          ),
          ///QR image section end///
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {

        },
      ),
    );
  }
}
