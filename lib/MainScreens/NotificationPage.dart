import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationItem {
  final int notificationId;
  final String message;
  final bool isRead;
  final String createdAt;   // or DateTime, parse if you prefer

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

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      // 1) Fetch all notifications
      final allUrl = 'http://10.0.2.2:8080/api/notifications/${widget.userId}';
      final respAll = await http.get(Uri.parse(allUrl));
      if (respAll.statusCode == 200) {
        final listAll = jsonDecode(respAll.body) as List<dynamic>;
        List<NotificationItem> allNotifs = listAll
            .map((item) => NotificationItem.fromJson(item))
            .toList();

        // 2) Split into unread & read
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
    final url = 'http://10.0.2.2:8080/api/notifications/mark-read/$notificationId';
    try {
      final resp = await http.post(Uri.parse(url));
      if (resp.statusCode == 200) {
        // update local state
        setState(() {
          _unread.removeWhere((n) => n.notificationId == notificationId);
          // Optional: put it in the read list
          // you might want to re-fetch or store the message if needed
        });
      } else {
        debugPrint("Error marking read: ${resp.body}");
      }
    } catch (e) {
      debugPrint("Exception in _markAsRead: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    final url = 'http://10.0.2.2:8080/api/notifications/${widget.userId}/mark-all-read';
    try {
      final resp = await http.post(Uri.parse(url));
      if (resp.statusCode == 200) {
        // Clear the unread array
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: _unread.isEmpty ? null : _markAllAsRead,
            child: Text(
              "Mark All Read",
              style: TextStyle(color: _unread.isEmpty ? Colors.grey : Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView(
          children: [
            if (_unread.isNotEmpty)
              ListTile(
                title: const Text("Unread Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ..._unread.map((notif) => ListTile(
              title: Text(notif.message),
              subtitle: Text("Created at: ${notif.createdAt}"),
              trailing: IconButton(
                icon: const Icon(Icons.done, color: Colors.blue),
                onPressed: () => _markAsRead(notif.notificationId),
              ),
            )),
            if (_read.isNotEmpty)
              ListTile(
                title: const Text("Read Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ..._read.map((notif) => ListTile(
              title: Text(notif.message),
              subtitle: Text("Created at: ${notif.createdAt}"),
              trailing: const Icon(Icons.check_circle, color: Colors.grey),
            )),
            if (_unread.isEmpty && _read.isEmpty)
              const ListTile(
                title: Text("No notifications found."),
              ),
          ],
        ),
      ),
    );
  }
}
