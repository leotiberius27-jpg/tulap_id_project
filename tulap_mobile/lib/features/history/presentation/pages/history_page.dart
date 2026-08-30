import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../search_archive/domain/entities/search_result_entity.dart';
import '../../../search_archive/domain/entities/search_filter_state.dart';
import '../../../search_archive/presentation/controllers/search_archive_controller.dart';
import '../../../search_archive/presentation/widgets/search_bar_header.dart';
import '../../../search_archive/presentation/widgets/search_filter_chips.dart';
import '../../../search_archive/presentation/widgets/search_filter_bottom_sheet.dart';
import '../../../search_archive/presentation/widgets/search_result_card.dart';
import '../../../search_archive/presentation/widgets/recent_searches_view.dart';
import '../../../search_archive/presentation/widgets/search_empty_state.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../../travel_mission/presentation/controllers/travel_mission_detail_controller.dart';
import '../../../travel_mission/presentation/pages/travel_mission_detail_page.dart';

/// HistoryPage (Unified Field Archive / Arsip & Riwayat Terpadu Phase 10)
/// ----------------------------------------------------------------------
/// Menyatukan seluruh riwayat lintas-domain Tulap.id:
/// - Pencarian Cerdas (Kegiatan, Perjalanan, Foto, Nota OCR, Laporan, Dokumen, LPJ)
/// - Normalisasi nominal rupiah & parsing tanggal otomatis
/// - Filter multi-kriteria (Tahun, Rentang Tanggal, Lokasi, Kategori)
/// - Pencarian Offline-First di SQLite + Sinkronisasi Cloud
/// - Deep-link langsung ke halaman detail otoritatif
/// ----------------------------------------------------------------------
class HistoryPage extends StatefulWidget {
  final SearchFilterState? initialFilter;
  final String? initialQuery;

