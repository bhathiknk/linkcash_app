import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeHandler {
  static bool isDarkMode = false;

  static Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
  }

  static Future<void> toggleDarkMode() async {
    isDarkMode = !isDarkMode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  //app bar color
  static Color getAppBarColor() {
    return isDarkMode ? Colors.black : const Color(0xFF0012fb);
  }

  //background color
  static Color getBackgroundColor() {
    return isDarkMode ? Color(0xFF303030) :  Color(0xFFE3F2FD);
  }

  //home page balance container included container
  static Color getTopContainerColor() {
    return isDarkMode ? Color(0xFF212121) : Colors.white;
  }

  //home page balace container color
  static Color getMainBalanceContainer() {
    return isDarkMode ? Color(0xFF303030) :  Color(0xFF007BFF);
  }
  static Color getMainBalanceContainerTextColor() {
    return isDarkMode ? Colors.white : Colors.white;
  }

  //home page transaction details container color
  static Color getMainContainersColor() {
    return isDarkMode ? Color(0xFF424242) : Colors.white;
  }
  static Color getMainContainersTextColor() {
    return isDarkMode ? Colors.white : Colors.black;
  }

  //calendar text color
  static Color getCalendarTextColor() {
    return isDarkMode ? Colors.white : Colors.black;
  }

  //container shadow color
  static Color getContainersShadowColor() {
    return isDarkMode ? Color(0xFF000000) : Color(0xff000000);
  }

  static Color getInputTextColor() {
    return isDarkMode ? Color(0xFFFFFFFF) : Color(0xff6b6b6b);
  }

  static Color getInputTypeTextColor() {
    return isDarkMode ? Color(0xFFFFFFFF) : Color(0xff6b6b6b);
  }
  static Color getProfilePageIconColor() {
    return isDarkMode ? Color(0xFFFFFFFF) : Color(0xff0009c2);
  }
  static Color getCalendarTodayTextColor() {
    return isDarkMode ? Color(0xFFFFFFFF) : Color(0xffffffff);
  }
}
