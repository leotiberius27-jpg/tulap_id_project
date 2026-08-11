import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/repositories/expense_ocr_repository.dart';

/// ReceiptReviewSheet
/// ----------------------------------------------------------------------
/// Bottom sheet review hasil OCR sesuai Bagian 9 spesifikasi:
/// Vendor, Nominal (besar), Kategori, Tanggal, No. Nota, Pajak, dengan
/// hierarchy ala "digital transaction receipt modern". Field dengan
/// confidence OCR rendah ditandai kuning agar user memeriksa manual.
/// ----------------------------------------------------------------------
class ReceiptReviewSheet extends StatefulWidget {
  final ScannedReceiptDraft draft;
  final bool isSaving;
  final void Function({
    required String vendorName,
    required DateTime transactionDate,
    required double totalAmount,
    required ExpenseCategoryEntity category,
    double? taxAmount,
    String? receiptNumber,
  }) onSave;

  const ReceiptReviewSheet({
    super.key,
    required this.draft,
    required this.isSaving,
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
  late DateTime _selectedDate;
  late ExpenseCategoryEntity _selectedCategory;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _vendorController = TextEditingController(text: d.vendorName ?? '');
    _amountController = TextEditingController(
      text: d.totalAmount?.toStringAsFixed(0) ?? '',
    );
    _taxController = TextEditingController(
      text: d.taxAmount?.toStringAsFixed(0) ?? '',
    );
    _receiptNumberController = TextEditingController(text: d.receiptNumber ?? '');
    _selectedDate = d.transactionDate ?? DateTime.now();
    _selectedCategory = d.category;
  }

  @override
  Widget build(BuildContext context) {
    final overallConfidenceLow = widget.draft.ocrConfidence < 0.7;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                  Text('Review Nota', style: AppTypography.sectionTitle),
                  _ConfidenceBadge(needsReview: overallConfidenceLow),
                ],
              ),
              const SizedBox(height: AppSpacing.base),

              // Thumbnail hasil foto nota
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Image.file(
                  File(widget.draft.localScanPath),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Nominal besar - hierarchy utama sesuai spesifikasi
              _isEditing
                  ? _buildAmountField()
                  : _buildDisplayNominal(),
              const SizedBox(height: AppSpacing.lg),

              _isEditing ? _buildVendorField() : _buildDisplayRow(
                label: 'Vendor',
                value: _vendorController.text.isEmpty ? '-' : _vendorController.text,
                needsReview: widget.draft.vendorName == null,
              ),

              _buildCategorySelector(),

              _isEditing
                  ? _buildDateField(context)
                  : _buildDisplayRow(
                      label: 'Tanggal',
                      value: _formatDate(_selectedDate),
                      needsReview: widget.draft.transactionDate == null,
                    ),

              if (_receiptNumberController.text.isNotEmpty || _isEditing)
                _isEditing
                    ? _buildTextField('No. Nota', _receiptNumberController)
                    : _buildDisplayRow(
                        label: 'No. Nota',
                        value: _receiptNumberController.text.isEmpty
                            ? '-'
                            : _receiptNumberController.text,
                        needsReview: false,
                      ),

              if (_taxController.text.isNotEmpty || _isEditing)
                _isEditing
                    ? _buildTextField('Pajak', _taxController, isNumber: true)
                    : _buildDisplayRow(
                        label: 'Pajak',
                        value: _taxController.text.isEmpty
                            ? '-'
                            : 'Rp ${_taxController.text}',
                        needsReview: false,
                      ),

              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.isSaving
                          ? null
                          : () => setState(() => _isEditing = !_isEditing),
                      child: Text(_isEditing ? 'Selesai Edit' : 'Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.isSaving ? null : _handleSave,
                      child: widget.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Nota'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSave() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final tax = double.tryParse(_taxController.text.replaceAll(',', ''));

    widget.onSave(
      vendorName: _vendorController.text.trim().isEmpty
          ? 'Vendor Tidak Diketahui'
          : _vendorController.text.trim(),
      transactionDate: _selectedDate,
      totalAmount: amount,
      category: _selectedCategory,
      taxAmount: tax,
      receiptNumber: _receiptNumberController.text.trim().isEmpty
          ? null
          : _receiptNumberController.text.trim(),
    );
  }

  Widget _buildDisplayNominal() {
    final needsReview = widget.draft.totalAmount == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nominal', style: AppTypography.small),
        Row(
          children: [
            Text(
              'Rp ${_amountController.text.isEmpty ? '0' : _amountController.text}',
              style: AppTypography.nominalDisplay,
            ),
            if (needsReview) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField() => _buildTextField('Nominal', _amountController, isNumber: true);
  Widget _buildVendorField() => _buildTextField('Vendor', _vendorController);

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildDisplayRow({required String label, required String value, required bool needsReview}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary),
          Row(
            children: [
              Text(value, style: AppTypography.body),
              if (needsReview) ...[
                const SizedBox(width: 4),
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Kategori', style: AppTypography.bodySecondary),
          DropdownButton<ExpenseCategoryEntity>(
            value: _selectedCategory,
            underline: const SizedBox.shrink(),
            items: ExpenseCategoryEntity.values.map((c) {
              return DropdownMenuItem(value: c, child: Text(_categoryLabel(c)));
            }).toList(),
            onChanged: widget.isSaving
                ? null
                : (value) {
                    if (value != null) setState(() => _selectedCategory = value);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Tanggal'),
          child: Text(_formatDate(_selectedDate)),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _categoryLabel(ExpenseCategoryEntity category) {
    switch (category) {
      case ExpenseCategoryEntity.bbm:
        return 'BBM';
      case ExpenseCategoryEntity.tol:
        return 'Tol';
      case ExpenseCategoryEntity.penginapan:
        return 'Penginapan';
      case ExpenseCategoryEntity.retail:
        return 'Retail';
      case ExpenseCategoryEntity.konsumsi:
        return 'Konsumsi';
      case ExpenseCategoryEntity.transportasiLain:
        return 'Transportasi Lain';
      case ExpenseCategoryEntity.lainnya:
        return 'Lainnya';
    }
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final bool needsReview;
  const _ConfidenceBadge({required this.needsReview});

  @override
  Widget build(BuildContext context) {
    final color = needsReview ? AppColors.warning : AppColors.success;
    final bg = needsReview ? AppColors.warningSoft : AppColors.successSoft;
    final label = needsReview ? 'Perlu Dicek' : 'OCR Berhasil';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.small)),
      child: Text(label, style: AppTypography.small.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
