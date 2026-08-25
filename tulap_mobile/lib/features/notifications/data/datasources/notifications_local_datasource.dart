import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

abstract class NotificationLocalDataSource {
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    NotificationCategory? category,
    int limit = 50,
    int offset = 0,
  });

  Future<int> getUnreadCount(String userId);

  Future<void> saveNotification(NotificationModel notification);

  Future<void> saveNotifications(List<NotificationModel> notifications);

  Future<void> markAsRead(String id, {DateTime? readAt});

  Future<void> markAllAsRead(String userId, {DateTime? readAt});

  Future<int> deleteReadNotifications(String userId);

  Future<void> deleteNotification(String id);

  Future<NotificationModel?> findExistingByType({
    required String userId,
    required NotificationType type,
    String? relatedEntityId,
  });
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final Future<Database> Function() _dbProvider;

  NotificationLocalDataSourceImpl({Future<Database> Function()? dbProvider})
      : _dbProvider = dbProvider ?? (() => LocalDatabase.instance);

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    NotificationCategory? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbProvider();
    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category.name);
    }

    final rows = await db.query(
      'notifications',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((map) => NotificationModel.fromMap(map)).toList();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final db = await _dbProvider();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE userId = ? AND isRead = 0',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> saveNotification(NotificationModel notification) async {
    final db = await _dbProvider();
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    final db = await _dbProvider();
    final batch = db.batch();
    for (final notif in notifications) {
      batch.insert(
        'notifications',
        notif.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> markAsRead(String id, {DateTime? readAt}) async {
    final db = await _dbProvider();
    final now = readAt ?? DateTime.now();
    await db.update(
      'notifications',
      {
        'isRead': 1,
        'readAt': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markAllAsRead(String userId, {DateTime? readAt}) async {
    final db = await _dbProvider();
    final now = readAt ?? DateTime.now();
    await db.update(
      'notifications',
      {
        'isRead': 1,
        'readAt': now.toIso8601String(),
      },
      where: 'userId = ? AND isRead = 0',
      whereArgs: [userId],
    );
  }

  @override
  Future<int> deleteReadNotifications(String userId) async {
    final db = await _dbProvider();
    return await db.delete(
      'notifications',
      where: 'userId = ? AND isRead = 1',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> deleteNotification(String id) async {
    final db = await _dbProvider();
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<NotificationModel?> findExistingByType({
    required String userId,
    required NotificationType type,
    String? relatedEntityId,
  }) async {
    final db = await _dbProvider();
    String where = 'userId = ? AND type = ?';
    List<dynamic> args = [userId, type.name];

    if (relatedEntityId != null) {
      where += ' AND relatedEntityId = ?';
      args.add(relatedEntityId);
    }

    final rows = await db.query(
      'notifications',
      where: where,
      whereArgs: args,
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return NotificationModel.fromMap(rows.first);
  }
}
