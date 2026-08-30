import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_task_expenses.dart';
import '../../domain/entities/expense_note_entity.dart';
import 'manual_expense_page.dart';
import 'receipt_detail_page.dart';
import 'receipt_scanner_entry_page.dart';

/// ActivityExpensesPage
/// ----------------------------------------------------------------------
/// Halaman lengkap daftar nota & pengeluaran untuk satu kegiatan (SPPD).
/// Memungkinkan pencarian, filter kategori, peninjauan detail nota,
/// penambahan scan baru, atau input pengeluaran manual.
/// ----------------------------------------------------------------------
class ActivityExpensesPage extends StatefulWidget {
  final TaskEntity task;

  const ActivityExpensesPage({super.key, required this.task});

  @override
  State<ActivityExpensesPage> createState() => _ActivityExpensesPageState();
}

class _ActivityExpensesPageState extends State<ActivityExpensesPage> {
  List<ExpenseNoteEntity> _allExpenses = [];
  List<ExpenseNoteEntity> _filteredExpenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  ExpenseCategoryEntity? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final getExpenses = sl<GetTaskExpenses>();
    final result = await getExpenses(widget.task.id);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (expenses) {
        setState(() {
          _isLoading = false;
          _allExpenses = expenses;
          _applyFilters();
        });
      },
    );
  }

  void _applyFilters() {
    List<ExpenseNoteEntity> list = List.from(_allExpenses);

    if (_selectedCategory != null) {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((e) {
        final vendor = e.vendorName.toLowerCase();
        final notes = (e.notes ?? '').toLowerCase();
        final receiptNo = (e.receiptNumber ?? '').toLowerCase();
        return vendor.contains(query) ||
            notes.contains(query) ||
            receiptNo.contains(query);
      }).toList();
    }

    setState(() => _filteredExpenses = list);
  }

  double get _totalFilteredAmount {
    return _filteredExpenses.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nota & Pengeluaran',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            Text(
              widget.task.taskName,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadExpenses,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Summary Header Card
                    _buildSummaryCard(),

                    // Search & Filter Section
                    _buildFilterSection(),

                    // List of Expense Items
                    Expanded(
                      child: _filteredExpenses.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.base,
                                AppSpacing.sm,
                                AppSpacing.base,
                                90,
                              ),
                              itemCount: _filteredExpenses.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final exp = _filteredExpenses[index];
                                return _buildExpenseCard(exp);
                              },
                            ),
                    ),
                  ],
                ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, 10, AppSpacing.base, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Input Manual'),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManualExpensePage(taskId: widget.task.id),
                    ),
                  );
                  if (result != null) _loadExpenses();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: const Icon(Icons.document_scanner_rounded, size: 18),
                label: const Text(
                  'Scan Nota',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReceiptScannerEntryPage(taskId: widget.task.id),
                    ),
                  );
                  if (result != null) _loadExpenses();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL PENGELUARAN REALISASI',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredExpenses.length} Nota',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _currencyFormat.format(_totalFilteredAmount),
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pagu Anggaran SPPD: ${_currencyFormat.format(widget.task.budgetAmount)}',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari vendor, catatan, no. struk...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _applyFilters();
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Category Filter Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _selectedCategory == null,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = null;
                    _applyFilters();
                  });
                },
              ),
              const SizedBox(width: 6),
              ...ExpenseCategoryEntity.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = isSelected ? null : cat;
                        _applyFilters();
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildExpenseCard(ExpenseNoteEntity exp) {
    final hasImage = exp.localScanPath.isNotEmpty && File(exp.localScanPath).existsSync();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () async {
          final changed = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReceiptDetailPage(
                expense: exp,
                task: widget.task,
              ),
            ),
          );
          if (changed == true) _loadExpenses();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Thumbnail / Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? Image.file(
                        File(exp.localScanPath),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        child: Icon(
                          exp.isManualEntry ? Icons.edit_note_rounded : Icons.receipt_long_rounded,
                          color: const Color(0xFF10B981),
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Title & details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.vendorName,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exp.category.label,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(exp.transactionDate),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Sync status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(exp.totalAmount),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSyncBadge(exp.syncStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncBadge(String status) {
    final isSynced = status.toUpperCase() == 'SYNCED';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
          size: 12,
          color: isSynced ? const Color(0xFF10B981) : Colors.amber.shade700,
        ),
        const SizedBox(width: 3),
        Text(
          isSynced ? 'Tersinkron' : 'Lokal',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSynced ? const Color(0xFF10B981) : Colors.amber.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pengeluaran',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dokumentasikan nota belanja, BBM, penginapan, atau transportasi selama bertugas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
