import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:tulap_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:tulap_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:tulap_mobile/features/notifications/domain/services/notification_coordinator.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/create_or_update_notification.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/delete_read_notifications.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/get_unread_notification_count.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/mark_all_notifications_read.dart';
import 'package:tulap_mobile/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:tulap_mobile/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:tulap_mobile/features/notifications/presentation/pages/notifications_page.dart';

class _FakeNotificationRepository implements NotificationsRepository {
  List<NotificationEntity> items = [];
  final _unreadController = StreamController<int>.broadcast();

  _FakeNotificationRepository({List<NotificationEntity>? initialItems}) {
    items = initialItems != null ? List.from(initialItems) : [];
  }

  @override
  Stream<int> get unreadCountStream => _unreadController.stream;

  @override
  Future<Either<Failure, NotificationListResult>> getNotifications({
    NotificationCategory? category,
  }) async {
    final filtered = category == null
        ? items
        : items.where((i) => i.category == category).toList();
    final unread = items.where((i) => !i.isRead).length;
    _unreadController.add(unread);
    return Right(
      NotificationListResult(
        items: filtered,
        unreadCount: unread,
      ),
    );
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    final unread = items.where((i) => !i.isRead).length;
    _unreadController.add(unread);
    return Right(unread);
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    items = items.map((i) => i.id == id ? i.copyWith(isRead: true) : i).toList();
    final unread = items.where((i) => !i.isRead).length;
    _unreadController.add(unread);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    items = items.map((i) => i.copyWith(isRead: true)).toList();
    _unreadController.add(0);
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> deleteReadNotifications() async {
    final initialCount = items.length;
    items.removeWhere((i) => i.isRead);
    final deleted = initialCount - items.length;
    final unread = items.where((i) => !i.isRead).length;
    _unreadController.add(unread);
    return Right(deleted);
  }

  @override
  Future<Either<Failure, void>> createOrUpdateNotification(
    NotificationEntity notification,
  ) async {
    final index = items.indexWhere((i) => i.id == notification.id || (i.type == notification.type && i.relatedEntityId == notification.relatedEntityId));
    if (index >= 0) {
      items[index] = notification;
    } else {
      items.insert(0, notification);
    }
    final unread = items.where((i) => !i.isRead).length;
    _unreadController.add(unread);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    items.removeWhere((i) => i.id == id);
    final unread = items.where((i) => !i.isRead).length;
    _unreadController.add(unread);
    return const Right(null);
  }
}

void main() {
  group('Home Bell & Unread Badge Tests (Section 65)', () {
    testWidgets('0 unread: no badge displayed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              fullName: 'Leo Tiberius',
              agencyName: 'BPKAD Mimika',
              unreadNotificationCount: 0,
              onNotificationTap: () {},
            ),
          ),
        ),
      );

