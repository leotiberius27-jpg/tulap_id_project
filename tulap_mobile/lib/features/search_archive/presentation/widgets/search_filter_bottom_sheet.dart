import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/search_filter_state.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilterState initialFilter;
  final List<int> availableYears;
  final ValueChanged<SearchFilterState> onApply;

  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.availableYears,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required SearchFilterState currentFilter,
    required List<int> availableYears,
    required ValueChanged<SearchFilterState> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchFilterBottomSheet(
        initialFilter: currentFilter,
        availableYears: availableYears,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilterState _state;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _state = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Arsip & Riwayat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _state = const SearchFilterState();
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Filter Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Tahun Arsip
                _buildSectionTitle('Tahun Arsip'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Semua Tahun',
                      selected: _state.selectedYear == null,
                      onSelected: () => setState(() => _state = _state.copyWith(clearYear: true)),
                    ),
                    ...widget.availableYears.map((year) {
                      return _buildChoiceChip(
                        label: '$year',
                        selected: _state.selectedYear == year,
                        onSelected: () => setState(() => _state = _state.copyWith(selectedYear: year)),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Rentang Periode
                _buildSectionTitle('Periode Waktu'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Semua',
                      selected: _state.quickDate == QuickDateFilter.all && _state.startDate == null,
                      onSelected: () => setState(() {
                        _state = _state.copyWith(
                          quickDate: QuickDateFilter.all,
                          clearDates: true,
                        );
                      }),
                    ),
                    _buildChoiceChip(
                      label: 'Hari Ini',
                      selected: _state.quickDate == QuickDateFilter.today,
                      onSelected: () {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, now.day);
                        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                        setState(() {
                          _state = _state.copyWith(
                            quickDate: QuickDateFilter.today,
                            startDate: start,
                            endDate: end,
                          );
                        });
                      },
                    ),
                    _buildChoiceChip(
                      label: '7 Hari Terakhir',
                      selected: _state.quickDate == QuickDateFilter.last7Days,
                      onSelected: () {
                        final now = DateTime.now();
                        final start = now.subtract(const Duration(days: 7));
                        setState(() {
                          _state = _state.copyWith(
                            quickDate: QuickDateFilter.last7Days,
                            startDate: start,
                            endDate: now,
                          );
                        });
                      },
                    ),
                    _buildChoiceChip(
                      label: '30 Hari Terakhir',
                      selected: _state.quickDate == QuickDateFilter.last30Days,
                      onSelected: () {
                        final now = DateTime.now();
                        final start = now.subtract(const Duration(days: 30));
                        setState(() {
                          _state = _state.copyWith(
                            quickDate: QuickDateFilter.last30Days,
                            startDate: start,
                            endDate: now,
                          );
                        });
                      },
                    ),
                    _buildChoiceChip(
                      label: 'Bulan Ini',
                      selected: _state.quickDate == QuickDateFilter.thisMonth,
                      onSelected: () {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, 1);
                        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                        setState(() {
                          _state = _state.copyWith(
                            quickDate: QuickDateFilter.thisMonth,
                            startDate: start,
                            endDate: end,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickCustomDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _state.startDate != null && _state.endDate != null
                        ? '${_dateFormat.format(_state.startDate!)} – ${_dateFormat.format(_state.endDate!)}'
                        : 'Pilih Rentang Tanggal Khusus',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Urutan Tampilan
                _buildSectionTitle('Urutan Hasil Pencarian'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Paling Relevan',
                      selected: _state.sortOrder == SearchSortOrder.relevance,
                      onSelected: () => setState(() => _state = _state.copyWith(sortOrder: SearchSortOrder.relevance)),
                    ),
                    _buildChoiceChip(
                      label: 'Terbaru',
                      selected: _state.sortOrder == SearchSortOrder.newest,
                      onSelected: () => setState(() => _state = _state.copyWith(sortOrder: SearchSortOrder.newest)),
                    ),
                    _buildChoiceChip(
                      label: 'Terlama',
                      selected: _state.sortOrder == SearchSortOrder.oldest,
                      onSelected: () => setState(() => _state = _state.copyWith(sortOrder: SearchSortOrder.oldest)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Kategori Pengeluaran (Hanya relevan jika nota/pengeluaran)
                _buildSectionTitle('Kategori Pengeluaran'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Semua Kategori',
                      selected: _state.expenseCategory == null,
                      onSelected: () => setState(() => _state = _state.copyWith(clearCategory: true)),
                    ),
                    ...['BBM', 'PENGINAPAN', 'KONSUMSI', 'TRANSPORTASI_LAIN', 'RETAIL', 'LAINNYA'].map((cat) {
                      return _buildChoiceChip(
                        label: cat,
                        selected: _state.expenseCategory == cat,
                        onSelected: () => setState(() => _state = _state.copyWith(expenseCategory: cat)),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_state);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Terapkan Filter (${_state.activeFilterCount})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _state.startDate != null && _state.endDate != null
          ? DateTimeRange(start: _state.startDate!, end: _state.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _state = _state.copyWith(
          quickDate: QuickDateFilter.custom,
          startDate: picked.start,
          endDate: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
      });
    }
  }
}
