import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final ConnectivityService _connectivityService = ConnectivityService();
  final ImagePicker _picker = ImagePicker();

  bool isDarkMode = DarkModeHandler.isDarkMode;
  bool _initialComplete = false;

  String? userId;
  String? stripeAccountId;
  String? verificationStatus = "Fetching...";
  String? _email       = "Loading…";
  String? _givenName   = "Loading…";
  String? _profileImageUrl;
  XFile?  _pickedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _connectivityService.checkInitialConnectivity();
    await _retrieveUser();
    setState(() => _initialComplete = true);
  }

  Future<void> _retrieveUser() async {
    final id = await secureStorage.read(key: 'User_ID');
    if (id == null) return;
    userId = id;
    await Future.wait([
      _loadUserProfile(id),
      _loadStripeAccount(id),
      _loadProfileImageUrl(id),
    ]);
  }

  Future<void> _loadUserProfile(String id) async {
    final resp = await http.get(Uri.parse("$baseUrl/api/users/$id/profile"));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      setState(() {
        _email     = data['email'];
        _givenName = data['givenName'];
      });
    }
  }

  Future<void> _loadStripeAccount(String id) async {
    final resp = await http.get(Uri.parse("$baseUrl/api/users/$id/stripe-account"));
    if (resp.statusCode == 200) {
      final d = jsonDecode(resp.body);
      setState(() => stripeAccountId = d['stripeAccountId']);
      final v = await http.get(
          Uri.parse("$baseUrl/api/stripe/${stripeAccountId!}/verification-status")
      );
      if (v.statusCode == 200) {
        setState(() => verificationStatus = jsonDecode(v.body)['verificationStatus']);
      }
    }
  }

  Future<void> _loadProfileImageUrl(String id) async {
    final resp = await http.get(Uri.parse("$baseUrl/api/users/$id/profile-image"));
    if (resp.statusCode == 200) {
      final fn = jsonDecode(resp.body)['fileName'];
      setState(() => _profileImageUrl = "$baseUrl/profile-images/$fn");
    }
  }

  Future<void> _pickAndConfirmImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 600, maxHeight: 600
    );
    if (picked == null) return;
    setState(() => _pickedImage = picked);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Profile Picture"),
        content: Image.file(File(picked.path), height: 150),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _pickedImage = null);
              Navigator.pop(ctx);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadProfileImage();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProfileImage() async {
    if (_pickedImage == null || userId == null) {
      Fluttertoast.showToast(msg: "No image selected", backgroundColor: Colors.orange);
      return;
    }

    final file = File(_pickedImage!.path);

    // ADD: Check file existence and size before uploading
    if (!file.existsSync() || file.lengthSync() == 0) {
      Fluttertoast.showToast(msg: "Invalid image file", backgroundColor: Colors.red);
      return;
    }

    final uri = Uri.parse("$baseUrl/api/users/$userId/profile-image");
    final token = await secureStorage.read(key: 'auth_token');

    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        Fluttertoast.showToast(msg: "Profile updated", backgroundColor: Colors.green);
        setState(() => _pickedImage = null);
        await _loadProfileImageUrl(userId!);
      } else {
        Fluttertoast.showToast(
          msg: "Upload failed: ${streamed.statusCode}\n${resp.body}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Upload error: $e", backgroundColor: Colors.red);
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
                padding: const EdgeInsets.all(16),
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
                          builder: (_) => SettingsPage(
                              stripeAccountId: stripeAccountId
                          ),
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
        onPressed: () => setState(
                () => isDarkMode = DarkModeHandler.toggleDarkMode() as bool
        ),
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
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          _givenName!,
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
                onTap: _pickAndConfirmImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : (_profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('assets/default_avatar.png')
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
                        color: Color(0xFF0054FF),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            _buildDetailTile(Icons.email, "Email", _email!),
            const SizedBox(height: 20),
            _buildDetailTile(
              Icons.verified,
              "Verification Status",
              verificationStatus!,
              trailingColor:
              verificationStatus == "Verified" ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
      IconData icon,
      String title,
      String value, {
        Color? trailingColor,
      }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0054FF)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
    required void Function()? onTap,
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
                Icon(icon, size: 28, color: const Color(0xFF0054FF)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
