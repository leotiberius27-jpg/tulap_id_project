import '../../dashboard/domain/entities/top_location_stat.dart';
import '../../task_detail/domain/entities/task_entity.dart';

/// Sinkronisasi "Peta & Sebaran Lokasi" <-> "Kegiatan Saya"
/// ----------------------------------------------------------------------
/// Peta sebaran berasal dari snapshot dashboard server (per periode),
/// sedangkan Kegiatan Saya berasal dari daftar tugas lokal (termasuk
/// kegiatan mandiri yang belum tersinkron). Tanpa penggabungan, keduanya
/// bisa tidak cocok: kegiatan baru/offline tidak muncul di peta, dan status
/// kegiatan di peta tertinggal dari status sebenarnya di perangkat.
///
/// Fungsi di sini menggabungkan keduanya: status & judul kegiatan di peta
/// selalu diambil dari tugas lokal (sumber paling mutakhir), dan tugas lokal
/// dalam periode aktif yang belum ada di snapshot server ditambahkan ke
/// klaster lokasinya. Koordinat & foto sampul tetap dari server.
/// ----------------------------------------------------------------------

/// Nama klaster lokasi dari alamat/tujuan - cermin 1:1 dari
/// `DashboardService.extractCityOrLocation` di backend, supaya tugas lokal
/// masuk ke klaster yang sama persis dengan yang dihitung server.
String locationClusterFor(String address) {
  if (address.trim().isEmpty) return 'Wilayah Tugas';
  final parts = address.split(',').map((p) => p.trim()).toList();
  const knownCities = [
    'mimika',
    'timika',
    'jayapura',
    'nabire',
    'merauke',
    'jakarta',
    'surabaya',
  ];
  for (final part in parts) {
    final lower = part.toLowerCase();
    if (knownCities.any(lower.contains)) return part;
  }
  final last = parts.last;
  if (last.isNotEmpty) return last;
  return parts.first.isNotEmpty ? parts.first : 'Wilayah Tugas';
}

/// TaskStatusEntity -> string enum backend (dipakai LocationStatusChip).
String taskStatusApiString(TaskStatusEntity status) {
  switch (status) {
    case TaskStatusEntity.draft:
      return 'DRAFT';
    case TaskStatusEntity.ongoing:
      return 'ONGOING';
    case TaskStatusEntity.pendingVerification:
      return 'PENDING_VERIFICATION';
    case TaskStatusEntity.revisionNeeded:
      return 'REVISION_NEEDED';
    case TaskStatusEntity.verified:
      return 'VERIFIED';
    case TaskStatusEntity.rejected:
      return 'REJECTED';
    case TaskStatusEntity.completed:
      return 'COMPLETED';
  }
}

LocationActivityStat _activityFromTask(TaskEntity t) => LocationActivityStat(
  taskId: t.id,
  title: t.taskName,
  status: taskStatusApiString(t.status),
  date: t.startDate,
);

/// Gabungkan klaster lokasi server dengan tugas lokal.
///
/// [periodStart]/[periodEnd] membatasi tugas lokal yang BARU ditambahkan
/// (sama seperti filter `startDate` di backend). Tugas yang sudah ada di
/// snapshot server tetap diperbarui statusnya meski di luar rentang.
List<TopLocationStat> mergeLocationsWithTasks({
  required List<TopLocationStat> serverLocations,
  required List<TaskEntity> localTasks,
  DateTime? periodStart,
  DateTime? periodEnd,
  int maxLocations = 8,
}) {
  final tasksById = {for (final t in localTasks) t.id: t};
  final knownTaskIds = <String>{
    for (final loc in serverLocations)
      for (final a in loc.activities) a.taskId,
  };

  // Klaster -> (stat server, daftar kegiatan yang sudah disegarkan)
  final order = <String>[];
  final base = <String, TopLocationStat>{};
  final activities = <String, List<LocationActivityStat>>{};
  final addedCount = <String, int>{};

  for (final loc in serverLocations) {
    order.add(loc.location);
    base[loc.location] = loc;
    activities[loc.location] = [
      for (final a in loc.activities)
        tasksById[a.taskId] != null ? _activityFromTask(tasksById[a.taskId]!) : a,
    ];
  }

  bool inPeriod(DateTime d) =>
      (periodStart == null || !d.isBefore(periodStart)) &&
      (periodEnd == null || !d.isAfter(periodEnd));

  for (final t in localTasks) {
    if (knownTaskIds.contains(t.id) || !inPeriod(t.startDate)) continue;
    final key = locationClusterFor(t.destination);
    if (!base.containsKey(key)) {
      order.add(key);
      base[key] = TopLocationStat(location: key, count: 0);
      activities[key] = [];
    }
    activities[key]!.add(_activityFromTask(t));
    addedCount[key] = (addedCount[key] ?? 0) + 1;
  }

  final merged = order.map((key) {
    final server = base[key]!;
    final list = activities[key]!
      ..sort((a, b) {
        final da = a.date, db = b.date;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    return TopLocationStat(
      location: server.location,
      count: server.count + (addedCount[key] ?? 0),
      latitude: server.latitude,
      longitude: server.longitude,
      thumbnailUrl: server.thumbnailUrl,
      latestActivity: list.isNotEmpty ? list.first : null,
      activities: list,
    );
  }).toList()..sort((a, b) => b.count.compareTo(a.count));

  return merged.take(maxLocations).toList();
}

/// Klaster lokasi tempat sebuah tugas berada (dicari lewat taskId dulu,
/// lalu lewat nama klaster dari tujuan tugas).
TopLocationStat? locationForTask(
  List<TopLocationStat> locations,
  TaskEntity task,
) {
  for (final loc in locations) {
    if (loc.activities.any((a) => a.taskId == task.id)) return loc;
  }
  final key = locationClusterFor(task.destination);
  for (final loc in locations) {
    if (loc.location == key) return loc;
  }
  return null;
}
