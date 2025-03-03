import 'dart:core';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../ConnectionCheck/No_Internet_Ui.dart';
import '../../ConnectionCheck/connectivity_service.dart';
import '../../WidgetsCom/bottom_navigation_bar.dart';
import '../../WidgetsCom/dark_mode_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
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
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;

  String? userId;
  String? stripeAccountId;
  String? verificationStatus = "Fetching...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialConnectivity();
    _retrieveUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retrieveUserId();
    }
  }

  /// Check connectivity
  Future<void> _checkInitialConnectivity() async {
    var initialConnectivityResults =
        await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult =
          initialConnectivityResults.contains(ConnectivityResult.none)
              ? ConnectivityResult.none
              : ConnectivityResult.wifi;
      _isInitialCheckComplete = true;
    });
  }

  /// Retrieve user ID
  Future<void> _retrieveUserId() async {
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? retrievedUserId = await secureStorage.read(key: 'User_ID');
    setState(() {
      userId = retrievedUserId;
    });
    if (userId != null) {
      _fetchStripeAccountId();
    }
  }

  /// Fetch the Stripe account ID for the logged-in user
  Future<void> _fetchStripeAccountId() async {
    final String apiUrl =
        "$baseUrl/api/users/$userId/stripe-account";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          stripeAccountId = responseData['stripeAccountId'];
        });
        _fetchVerificationStatus();
      } else {
        Fluttertoast.showToast(
          msg: "Failed to fetch Stripe Account ID: ${response.body}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching Stripe Account ID: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  /// Fetch verification status
  Future<void> _fetchVerificationStatus() async {
    if (stripeAccountId == null) return;
    final String apiUrl =
        "$baseUrl/api/stripe/$stripeAccountId/verification-status";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          verificationStatus = responseData['verificationStatus'];
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to fetch verification status: ${response.body}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching verification status: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  /// Start the Stripe onboarding process
  Future<void> _startStripeOnboarding() async {
    if (stripeAccountId == null) {
      await _fetchStripeAccountId();
    }
    final String apiUrl = "https://api.stripe.com/v1/account_links";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
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
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final onboardingUrl = responseData['url'];
        if (await canLaunch(onboardingUrl)) {
          await launch(onboardingUrl);
        } else {
          throw 'Could not launch $onboardingUrl';
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to create Stripe onboarding link: ${response.body}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error starting Stripe onboarding: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure the Scaffold background matches the page background
      backgroundColor: DarkModeHandler.getBackgroundColor(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<List<ConnectivityResult>>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          if (!_isInitialCheckComplete) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final results = snapshot.data ?? [];
            final result = results.contains(ConnectivityResult.none)
                ? ConnectivityResult.none
                : ConnectivityResult.wifi;
            if (result == ConnectivityResult.none) {
              return NoInternetUI();
            } else {
              // Use SingleChildScrollView directly
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileDetail(
                            icon: Icons.email,
                            text: 'bhathika@gmail.com',
                            iconColor: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          _buildProfileDetail(
                            icon: Icons.verified,
                            text: 'Verification Status: $verificationStatus',
                            iconColor: verificationStatus == "Verified"
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1) Stripe Onboarding item
                    _buildProfileItem(
                      icon: Icons.verified_user,
                      title: 'Verify Stripe Account',
                      onTap: _startStripeOnboarding,
                      showArrow: true,
                      isEnabled: verificationStatus != "Verified",
                    ),

                    // 2) Master "Settings" item
                    _buildProfileItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      showArrow: true,
                      onTap: () {
                        // Navigate to new SettingsPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(
                              stripeAccountId: stripeAccountId,
                            ),
                          ),
                        );
                      },
                    ),

                    // Remove or reduce extra bottom space
                    // const SizedBox(height: 30), // <— removed
                  ],
                ),
              );
            }
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 3,
        onTap: (index) {
          // handle nav if needed
        },
      ),
    );
  }

  /// Profile header
  Widget _buildProfileHeader() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: DarkModeHandler.getTopContainerColor(),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          height: 230,
        ),
        const Positioned(
          top: 10,
          right: 10,
          child: Icon(Icons.edit, size: 25, color: Colors.grey),
        ),
        Positioned(
          top: 30,
          left: MediaQuery.of(context).size.width / 2 - 70,
          child: Column(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: ClipOval(
                  child: Image.asset(
                    'lib/images/coverimage.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bhathika Nilesh',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 5,
          left: 5,
          child: GestureDetector(
            onTap: () async {
              await DarkModeHandler.toggleDarkMode();
              setState(() {
                isDarkMode = DarkModeHandler.isDarkMode;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : const Color(0xFF83B6B9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDarkMode
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    size: 25,
                    color: Colors.yellow,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a profile detail row
  Widget _buildProfileDetail({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  /// Builds a single profile item row
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    bool showArrow = false,
    Function()? onTap,
    bool isEnabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 80,
            decoration: BoxDecoration(
              color: isEnabled
                  ? DarkModeHandler.getMainContainersColor()
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: isEnabled
                      ? DarkModeHandler.getProfilePageIconColor()
                      : Colors.grey,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          color: isEnabled
                              ? DarkModeHandler.getMainContainersTextColor()
                              : Colors.grey,
                        ),
                      ),
                      if (showArrow)
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isEnabled ? Colors.black : Colors.grey,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
