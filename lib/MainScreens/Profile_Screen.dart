import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = DarkModeHandler.isDarkMode;
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    var initialConnectivityResult = await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = initialConnectivityResult;
      _isInitialCheckComplete = true;
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
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<ConnectivityResult>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          if (!_isInitialCheckComplete) {
            return Center(child: CircularProgressIndicator());
          } else {
            ConnectivityResult? result = snapshot.data ?? _initialConnectivityResult;
            if (result == ConnectivityResult.none) {
              return NoInternetUI();
            } else {
              return _buildProfilePageContent(context);
            }
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 3,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  Widget _buildProfilePageContent(BuildContext context) {
    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: DarkModeHandler.getTopContainerColor(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                height: 200,
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: Icon(Icons.edit, size: 25, color: Colors.grey),
              ),
              Positioned(
                top: 40,
                left: MediaQuery.of(context).size.width / 2 - 70,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'lib/images/coverimage.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
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
                    duration: Duration(milliseconds: 600),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black : Colors.blue[300],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode ? Colors.grey : Colors.transparent,
                          blurRadius: 5,
                          spreadRadius: 2,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                          size: 25,
                          color: Colors.yellow,
                        ),
                        SizedBox(width: 4),
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
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(5, (index) {
              IconData icon;
              String title;
              switch (index) {
                case 0:
                  icon = Icons.person;
                  title = 'Bhathika Nilesh';
                  break;
                case 1:
                  icon = Icons.email;
                  title = 'bhathika@gmail.com';
                  break;
                case 2:
                  icon = Icons.phone;
                  title = '11111111111';
                  break;
                case 3:
                  icon = Icons.settings;
                  title = 'Settings';
                  break;
                case 4:
                  icon = Icons.support;
                  title = 'Support';
                  break;
                default:
                  icon = Icons.error;
                  title = 'Error';
                  break;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 20,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DarkModeHandler.getMainContainersColor(),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff000000).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          icon,
                          size: 30,
                          color: DarkModeHandler.getProfilePageIconColor(),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                color: DarkModeHandler.getMainContainersTextColor(),
                              ),
                            ),
                            if (index == 3 || index == 4)
                              Icon(Icons.arrow_forward_ios),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
