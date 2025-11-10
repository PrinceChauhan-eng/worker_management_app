import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/base_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      if (_showUnreadOnly) {
        await notificationProvider.loadUnreadNotifications(
          userProvider.currentUser!.id!,
          userProvider.currentUser!.role,
        );
      } else {
        await notificationProvider.loadNotifications(
          userProvider.currentUser!.id!,
          userProvider.currentUser!.role,
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
        
    await notificationProvider.markAsRead(notification.id!);
  }

  Future<void> _markAllAsRead() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      await notificationProvider.markAllAsRead(
        userProvider.currentUser!.id!,
        userProvider.currentUser!.role,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Notifications',
          onLeadingPressed: () {
            Navigator.pop(context);
          },
          actions: [
            if (notificationProvider.unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
              ),
          ],
        ),
        body: Column(
          children: [
            // Filter options
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Show unread only',
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: _showUnreadOnly,
                    onChanged: (value) {
                      setState(() {
                        _showUnreadOnly = value;
                      });
                      _loadNotifications();
                    },
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.state == ViewState.busy) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = provider.notifications;

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _showUnreadOnly
                                ? 'No unread notifications'
                                : 'No notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final color = notification.isRead ? Colors.grey[300] : Colors.blue[100];
    final iconColor = notification.isRead ? Colors.grey : _getIconColor(notification.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForType(notification.type),
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: notification.isRead ? Colors.grey[700] : Colors.black,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'New',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notification.message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: notification.isRead ? Colors.grey[600] : Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(
                      DateTime.parse(notification.createdAt),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (notification.relatedId != null)
                    Text(
                      'ID: ${notification.relatedId}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'salary':
        return Icons.account_balance_wallet;
      case 'advance':
        return Icons.payments;
      case 'attendance':
        return Icons.check_circle;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color? _getIconColor(String type) {
    switch (type) {
      case 'salary':
        return Colors.green;
      case 'advance':
        return Colors.orange;
      case 'attendance':
        return Colors.blue;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}