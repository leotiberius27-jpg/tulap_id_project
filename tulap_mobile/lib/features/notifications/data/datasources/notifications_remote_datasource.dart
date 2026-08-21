import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationsRemoteDataSource {
  final DioClient _dioClient;
  NotificationsRemoteDataSource(this._dioClient);

  Future<({List<NotificationModel> items, int unreadCount})> getNotifications() async {
    final response = await _dioClient.dio.get('/notifications?pageSize=50');
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
    final unreadCount = (data['meta'] as Map<String, dynamic>)['unreadCount'] as int;
    return (items: items, unreadCount: unreadCount);
  }

  Future<void> markRead(String id) async {
    await _dioClient.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dioClient.dio.patch('/notifications/read-all');
  }
}
