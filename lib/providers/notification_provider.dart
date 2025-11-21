import '../models/notification.dart';
import '../services/notifications_service.dart';
import '../services/notification_service.dart';
import '../services/schema_refresher.dart';
import 'base_provider.dart';

class NotificationProvider extends BaseProvider {
  final NotificationsService _notificationsService = NotificationsService();
  final NotificationService _notificationService = NotificationService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Add caching flag (Fix #9)
  bool isLoaded = false;

  // Remove the automatic database access during initialization
  Future<void> loadNotifications(int userId, String userRole) async {
    // Check if already loaded (Fix #9)
    if (isLoaded) return;
    
    setState(ViewState.busy);
    try {
      final notificationsData = await _notificationsService.byUser(userId, userRole);
      _notifications = notificationsData.map((data) => NotificationModel.fromMap(data)).toList();
      _unreadCount = await _notificationsService.unreadCount(userId, userRole);
      
      // Mark as loaded (Fix #9)
      isLoaded = true;
      
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      // Try to fix potential schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      // Retry after attempting to fix schema
      try {
        await Future.delayed(Duration(seconds: 1));
        final notificationsData = await _notificationsService.byUser(userId, userRole);
        _notifications = notificationsData.map((data) => NotificationModel.fromMap(data)).toList();
        _unreadCount = await _notificationsService.unreadCount(userId, userRole);
        
        // Mark as loaded (Fix #9)
        isLoaded = true;
      } catch (retryError) {
        rethrow;
      } finally {
        setState(ViewState.idle);
        notifyListeners();
      }
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
      // Try to fix potential schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      // Retry after attempting to fix schema
      try {
        await Future.delayed(Duration(seconds: 1));
        final notificationsData = await _notificationsService.unreadByUser(userId, userRole);
        _notifications = notificationsData.map((data) => NotificationModel.fromMap(data)).toList();
        _unreadCount = _notifications.length;
      } catch (retryError) {
        rethrow;
      } finally {
        setState(ViewState.idle);
        notifyListeners();
      }
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
      // Try to fix potential schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      // Retry after attempting to fix schema
      try {
        await Future.delayed(Duration(seconds: 1));
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
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
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
      // Try to fix potential schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      // Retry after attempting to fix schema
      try {
        await Future.delayed(Duration(seconds: 1));
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
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
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
      // Try to fix potential schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      // Retry after attempting to fix schema
      try {
        await Future.delayed(Duration(seconds: 1));
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
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
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
      // Try to fix potential schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      // Retry after attempting to fix schema
      try {
        await Future.delayed(Duration(seconds: 1));
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
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
    }
  }

  /// Load notifications only if not already loaded or if forced
  Future<void> loadIfNeeded(int userId, String userRole) async {
    // Only load if notifications list is empty
    if (_notifications.isEmpty) {
      await loadNotifications(userId, userRole);
    }
  }
}