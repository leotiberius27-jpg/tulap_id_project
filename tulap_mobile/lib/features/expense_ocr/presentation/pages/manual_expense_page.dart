import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/expense_note_entity.dart';
import '../../domain/usecases/save_manual_expense.dart';

/// ManualExpensePage
/// ----------------------------------------------------------------------
/// Form pencatatan pengeluaran lapangan manual tanpa bukti fisik nota
/// (misal parkir liar, ojek pangkalan, konsumsi warung tradisional).
/// ----------------------------------------------------------------------
class ManualExpensePage extends StatefulWidget {
  final String taskId;

  const ManualExpensePage({super.key, required this.taskId});

  @override
  State<ManualExpensePage> createState() => _ManualExpensePageState();
}

class _ManualExpensePageState extends State<ManualExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ExpenseCategoryEntity _selectedCategory = ExpenseCategoryEntity.konsumsi;
  String _selectedPaymentMethod = 'Tunai / Cash';
  bool _isSubmitting = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Catat Pengeluaran Manual',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gunakan form ini untuk transaksi yang tidak menerbitkan struk/nota fisik resmi (contoh: parkir, ojek tunai, warung makan).',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        color: Color(0xFF1E3A8A),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            // Card Input Fields
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
                  // Nominal Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nominal Pengeluaran *',
                      prefixText: 'Rp ',
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nominal pengeluaran wajib diisi';
                      }
                      final parsed = double.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                      if (parsed == null || parsed <= 0) {
                        return 'Masukkan nominal yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Keterangan / Vendor
                  TextFormField(
                    controller: _vendorController,
                    decoration: InputDecoration(
                      labelText: 'Keperluan / Keterangan Transaksi *',
                      hintText: 'Misal: Parkir Pelabuhan, Ojek Pangkalan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Keterangan pengeluaran wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Kategori
                  const Text(
                    'Kategori Pengeluaran',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategoryEntity.values.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Tanggal Transaksi
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Tanggal Transaksi',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
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
                  const Divider(color: AppColors.border),

                  // Metode Pembayaran
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Metode Pembayaran',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tunai / Cash', child: Text('Tunai / Cash')),
                      DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                      DropdownMenuItem(value: 'Transfer Bank', child: Text('Transfer Bank')),
                      DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPaymentMethod = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Catatan
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Catatan Tambahan (Opsional)',
                      hintText: 'Rincian lokasi atau rute...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitManualExpense,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Simpan Pengeluaran',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitManualExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final cleanAmount = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final totalAmount = double.parse(cleanAmount);
    final vendor = _vendorController.text.trim();
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    final saveManual = sl<SaveManualExpense>();
    final result = await saveManual(
      taskId: widget.taskId,
      vendorName: vendor,
      transactionDate: _selectedDate,
      totalAmount: totalAmount,
      category: _selectedCategory,
      notes: notes,
      paymentMethod: _selectedPaymentMethod,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.danger,
          ),
        );
      },
      (savedNote) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil disimpan.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(savedNote);
      },
    );
  }
}