  const HistoryPage({
    super.key,
    this.initialFilter,
    this.initialQuery,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final TextEditingController _searchController;
  late final SearchArchiveController _searchArchiveController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchArchiveController = sl<SearchArchiveController>();
    if (widget.initialFilter != null) {
      _searchArchiveController.applyFilter(widget.initialFilter!);
    }
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchArchiveController.onQueryChanged(widget.initialQuery!);
    } else {
      _searchArchiveController.initialize();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchArchiveController>.value(
      value: _searchArchiveController,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Arsip & Riwayat'),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync_outlined, color: AppColors.textSecondary, size: 22),
              tooltip: 'Bangun Ulang Indeks',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await _searchArchiveController.triggerRebuildIndex();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Indeks arsip pencarian lokal telah diperbarui.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<SearchArchiveController>(
          builder: (context, controller, _) {
            final filter = controller.filter;
            final isSearching = controller.query.isNotEmpty;

            return RefreshIndicator(
              onRefresh: () => controller.initialize(),
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // 1. Search Bar Header
                  SliverToBoxAdapter(
                    child: SearchBarHeader(
                      controller: _searchController,
                      isLoading: controller.isLoading,
                      activeFilterCount: filter.activeFilterCount,
                      onChanged: (text) => controller.onQueryChanged(text),
                      onClear: () {
                        _searchController.clear();
                        controller.clearQuery();
                      },
                      onFilterTap: () {
                        SearchFilterBottomSheet.show(
                          context: context,
                          currentFilter: controller.filter,
                          availableYears: controller.availableYears,
                          onApply: (newFilter) => controller.applyFilter(newFilter),
                        );
                      },
                    ),
                  ),

                  // 2. Filter Category Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SearchFilterChips(
                        selectedType: filter.selectedType,
                        onSelected: (type) => controller.selectEntityType(type),
                      ),
                    ),
                  ),

                  // 3. Active Filters Ribbon (if any active)
                  if (filter.hasActiveFilters)
                    SliverToBoxAdapter(
                      child: _buildActiveFiltersRibbon(controller),
                    ),

                  // 4. Recent Searches (Only when query is empty)
                  if (!isSearching && controller.recentSearches.isNotEmpty)
                    SliverToBoxAdapter(
                      child: RecentSearchesView(
                        recentSearches: controller.recentSearches,
                        onSearchTapped: (query) {
                          _searchController.text = query;
                          controller.onRecentSearchTapped(query);
                        },
                        onRemoveTapped: (id) => controller.removeRecentSearchItem(id),
                        onClearAllTapped: () => controller.clearAllRecentSearches(),
                      ),
                    ),

                  // 5. Section Title / Result Summary
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isSearching
                                  ? 'Hasil Pencarian (${controller.resultCount})'
                                  : 'Arsip Terbaru (${controller.resultCount})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (controller.results.isNotEmpty)
                            Text(
                              controller.filter.sortOrder.label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 6. Results List or Empty State
                  if (controller.results.isEmpty && !controller.isLoading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: SearchEmptyState(
                        query: controller.query,
                        hasFilters: filter.hasActiveFilters,
                        onResetFilters: () {
                          _searchController.clear();
                          controller.resetFilters();
                        },
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = controller.results[index];
                          return SearchResultCard(
                            item: item,
                            onTap: () => _handleItemTap(context, item),
                          );
                        },
                        childCount: controller.results.length,
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRibbon(SearchArchiveController controller) {
    final filter = controller.filter;
    final tags = <Widget>[];

    if (filter.selectedYear != null) {
      tags.add(_buildFilterTag('${filter.selectedYear}', () => controller.selectYear(null)));
    }
    if (filter.location != null) {
      tags.add(_buildFilterTag(filter.location!, () => controller.applyFilter(filter.copyWith(clearLocation: true))));
    }
    if (filter.expenseCategory != null) {
      tags.add(_buildFilterTag(filter.expenseCategory!, () => controller.applyFilter(filter.copyWith(clearCategory: true))));
    }
    if (filter.status != null) {
      tags.add(_buildFilterTag(filter.status!, () => controller.applyFilter(filter.copyWith(clearStatus: true))));
    }
    if (filter.quickDate != QuickDateFilter.all) {
      tags.add(_buildFilterTag(filter.quickDate.label, () => controller.applyFilter(filter.copyWith(quickDate: QuickDateFilter.all, clearDates: true))));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          ...tags,
          InkWell(
            onTap: () => controller.resetFilters(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Hapus Filter',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  void _handleItemTap(BuildContext context, SearchResultEntity item) {
    final user = sl<AuthSessionManager>().currentUser;

    switch (item.entityType) {
      case SearchEntityType.activity:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<TaskDetailController>(
              create: (_) => TaskDetailController(
                taskId: item.entityId,
                getTaskDetail: sl<GetTaskDetail>(),
                startTask: sl<StartTask>(),
                submitForVerification: sl<SubmitTaskForVerification>(),
                toggleChecklistItem: sl<ToggleChecklistItem>(),
                getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
              ),
              child: TaskDetailPage(
                officerName: user?.fullName ?? 'Pengguna',
                agencyName: user?.instansiName ?? 'Instansi',
              ),
            ),
          ),
        );
        break;

      case SearchEntityType.travel:
      case SearchEntityType.document:
      case SearchEntityType.lpj:
        final travelId = item.entityType == SearchEntityType.travel
            ? item.entityId
            : (item.parentId ?? item.entityId);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TravelMissionDetailPage(travelId: travelId),
          ),
        );
        break;

      case SearchEntityType.receipt:
      case SearchEntityType.expense:
        final taskId = item.parentId ?? item.entityId;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptScannerEntryPage(taskId: taskId),
          ),
        );
        break;

      case SearchEntityType.evidence:
      case SearchEntityType.report:
        final taskId = item.parentId ?? item.entityId;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<TaskDetailController>(
              create: (_) => TaskDetailController(
                taskId: taskId,
                getTaskDetail: sl<GetTaskDetail>(),
                startTask: sl<StartTask>(),
                submitForVerification: sl<SubmitTaskForVerification>(),
                toggleChecklistItem: sl<ToggleChecklistItem>(),
                getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
              ),
              child: TaskDetailPage(
                officerName: user?.fullName ?? 'Pengguna',
                agencyName: user?.instansiName ?? 'Instansi',
              ),
            ),
          ),
        );
        break;
    }
  }
}
