import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/map/map_launcher_service.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../dashboard/domain/entities/top_location_stat.dart';
import '../theme/map_palette.dart';
import '../widgets/map_ui_kit.dart';

/// LocationActivityDetailPage
/// ----------------------------------------------------------------------
/// "Tab" detail satu klaster lokasi - dibuka dari kartu carousel Beranda
/// (LocationIntelligenceCard) atau dari hasil pencarian/marker di
/// LocationDistributionMapPage. Mengikuti pola aplikasi navigasi:
/// peta + search bar mengambang di atas, lembar bawah (bottom sheet)
/// berisi foto sampul, judul lokasi, chip status/jumlah kegiatan, tombol
/// Rute - yang jika digeser/discroll ke atas memperlihatkan linimasa
/// seluruh kegiatan yang pernah tercatat di lokasi ini.
/// ----------------------------------------------------------------------
class LocationActivityDetailPage extends StatefulWidget {
  final TopLocationStat location;
  final List<TopLocationStat> allLocations;
  final void Function(BuildContext context, String taskId)? onOpenTask;

  const LocationActivityDetailPage({
    super.key,
    required this.location,
    required this.allLocations,
    this.onOpenTask,
  });

  @override
  State<LocationActivityDetailPage> createState() =>
      _LocationActivityDetailPageState();
}

class _LocationActivityDetailPageState
    extends State<LocationActivityDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  List<TopLocationStat> get _searchResults {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    return widget.allLocations
        .where((l) =>
            l.location != widget.location.location &&
            l.location.toLowerCase().contains(q))
        .toList();
  }

  void _openLocation(TopLocationStat loc) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LocationActivityDetailPage(
          location: loc,
          allLocations: widget.allLocations,
          onOpenTask: widget.onOpenTask,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final hasCoords = loc.latitude != null && loc.longitude != null;
    final latestStatus = loc.latestActivity?.status;

    return Scaffold(
      backgroundColor: MapPalette.deep,
      body: Stack(
        children: [
          if (hasCoords)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(loc.latitude!, loc.longitude!),
                zoom: 14.5,
              ),
              onMapCreated: (c) => _mapController = c,
              markers: {
                Marker(
                  markerId: MarkerId(loc.location),
                  position: LatLng(loc.latitude!, loc.longitude!),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              padding: const EdgeInsets.only(bottom: 340),
            )
          else
            const Center(
              child: Icon(Icons.map_outlined, size: 48, color: Colors.white38),
            ),

          // Lembar bawah - bisa digeser/discroll untuk melihat linimasa.
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.42,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Material(
                elevation: 16,
                shadowColor: Colors.black45,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                color: Colors.white,
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: _LocationCoverPhoto(url: loc.thumbnailUrl),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.location,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: MapPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (latestStatus != null)
                                LocationStatusChip(status: latestStatus),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: MapPalette.soft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${loc.count} kegiatan tercatat',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: MapPalette.deep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (hasCoords)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => sl<MapLauncherService>()
                                    .openGoogleMaps(
                                  latitude: loc.latitude!,
                                  longitude: loc.longitude!,
                                ),
                                icon: const Icon(Icons.directions_rounded, size: 20),
                                label: const Text(
                                  'Rute ke Lokasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MapPalette.accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 22),
                          const Text(
                            'Riwayat Aktivitas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: MapPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kegiatan yang tercatat di ${loc.location}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: MapPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (loc.activities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: Text(
                          'Belum ada rincian kegiatan tersimpan untuk lokasi ini.',
                          style: TextStyle(fontSize: 13, color: MapPalette.textSecondary),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ActivityTimeline(
                          activities: loc.activities,
                          onTapActivity: (taskId) =>
                              widget.onOpenTask?.call(context, taskId),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),

          // Baris atas: kembali + search bar (mencari lokasi kegiatan lain
          // yang pernah tercatat) - SENGAJA jadi child TERAKHIR Stack
          // (bukan sebelum DraggableScrollableSheet) supaya tetap berada
          // di lapisan paling atas dan search bar + dropdown hasil tidak
          // pernah tertutup saat lembar bawah digeser naik penuh.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    MapCircleButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Kembali',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MapFloatingSearchBar(
                        controller: _searchController,
                        hintText: 'Cari lokasi kegiatan lain...',
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 46),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.place_outlined,
                            color: MapPalette.deep,
                            size: 20,
                          ),
                          title: Text(
                            result.location,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: MapPalette.textPrimary,
                            ),
                          ),
                          trailing: Text(
                            '${result.count} kegiatan',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: MapPalette.accentDark,
                            ),
                          ),
                          onTap: () => _openLocation(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCoverPhoto extends StatelessWidget {
  final String? url;

  const _LocationCoverPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MapPalette.deep, MapPalette.deepSoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.photo_camera_outlined, color: Colors.white54, size: 36),
        ),
      );
    }
    return Image.network(
      url!,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 150,
        color: MapPalette.soft,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: MapPalette.deep, size: 32),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 150,
          color: MapPalette.soft,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: MapPalette.accent),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  final List<LocationActivityStat> activities;
  final ValueChanged<String> onTapActivity;

  const _ActivityTimeline({required this.activities, required this.onTapActivity});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < activities.length; i++)
          _TimelineRow(
            activity: activities[i],
            isLast: i == activities.length - 1,
            onTap: activities[i].taskId.isEmpty
                ? null
                : () => onTapActivity(activities[i].taskId),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final LocationActivityStat activity;
  final bool isLast;
  final VoidCallback? onTap;

  const _TimelineRow({required this.activity, required this.isLast, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = LocationStatusChip.colorFor(activity.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: MapPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        LocationStatusChip(status: activity.status),
                        const SizedBox(width: 8),
                        if (activity.date != null)
                          Text(
                            AppDateFormatter.formatCompact(activity.date!),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: MapPalette.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: MapPalette.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
