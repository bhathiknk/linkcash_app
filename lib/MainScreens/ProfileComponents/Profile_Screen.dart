import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../ConnectionCheck/No_Internet_Ui.dart';
import '../../ConnectionCheck/connectivity_service.dart';
import '../../WidgetsCom/bottom_navigation_bar.dart';
import '../../WidgetsCom/dark_mode_handler.dart';
import '../../config.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  bool isDarkMode = DarkModeHandler.isDarkMode;
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _initialComplete = false;

  String? userId;
  String? stripeAccountId;
  String? verificationStatus = "Fetching...";
  String? _email = "Loading...";
  String? _givenNameProfile = "Loading...";
  String? _profileImageUrl;
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryBlue = Color(0xFF0054FF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _retrieveUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _retrieveUser();
  }

  Future<void> _checkConnectivity() async {
    await _connectivityService.checkInitialConnectivity();
    setState(() => _initialComplete = true);
  }

  Future<void> _retrieveUser() async {
    final store = const FlutterSecureStorage();
    final id = await store.read(key: 'User_ID');
    setState(() => userId = id);
    if (userId != null) {
      await _loadUserProfile(id!);
      await _loadStripeAccount(id!);
      await _loadProfileImageUrl();
    }
  }

  Future<void> _loadUserProfile(String id) async {
    final resp = await http.get(Uri.parse("$baseUrl/api/users/$id/profile"));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      setState(() {
        _email = data['email'];
        _givenNameProfile = data['givenName'];
      });
    }
  }

  Future<void> _loadStripeAccount(String id) async {
    final resp = await http.get(Uri.parse("$baseUrl/api/users/$id/stripe-account"));
    if (resp.statusCode == 200) {
      final d = jsonDecode(resp.body);
      setState(() => stripeAccountId = d['stripeAccountId']);
      _loadVerification();
    }
  }

  Future<void> _loadVerification() async {
    if (stripeAccountId == null) return;
    final resp = await http.get(Uri.parse("$baseUrl/api/stripe/$stripeAccountId/verification-status"));
    if (resp.statusCode == 200) {
      final d = jsonDecode(resp.body);
      setState(() => verificationStatus = d['verificationStatus']);
    }
  }

  Future<void> _loadProfileImageUrl() async {
    if (userId == null) return;
    final resp = await http.get(Uri.parse("$baseUrl/api/users/$userId/profile-image"));
    if (resp.statusCode == 200) {
      final fn = jsonDecode(resp.body)['fileName'];
      setState(() {
        _profileImageUrl = "$baseUrl/profile-images/$fn";
      });
    }
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _uploadProfileImage() async {
    if (_pickedImage == null || userId == null) return;
    final uri = Uri.parse("$baseUrl/api/users/$userId/profile-image");
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', _pickedImage!.path));
    final res = await req.send();
    if (res.statusCode == 200) {
      Fluttertoast.showToast(msg: "Image uploaded!", backgroundColor: Colors.green);
      setState(() => _pickedImage = null);
      _loadProfileImageUrl();
    } else {
      Fluttertoast.showToast(msg: "Upload failed", backgroundColor: Colors.red);
    }
  }

  Future<void> _startOnboarding() async {
    if (stripeAccountId == null) return;
    final resp = await http.post(
      Uri.parse("https://api.stripe.com/v1/account_links"),
      headers: {
        'Authorization': 'Bearer ${dotenv.env['STRIPE_API_KEY']}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'account': stripeAccountId!,
        'refresh_url': 'https://your-app.com/refresh',
        'return_url': 'https://your-app.com/return',
        'type': 'account_onboarding',
      },
    );
    if (resp.statusCode == 200) {
      final url = jsonDecode(resp.body)['url'];
      if (await canLaunch(url)) await launch(url);
    } else {
      Fluttertoast.showToast(msg: "Onboarding failed", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: !_initialComplete
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ConnectivityResult>>(
        stream: _connectivityService.connectivityStream,
        builder: (ctx, snap) {
          if ((snap.data ?? []).contains(ConnectivityResult.none)) {
            return NoInternetUI();
          }
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 30),
                    _buildDetailSection(),
                    const SizedBox(height: 30),
                    _buildActionCard(
                      icon: Icons.verified_user,
                      title: "Verify Stripe Account",
                      enabled: verificationStatus != "Verified",
                      onTap: _startOnboarding,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.settings,
                      title: "Settings",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsPage(stripeAccountId: stripeAccountId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => isDarkMode = DarkModeHandler.toggleDarkMode() as bool),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.yellow[700],
        child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 3,
        onTap: (_) {},
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_pickedImage != null)
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _uploadProfileImage,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          _givenNameProfile ?? "",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0054FF), Color(0xFF83B6B9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
            ),
            Positioned(
              bottom: 100,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                      as ImageProvider
                          : (_profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('lib/images/default.png')
                      as ImageProvider),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        color: _primaryBlue,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            _buildDetailTile(Icons.email, "Email", _email ?? ""),
            const SizedBox(height: 20),
            _buildDetailTile(
              Icons.verified,
              "Verification Status",
              verificationStatus ?? "",
              trailingColor:
              verificationStatus == "Verified" ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value,
      {Color? trailingColor}) {
    return Row(
      children: [
        Icon(icon, color: _primaryBlue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        if (trailingColor != null)
          Icon(Icons.circle, color: trailingColor, size: 14),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    void Function()? onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 28, color: _primaryBlue),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
