import '../models/notification.dart';
import '../services/notifications_service.dart';
import '../services/notification_service.dart';
import 'base_provider.dart';

class NotificationProvider extends BaseProvider {
  final NotificationsService _notificationsService = NotificationsService();
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Remove the automatic database access during initialization
  Future<void> loadNotifications(int userId, String userRole) async {
    setState(ViewState.busy);
    try {
      final notificationsData = await _notificationsService.byUser(userId, userRole);
      _notifications = notificationsData.map((data) => NotificationModel.fromMap(data)).toList();
      _unreadCount = await _notificationsService.unreadCount(userId, userRole);
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      setState(ViewState.idle);
      rethrow;
    }
  }

  Future<void> loadUnreadNotifications(int userId, String userRole) async {
    setState(ViewState.busy);
    try {
      final notificationsData = await _notificationsService.unreadByUser(userId, userRole);
      _notifications = notificationsData.map((data) => NotificationModel.fromMap(data)).toList();
      _unreadCount = _notifications.length;
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      setState(ViewState.idle);
      rethrow;
    }
  }

  Future<bool> addNotification(NotificationModel notification) async {
    setState(ViewState.busy);
    try {
      final id = await _notificationsService.insert(notification.toMap());
      
      // Show local notification
      await _notificationService.showNotification(
        id: id,
        title: notification.title,
        body: notification.message,
      );
      
      // Reload notifications
      await loadNotifications(notification.userId, notification.userRole);
          
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    setState(ViewState.busy);
    try {
      await _notificationsService.markRead(notificationId);
      
      // Update local list
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          userId: _notifications[index].userId,
          userRole: _notifications[index].userRole,
          isRead: true,
          createdAt: _notifications[index].createdAt,
          relatedId: _notifications[index].relatedId,
        );
      }
      
      // Update unread count
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      
      setState(ViewState.idle);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> markAllAsRead(int userId, String userRole) async {
    setState(ViewState.busy);
    try {
      await _notificationsService.markAllRead(userId, userRole);
      
      // Update local list
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          title: _notifications[i].title,
          message: _notifications[i].message,
          type: _notifications[i].type,
          userId: _notifications[i].userId,
          userRole: _notifications[i].userRole,
          isRead: true,
          createdAt: _notifications[i].createdAt,
          relatedId: _notifications[i].relatedId,
        );
      }
      
      // Reset unread count
      _unreadCount = 0;
      
      setState(ViewState.idle);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    setState(ViewState.busy);
    try {
      await _notificationsService.delete(id);
      
      // Remove from local list
      _notifications.removeWhere((n) => n.id == id);
      
      // Update unread count if necessary
      final notification = _notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => NotificationModel(
          id: 0,
          title: '',
          message: '',
          type: '',
          userId: 0,
          userRole: '',
          isRead: true,
          createdAt: '',
        ),
      );
      
      if (!notification.isRead && _unreadCount > 0) {
        _unreadCount--;
      }
      
      setState(ViewState.idle);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }
}