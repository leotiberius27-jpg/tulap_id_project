import 'package:flutter/foundation.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/mark_notification_read.dart';

enum NotificationsStatus { loading, loaded, error }

class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationEntity> items;
  final int unreadCount;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.items = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });
}

class NotificationsController extends ChangeNotifier {
  final GetNotifications _getNotifications;
  final MarkNotificationRead _markNotificationRead;
  final MarkAllNotificationsRead _markAllNotificationsRead;

  NotificationsState _state = const NotificationsState();
  NotificationsState get state => _state;

  NotificationsController({
    required GetNotifications getNotifications,
    required MarkNotificationRead markNotificationRead,
    required MarkAllNotificationsRead markAllNotificationsRead,
  })  : _getNotifications = getNotifications,
        _markNotificationRead = markNotificationRead,
        _markAllNotificationsRead = markAllNotificationsRead {
    load();
  }

  void _update(NotificationsState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> load() async {
    _update(const NotificationsState(status: NotificationsStatus.loading));

    final result = await _getNotifications();
    result.fold(
      (failure) => _update(
        NotificationsState(status: NotificationsStatus.error, errorMessage: failure.message),
      ),
      (data) => _update(
        NotificationsState(
          status: NotificationsStatus.loaded,
          items: data.items,
          unreadCount: data.unreadCount,
        ),
      ),
    );
  }

  /// Update optimistik lokal (langsung, tanpa menunggu response) supaya
  /// badge/centang terasa instan - sama seperti pola checklist toggle di
  /// TaskDetailController. Jika request gagal, badge tetap terupdate
  /// (kegagalan menandai-baca bukan hal kritis, tidak perlu rollback UI).
  Future<void> markRead(String id) async {
    final matches = _state.items.where((n) => n.id == id);
    if (matches.isEmpty || matches.first.isRead) return;

    _update(
      NotificationsState(
        status: _state.status,
        items: _state.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
        unreadCount: _state.unreadCount > 0 ? _state.unreadCount - 1 : 0,
      ),
    );

    await _markNotificationRead(id);
  }

  Future<void> markAllRead() async {
    if (_state.unreadCount == 0) return;

    _update(
      NotificationsState(
        status: _state.status,
        items: _state.items.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
      ),
    );

    await _markAllNotificationsRead();
  }
}
