# Notification System Documentation

## Overview
The Worker Management App now includes a comprehensive notification system that works for both admin and worker roles. Notifications are displayed in real-time and can be viewed in a dedicated notifications screen.

## Features
1. **Local Notifications**: Displayed as system notifications on the device
2. **In-App Notifications**: Visible within the app with unread indicators
3. **Role-Based Notifications**: Different notifications for admins and workers
4. **Notification Types**: Salary, advance, attendance, and system notifications
5. **Read/Unread Status**: Track which notifications have been read
6. **Filtering**: Show all or only unread notifications

## Notification Types

### Salary Notifications
- **Worker**: Notified when their salary is processed
- **Admin**: Notified when a salary is processed for any worker

### Advance Notifications
- **Admin**: Notified when a worker submits an advance request
- **Worker**: Notified when their advance request is approved/rejected

### Attendance Notifications
- **Admin**: Notified about attendance-related events
- **Worker**: Notified about login/logout status

### System Notifications
- **Both**: Notified about system updates, maintenance, etc.

## Implementation Details

### Models
- `NotificationModel`: Represents a notification with properties like title, message, type, user info, read status, etc.

### Services
- `NotificationService`: Handles local notifications using the `flutter_local_notifications` package
- `DatabaseHelper`: Manages notification storage in SQLite database

### Providers
- `NotificationProvider`: Manages notification state and business logic using Provider pattern

### Screens
- `NotificationsScreen`: Displays all notifications with filtering options

## Notification Triggers

### Salary Processing
Triggered when admin processes a worker's salary:
- Worker receives notification with salary details
- Admin receives confirmation of salary processing

### Advance Requests
Triggered when worker submits an advance request:
- Admin receives notification about new advance request

## UI Components

### Notification Badge
- Displays unread notification count in app bar
- Red badge with number of unread notifications
- Updates in real-time

### Notification Screen
- Filter between all and unread notifications
- Mark individual or all notifications as read
- Swipe to delete notifications (future enhancement)

## Database Schema

### notifications Table
```sql
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  message TEXT,
  type TEXT,
  userId INTEGER,
  userRole TEXT,
  isRead INTEGER DEFAULT 0,
  createdAt TEXT,
  relatedId TEXT
)
```

## Usage Examples

### Sending a Notification
```dart
final notification = NotificationModel(
  title: 'Salary Processed',
  message: 'Your salary for January 2023 has been processed.',
  type: 'salary',
  userId: workerId,
  userRole: 'worker',
  isRead: false,
  createdAt: DateTime.now().toIso8601String(),
);

await notificationProvider.addNotification(notification);
```

### Loading Notifications
```dart
// Load all notifications for a user
await notificationProvider.loadNotifications(userId, userRole);

// Load only unread notifications
await notificationProvider.loadUnreadNotifications(userId, userRole);
```

### Marking as Read
```dart
// Mark single notification as read
await notificationProvider.markAsRead(notificationId);

// Mark all notifications as read
await notificationProvider.markAllAsRead(userId, userRole);
```

## Future Enhancements
1. **Push Notifications**: Integrate with Firebase Cloud Messaging for remote notifications
2. **Notification Settings**: Allow users to customize notification preferences
3. **Notification Categories**: Group notifications by type
4. **Snooze Functionality**: Allow users to snooze notifications
5. **Notification History**: Maintain history of all notifications
6. **Rich Notifications**: Include images and actions in notifications

## Testing
The notification system has been tested for:
- Notification creation and storage
- Local notification display
- Read/unread status management
- Filtering functionality
- Performance with large numbers of notifications
- Cross-platform compatibility (Web, Android, iOS)

## Troubleshooting
Common issues and solutions:
1. **Notifications not showing**: Ensure notification permissions are granted
2. **Database errors**: Check database initialization and table creation
3. **Provider issues**: Verify provider setup in main.dart
4. **Import errors**: Ensure all necessary packages are imported

## Dependencies
- `flutter_local_notifications`: For local notification handling
- `provider`: For state management
- `sqflite`: For database storage
- `intl`: For date formatting