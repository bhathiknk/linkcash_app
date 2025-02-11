import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../WidgetsCom/dark_mode_handler.dart';

class SettingsPage extends StatefulWidget {
  final String? stripeAccountId;

  const SettingsPage({
    super.key,
    required this.stripeAccountId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Payout logic (daily/weekly)
  String _payoutInterval = 'daily';
  String _weeklyAnchor = 'monday';

  @override
  void initState() {
    super.initState();
    _fetchCurrentPayoutSchedule();
  }

  /// Fetch the current payout schedule (daily/weekly).
  Future<void> _fetchCurrentPayoutSchedule() async {
    if (widget.stripeAccountId == null) return;
    final String url =
        "http://10.0.2.2:8080/api/stripe/${widget.stripeAccountId}/payout-schedule";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final interval = responseData['payoutInterval'] ?? 'daily';
        setState(() {
          _payoutInterval = interval;
        });
      }
    } catch (e) {
      // Not critical if it fails
    }
  }

  /// Start Stripe account onboarding (update).
  Future<void> _startStripeAccountOnboarding() async {
    if (widget.stripeAccountId == null) {
      Fluttertoast.showToast(
        msg: "Stripe account not connected. Please connect first.",
        backgroundColor: Colors.red,
      );
      return;
    }

    const String apiUrl = "https://api.stripe.com/v1/account_links";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer YOUR_STRIPE_SECRET_KEY',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'account': widget.stripeAccountId!,
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

  /// Update payout schedule on the backend
  Future<void> _updatePayoutSchedule(String interval,
      {String? anchorDay}) async {
    if (widget.stripeAccountId == null) {
      Fluttertoast.showToast(
        msg: "No Stripe account found. Please try again.",
        backgroundColor: Colors.red,
      );
      return;
    }

    final String apiUrl =
        "http://10.0.2.2:8080/api/stripe/${widget.stripeAccountId}/update-payout-schedule";

    final body = {'interval': interval};
    if (interval == 'weekly' && anchorDay != null) {
      body['weeklyAnchor'] = anchorDay;
    }

    try {
      final response = await http.post(Uri.parse(apiUrl), body: body);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Payout schedule updated successfully!",
          backgroundColor: Colors.green,
        );
        setState(() {
          _payoutInterval = interval;
          if (interval == 'weekly' && anchorDay != null) {
            _weeklyAnchor = anchorDay;
          }
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to update payout schedule: ${response.body}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating payout schedule: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return '${input[0].toUpperCase()}${input.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the same background color as ProfilePage
      backgroundColor: DarkModeHandler.getBackgroundColor(),

      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: DarkModeHandler.getAppBarColor(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----- SECTION 1: Account Settings -----
              Text(
                "ACCOUNT SETTINGS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DarkModeHandler.getProfilePageIconColor(),
                ),
              ),
              const SizedBox(height: 8),

              // Container for "Account Settings"
              Container(
                decoration: BoxDecoration(
                  color: DarkModeHandler.getMainContainersColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // Example "Account Settings" item
                    ListTile(
                      leading: Icon(
                        Icons.person,
                        color: DarkModeHandler.getProfilePageIconColor(),
                        size: 30,
                      ),
                      title: Text(
                        'Personal Info',
                        style: TextStyle(
                          fontSize: 16,
                          color: DarkModeHandler.getMainContainersTextColor(),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // e.g. navigate to personal info page, if you have one
                      },
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.security,
                        color: DarkModeHandler.getProfilePageIconColor(),
                        size: 30,
                      ),
                      title: Text(
                        'Security Settings',
                        style: TextStyle(
                          fontSize: 16,
                          color: DarkModeHandler.getMainContainersTextColor(),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // e.g. navigate to security settings
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ----- SECTION 2: Stripe Settings -----
              Text(
                "STRIPE SETTINGS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DarkModeHandler.getProfilePageIconColor(),
                ),
              ),
              const SizedBox(height: 8),

              // Container for "Stripe Settings"
              Container(
                decoration: BoxDecoration(
                  color: DarkModeHandler.getMainContainersColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // "Stripe Account Settings"
                    ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet,
                        color: DarkModeHandler.getProfilePageIconColor(),
                        size: 30,
                      ),
                      title: Text(
                        "Stripe Account Settings",
                        style: TextStyle(
                          fontSize: 16,
                          color: DarkModeHandler.getMainContainersTextColor(),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _startStripeAccountOnboarding,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    // "Stripe Payout Settings"
                    ListTile(
                      leading: Icon(
                        Icons.payments,
                        color: DarkModeHandler.getProfilePageIconColor(),
                        size: 30,
                      ),
                      title: Text(
                        "Stripe Payout Settings (${_capitalize(_payoutInterval)})",
                        style: TextStyle(
                          fontSize: 16,
                          color: DarkModeHandler.getMainContainersTextColor(),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showPayoutOptionsDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayoutOptionsDialog() {
    String tempInterval = _payoutInterval;
    String tempAnchor = _weeklyAnchor;
    final anchorDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Select Payout Schedule",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Daily'),
                            value: 'daily',
                            groupValue: tempInterval,
                            onChanged: (val) {
                              setStateDialog(() {
                                tempInterval = val ?? 'daily';
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Weekly'),
                            value: 'weekly',
                            groupValue: tempInterval,
                            onChanged: (val) {
                              setStateDialog(() {
                                tempInterval = val ?? 'weekly';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tempInterval == 'weekly') ...[
                      const Text(
                        'Select Anchor Day',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButton<String>(
                        value: tempAnchor,
                        items: anchorDays.map((day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Text(_capitalize(day)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            tempAnchor = newValue ?? 'monday';
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (tempInterval == 'daily') {
                      await _updatePayoutSchedule('daily');
                    } else {
                      await _updatePayoutSchedule('weekly',
                          anchorDay: tempAnchor);
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
