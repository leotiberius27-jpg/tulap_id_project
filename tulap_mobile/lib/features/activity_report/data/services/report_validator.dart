import 'dart:io';
import '../../domain/entities/report_draft_data.dart';
import '../../domain/entities/report_validation_result.dart';

class ReportValidator {
  ReportValidationResult validate(ReportDraftData draft) {
    final blockers = <String>[];
    final warnings = <String>[];

    int availableLocalMedia = 0;
    int missingLocalMedia = 0;
    int unconfirmedExpenses = 0;

    // 1. Validasi Keberadaan File Dokumentasi Foto
    for (final evidence in draft.selectedEvidence) {
      if (!evidence.isVideo) {
        final file = File(evidence.localFilePath);
        if (file.existsSync()) {
          availableLocalMedia++;
        } else {
          missingLocalMedia++;
          warnings.add(
            'Foto bukti (${evidence.id.substring(0, 8)}) belum terunduh di penyimpanan lokal perangkat.',
          );
        }
      }
    }

    // 2. Validasi File Nota / Struk Pengeluaran
    for (final expense in draft.selectedExpenses) {
      if (!expense.isManualEntry && expense.localScanPath.isNotEmpty) {
        final receiptFile = File(expense.localScanPath);
        if (!receiptFile.existsSync()) {
          warnings.add(
            'Lampiran nota untuk ${expense.vendorName} (Rp ${expense.totalAmount.toStringAsFixed(0)}) belum tersedia di lokal.',
          );
        }
      }

      if (expense.verificationStatus.name == 'ocrExtracted' ||
          expense.verificationStatus.name == 'pendingReview') {
        unconfirmedExpenses++;
        warnings.add(
          'Nota ${expense.vendorName} masih berstatus draf ekstraksi OCR dan belum diverifikasi manual.',
        );
      }
    }

    // 3. Validasi Kelengkapan Informasi Pokok
    if (draft.title.trim().isEmpty) {
      blockers.add('Judul laporan tidak boleh kosong.');
    }

    if (draft.task.taskName.trim().isEmpty) {
      blockers.add('Nama kegiatan tidak valid.');
    }

    final isReady = blockers.isEmpty;

    return ReportValidationResult(
      isReady: isReady,
      blockers: blockers,
      warnings: warnings,
      availableLocalMediaCount: availableLocalMedia,
      missingLocalMediaCount: missingLocalMedia,
      unconfirmedExpenseCount: unconfirmedExpenses,
    );
  }
}
