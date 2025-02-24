import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationItem {
  final int notificationId;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationItem({
    required this.notificationId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notificationId'],
      message: json['message'],
      isRead: json['read'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }
}

class NotificationPage extends StatefulWidget {
  final String userId;

  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> _unread = [];
  List<NotificationItem> _read = [];
  bool _isLoading = false;
  int _selectedTabIndex = 0; // 0 for Unread, 1 for Read

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final allUrl = 'http://10.0.2.2:8080/api/notifications/${widget.userId}';
      final respAll = await http.get(Uri.parse(allUrl));
      if (respAll.statusCode == 200) {
        final listAll = jsonDecode(respAll.body) as List<dynamic>;
        List<NotificationItem> allNotifs =
        listAll.map((item) => NotificationItem.fromJson(item)).toList();

        List<NotificationItem> unread = [];
        List<NotificationItem> read = [];
        for (var n in allNotifs) {
          if (!n.isRead) {
            unread.add(n);
          } else {
            read.add(n);
          }
        }

        setState(() {
          _unread = unread;
          _read = read;
        });
      } else {
        debugPrint("Error fetching notifications: ${respAll.body}");
      }
    } catch (e) {
      debugPrint("Exception in _fetchNotifications: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final url =
        'http://10.0.2.2:8080/api/notifications/mark-read/$notificationId';
    try {
      final resp = await http.post(Uri.parse(url));
      if (resp.statusCode == 200) {
        setState(() {
          _unread.removeWhere((n) => n.notificationId == notificationId);
        });
      } else {
        debugPrint("Error marking read: ${resp.body}");
      }
    } catch (e) {
      debugPrint("Exception in _markAsRead: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    final url =
        'http://10.0.2.2:8080/api/notifications/${widget.userId}/mark-all-read';
    try {
      final resp = await http.post(Uri.parse(url));
      if (resp.statusCode == 200) {
        setState(() {
          _read.addAll(_unread);
          _unread.clear();
        });
      } else {
        debugPrint("Error marking all read: ${resp.body}");
      }
    } catch (e) {
      debugPrint("Exception in _markAllAsRead: $e");
    }
  }

  Widget _buildNotificationTile(NotificationItem notif) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Set background color for notifications
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.notifications_active,
          color: Colors.blue.shade800,
          size: 30,
        ),
        title: Text(
          notif.message,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        subtitle: Text(
          "Created at: ${notif.createdAt}",
          style: TextStyle(color: Colors.black54),
        ),
        trailing: notif.isRead
            ? Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
          icon: const Icon(Icons.done, color: Colors.green),
          onPressed: () => _markAsRead(notif.notificationId),
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(
              "No notifications found.",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 70),
        itemCount: notifications.length,
        itemBuilder: (context, index) =>
            _buildNotificationTile(notifications[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Set full page background color
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.blue),
            onPressed: _unread.isEmpty ? null : _markAllAsRead,
            tooltip: "Mark All as Read",
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade100,
            child: Row(
              children: [
                _buildTabButton("Unread", 0),
                _buildTabButton("Read", 1),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTabIndex == 0
                ? _buildNotificationList(_unread)
                : _buildNotificationList(_read),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _selectedTabIndex == index
                ? Colors.blue.shade800
                : Colors.blue.shade200,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: _selectedTabIndex == index ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