      // Icon lonceng ada, badge angka tidak ada
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('1-9 unread: displays exact number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              fullName: 'Leo Tiberius',
              agencyName: 'BPKAD Mimika',
              unreadNotificationCount: 3,
              onNotificationTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('10+ unread: displays compact 9+ badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              fullName: 'Leo Tiberius',
              agencyName: 'BPKAD Mimika',
              unreadNotificationCount: 15,
              onNotificationTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('9+'), findsOneWidget);
    });
  });

  group('NotificationCenterPage & Filtering Tests (Section 58, 66, 67)', () {
    late _FakeNotificationRepository repo;
    late GetNotifications getNotifications;
    late MarkNotificationRead markNotificationRead;
    late MarkAllNotificationsRead markAllNotificationsRead;
    late DeleteReadNotifications deleteReadNotifications;
    late GetUnreadNotificationCount getUnreadNotificationCount;

    setUp(() {
      final sl = GetIt.instance;
      sl.reset();

      final now = DateTime.now();
      repo = _FakeNotificationRepository(
        initialItems: [
          NotificationEntity(
            id: 'n1',
            userId: 'user1',
            category: NotificationCategory.kegiatan,
            type: NotificationType.activityRunning,
            title: 'Kegiatan sedang berjalan',
            message: 'Koordinasi Data BMD masih aktif. 2 dari 4 checklist selesai.',
            priority: NotificationPriority.info,
            actionType: NotificationActionType.openTask,
            relatedEntityId: 'task-1',
            isRead: false,
            createdAt: now,
          ),
          NotificationEntity(
            id: 'n2',
            userId: 'user1',
            category: NotificationCategory.sinkronisasi,
            type: NotificationType.syncPending,
            title: 'Data belum tersinkronisasi',
            message: '3 dokumentasi menunggu dikirim ke cloud.',
            priority: NotificationPriority.warning,
            actionType: NotificationActionType.openSync,
            isRead: false,
            createdAt: now.subtract(const Duration(minutes: 30)),
          ),
          NotificationEntity(
            id: 'n3',
            userId: 'user1',
            category: NotificationCategory.kegiatan,
            type: NotificationType.receiptProcessed,
            title: 'Nota berhasil diproses',
            message: 'Nota Rp250.000 telah ditambahkan ke Survey Aset.',
            priority: NotificationPriority.success,
            actionType: NotificationActionType.openTask,
            relatedEntityId: 'task-2',
            isRead: true,
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          NotificationEntity(
            id: 'n4',
            userId: 'user1',
            category: NotificationCategory.sistem,
            type: NotificationType.locationPermissionRequired,
            title: 'Izin lokasi diperlukan',
            message: 'Tulap.id membutuhkan izin lokasi untuk geotag.',
            priority: NotificationPriority.warning,
            actionType: NotificationActionType.openLocation,
            isRead: false,
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
      );

      getNotifications = GetNotifications(repo);
      markNotificationRead = MarkNotificationRead(repo);
      markAllNotificationsRead = MarkAllNotificationsRead(repo);
      deleteReadNotifications = DeleteReadNotifications(repo);
      getUnreadNotificationCount = GetUnreadNotificationCount(repo);

      sl.registerSingleton<GetNotifications>(getNotifications);
      sl.registerSingleton<MarkNotificationRead>(markNotificationRead);
      sl.registerSingleton<MarkAllNotificationsRead>(markAllNotificationsRead);
      sl.registerSingleton<DeleteReadNotifications>(deleteReadNotifications);
      sl.registerSingleton<GetUnreadNotificationCount>(getUnreadNotificationCount);
    });

    testWidgets('Renders all categories, date groups (Hari Ini, Kemarin, Lebih Lama)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsPage(
            officerName: 'Leo Tiberius',
            agencyName: 'BPKAD Mimika',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Kegiatan'), findsOneWidget);
      expect(find.text('Sinkronisasi'), findsOneWidget);
      expect(find.text('Sistem'), findsOneWidget);

      expect(find.text('HARI INI'), findsOneWidget);
      expect(find.text('KEMARIN'), findsOneWidget);
      expect(find.text('LEBIH LAMA'), findsOneWidget);

      expect(find.text('Kegiatan sedang berjalan'), findsOneWidget);
      expect(find.text('Data belum tersinkronisasi'), findsOneWidget);
      expect(find.text('Nota berhasil diproses'), findsOneWidget);
      expect(find.text('Izin lokasi diperlukan'), findsOneWidget);
    });

    testWidgets('Filter chip category switches items properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsPage(
            officerName: 'Leo Tiberius',
            agencyName: 'BPKAD Mimika',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Sinkronisasi'
      await tester.tap(find.text('Sinkronisasi'));
      await tester.pumpAndSettle();

      expect(find.text('Data belum tersinkronisasi'), findsOneWidget);
      expect(find.text('Kegiatan sedang berjalan'), findsNothing);

      // Tap 'Semua'
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();

      expect(find.text('Kegiatan sedang berjalan'), findsOneWidget);
      expect(find.text('Data belum tersinkronisasi'), findsOneWidget);
    });

    testWidgets('Tap unread notification marks it read immediately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsPage(
            officerName: 'Leo Tiberius',
            agencyName: 'BPKAD Mimika',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // n1 is unread
      expect(repo.items.firstWhere((i) => i.id == 'n1').isRead, isFalse);

      await tester.tap(find.text('Kegiatan sedang berjalan'));
      await tester.pumpAndSettle();

      expect(repo.items.firstWhere((i) => i.id == 'n1').isRead, isTrue);
    });

    testWidgets('Mark all as read from overflow menu marks all items read', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsPage(
            officerName: 'Leo Tiberius',
            agencyName: 'BPKAD Mimika',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tandai semua sudah dibaca'));
      await tester.pumpAndSettle();

      expect(repo.items.every((i) => i.isRead), isTrue);
    });

    testWidgets('Delete read notifications removes read items and preserves unread', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsPage(
            officerName: 'Leo Tiberius',
            agencyName: 'BPKAD Mimika',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus yang sudah dibaca'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Hapus Notifikasi Dibaca'), findsOneWidget);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(repo.items.any((i) => i.id == 'n3'), isFalse); // n3 was read
      expect(repo.items.any((i) => i.id == 'n1'), isTrue); // n1 was unread
    });
  });

  group('NotificationCoordinator & De-duplication Tests (Section 29, 30, 73)', () {
    late _FakeNotificationRepository repo;
    late CreateOrUpdateNotification createOrUpdate;
    late NotificationCoordinator coordinator;

    setUp(() {
      repo = _FakeNotificationRepository();
      createOrUpdate = CreateOrUpdateNotification(repo);
      coordinator = NotificationCoordinator(
        createOrUpdateNotification: createOrUpdate,
        notificationsRepository: repo,
      );
    });

    test('Sync queue grows: 1 -> 2 -> 3 updates single sync notification without duplication', () async {
      // 1 item pending
      await coordinator.evaluateSyncQueue(pendingCount: 1, failedCount: 0, syncedCount: 0);
      expect(repo.items.length, 1);
      expect(repo.items.first.message, contains('1 dokumentasi'));

      // 2 items pending
      await coordinator.evaluateSyncQueue(pendingCount: 2, failedCount: 0, syncedCount: 0);
      expect(repo.items.length, 1);
      expect(repo.items.first.message, contains('2 dokumentasi'));

      // 3 items pending
      await coordinator.evaluateSyncQueue(pendingCount: 3, failedCount: 0, syncedCount: 0);
      expect(repo.items.length, 1);
      expect(repo.items.first.message, contains('3 dokumentasi'));
    });

    test('Sync completed resolves pending notification and sets all synced', () async {
      await coordinator.evaluateSyncQueue(pendingCount: 3, failedCount: 0, syncedCount: 0);
      expect(repo.items.first.type, NotificationType.syncPending);

      // Now sync succeeds
      await coordinator.evaluateSyncQueue(pendingCount: 0, failedCount: 0, syncedCount: 3);
      expect(repo.items.any((i) => i.type == NotificationType.syncPending), isFalse);
      expect(repo.items.any((i) => i.type == NotificationType.syncCompleted), isTrue);
    });

    test('Receipt processed adds formatted expense notification', () async {
      await coordinator.notifyReceiptProcessed(
        taskName: 'Koordinasi Data BMD',
        taskId: 'task-100',
        totalAmount: 250000,
        vendorName: 'SPBU Pertamina',
      );

      expect(repo.items.length, 1);
      expect(repo.items.first.title, 'Nota berhasil diproses');
      expect(repo.items.first.message, contains('Rp250.000'));
      expect(repo.items.first.message, contains('SPBU Pertamina'));
    });
  });

  group('Multi-Viewport & Responsive Tests (Section 50, 74)', () {
    final viewports = <Size>[
      const Size(320, 568),
      const Size(360, 640),
      const Size(360, 800),
      const Size(375, 812),
      const Size(390, 844),
      const Size(412, 915),
      const Size(430, 932),
    ];

    setUp(() {
      final sl = GetIt.instance;
      sl.reset();
      final repo = _FakeNotificationRepository(
        initialItems: [
          NotificationEntity(
            id: 'n1',
            userId: 'user1',
            category: NotificationCategory.kegiatan,
            type: NotificationType.activityRunning,
            title: 'Kegiatan sedang berjalan',
            message: 'Koordinasi Data BMD masih aktif. 2 dari 4 checklist selesai.',
            createdAt: DateTime.now(),
          ),
        ],
      );
      sl.registerSingleton<GetNotifications>(GetNotifications(repo));
      sl.registerSingleton<MarkNotificationRead>(MarkNotificationRead(repo));
      sl.registerSingleton<MarkAllNotificationsRead>(MarkAllNotificationsRead(repo));
      sl.registerSingleton<DeleteReadNotifications>(DeleteReadNotifications(repo));
      sl.registerSingleton<GetUnreadNotificationCount>(GetUnreadNotificationCount(repo));
    });

    for (final size in viewports) {
      testWidgets('NotificationCenterPage renders cleanly on viewport ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: NotificationsPage(
              officerName: 'Leo Tiberius',
              agencyName: 'BPKAD Mimika',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Notifikasi'), findsOneWidget);
        expect(find.text('Semua'), findsOneWidget);
      });
    }

    testWidgets('NotificationSettingsPage renders cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationSettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
      expect(find.text('Notifikasi Kegiatan'), findsOneWidget);
      expect(find.text('Status Sinkronisasi'), findsOneWidget);
    });
  });
}
