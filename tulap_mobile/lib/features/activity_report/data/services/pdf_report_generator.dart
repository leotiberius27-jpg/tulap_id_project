import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../domain/entities/activity_report_entity.dart';
import '../../domain/entities/report_draft_data.dart';
import '../../domain/entities/report_template_entity.dart';
import '../models/activity_report_model.dart';

class PdfReportGenerator {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  final DateFormat _fullDateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

  /// Menghasilkan file PDF resmi A4 portrait dan mengembalikan entitas laporan lengkap
  Future<ActivityReportModel> generateReportPdf({
    required ReportDraftData draft,
    required String reportId,
    required String reportCode,
    required int versionNumber,
  }) async {
    final pdf = pw.Document(
      title: draft.title,
      author: draft.implementerName ?? 'Tulap.id Field Worker',
      subject: 'Laporan Pelaksanaan Tugas ${draft.task.taskCode}',
      creator: 'Tulap.id Smart Report Engine v1.0',
    );

    final template = draft.template;

    // Load logo if available
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Load photo images bounded & safely
    final evidenceImages = <String, pw.MemoryImage>{};
    for (final evidence in draft.selectedEvidence) {
      if (!evidence.isVideo && File(evidence.localFilePath).existsSync()) {
        try {
          final bytes = await File(evidence.localFilePath).readAsBytes();
          evidenceImages[evidence.id] = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    final receiptImages = <String, pw.MemoryImage>{};
    if (template.showReceipts) {
      for (final expense in draft.selectedExpenses) {
        if (expense.localScanPath.isNotEmpty && File(expense.localScanPath).existsSync()) {
          try {
            final bytes = await File(expense.localScanPath).readAsBytes();
            receiptImages[expense.id] = pw.MemoryImage(bytes);
          } catch (_) {}
        }
      }
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
    );

    // MultiPage Document Structure
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => _buildHeader(context, template, logoImage),
        footer: (context) => _buildFooter(context, reportCode),
        build: (context) {
          return [
            // 1. Judul Laporan
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                draft.title,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. I. INFORMASI KEGIATAN
            _buildSectionTitle('I. INFORMASI UMUM PENUGASAN'),
            _buildTaskInfoTable(draft),
            pw.SizedBox(height: 12),

            // 3. II. RINGKASAN & NARASI PELAKSANAAN
            _buildSectionTitle('II. RINGKASAN PELAKSANAAN'),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                draft.narrative,
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2),
              ),
            ),
            pw.SizedBox(height: 12),

            // 4. III. KRONOLOGI / LINIMASA
            if (template.showTimeline && draft.selectedTimelineEvents.isNotEmpty) ...[
              _buildSectionTitle('III. KRONOLOGI / LINIMASA PELAKSANAAN'),
              _buildTimelineTable(draft.selectedTimelineEvents),
              pw.SizedBox(height: 12),
            ],

            // 5. IV. DOKUMENTASI FOTO / BUKTI GEOTAG
            if (draft.selectedEvidence.isNotEmpty) ...[
              _buildSectionTitle('IV. DOKUMENTASI KEGIATAN LAPANGAN'),
              _buildEvidenceGrid(draft.selectedEvidence, evidenceImages, template),
              pw.SizedBox(height: 12),
            ],

            // 6. V. REKAPITULASI BIAYA & PENGELUARAN
            if (template.showExpenses && draft.selectedExpenses.isNotEmpty) ...[
              _buildSectionTitle('V. REKAPITULASI BIAYA & PENGELUARAN LAPANGAN'),
              _buildExpensesTable(draft.selectedExpenses, draft.task.budgetAmount),
              pw.SizedBox(height: 12),
            ],

            // 7. VI. INFORMASI VERIFIKASI DOKUMENTASI
            if (template.showVerification) ...[
              _buildSectionTitle('VI. VERIFIKASI & INTEGRITAS DATA'),
              _buildVerificationCard(draft),
              pw.SizedBox(height: 12),
            ],

            // 8. VII. LEMBAR PENGESAHAN
            if (template.showSignatures) ...[
              pw.SizedBox(height: 8),
              _buildSignatureBlock(draft),
            ],
          ];
        },
      ),
    );

    // Lampiran Nota Fisik Terbaca (Jika ada dan diaktifkan)
    if (template.showReceipts && receiptImages.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pageTheme,
          header: (context) => _buildHeader(context, template, logoImage),
          footer: (context) => _buildFooter(context, reportCode),
          build: (context) {
            return [
              _buildSectionTitle('LAMPIRAN: BUKTI FISIK NOTA & STRUK TRANSAKSI'),
              pw.SizedBox(height: 8),
              _buildReceiptAppendix(draft.selectedExpenses, receiptImages),
            ];
          },
        ),
      );
    }

    // Simpan PDF ke penyimpanan lokal
    final appDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(appDir.path, 'tasks', draft.task.id, 'reports'));
    if (!reportsDir.existsSync()) {
      reportsDir.createSync(recursive: true);
    }

    final sanitizedTaskCode = draft.task.taskCode.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = 'Laporan_${sanitizedTaskCode}_v$versionNumber.pdf';
    final targetFile = File(p.join(reportsDir.path, fileName));

    final pdfBytes = await pdf.save();
    await targetFile.writeAsBytes(pdfBytes, flush: true);

    // Hitung SHA-256 Checksum dari file PDF yang dihasilkan
    final reportSha256 = sha256.convert(pdfBytes).toString();

    // Buat snapshot JSON dari data sumber
    final snapshotMap = {
      'reportId': reportId,
      'reportCode': reportCode,
      'versionNumber': versionNumber,
      'taskId': draft.task.id,
      'taskCode': draft.task.taskCode,
      'taskName': draft.task.taskName,
      'destination': draft.task.destination,
      'startDate': draft.task.startDate.toIso8601String(),
      'endDate': draft.task.endDate.toIso8601String(),
      'budgetAmount': draft.task.budgetAmount,
      'totalExpenseSum': draft.totalExpenseSum,
      'implementer': {
        'id': draft.user?.id,
        'name': draft.implementerName ?? draft.task.assigneeName,
        'nip': draft.user?.nip,
        'instansi': draft.template.institutionName,
        'unitKerja': draft.template.workUnit,
      },
      'selectedEvidenceIds': draft.selectedEvidence.map((e) => e.id).toList(),
      'selectedExpenseIds': draft.selectedExpenses.map((e) => e.id).toList(),
      'narrative': draft.narrative,
      'assembledAt': draft.assembledAt.toIso8601String(),
      'generatedAt': DateTime.now().toIso8601String(),
    };

    final now = DateTime.now();

    return ActivityReportModel(
      id: reportId,
      taskId: draft.task.id,
      userId: draft.user?.id,
      reportCode: reportCode,
      reportType: 'ACTIVITY_REPORT',
      templateId: template.id,
      templateVersion: template.version,
      title: draft.title,
      summary: draft.narrative.length > 120 ? '${draft.narrative.substring(0, 120)}...' : draft.narrative,
      narrative: draft.narrative,
      periodStart: draft.task.startDate,
      periodEnd: draft.task.endDate,
      versionNumber: versionNumber,
      status: ReportStatus.generated,
      pdfLocalPath: targetFile.path,
      contentSnapshotJson: jsonEncode(snapshotMap),
      reportSha256: reportSha256,
      totalExpense: draft.totalExpenseSum,
      evidenceCount: draft.selectedEvidence.length,
      receiptCount: draft.selectedExpenses.length,
      syncStatus: 'LOCAL_ONLY',
      createdAt: now,
      updatedAt: now,
    );
  }

  pw.Widget _buildHeader(pw.Context context, ReportTemplateEntity template, pw.MemoryImage? logo) {
    if (!template.showHeader) return pw.SizedBox();

    final instansi = template.institutionName ?? 'PEMERINTAH KABUPATEN MIMIKA';
    final unit = template.workUnit ?? 'DINAS KOMUNIKASI DAN INFORMATIKA';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 44,
                  height: 44,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      instansi.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Text(
                      unit.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sistem Dokumentasi Lapangan & Verifikasi Digital Tulap.id',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(height: 1.5, color: PdfColors.black),
          pw.SizedBox(height: 1),
          pw.Container(height: 0.5, color: PdfColors.black),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, String reportCode) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Tulap.id • ID Laporan: $reportCode',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildTaskInfoTable(ReportDraftData draft) {
    final task = draft.task;
    final startStr = _dateFormat.format(task.startDate);
    final endStr = _dateFormat.format(task.endDate);
    final period = startStr == endStr ? startStr : '$startStr s/d $endStr';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(7),
      },
      children: [
        _buildTableRow('Nomor Tugas / SPPD', task.taskCode),
        _buildTableRow('Nama Kegiatan', task.taskName),
        _buildTableRow('Lokasi Pelaksanaan', task.destination),
        _buildTableRow('Waktu / Periode', period),
        _buildTableRow('Petugas Pelaksana', '${draft.implementerName ?? task.assigneeName} (${draft.implementerTitle ?? "Staf Lapangan"})'),
        _buildTableRow('Pagu Anggaran Disetujui', _currencyFormat.format(task.budgetAmount)),
      ],
    );
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: PdfColors.grey100,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
        ),
      ],
    );
  }

  pw.Widget _buildTimelineTable(List<dynamic> events) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Waktu', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Peristiwa / Aktivitas', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Keterangan', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...events.take(8).map((event) {
          final time = _fullDateTimeFormat.format(event.eventTimestamp);
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(time, style: const pw.TextStyle(fontSize: 7.5)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(event.title, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(event.description ?? '-', style: const pw.TextStyle(fontSize: 7.5)),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildEvidenceGrid(
    List<GeotagPhotoEntity> items,
    Map<String, pw.MemoryImage> images,
    ReportTemplateEntity template,
  ) {
    final rows = <pw.Widget>[];

    // Proses item foto berpasangan (2 foto per baris untuk layout 2-per-page)
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;

      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildEvidenceCard(left, images[left.id])),
            pw.SizedBox(width: 8),
            if (right != null)
              pw.Expanded(child: _buildEvidenceCard(right, images[right.id]))
            else
              pw.Expanded(child: pw.Container()),
          ],
        ),
      );
      rows.add(pw.SizedBox(height: 8));
    }

    return pw.Column(children: rows);
  }

  pw.Widget _buildEvidenceCard(GeotagPhotoEntity item, pw.MemoryImage? img) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (img != null)
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Container(
                height: 140,
                width: double.infinity,
                child: pw.Image(img, fit: pw.BoxFit.cover),
              ),
            )
          else
            pw.Container(
              height: 140,
              color: PdfColors.grey100,
              child: pw.Center(
                child: pw.Text(
                  item.isVideo
                      ? '[REKAMAN VIDEO TERSIMPAN DI TULAP.ID]\nID: ${item.id.substring(0, 8)}'
                      : '[FOTO DOKUMENTASI TERSIMPAN]\nID: ${item.id.substring(0, 8)}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            (item.caption != null && item.caption!.isNotEmpty)
                ? item.caption!
                : (item.isVideo ? 'Dokumentasi Video Lapangan' : 'Dokumentasi Foto Lapangan'),
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            maxLines: 1,
          ),
          pw.Text(
            'Waktu: ${_fullDateTimeFormat.format(item.serverTimestamp)}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
          pw.Text(
            'Koordinat: ${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)} (±${item.gpsAccuracyMeters.toStringAsFixed(1)}m)',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
          ),
          if (item.plusCode.isNotEmpty)
            pw.Text(
              'Plus Code: ${item.plusCode}',
              style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildExpensesTable(List<ExpenseNoteEntity> expenses, double budget) {
    double total = 0;
    for (final exp in expenses) {
      total += exp.totalAmount;
    }

    final sisa = budget - total;

    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.8),
            1: const pw.FlexColumnWidth(2.2),
            2: const pw.FlexColumnWidth(3.5),
            3: const pw.FlexColumnWidth(2.0),
            4: const pw.FlexColumnWidth(2.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tanggal', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Uraian / Tempat Transaksi', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Kategori', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Jumlah (Rp)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...expenses.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final exp = entry.value;
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 7.5))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_dateFormat.format(exp.transactionDate), style: const pw.TextStyle(fontSize: 7.5))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(exp.vendorName, style: const pw.TextStyle(fontSize: 7.5))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(exp.category.label, style: const pw.TextStyle(fontSize: 7.5))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_currencyFormat.format(exp.totalAmount), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5))),
                ],
              );
            }),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Container(),
                pw.Container(),
                pw.Container(),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total Realisasi', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_currencyFormat.format(total), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Pagu Anggaran: ${_currencyFormat.format(budget)}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            pw.Text('Sisa / Selisih: ${_currencyFormat.format(sisa)}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: sisa >= 0 ? PdfColors.green800 : PdfColors.red800)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVerificationCard(ReportDraftData draft) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Pernyataan Integritas & Forensik Bukti Digital',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '• ${draft.selectedEvidence.length} item bukti dokumentasi terekam dengan timestamp server dan koordinat GPS anti-spoofing.\n'
            '• ${draft.selectedExpenses.length} bukti nota transaksi terverifikasi dan terikat secara sah pada kegiatan.\n'
            '• Integritas struktur berkas dilindungi dengan hashing digital SHA-256.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800, lineSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureBlock(ReportDraftData draft) {
    final nowStr = _dateFormat.format(DateTime.now());
    final dest = draft.task.destination.split(',').first.trim();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Mengetahui / Menyetujui,', style: const pw.TextStyle(fontSize: 8.5)),
            pw.Text(draft.supervisorTitle ?? 'Pejabat Pembuat Komitmen', style: const pw.TextStyle(fontSize: 8.5)),
            pw.SizedBox(height: 48),
            pw.Text(
              draft.supervisorName ?? '.........................................',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('$dest, $nowStr', style: const pw.TextStyle(fontSize: 8.5)),
            pw.Text('Pelaksana Lapangan,', style: const pw.TextStyle(fontSize: 8.5)),
            pw.SizedBox(height: 48),
            pw.Text(
              draft.implementerName ?? draft.task.assigneeName,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
            pw.Text(draft.implementerTitle ?? 'Staf Pelaksana', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReceiptAppendix(
    List<ExpenseNoteEntity> expenses,
    Map<String, pw.MemoryImage> images,
  ) {
    final rows = <pw.Widget>[];

    for (final exp in expenses) {
      final img = images[exp.id];
      if (img != null) {
        rows.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 140,
                  height: 180,
                  child: pw.Image(img, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        exp.vendorName,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('Kategori: ${exp.category.label}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Tanggal: ${_dateFormat.format(exp.transactionDate)}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Nominal: ${_currencyFormat.format(exp.totalAmount)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      if (exp.notes != null && exp.notes!.isNotEmpty)
                        pw.Text('Catatan: ${exp.notes!}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return pw.Column(children: rows);
  }
}
