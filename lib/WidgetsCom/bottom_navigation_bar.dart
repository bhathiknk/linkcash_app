import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PAGES
import '../MainScreens/Home_Screen.dart';
import '../MainScreens/ShopComponent/ShopPage.dart';
import '../MainScreens/QRpaymentPages/QRPayReceivePage.dart';
import '../MainScreens/QRpaymentPages/QRPaySendPage.dart';
import '../MainScreens/ProfileComponents/Profile_Screen.dart';
import '../MainScreens/TransactionAnalysisPage/TransactionHistory_Screen.dart';
// ──────────────────────────────────────────────────────────────────────────────

const Color kBlue       = Color(0xFF0054FF);
const Color kBarBg      = Colors.white;
const double kBarHeight = 60.0;

class BottomNavigationBarWithFab extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  const BottomNavigationBarWithFab({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });
  @override
  State<BottomNavigationBarWithFab> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavigationBarWithFab> {
  final _storage = const FlutterSecureStorage();
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await _storage.read(key: 'User_ID');
    if (id != null && mounted) setState(() => userId = id);
  }

  void _go(int idx) {
    widget.onTap(idx);
    switch (idx) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => MyHomePage(givenName: '')));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()));
        break;
      case 2:
        _showQrSheet();
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryPage()));
        break;
    }
  }

  void _showQrSheet() {
    if (userId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Choose an action",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _QrOption(icon: Icons.download_rounded, label: "Receive", onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => QRReceivePage(userId: int.parse(userId!)),
              ));
            }),
            _QrOption(icon: Icons.send_rounded, label: "Send", onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => QRSendPayPage(userId: int.parse(userId!)),
              ));
            }),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kBarHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Bar background
          Container(
            height: kBarHeight,
            decoration: const BoxDecoration(
              color: kBarBg,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BarIcon(Icons.home,    0),
                _BarIcon(Icons.receipt, 4),
                const SizedBox(width: 56), // space for fab
                _BarIcon(Icons.store,   1),
                _BarIcon(Icons.person,  3),
              ],
            ),
          ),
          // Floating FAB stays at bar bottom
          Positioned(
            bottom: 0,
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _go(2);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0054FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF010202), blurRadius: 9, offset: Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.link, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _BarIcon(IconData icon, int idx) {
    final bool selected = widget.currentIndex == idx;
    // lift icon up by 6px
    return Transform.translate(
      offset: const Offset(0, -6),
      child: IconButton(
        splashRadius: 24,
        onPressed: () {
          HapticFeedback.lightImpact();
          _go(idx);
        },
        icon: Icon(icon, size: 26, color: selected ? kBlue : Colors.black45),
      ),
    );
  }
}

class _QrOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QrOption({required this.icon, required this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(backgroundColor: kBlue, radius: 28, child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
