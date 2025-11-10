import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/notification.dart';
import '../services/database_helper.dart';
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings for all platforms
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        // Handle notification tap
        Logger.info('Notification tapped: ${notificationResponse.payload}');
      },
    );
  }

  // Show a simple notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'worker_management_channel',
      'Worker Management Notifications',
      channelDescription: 'Notifications for worker management app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'worker_management_channel',
      'Worker Management Notifications',
      channelDescription: 'Notifications for worker management app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Save notification to database
  Future<int> saveNotification(NotificationModel notification) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.insertNotification(notification);
  }

  // Get notifications for a user
  Future<List<NotificationModel>> getNotificationsForUser(
    int userId,
    String userRole,
  ) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getNotificationsByUser(userId, userRole);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.markNotificationAsRead(notificationId);
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(
    int userId,
    String userRole,
  ) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.markAllNotificationsAsRead(userId, userRole);
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(
    int userId,
    String userRole,
  ) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getUnreadNotificationCount(userId, userRole);
  }
}