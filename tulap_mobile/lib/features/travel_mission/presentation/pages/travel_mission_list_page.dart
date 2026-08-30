import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/travel_mission_entity.dart';
import '../controllers/travel_mission_list_controller.dart';
import 'create_travel_mission_page.dart';
import 'travel_mission_detail_page.dart';

class TravelMissionListPage extends StatelessWidget {
  const TravelMissionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      Provider.of<TravelMissionListController>(context, listen: false);
      return const _TravelMissionListPageContent();
    } catch (_) {
      return ChangeNotifierProvider<TravelMissionListController>(
        create: (_) => sl<TravelMissionListController>()..loadMissions(),
        child: const _TravelMissionListPageContent(),
      );
    }
  }
}

class _TravelMissionListPageContent extends StatefulWidget {
  const _TravelMissionListPageContent();

  @override
  State<_TravelMissionListPageContent> createState() => _TravelMissionListPageContentState();
}

class _TravelMissionListPageContentState extends State<_TravelMissionListPageContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelMissionListController>().loadMissions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TravelMissionListController>();
    final state = controller.state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'Perjalanan Dinas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => controller.loadMissions(),
          ),
        ],
      ),
      floatingActionButton: state.missions.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: AppColors.onPrimary),
              label: const Text(
                'Perjalanan Baru',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTravelMissionPage(),
                  ),
                );
                if (created == true && mounted) {
                  controller.loadMissions();
                }
              },
            )
          : null,
      body: Column(
        children: [
          // Filter & Search Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari destinasi, surat tugas, kode misi...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              controller.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => controller.setSearchQuery(val),
                ),
                const SizedBox(height: 8),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Semua',
                        isSelected: state.selectedStatus == null,
                        onTap: () => controller.setStatusFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Berjalan',
                        isSelected: state.selectedStatus == 'ongoing',
                        onTap: () => controller.setStatusFilter('ongoing'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Selesai',
                        isSelected: state.selectedStatus == 'completed',
                        onTap: () => controller.setStatusFilter('completed'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'LPJ Siap',
                        isSelected: state.selectedStatus == 'lpjReady',
                        onTap: () => controller.setStatusFilter('lpjReady'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.missions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => controller.loadMissions(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.missions.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final mission = state.missions[index];
                            return _buildMissionCard(mission);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(TravelMissionEntity mission) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TravelMissionDetailPage(travelId: mission.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mission.displayId,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(mission.status),
              ],
            ),
            const SizedBox(height: 10),

            // Title & Destination
            Text(
              mission.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${mission.origin} → ${mission.destination}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date & Duration & Transport
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${mission.formattedPeriod} (${mission.durationDays} Hari)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.directions_car_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  mission.transportMode.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.border),

            // Bottom Row: Budget & Person
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimasi Anggaran',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                    Text(
                      currencyFormat.format(mission.budgetEstimate.total),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.infoSoft,
                        child: Text(
                          mission.personnelSnapshot.fullName.isNotEmpty
                              ? mission.personnelSnapshot.fullName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          mission.personnelSnapshot.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TravelMissionStatus status) {
    Color bg = AppColors.background;
    Color fg = AppColors.textSecondary;

    switch (status) {
      case TravelMissionStatus.ongoing:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        break;
      case TravelMissionStatus.completed:
        bg = AppColors.successSoft;
        fg = AppColors.success;
        break;
      case TravelMissionStatus.lpjReady:
        bg = AppColors.infoSoft;
        fg = AppColors.primary;
        break;
      case TravelMissionStatus.draft:
      default:
        bg = AppColors.background;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => context.read<TravelMissionListController>().loadMissions(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.flight_takeoff, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Perjalanan Dinas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat rencana perjalanan dinas baru untuk mengelola surat tugas, kegiatan lapangan, nota, dan paket LPJ terpadu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: AppColors.onPrimary),
              label: const Text(
                'Buat Perjalanan Dinas Baru',
                style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTravelMissionPage(),
                  ),
                );
                if (created == true && mounted) {
                  context.read<TravelMissionListController>().loadMissions();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
