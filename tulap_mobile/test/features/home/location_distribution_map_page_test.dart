import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/dashboard/domain/entities/top_location_stat.dart';
import 'package:tulap_mobile/features/home/presentation/pages/location_distribution_map_page.dart';

void main() {
  testWidgets('renders empty-coordinates fallback when no location has lat/lng', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LocationDistributionMapPage(
          topLocations: [
            TopLocationStat(location: 'Waena', count: 3),
            TopLocationStat(location: 'Timika Kota', count: 2),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peta Sebaran Lokasi'), findsOneWidget);
    expect(
      find.textContaining('belum ada koordinat GPS'),
      findsOneWidget,
    );
    // Semua lokasi tanpa koordinat tetap tampil di daftar bawah.
    expect(find.text('Waena'), findsOneWidget);
    expect(find.text('Timika Kota'), findsOneWidget);
  });

  testWidgets('lists locations without coordinates alongside a plotted one', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LocationDistributionMapPage(
          topLocations: [
            TopLocationStat(
              location: 'Waena',
              count: 5,
              latitude: -2.5807,
              longitude: 140.6699,
            ),
            TopLocationStat(location: 'Tanpa Koordinat', count: 1),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lokasi tanpa koordinat GPS (1)'), findsOneWidget);
    expect(find.text('Tanpa Koordinat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
