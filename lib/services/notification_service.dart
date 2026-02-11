import 'package:flutter/material.dart';

/// 通知类型
enum NotificationType { pipelineChange, orderCreated, orderShipped, productionComplete, taskAssigned, system }

/// 单条通知
class CrmNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final String? relatedId; // dealId, orderId, etc.

  CrmNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.system,
    DateTime? createdAt,
    this.isRead = false,
    this.relatedId,
  }) : createdAt = createdAt ?? DateTime.now();

  IconData get icon {
    switch (type) {
      case NotificationType.pipelineChange: return Icons.view_kanban;
      case NotificationType.orderCreated: return Icons.add_shopping_cart;
      case NotificationType.orderShipped: return Icons.local_shipping;
      case NotificationType.productionComplete: return Icons.precision_manufacturing;
      case NotificationType.taskAssigned: return Icons.task;
      case NotificationType.system: return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.pipelineChange: return const Color(0xFF6C5CE7);
      case NotificationType.orderCreated: return const Color(0xFF00B894);
      case NotificationType.orderShipped: return const Color(0xFF74B9FF);
      case NotificationType.productionComplete: return const Color(0xFF00CEC9);
      case NotificationType.taskAssigned: return const Color(0xFFFDAA5B);
      case NotificationType.system: return const Color(0xFFDFE6E9);
    }
  }
}

/// 通知管理服务 (in-memory, app-level)
class NotificationService extends ChangeNotifier {
  final List<CrmNotification> _notifications = [];

  List<CrmNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<CrmNotification> get unread => _notifications.where((n) => !n.isRead).toList();

  void add(CrmNotification notification) {
    _notifications.insert(0, notification);
    // keep max 100
    if (_notifications.length > 100) _notifications.removeLast();
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) { _notifications[idx].isRead = true; notifyListeners(); }
  }

  void markAllRead() {
    for (final n in _notifications) { n.isRead = true; }
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}
