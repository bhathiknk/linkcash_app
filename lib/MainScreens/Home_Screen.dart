import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  static const routeName = '/home';

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
          "Link Cash",
          style: TextStyle(
            color: Colors.white, // Set text color to white
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
              return _buildHomePageContent(context);
            }
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  Widget _buildHomePageContent(BuildContext context) {
    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: Column(
        children: [
          Stack(
            children: [
              ///Top White Container///
              Container(
                decoration: BoxDecoration(
                  color: DarkModeHandler.getTopContainerColor(),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                height: 200,
              ),

              ///'Welcome Back' text///
              const Positioned(
                top: 10,
                left: 10,
                child: Row(
                  children: [
                    SizedBox(width: 10), // Add some space between the icon and text
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.waving_hand_rounded, size: 20, color: Colors.grey),
                  ],
                ),
              ),

              ///'Bhathika Nilesh' text///
              Positioned(
                top: 30, // Adjust the position as needed
                left: 20,
                child: Text(
                  'Bhathika Nilesh',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    color: DarkModeHandler.getCalendarTextColor(),
                  ),
                ),
              ),

              ///Notification icon///
              const Positioned(
                top: 10,
                right: 10,
                child: Icon(Icons.notifications, size: 25, color: Colors.grey),
              ),

              ///balance show container///
              Positioned(
                top: 80, // Adjust the position as needed
                left: 10,
                right: 10,
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    //background color called//
                    color: DarkModeHandler.getBackgroundColor(),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff000000).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(3, 3), // changes position of shadow
                      ),
                    ],
                  ),

                  ///Balance text and value///
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: DarkModeHandler.getMainContainersTextColor(),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '\$800.00',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 30,
                            color: DarkModeHandler.getMainContainersTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          ///calendar container///
          const SizedBox(height: 10), // space between the white container and the calendar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: MediaQuery.of(context).size.width - 20,
            decoration: BoxDecoration(
              color: DarkModeHandler.getMainContainersColor(),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff000000).withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(2, 2), // changes position of shadow
                ),
              ],
            ),
            child: CalendarWidget(),
          ),

          /// 'Transactions' text///
          const SizedBox(height: 20), // Add some space between the white calendar container and the Transaction text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    color: DarkModeHandler.getMainContainersTextColor(),
                  ),
                ),
                Spacer(), // Add flexible space to push the text to the left
              ],
            ),
          ),

          /// Transactions show container///
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allow scrolling horizontally
              child: Row(
                children: List.generate(
                  5, // Number of containers to generate
                      (index) => Padding(
                    padding: const EdgeInsets.all(9.0), // Add padding between containers
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8, // Adjust the width of the container
                      decoration: BoxDecoration(
                        color: DarkModeHandler.getBackgroundColor(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 20, // Add space between SizedBox widgets
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.75, // Adjust the width of the inner container
                            decoration: BoxDecoration(
                              color: DarkModeHandler.getMainContainersColor(),
                              borderRadius: BorderRadius.circular(10), // Adjust the border radius
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff000000).withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 1,
                                  offset: Offset(2, 2), // changes position of shadow
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75, // Adjust the width
                              height: 100, // Adjust the height
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align content horizontally
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center, // Align content vertically
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          "Payment Link Title",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: DarkModeHandler.getMainContainersTextColor(),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.0, top: 8.0),
                                        child: Text(
                                          "Bhathika",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: DarkModeHandler.getMainContainersTextColor(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "+ \$300",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: DarkModeHandler.getMainContainersTextColor(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
