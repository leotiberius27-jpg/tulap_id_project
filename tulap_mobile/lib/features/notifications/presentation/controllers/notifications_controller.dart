import 'package:flutter/foundation.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/delete_read_notifications.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_unread_notification_count.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/mark_notification_read.dart';

enum NotificationsStatus { loading, loaded, error }

class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationEntity> items;
  final int unreadCount;
  final NotificationCategory? selectedCategory;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.items = const [],
    this.unreadCount = 0,
    this.selectedCategory,
    this.errorMessage,
  });

  List<NotificationEntity> get filteredItems {
    if (selectedCategory == null) return items;
    return items.where((item) => item.category == selectedCategory).toList();
  }
}

class NotificationsController extends ChangeNotifier {
  final GetNotifications _getNotifications;
  final MarkNotificationRead _markNotificationRead;
  final MarkAllNotificationsRead _markAllNotificationsRead;
  final DeleteReadNotifications? _deleteReadNotifications;
  final GetUnreadNotificationCount? _getUnreadNotificationCount;

  NotificationsState _state = const NotificationsState();
  NotificationsState get state => _state;
  bool _disposed = false;
  dynamic _subscription;

  NotificationsController({
    required GetNotifications getNotifications,
    required MarkNotificationRead markNotificationRead,
    required MarkAllNotificationsRead markAllNotificationsRead,
    DeleteReadNotifications? deleteReadNotifications,
    GetUnreadNotificationCount? getUnreadNotificationCount,
  })  : _getNotifications = getNotifications,
        _markNotificationRead = markNotificationRead,
        _markAllNotificationsRead = markAllNotificationsRead,
        _deleteReadNotifications = deleteReadNotifications,
        _getUnreadNotificationCount = getUnreadNotificationCount {
    load();
    _subscription = _getUnreadNotificationCount?.stream.listen((count) {
      if (!_disposed && _state.unreadCount != count) {
        _update(
          NotificationsState(
            status: _state.status,
            items: _state.items,
            unreadCount: count,
            selectedCategory: _state.selectedCategory,
            errorMessage: _state.errorMessage,
          ),
        );
      }
    });
  }

  void _update(NotificationsState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    _update(
      NotificationsState(
        status: NotificationsStatus.loading,
        items: _state.items,
        unreadCount: _state.unreadCount,
        selectedCategory: _state.selectedCategory,
      ),
    );

    final result = await _getNotifications(category: _state.selectedCategory);
    result.fold(
      (failure) => _update(
        NotificationsState(
          status: NotificationsStatus.error,
          items: _state.items,
          unreadCount: _state.unreadCount,
          selectedCategory: _state.selectedCategory,
          errorMessage: failure.message,
        ),
      ),
      (data) => _update(
        NotificationsState(
          status: NotificationsStatus.loaded,
          items: data.items,
          unreadCount: data.unreadCount,
          selectedCategory: _state.selectedCategory,
        ),
      ),
    );
  }

  void setCategory(NotificationCategory? category) {
    if (_state.selectedCategory == category) return;
    _state = NotificationsState(
      status: _state.status,
      items: _state.items,
      unreadCount: _state.unreadCount,
      selectedCategory: category,
      errorMessage: _state.errorMessage,
    );
    notifyListeners();
    load();
  }

  Future<void> markRead(String id) async {
    final matches = _state.items.where((n) => n.id == id);
    if (matches.isEmpty || matches.first.isRead) return;

    _update(
      NotificationsState(
        status: _state.status,
        items: _state.items
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
        unreadCount: _state.unreadCount > 0 ? _state.unreadCount - 1 : 0,
        selectedCategory: _state.selectedCategory,
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
        selectedCategory: _state.selectedCategory,
      ),
    );

    await _markAllNotificationsRead();
  }

  Future<void> deleteReadNotifications() async {
    if (_deleteReadNotifications == null) return;
    await _deleteReadNotifications!.call();
    await load();
  }
}
