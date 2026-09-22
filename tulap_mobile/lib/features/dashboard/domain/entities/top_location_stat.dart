/// Satu kegiatan ringkas di sebuah klaster lokasi - dipakai untuk kartu
/// "kegiatan terbaru" di Beranda dan linimasa di halaman detail lokasi.
class LocationActivityStat {
  final String taskId;
  final String title;
  final String status;
  final DateTime? date;

  const LocationActivityStat({
    required this.taskId,
    required this.title,
    required this.status,
    this.date,
  });
}

class TopLocationStat {
  final String location;
  final int count;
  final double? latitude;
  final double? longitude;
  final String? thumbnailUrl;
  final LocationActivityStat? latestActivity;
  final List<LocationActivityStat> activities;

  const TopLocationStat({
    required this.location,
    required this.count,
    this.latitude,
    this.longitude,
    this.thumbnailUrl,
    this.latestActivity,
    this.activities = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopLocationStat &&
          runtimeType == other.runtimeType &&
          location == other.location &&
          count == other.count &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(location, count, latitude, longitude);
}
