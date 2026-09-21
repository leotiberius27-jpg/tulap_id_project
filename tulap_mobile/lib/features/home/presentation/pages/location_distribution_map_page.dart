import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/map/map_launcher_service.dart';
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
/// Redesain mengikuti pola aplikasi navigasi (search bar mengambang,
/// tombol aksi bulat di atas peta, pin berbentuk lencana bulat dengan
/// jumlah kegiatan, kartu detail bawah dengan chip jarak & tombol Rute)
/// - bukan sekadar daftar pin default Google Maps.
///
/// Setiap titik punya "halo" cincin (Circle overlay, radius dalam meter)
/// yang berdenyut terus-menerus - menandakan lokasi ini AKTIF, bukan pin
/// statis diam - besarnya cincin proporsional ke jumlah kegiatan di
/// lokasi itu.
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
    extends State<LocationDistributionMapPage> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  TopLocationStat? _selected;
  Position? _myPosition;
  MapType _mapType = MapType.normal;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _pulseController;
  Timer? _pulseTimer;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  final Map<String, BitmapDescriptor> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _circles = _buildPulseCircles();
    _rebuildMarkers();
    _loadMyPosition();

    // GoogleMap adalah native view - setiap perubahan `circles`/`markers`
    // dikirim lewat platform channel. Sebelumnya animasi denyut dibangun
    // dengan AnimatedBuilder yang rebuild SELURUH Stack (termasuk
    // GoogleMap) di SETIAP frame (~60x/detik) selama halaman ini terbuka,
    // membanjiri platform channel dan membuat peta macet-macet di
    // perangkat fisik. Di-throttle ke ~8x/detik lewat Timer - animasi
    // denyut tetap terlihat mengalir tanpa membanjiri channel tersebut.
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() => _circles = _buildPulseCircles());
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getLastKnownPosition();
      if (position != null && mounted) {
        setState(() => _myPosition = position);
      }
    } catch (_) {
      // Diam-diam gagal - jarak & tombol "Lokasi Saya" cukup tidak
      // tampil, tidak menghalangi peta utama untuk tetap dipakai.
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.deniedForever ||
          granted == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin akses lokasi tidak diizinkan.')),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted) return;
      setState(() => _myPosition = position);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendeteksi lokasi Anda saat ini.')),
        );
      }
    }
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  void _selectLocation(TopLocationStat? loc) {
    setState(() => _selected = loc);
    _rebuildMarkers();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
    _rebuildMarkers();
  }

  List<TopLocationStat> get _allPlotted => widget.topLocations
      .where((l) => l.latitude != null && l.longitude != null)
      .toList();

  List<TopLocationStat> get _allUnplotted => widget.topLocations
      .where((l) => l.latitude == null || l.longitude == null)
      .toList();

  bool _matchesSearch(TopLocationStat loc) =>
      _searchQuery.isEmpty || loc.location.toLowerCase().contains(_searchQuery);

  List<TopLocationStat> get _plotted =>
      _allPlotted.where(_matchesSearch).toList();

  List<TopLocationStat> get _unplotted =>
      _allUnplotted.where(_matchesSearch).toList();

  /// Jarak dari posisi user saat ini ke lokasi, dalam KM (null jika
  /// posisi user belum diketahui) - ditampilkan sebagai chip di kartu
  /// detail, meniru pola aplikasi navigasi pada umumnya.
  double? _distanceKmTo(TopLocationStat loc) {
    final me = _myPosition;
    if (me == null || loc.latitude == null || loc.longitude == null) return null;
    final meters = Geolocator.distanceBetween(
      me.latitude,
      me.longitude,
      loc.latitude!,
      loc.longitude!,
    );
    return meters / 1000;
  }

  CameraPosition _initialCamera() {
    final plotted = _allPlotted;
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitToPlotted();
  }

  void _fitToPlotted() {
    final plotted = _plotted;
    if (plotted.length <= 1) return;

    var minLat = plotted.first.latitude!;
    var maxLat = plotted.first.latitude!;
    var minLng = plotted.first.longitude!;
    var maxLng = plotted.first.longitude!;
    for (final l in plotted) {
      minLat = l.latitude! < minLat ? l.latitude! : minLat;
      maxLat = l.latitude! > maxLat ? l.latitude! : maxLat;
      minLng = l.longitude! < minLng ? l.longitude! : minLng;
      maxLng = l.longitude! > maxLng ? l.longitude! : maxLng;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    // Ditunda 1 frame - animateCamera langsung di onMapCreated kadang
    // diabaikan native view sebelum ukurannya sendiri final.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
    });
  }

  Future<void> _rebuildMarkers() async {
    final plotted = _plotted;
    final maxCount = plotted.isEmpty
        ? 1
        : plotted.map((l) => l.count).reduce((a, b) => a > b ? a : b);

    final markers = <Marker>{};
    for (final loc in plotted) {
      final isSelected = _selected?.location == loc.location;
      final icon = await _badgeIcon(
        count: loc.count,
        isSelected: isSelected,
        isHighIntensity: loc.count >= (maxCount * 0.66),
      );
      markers.add(
        Marker(
          markerId: MarkerId(loc.location),
          position: LatLng(loc.latitude!, loc.longitude!),
          icon: icon,
          anchor: const Offset(0.5, 0.82),
          infoWindow: InfoWindow(title: loc.location, snippet: '${loc.count} kegiatan'),
          onTap: () {
            _selectLocation(loc);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(loc.latitude!, loc.longitude!)),
            );
          },
        ),
      );
    }

    if (!mounted) return;
    setState(() => _markers = markers);
  }

  /// _badgeIcon
  /// ----------------------------------------------------------------------
  /// Menggambar pin lencana bulat (angka jumlah kegiatan di dalamnya)
  /// lewat Canvas - menggantikan pin merah bawaan Google Maps yang
  /// generik, mendekati gaya pin lingkaran pada referensi desain aplikasi
  /// navigasi. Di-cache per (jumlah, status pilih, intensitas) supaya
  /// tidak menggambar ulang bitmap yang sama berkali-kali.
  Future<BitmapDescriptor> _badgeIcon({
    required int count,
    required bool isSelected,
    required bool isHighIntensity,
  }) async {
    final cacheKey = '$count-$isSelected-$isHighIntensity';
    final cached = _iconCache[cacheKey];
    if (cached != null) return cached;

    const double logicalSize = 46;
    const double scale = 3.0; // render 3x untuk ketajaman di layar densitas tinggi
    const double canvasSize = logicalSize * scale;
    const double tailHeight = 14 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasSize, canvasSize + tailHeight),
    );

    final Color bgColor = isSelected
        ? AppColors.success
        : (isHighIntensity ? AppColors.primary : AppColors.primary.withValues(alpha: 0.6));
    final center = Offset(canvasSize / 2, canvasSize / 2);
    final radius = canvasSize / 2 - (4 * scale);

    // Bayangan lembut
    canvas.drawCircle(
      center.translate(0, 3 * scale),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Ekor pin
    final tailPath = Path()
      ..moveTo(center.dx - 9 * scale, center.dy + radius - 3 * scale)
      ..lineTo(center.dx + 9 * scale, center.dy + radius - 3 * scale)
      ..lineTo(center.dx, center.dy + radius + tailHeight)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = bgColor);

    // Lingkaran utama + cincin putih
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    canvas.drawCircle(
      center,
      radius - (2 * scale),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..color = Colors.white,
    );

    // Angka jumlah kegiatan
    final textPainter = TextPainter(
      text: TextSpan(
        text: count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: (count > 9 ? 15 : 17) * scale,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.toInt(),
      (canvasSize + tailHeight).toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(
      bytes,
      width: logicalSize,
      height: logicalSize + 14,
    );
    _iconCache[cacheKey] = descriptor;
    return descriptor;
  }

  Set<Circle> _buildPulseCircles() {
    final plotted = _plotted;
    if (plotted.isEmpty) return {};
    final maxCount = plotted.map((l) => l.count).reduce((a, b) => a > b ? a : b);
    final pulse = _pulseController.value; // 0..1 berulang

    return plotted.map((loc) {
      final sizeFactor = 0.7 + (loc.count / maxCount) * 0.6;
      final baseRadius = 260.0 * sizeFactor;
      final radius = baseRadius * (1 + pulse * 0.7);
      final opacity = (1 - pulse) * 0.28;
      return Circle(
        circleId: CircleId('pulse-${loc.location}'),
        center: LatLng(loc.latitude!, loc.longitude!),
        radius: radius,
        fillColor: AppColors.primary.withValues(alpha: opacity),
        strokeWidth: 0,
        consumeTapEvents: false,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final plotted = _plotted;
    final unplotted = _unplotted;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Peta Sebaran Lokasi'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _allPlotted.isEmpty
                ? _buildEmptyCoordinatesState()
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: _initialCamera(),
                        mapType: _mapType,
                        onMapCreated: _onMapCreated,
                        markers: _markers,
                        circles: _circles,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        padding: const EdgeInsets.only(top: 110, bottom: 16),
                        onTap: (_) => _selectLocation(null),
                      ),

                      // Search bar mengambang di atas peta
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        child: _FloatingSearchBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          resultCount: plotted.length + unplotted.length,
                        ),
                      ),

                      // Tombol aksi bulat mengambang di kanan peta
                      Positioned(
                        right: 16,
                        bottom: _selected == null ? 24 : 190,
                        child: Column(
                          children: [
                            _MapFab(
                              icon: Icons.my_location_rounded,
                              tooltip: 'Lokasi Saya',
                              onTap: _goToMyLocation,
                            ),
                            const SizedBox(height: 10),
                            _MapFab(
                              icon: _mapType == MapType.normal
                                  ? Icons.layers_outlined
                                  : Icons.map_outlined,
                              tooltip: 'Ganti Jenis Peta',
                              onTap: _toggleMapType,
                            ),
                            const SizedBox(height: 10),
                            _MapFab(
                              icon: Icons.center_focus_strong_rounded,
                              tooltip: 'Lihat Semua Lokasi',
                              onTap: _fitToPlotted,
                            ),
                          ],
                        ),
                      ),

                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(opacity: animation, child: child),
                          ),
                          child: _selected == null
                              ? const SizedBox.shrink(key: ValueKey('empty'))
                              : _SelectedLocationCard(
                                  key: ValueKey(_selected!.location),
                                  location: _selected!,
                                  distanceKm: _distanceKmTo(_selected!),
                                  onClose: () => _selectLocation(null),
                                  onRoute: () {
                                    sl<MapLauncherService>().openGoogleMaps(
                                      latitude: _selected!.latitude!,
                                      longitude: _selected!.longitude!,
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (unplotted.isNotEmpty) _buildUnplottedList(unplotted),
        ],
      ),
    );
  }

  Widget _buildEmptyCoordinatesState() {
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada kegiatan dengan foto geotag pada periode ini,\n'
            'jadi belum ada koordinat GPS untuk diplot di peta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnplottedList(List<TopLocationStat> unplotted) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
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
                  leading: const Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  title: Text(
                    loc.location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
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

/// _FloatingSearchBar
/// ----------------------------------------------------------------------
/// Search bar mengambang di atas peta - meniru pola aplikasi navigasi
/// (search box putih dengan bayangan lembut, ikon kaca pembesar). Filter
/// bekerja sungguhan (bukan dekoratif): menyaring marker peta & daftar
/// lokasi tanpa koordinat sekaligus.
class _FloatingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int resultCount;

  const _FloatingSearchBar({
    required this.controller,
    required this.onChanged,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cari nama lokasi kegiatan...',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// _MapFab
/// ----------------------------------------------------------------------
/// Tombol aksi bulat mengambang di atas peta - dipakai untuk "Lokasi
/// Saya", ganti jenis peta, dan reset tampilan ke semua lokasi.
class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFab({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        color: AppColors.surface,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _SelectedLocationCard extends StatelessWidget {
  final TopLocationStat location;
  final double? distanceKm;
  final VoidCallback onClose;
  final VoidCallback onRoute;

  const _SelectedLocationCard({
    super.key,
    required this.location,
    required this.distanceKm,
    required this.onClose,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(20),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                            icon: Icons.assignment_turned_in_outlined,
                            label: '${location.count} kegiatan',
                          ),
                          if (distanceKm != null)
                            _InfoChip(
                              icon: Icons.social_distance_rounded,
                              label: '${distanceKm!.toStringAsFixed(1)} km dari Anda',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRoute,
                icon: const Icon(Icons.directions_rounded, size: 20),
                label: const Text(
                  'Rute ke Lokasi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
