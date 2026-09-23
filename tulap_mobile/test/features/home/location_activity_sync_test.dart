import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/top_location_stat.dart';
import 'package:tulap_mobile/features/home/domain/location_activity_sync.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';

TaskEntity _task(
  String id, {
  required String destination,
  required DateTime start,
  TaskStatusEntity status = TaskStatusEntity.ongoing,
  String? name,
}) => TaskEntity(
  id: id,
  taskCode: 'TC-$id',
  taskName: name ?? 'Kegiatan $id',
  destination: destination,
  startDate: start,
  endDate: start.add(const Duration(days: 1)),
  budgetAmount: 0,
  status: status,
  assigneeId: 'u1',
  assigneeName: 'Pegawai',
  checklistItems: const [],
  geotagPhotoCount: 0,
  expenseNoteCount: 0,
);

void main() {
  final periodStart = DateTime(2026, 9, 1);
  final periodEnd = DateTime(2026, 9, 30, 23, 59, 59);

  group('locationClusterFor (cermin backend extractCityOrLocation)', () {
    test('mengambil bagian yang memuat kota yang dikenal', () {
      expect(locationClusterFor('Jl. Budi Utomo, Timika Kota, Papua'), 'Timika Kota');
    });
    test('jatuh ke bagian terakhir bila tidak ada kota yang dikenal', () {
      expect(locationClusterFor('Kantor Distrik, Waena'), 'Waena');
    });
    test('alamat kosong -> Wilayah Tugas', () {
      expect(locationClusterFor('  '), 'Wilayah Tugas');
    });
  });

  group('mergeLocationsWithTasks', () {
    const server = [
      TopLocationStat(
        location: 'Timika Kota',
        count: 3,
        latitude: -4.5,
        longitude: 136.9,
        thumbnailUrl: 'https://x/foto.jpg',
        latestActivity: LocationActivityStat(
          taskId: 't1',
          title: 'Judul lama',
          status: 'DRAFT',
        ),
        activities: [
          LocationActivityStat(taskId: 't1', title: 'Judul lama', status: 'DRAFT'),
        ],
      ),
    ];

    test('status & judul kegiatan di peta mengikuti tugas lokal', () {
      final merged = mergeLocationsWithTasks(
        serverLocations: server,
        localTasks: [
          _task(
            't1',
            destination: 'Timika Kota',
            start: DateTime(2026, 9, 10),
            status: TaskStatusEntity.pendingVerification,
            name: 'Judul baru',
          ),
        ],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      final loc = merged.single;
      expect(loc.activities.single.status, 'PENDING_VERIFICATION');
      expect(loc.latestActivity?.title, 'Judul baru');
      // Data milik server tetap dipertahankan.
      expect(loc.count, 3);
      expect(loc.latitude, -4.5);
      expect(loc.thumbnailUrl, 'https://x/foto.jpg');
    });

    test('tugas lokal yang belum ada di server masuk ke klasternya', () {
      final merged = mergeLocationsWithTasks(
        serverLocations: server,
        localTasks: [
          _task('offline-1', destination: 'Jl. A, Timika Kota', start: DateTime(2026, 9, 20)),
          _task('offline-2', destination: 'Kampung, Waena', start: DateTime(2026, 9, 21)),
        ],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      final timika = merged.firstWhere((l) => l.location == 'Timika Kota');
      expect(timika.count, 4);
      expect(timika.latestActivity?.taskId, 'offline-1');
      final waena = merged.firstWhere((l) => l.location == 'Waena');
      expect(waena.count, 1);
      expect(waena.latitude, isNull);
    });

    test('tugas lokal di luar periode tidak ditambahkan', () {
      final merged = mergeLocationsWithTasks(
        serverLocations: const [],
        localTasks: [
          _task('old', destination: 'Waena', start: DateTime(2026, 8, 1)),
        ],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      expect(merged, isEmpty);
    });

    test('tetap terisi dari tugas lokal saat snapshot server kosong (offline)', () {
      final merged = mergeLocationsWithTasks(
        serverLocations: const [],
        localTasks: [
          _task('a', destination: 'Waena', start: DateTime(2026, 9, 2)),
          _task('b', destination: 'Waena', start: DateTime(2026, 9, 5)),
        ],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      expect(merged.single.count, 2);
      expect(merged.single.latestActivity?.taskId, 'b');
    });
  });

  test('locationForTask menemukan klaster lewat taskId lalu nama', () {
    const locations = [
      TopLocationStat(
        location: 'Timika Kota',
        count: 1,
        activities: [LocationActivityStat(taskId: 't1', title: 'x', status: 'ONGOING')],
      ),
      TopLocationStat(location: 'Waena', count: 1),
    ];
    final t1 = _task('t1', destination: 'Tempat lain', start: DateTime(2026, 9, 1));
    final t2 = _task('t2', destination: 'Kampung, Waena', start: DateTime(2026, 9, 1));
    final t3 = _task('t3', destination: 'Nowhere Town', start: DateTime(2026, 9, 1));
    expect(locationForTask(locations, t1)?.location, 'Timika Kota');
    expect(locationForTask(locations, t2)?.location, 'Waena');
    expect(locationForTask(locations, t3), isNull);
  });
}
