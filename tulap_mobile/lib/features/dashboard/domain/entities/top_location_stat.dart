class TopLocationStat {
  final String location;
  final int count;
  final double? latitude;
  final double? longitude;

  const TopLocationStat({
    required this.location,
    required this.count,
    this.latitude,
    this.longitude,
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
