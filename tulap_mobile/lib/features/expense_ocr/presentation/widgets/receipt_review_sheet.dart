import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/repositories/expense_ocr_repository.dart';

/// ReceiptReviewSheet
/// ----------------------------------------------------------------------
/// Bottom sheet review dan verifikasi hasil OCR sebelum disimpan permanen.
/// Memastikan user memvalidasi data dan dapat mengoreksi vendor, tanggal,
/// nominal, kategori, metode pembayaran, atau catatan.
/// ----------------------------------------------------------------------
class ReceiptReviewSheet extends StatefulWidget {
  final ScannedReceiptDraft draft;
  final bool isSaving;
  final String? duplicateWarning;
  final void Function({
    required String vendorName,
    required DateTime transactionDate,
    String? transactionTime,
    required double totalAmount,
    required ExpenseCategoryEntity category,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? serviceCharge,
    String? receiptNumber,
    String? paymentMethod,
    String? notes,
  }) onSave;

  const ReceiptReviewSheet({
    super.key,
    required this.draft,
    required this.isSaving,
    this.duplicateWarning,
    required this.onSave,
  });

  @override
  State<ReceiptReviewSheet> createState() => _ReceiptReviewSheetState();
}

class _ReceiptReviewSheetState extends State<ReceiptReviewSheet> {
  late TextEditingController _vendorController;
  late TextEditingController _amountController;
  late TextEditingController _taxController;
  late TextEditingController _receiptNumberController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late ExpenseCategoryEntity _selectedCategory;
  late String _selectedPaymentMethod;
  bool _isEditing = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _vendorController = TextEditingController(text: d.vendorName ?? '');
    _amountController = TextEditingController(
      text: d.totalAmount != null ? d.totalAmount!.toStringAsFixed(0) : '',
    );
    _taxController = TextEditingController(
      text: d.taxAmount != null ? d.taxAmount!.toStringAsFixed(0) : '',
    );
    _receiptNumberController = TextEditingController(
      text: d.receiptNumber ?? '',
    );
    _notesController = TextEditingController();
    _selectedDate = d.transactionDate ?? DateTime.now();
    _selectedCategory = d.category;
    _selectedPaymentMethod = d.paymentMethod ?? 'Tunai / Cash';
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _receiptNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overallConfidenceLow = widget.draft.ocrConfidence < 0.7;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.bottomSheetTop),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Periksa Rincian Nota',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _ConfidenceBadge(needsReview: overallConfidenceLow),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (widget.duplicateWarning != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.duplicateWarning!,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: Colors.brown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Thumbnail hasil foto nota dengan kemampuan tap untuk zoom
              GestureDetector(
                onTap: () => _openImagePreview(context, widget.draft.localScanPath),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Image.file(
                        File(widget.draft.localScanPath),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Lihat Foto',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              // Nominal besar
              _isEditing ? _buildAmountField() : _buildDisplayNominal(),
              const SizedBox(height: AppSpacing.base),

              if (_isEditing) ...[
                _buildVendorField(),
                _buildCategorySelector(),
                _buildDateField(context),
                _buildPaymentMethodSelector(),
                _buildTextField('No. Nota / Struk', _receiptNumberController),
                _buildTextField('Pajak / PPN', _taxController, isNumber: true),
                _buildTextField('Catatan Tambahan', _notesController, maxLines: 2),
              ] else
                _buildDetailCard(),

              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      onPressed: widget.isSaving
                          ? null
                          : () => setState(() => _isEditing = !_isEditing),
                      child: Text(
                        _isEditing ? 'Selesai Edit' : 'Koreksi Data',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      onPressed: widget.isSaving ? null : _handleSave,
                      child: widget.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Simpan Nota',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        );
      },
    );
  }

  void _openImagePreview(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Foto Nota'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayNominal() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL PENGELUARAN',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(amount),
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildDetailRow('Vendor / Toko', _vendorController.text.isNotEmpty ? _vendorController.text : '-'),
          const Divider(color: AppColors.border, height: 16),
          _buildDetailRow('Kategori', _selectedCategory.label),
          const Divider(color: AppColors.border, height: 16),
          _buildDetailRow('Tanggal Transaksi', DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)),
          const Divider(color: AppColors.border, height: 16),
          _buildDetailRow('Metode Pembayaran', _selectedPaymentMethod),
          if (_receiptNumberController.text.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 16),
            _buildDetailRow('No. Nota', _receiptNumberController.text),
          ],
          if (_taxController.text.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 16),
            _buildDetailRow(
              'Pajak / PPN',
              _currencyFormat.format(double.tryParse(_taxController.text) ?? 0),
            ),
          ],
          if (_notesController.text.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 16),
            _buildDetailRow('Catatan', _notesController.text),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Total Nominal (Rp)',
        prefixText: 'Rp ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
      ),
    );
  }

  Widget _buildVendorField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: _vendorController,
        decoration: InputDecoration(
          labelText: 'Vendor / Tempat Pengeluaran',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori Pengeluaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ExpenseCategoryEntity.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = cat),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = ['Tunai / Cash', 'QRIS', 'Kartu Debit / Kredit', 'Transfer Bank', 'Lainnya'];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DropdownButtonFormField<String>(
        value: _selectedPaymentMethod,
        decoration: InputDecoration(
          labelText: 'Metode Pembayaran',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        ),
        items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedPaymentMethod = val);
        },
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Tanggal Transaksi', style: TextStyle(fontSize: 13)),
        subtitle: Text(
          DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.calendar_today_rounded, size: 20),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            locale: const Locale('id', 'ID'),
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        ),
      ),
    );
  }

  void _handleSave() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final tax = double.tryParse(_taxController.text);
    final vendor = _vendorController.text.trim();

    widget.onSave(
      vendorName: vendor.isNotEmpty ? vendor : 'Nota Tanpa Nama',
      transactionDate: _selectedDate,
      transactionTime: widget.draft.transactionTime,
      totalAmount: amount,
      category: _selectedCategory,
      taxAmount: tax,
      receiptNumber: _receiptNumberController.text.trim().isNotEmpty
          ? _receiptNumberController.text.trim()
          : null,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final bool needsReview;

  const _ConfidenceBadge({required this.needsReview});

  @override
  Widget build(BuildContext context) {
    if (needsReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.brown),
            SizedBox(width: 4),
            Text(
              'Perlu Diperiksa',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.brown,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
          SizedBox(width: 4),
          Text(
            'OCR Terbaca',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
