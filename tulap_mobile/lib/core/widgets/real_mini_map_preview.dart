import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../geo/static_map_fetcher.dart';

/// RealMiniMapPreview
/// ----------------------------------------------------------------------
/// Widget mini-map NYATA yang dipakai bersama oleh live viewfinder
/// (CameraStampPreview) dan kartu review foto/video (GeotagPhotoLocationCard)
/// - mengambil thumbnail Google/OSM static map sungguhan lewat
/// StaticMapFetcher (dicache & di-throttle jarak ~40m di dalam fetcher itu
/// sendiri), jatuh ke placeholder bergaya "Google Maps" (pin merah di atas
/// gradient gelap) selagi memuat atau saat offline/gagal.
///
/// Murni kosmetik UI - kegagalan/lambatnya jaringan TIDAK PERNAH
/// menghentikan atau menunda alur kamera, hanya mempertahankan placeholder.
/// ----------------------------------------------------------------------
class RealMiniMapPreview extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final double size;
  final BorderRadius borderRadius;

  const RealMiniMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  State<RealMiniMapPreview> createState() => _RealMiniMapPreviewState();
}

class _RealMiniMapPreviewState extends State<RealMiniMapPreview> {
  Uint8List? _bytes;
  double? _fetchedLat;
  double? _fetchedLng;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _maybeFetch();
  }

  @override
  void didUpdateWidget(covariant RealMiniMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeFetch();
  }

  @override
  void dispose() {
    // Batalkan request yang masih berjalan - mencegah Timer internal
    // `.timeout()` di StaticMapFetcher tetap "pending" setelah widget ini
    // hilang dari tree (fatal di widget test: "A Timer is still pending
    // even after the widget tree was disposed").
    _cancelToken?.cancel();
    super.dispose();
  }

  void _maybeFetch() {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return;
    if (_fetchedLat != null && _fetchedLng != null) {
      final dLat = (lat - _fetchedLat!).abs();
      final dLng = (lng - _fetchedLng!).abs();
      if (dLat < 0.0004 && dLng < 0.0004) return;
    }
    _fetchedLat = lat;
    _fetchedLng = lng;
    _cancelToken?.cancel();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    StaticMapFetcher.instance
        .fetch(
      latitude: lat,
      longitude: lng,
      width: 160,
      height: 160,
      cancelToken: cancelToken,
    )
        .then((bytes) {
      if (mounted && bytes != null) {
        setState(() => _bytes = bytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    if (_bytes != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Image.memory(
          _bytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(color: Colors.white24, width: 0.8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3B4C), Color(0xFF1B2631)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.location_on,
          color: Color(0xFFEA4335),
          size: 22,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}
