class TravelDestinationStat {
  final String destination;
  final int count;

  const TravelDestinationStat({
    required this.destination,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelDestinationStat &&
          runtimeType == other.runtimeType &&
          destination == other.destination &&
          count == other.count;

  @override
  int get hashCode => Object.hash(destination, count);
}
