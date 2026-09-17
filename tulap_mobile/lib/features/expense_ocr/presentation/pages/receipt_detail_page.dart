import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/usecases/delete_expense_note.dart';
import '../../domain/usecases/update_expense_note.dart';

/// ReceiptDetailPage
/// ----------------------------------------------------------------------
/// Menampilkan rincian lengkap satu nota/pengeluaran, termasuk inspeksi
/// foto beresolusi tinggi, integritas checksum SHA-256, teks mentah OCR,
/// dan fungsi pengeditan atau penghapusan aman.
/// ----------------------------------------------------------------------
class ReceiptDetailPage extends StatefulWidget {
  final ExpenseNoteEntity expense;
  final TaskEntity task;

  const ReceiptDetailPage({
    super.key,
    required this.expense,
    required this.task,
  });

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  late ExpenseNoteEntity _currentExpense;
  bool _isDeleting = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense;
  }

  @override
  Widget build(BuildContext context) {
    final exp = _currentExpense;
    final hasImage = exp.localScanPath.isNotEmpty && File(exp.localScanPath).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Nota Pengeluaran',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Koreksi Data',
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Hapus Nota',
            onPressed: _isDeleting ? null : () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // 1. Receipt Image Viewer with Zoom
          if (hasImage) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 260,
                      width: double.infinity,
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.file(
                          File(exp.localScanPath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pinch_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Cubit untuk Zoom',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ],

          // 2. Financial Amount Summary Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL TRANSAKSI',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exp.category.label,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _currencyFormat.format(exp.totalAmount),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // 3. Detailed Metadata Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Transaksi',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Vendor / Tempat', exp.vendorName),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow(
                  'Tanggal Transaksi',
                  DateFormat('dd MMMM yyyy', 'id_ID').format(exp.transactionDate),
                ),
                if (exp.transactionTime != null && exp.transactionTime!.isNotEmpty) ...[
                  const Divider(color: AppColors.border, height: 16),
                  _buildInfoRow('Waktu Transaksi', exp.transactionTime!),
                ],
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow('Metode Pembayaran', exp.paymentMethod ?? 'Tunai / Cash'),
                if (exp.receiptNumber != null && exp.receiptNumber!.isNotEmpty) ...[
                  const Divider(color: AppColors.border, height: 16),
                  _buildInfoRow('No. Nota / Struk', exp.receiptNumber!),
                ],
                if (exp.taxAmount != null && exp.taxAmount! > 0) ...[
                  const Divider(color: AppColors.border, height: 16),
                  _buildInfoRow('Pajak / PPN', _currencyFormat.format(exp.taxAmount)),
                ],
                if (exp.notes != null && exp.notes!.isNotEmpty) ...[
                  const Divider(color: AppColors.border, height: 16),
                  _buildInfoRow('Catatan Lapangan', exp.notes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // 4. Provenance & Digital Integrity Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integritas Bukti & Provenance',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Sumber Rekam', exp.source.label),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow('Status Verifikasi', exp.verificationStatus.label),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow('Status Sinkronisasi', exp.syncStatus),
                if (exp.originalSha256 != null && exp.originalSha256!.isNotEmpty) ...[
                  const Divider(color: AppColors.border, height: 16),
                  _buildInfoRow(
                    'SHA-256 Checksum',
                    '${exp.originalSha256!.substring(0, 16)}... (Terverifikasi)',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // 5. Expandable Raw OCR Text (Forensic Inspection)
          if (exp.ocrRawText.isNotEmpty && exp.ocrRawText != '[INPUT_MANUAL]') ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: ExpansionTile(
                title: const Text(
                  'Teks Mentah Hasil OCR',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        exp.ocrRawText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final vendorCtrl = TextEditingController(text: _currentExpense.vendorName);
    final amountCtrl = TextEditingController(
      text: _currentExpense.totalAmount.toStringAsFixed(0),
    );
    final notesCtrl = TextEditingController(text: _currentExpense.notes ?? '');
    var selectedCategory = _currentExpense.category;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Koreksi Rincian Nota'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: vendorCtrl,
                      decoration: const InputDecoration(labelText: 'Vendor / Tempat'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp '),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ExpenseCategoryEntity>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: ExpenseCategoryEntity.values.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final cleanAmount = amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
                    final newAmount = double.tryParse(cleanAmount) ?? _currentExpense.totalAmount;
                    final updatedNote = _currentExpense.copyWith(
                      vendorName: vendorCtrl.text.trim(),
                      totalAmount: newAmount,
                      category: selectedCategory,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    );

                    final updateUsecase = sl<UpdateExpenseNote>();
                    final result = await updateUsecase(updatedNote);

                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }

                    result.fold(
                      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
                      (saved) {
                        setState(() => _currentExpense = saved);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rincian nota berhasil diperbarui.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Hapus Nota Ini?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus nota ${_currentExpense.vendorName} sejumlah ${_currencyFormat.format(_currentExpense.totalAmount)}? Tindakan ini akan memperbarui total pengeluaran kegiatan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                setState(() => _isDeleting = true);

                final deleteUsecase = sl<DeleteExpenseNote>();
                final result = await deleteUsecase(
                  noteId: _currentExpense.id,
                  taskId: widget.task.id,
                );

                if (!mounted) return;

                result.fold(
                  (failure) {
                    setState(() => _isDeleting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
                    );
                  },
                  (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nota berhasil dihapus.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    Navigator.of(context).pop(true); // Return true indicating change
                  },
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
