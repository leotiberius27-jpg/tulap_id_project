import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../dashboard/domain/entities/top_location_stat.dart';
import '../pages/location_activity_detail_page.dart';
import '../pages/location_distribution_map_page.dart';
import '../theme/map_palette.dart';
import 'map_ui_kit.dart';

/// LocationIntelligenceCard
/// ----------------------------------------------------------------------
/// Kartu "Peta & Sebaran Lokasi" di Beranda - menyajikan tiap klaster
/// lokasi sebagai "jendela" yang bisa digeser kiri/kanan (PageView),
/// meniru pola kartu pelacakan pada referensi desain aplikasi navigasi:
/// sampul foto/peta mini, status kegiatan terbaru, ringkasan singkat.
/// Ketuk sebuah jendela untuk masuk ke tab detail lokasi penuh.
/// ----------------------------------------------------------------------
class LocationIntelligenceCard extends StatefulWidget {
  final List<TopLocationStat> topLocations;
  final void Function(BuildContext context, String taskId)? onOpenTask;

  const LocationIntelligenceCard({
    super.key,
    required this.topLocations,
    this.onOpenTask,
  });

  @override
  State<LocationIntelligenceCard> createState() => _LocationIntelligenceCardState();
}

class _LocationIntelligenceCardState extends State<LocationIntelligenceCard> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.87);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = widget.topLocations;
    if (locations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MapPalette.softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.place_rounded, size: 17, color: MapPalette.deep),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Peta & Sebaran Lokasi',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openFullMap(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${locations.length} Wilayah',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MapPalette.accentDark,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: MapPalette.accentDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 176,
              child: PageView.builder(
                controller: _pageController,
                itemCount: locations.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _LocationWindowCard(
                      location: loc,
                      onTap: () => _openDetail(context, loc),
                    ),
                  );
                },
              ),
            ),
            if (locations.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(locations.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? MapPalette.accent : MapPalette.softBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, TopLocationStat loc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationActivityDetailPage(
          location: loc,
          allLocations: widget.topLocations,
          onOpenTask: widget.onOpenTask,
        ),
      ),
    );
  }

  void _openFullMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationDistributionMapPage(
          topLocations: widget.topLocations,
          onOpenTask: widget.onOpenTask,
        ),
      ),
    );
  }
}

/// _LocationWindowCard
/// ----------------------------------------------------------------------
/// Satu "jendela" kegiatan/lokasi dalam carousel - sampul foto/gradien
/// teal di atas (dengan chip status & jumlah kegiatan mengambang), judul
/// lokasi & kegiatan terbaru di bawah.
class _LocationWindowCard extends StatelessWidget {
  final TopLocationStat location;
  final VoidCallback onTap;

  const _LocationWindowCard({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = location.latestActivity;
    final thumbnail = location.thumbnailUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnail != null && thumbnail.isNotEmpty)
                    Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackCover(),
                    )
                  else
                    _fallbackCover(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: latest != null
                        ? LocationStatusChip(status: latest.status)
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${location.count} kegiatan',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: MapPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latest != null
                              ? latest.title
                              : 'Belum ada kegiatan tercatat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: MapPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: MapPalette.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          latest?.date != null
                              ? AppDateFormatter.formatCompact(latest!.date!)
                              : '-',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: MapPalette.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: MapPalette.accentDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MapPalette.deep, MapPalette.deepSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.location_on_rounded, color: Colors.white38, size: 30),
      ),
    );
  }
}
