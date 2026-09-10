import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/domain/entities/top_location_stat.dart';

/// LocationDistributionMapPage
/// ----------------------------------------------------------------------
/// Peta sungguhan (Google Maps) untuk kartu "Peta & Sebaran Lokasi" di
/// Beranda - dibuka dari LocationIntelligenceCard. Marker diplot dari
/// koordinat GPS rata-rata tiap klaster lokasi (dihitung backend di
/// DashboardService dari foto geotag kegiatan sungguhan, BUKAN posisi
/// dekoratif seperti kotak preview di kartu Beranda).
///
/// Lokasi tanpa koordinat (mis. task destination berupa teks bebas tanpa
/// satupun foto geotag) TIDAK bisa diplot di peta - tetap ditampilkan di
/// daftar bawah supaya datanya tidak hilang dari pandangan user.
/// ----------------------------------------------------------------------
class LocationDistributionMapPage extends StatefulWidget {
  final List<TopLocationStat> topLocations;

  const LocationDistributionMapPage({super.key, required this.topLocations});

  @override
  State<LocationDistributionMapPage> createState() =>
      _LocationDistributionMapPageState();
}

class _LocationDistributionMapPageState
    extends State<LocationDistributionMapPage> {
  GoogleMapController? _mapController;
  TopLocationStat? _selected;

  List<TopLocationStat> get _plotted => widget.topLocations
      .where((l) => l.latitude != null && l.longitude != null)
      .toList();

  List<TopLocationStat> get _unplotted => widget.topLocations
      .where((l) => l.latitude == null || l.longitude == null)
      .toList();

  Set<Marker> _buildMarkers() {
    return _plotted.map((loc) {
      return Marker(
        markerId: MarkerId(loc.location),
        position: LatLng(loc.latitude!, loc.longitude!),
        infoWindow: InfoWindow(
          title: loc.location,
          snippet: '${loc.count} kegiatan',
        ),
        onTap: () {
          setState(() => _selected = loc);
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(loc.latitude!, loc.longitude!)),
          );
        },
      );
    }).toSet();
  }

  CameraPosition _initialCamera() {
    final plotted = _plotted;
    if (plotted.isEmpty) {
      // Belum ada satupun lokasi dengan koordinat - pusatkan ke tengah
      // Indonesia sebagai fallback netral, bukan (0,0).
      return const CameraPosition(target: LatLng(-2.5, 118.0), zoom: 4.2);
    }
    if (plotted.length == 1) {
      final l = plotted.first;
      return CameraPosition(target: LatLng(l.latitude!, l.longitude!), zoom: 13);
    }
    final avgLat =
        plotted.map((l) => l.latitude!).reduce((a, b) => a + b) / plotted.length;
    final avgLng =
        plotted.map((l) => l.longitude!).reduce((a, b) => a + b) / plotted.length;
    return CameraPosition(target: LatLng(avgLat, avgLng), zoom: 10);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plotted = _plotted;
    final unplotted = _unplotted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Sebaran Lokasi'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: plotted.isEmpty
                ? _buildEmptyCoordinatesState(isDark)
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: _initialCamera(),
                        markers: _buildMarkers(),
                        onMapCreated: (controller) => _mapController = controller,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        onTap: (_) => setState(() => _selected = null),
                      ),
                      if (_selected != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: _SelectedLocationCard(location: _selected!),
                        ),
                    ],
                  ),
          ),
          if (unplotted.isNotEmpty)
            _buildUnplottedList(unplotted, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyCoordinatesState(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 40,
            color: isDark ? Colors.white38 : AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada kegiatan dengan foto geotag pada periode ini,\n'
            'jadi belum ada koordinat GPS untuk diplot di peta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnplottedList(List<TopLocationStat> unplotted, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Lokasi tanpa koordinat GPS (${unplotted.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: unplotted.length,
              itemBuilder: (context, index) {
                final loc = unplotted[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                  ),
                  title: Text(
                    loc.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  trailing: Text(
                    '${loc.count} kegiatan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedLocationCard extends StatelessWidget {
  final TopLocationStat location;

  const _SelectedLocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.location,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${location.count} kegiatan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
