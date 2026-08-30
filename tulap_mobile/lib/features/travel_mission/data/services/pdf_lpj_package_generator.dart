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
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/entities/lpj_package_entity.dart';
import '../../domain/entities/supporting_document_entity.dart';
import '../../domain/entities/travel_completeness_result.dart';
import '../../domain/entities/travel_expense_summary.dart';
import '../../domain/entities/travel_mission_entity.dart';
import '../models/lpj_package_model.dart';

class PdfLpjPackageGenerator {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

  Future<LpjPackageModel> generateLpjPackagePdf({
    required TravelMissionEntity travel,
    required List<TaskEntity> linkedTasks,
    required TravelExpenseSummary expenseSummary,
    required List<GeotagPhotoModel> photos,
    required List<SupportingDocumentEntity> supportingDocs,
    required TravelCompletenessResult completeness,
    required String packageId,
    required String packageCode,
    required int versionNumber,
  }) async {
    final pdf = pw.Document(
      title: 'LPJ Perjalanan Dinas - ${travel.displayId}',
      author: travel.personnelSnapshot.fullName,
      subject: 'Laporan Pertanggungjawaban ${travel.title}',
      creator: 'Tulap.id SPPD & LPJ Engine v1.0',
    );

    // Load Logo if available
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Load bounded photo images
    final photoImages = <String, pw.MemoryImage>{};
    for (final photo in photos) {
      if (!photo.isVideo && File(photo.localFilePath).existsSync()) {
        try {
          final bytes = await File(photo.localFilePath).readAsBytes();
          photoImages[photo.id] = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    // Load bounded receipt images
    final receiptImages = <String, pw.MemoryImage>{};
    final allExpenses = [
      ...expenseSummary.directExpenses,
      ...expenseSummary.activityExpenses,
    ];
    for (final exp in allExpenses) {
      if (exp.localScanPath.isNotEmpty && File(exp.localScanPath).existsSync()) {
        try {
          final bytes = await File(exp.localScanPath).readAsBytes();
          receiptImages[exp.id] = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    // Load bounded supporting doc images (non-pdf)
    final docImages = <String, pw.MemoryImage>{};
    for (final doc in supportingDocs) {
      if (!doc.isPdf && File(doc.filePath).existsSync()) {
        try {
          final bytes = await File(doc.filePath).readAsBytes();
          docImages[doc.id] = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
    );

    // Build Multipage PDF
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => _buildHeader(context, logoImage, packageCode),
        footer: (context) => _buildFooter(context, packageCode),
        build: (context) {
          return [
            // 1. Judul Utama
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'LAPORAN PERTANGGUNGJAWABAN (LPJ) PERJALANAN DINAS',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'KODE MISI: ${travel.displayId} | NOMOR LPJ: $packageCode (v$versionNumber)',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.SizedBox(height: 10),

            // 2. Data Umum & Dasar Penugasan
            _buildSectionHeader('I. DASAR PENUGASAN & DATA PERJALANAN'),
            pw.SizedBox(height: 6),
            _buildTravelInfoTable(travel),
            pw.SizedBox(height: 14),

            // 3. Rekapitulasi Biaya & Pengeluaran
            _buildSectionHeader('II. REKAPITULASI BIAYA & PENGELUARAN'),
            pw.SizedBox(height: 6),
            _buildExpenseRecapTable(expenseSummary, travel),
            pw.SizedBox(height: 14),

            // 4. Rekapitulasi Pelaksanaan Kegiatan
            _buildSectionHeader('III. REKAPITULASI PELAKSANAAN KEGIATAN LAPANGAN'),
            pw.SizedBox(height: 6),
            _buildActivitiesTable(linkedTasks),
            pw.SizedBox(height: 14),

            // 5. Catatan & Hasil Perjalanan
            if (travel.notes != null && travel.notes!.trim().isNotEmpty) ...[
              _buildSectionHeader('IV. CATATAN & HASIL PENUGASAN'),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Text(
                  travel.notes!,
                  style: const pw.TextStyle(fontSize: 9, height: 1.4),
                ),
              ),
              pw.SizedBox(height: 14),
            ],

            // 6. Lembar Pengesahan & Tanda Tangan
            _buildSectionHeader('V. LEMBAR PENGESAHAN'),
            pw.SizedBox(height: 8),
            _buildSignatureSection(travel),
            pw.SizedBox(height: 20),

            // 7. Lampiran Dokumentasi Foto
            if (photoImages.isNotEmpty) ...[
              pw.NewPage(),
              _buildSectionHeader('LAMPIRAN A: DOKUMENTASI VISUAL & GEOTAG'),
              pw.SizedBox(height: 8),
              _buildPhotoGrid(photos, photoImages),
              pw.SizedBox(height: 16),
            ],

            // 8. Lampiran Kuitansi & Nota
            if (receiptImages.isNotEmpty) ...[
              pw.NewPage(),
              _buildSectionHeader('LAMPIRAN B: BUKTI NOTA & KUITANSI PENGELUARAN'),
              pw.SizedBox(height: 8),
              _buildReceiptsGrid(allExpenses, receiptImages),
              pw.SizedBox(height: 16),
            ],

            // 9. Lampiran Dokumen Pendukung Lainnya
            if (docImages.isNotEmpty) ...[
              pw.NewPage(),
              _buildSectionHeader('LAMPIRAN C: DOKUMEN PENDUKUNG TERLAMPIR'),
              pw.SizedBox(height: 8),
              _buildDocsGrid(supportingDocs, docImages),
            ],
          ];
        },
      ),
    );

    // Save PDF locally in app documents directory
    final outputDir = await getApplicationDocumentsDirectory();
    final travelDir = Directory(p.join(outputDir.path, 'lpj_packages', travel.id));
    if (!travelDir.existsSync()) {
      travelDir.createSync(recursive: true);
    }

    final pdfFileName = '${packageCode}_v$versionNumber.pdf';
    final pdfFilePath = p.join(travelDir.path, pdfFileName);
    final pdfFile = File(pdfFilePath);
    final pdfBytes = await pdf.save();
    await pdfFile.writeAsBytes(pdfBytes);

    // Compute SHA-256
    final packageSha256 = sha256.convert(pdfBytes).toString();

    // Create Content Snapshot JSON
    final snapshotMap = {
      'travel': travel.copyWith().displayId,
      'assignmentLetterNumber': travel.assignmentLetterNumber,
      'personnel': travel.personnelSnapshot.toJson(),
      'origin': travel.origin,
      'destination': travel.destination,
      'departureDate': travel.departureDate.toIso8601String(),
      'returnDate': travel.returnDate.toIso8601String(),
      'totalActualExpense': expenseSummary.totalActualExpense,
      'estimatedBudget': expenseSummary.estimatedBudget,
      'activityCount': linkedTasks.length,
      'evidenceCount': photos.length,
      'receiptCount': allExpenses.length,
      'documentCount': supportingDocs.length,
      'completenessScore': completeness.score,
      'generatedAt': DateTime.now().toIso8601String(),
    };

    return LpjPackageModel(
      id: packageId,
      travelMissionId: travel.id,
      packageCode: packageCode,
      versionNumber: versionNumber,
      title: 'LPJ Perjalanan Dinas - ${travel.title}',
      pdfLocalPath: pdfFilePath,
      packageSha256: packageSha256,
      completenessScore: completeness.score,
      totalActualExpense: expenseSummary.totalActualExpense,
      activityCount: linkedTasks.length,
      evidenceCount: photos.length,
      receiptCount: allExpenses.length,
      documentCount: supportingDocs.length,
      contentSnapshotJson: jsonEncode(snapshotMap),
      status: LpjPackageStatus.generated,
      syncStatus: 'LOCAL_ONLY',
      createdAt: DateTime.now(),
    );
  }

  pw.Widget _buildHeader(pw.Context context, pw.MemoryImage? logo, String code) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Image(logo, width: 28, height: 28),
                pw.SizedBox(width: 8),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TULAP.ID',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'Sistem Pelaporan & Pertanggungjawaban Dinas Terpadu',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.Text(
            'Hal. ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, String code) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Dokumen resmi dibuat otomatis via Tulap.id SPPD & LPJ Engine',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            code,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _buildTravelInfoTable(TravelMissionEntity travel) {
    final infoRows = [
      ['Nomor Surat Tugas', travel.assignmentLetterNumber],
      ['Tanggal Surat Tugas', _dateFormat.format(travel.assignmentLetterDate)],
      ['Maksud / Perihal', travel.purpose],
      [
        'Pelaksana Tugas',
        '${travel.personnelSnapshot.fullName}${travel.personnelSnapshot.employeeNumber != null ? ' (NIP: ${travel.personnelSnapshot.employeeNumber})' : ''}',
      ],
      [
        'Jabatan / Unit',
        '${travel.personnelSnapshot.position ?? '-'} / ${travel.personnelSnapshot.unitName ?? '-'}',
      ],
      ['Rute Perjalanan', '${travel.origin} -> ${travel.destination}'],
      ['Periode & Durasi', '${travel.formattedPeriod} (${travel.durationDays} Hari)'],
      [
        'Moda Transportasi',
        '${travel.transportMode.label}${travel.transportDetails != null ? ' (${travel.transportDetails})' : ''}',
      ],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(4.8),
      },
      children: infoRows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 8.5)),
            ),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _buildExpenseRecapTable(
    TravelExpenseSummary summary,
    TravelMissionEntity travel,
  ) {
    final b = travel.budgetEstimate;
    final catBreakdown = summary.categoryBreakdown;

    final categories = [
      ['Transportasi / Tiket', b.transportasi, catBreakdown[ExpenseCategoryEntity.transportasiLain] ?? 0.0],
      ['Uang Harian / Representasi', b.uangHarian, 0.0],
      ['Penginapan / Hotel', b.penginapan, catBreakdown[ExpenseCategoryEntity.penginapan] ?? 0.0],
      ['BBM Kendaraan', b.bbm, catBreakdown[ExpenseCategoryEntity.bbm] ?? 0.0],
      ['Tol & Parkir', b.tol, catBreakdown[ExpenseCategoryEntity.tol] ?? 0.0],
      ['Konsumsi Lapangan', b.konsumsi, catBreakdown[ExpenseCategoryEntity.konsumsi] ?? 0.0],
      ['Lain-lain / Perlengkapan', b.lainnya, (catBreakdown[ExpenseCategoryEntity.lainnya] ?? 0.0) + (catBreakdown[ExpenseCategoryEntity.atk] ?? 0.0) + (catBreakdown[ExpenseCategoryEntity.perlengkapan] ?? 0.0) + (catBreakdown[ExpenseCategoryEntity.retail] ?? 0.0)],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeaderCell('Kategori Rincian'),
            _tableHeaderCell('Estimasi (Rp)', align: pw.TextAlign.right),
            _tableHeaderCell('Realisasi (Rp)', align: pw.TextAlign.right),
            _tableHeaderCell('Selisih (Rp)', align: pw.TextAlign.right),
          ],
        ),
        ...categories.map((cat) {
          final est = cat[1] as double;
          final act = cat[2] as double;
          final diff = est - act;
          return pw.TableRow(
            children: [
              _tableDataCell(cat[0] as String),
              _tableDataCell(_currencyFormat.format(est), align: pw.TextAlign.right),
              _tableDataCell(_currencyFormat.format(act), align: pw.TextAlign.right),
              _tableDataCell(
                _currencyFormat.format(diff),
                align: pw.TextAlign.right,
                color: diff < 0 ? PdfColors.red800 : PdfColors.green800,
              ),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableHeaderCell('TOTAL KESELURUHAN'),
            _tableHeaderCell(_currencyFormat.format(summary.estimatedBudget), align: pw.TextAlign.right),
            _tableHeaderCell(_currencyFormat.format(summary.totalActualExpense), align: pw.TextAlign.right),
            _tableHeaderCell(
              _currencyFormat.format(summary.varianceAmount),
              align: pw.TextAlign.right,
              color: summary.varianceAmount < 0 ? PdfColors.red800 : PdfColors.green800,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildActivitiesTable(List<TaskEntity> tasks) {
    if (tasks.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Tidak ada kegiatan lapangan khusus yang ditautkan.',
          style: const pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(3.0),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(1.0),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeaderCell('Kode Tugas'),
            _tableHeaderCell('Nama Kegiatan Lapangan'),
            _tableHeaderCell('Lokasi / Destinasi'),
            _tableHeaderCell('Bukti', align: pw.TextAlign.center),
          ],
        ),
        ...tasks.map((t) {
          return pw.TableRow(
            children: [
              _tableDataCell(t.taskCode),
              _tableDataCell(t.taskName),
              _tableDataCell(t.destination),
              _tableDataCell('${t.geotagPhotoCount} Foto', align: pw.TextAlign.center),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildSignatureSection(TravelMissionEntity travel) {
    final now = DateTime.now();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Mengetahui / Menyetujui,', style: const pw.TextStyle(fontSize: 8.5)),
            pw.Text('Pejabat Pembuat Komitmen / Atasan', style: const pw.TextStyle(fontSize: 8.5)),
            pw.SizedBox(height: 48),
            pw.Text('( .................................................. )', style: const pw.TextStyle(fontSize: 8.5)),
            pw.Text('NIP. ..........................................', style: const pw.TextStyle(fontSize: 7.5)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('${travel.origin}, ${_dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 8.5)),
            pw.Text('Pelaksana Perjalanan Dinas,', style: const pw.TextStyle(fontSize: 8.5)),
            pw.SizedBox(height: 48),
            pw.Text(
              '( ${travel.personnelSnapshot.fullName} )',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'NIP. ${travel.personnelSnapshot.employeeNumber ?? '-'}',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPhotoGrid(
    List<GeotagPhotoModel> photos,
    Map<String, pw.MemoryImage> images,
  ) {
    final photoRows = <pw.Widget>[];
    for (int i = 0; i < photos.length; i += 2) {
      final p1 = photos[i];
      final img1 = images[p1.id];
      final p2 = (i + 1 < photos.length) ? photos[i + 1] : null;
      final img2 = p2 != null ? images[p2.id] : null;

      photoRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildPhotoCard(p1, img1),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: p2 != null
                  ? _buildPhotoCard(p2, img2)
                  : pw.Container(),
            ),
          ],
        ),
      );
      photoRows.add(pw.SizedBox(height: 10));
    }

    return pw.Column(children: photoRows);
  }

  pw.Widget _buildPhotoCard(GeotagPhotoModel photo, pw.MemoryImage? img) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (img != null)
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Image(img, height: 110, fit: pw.BoxFit.cover),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Waktu: ${_dateTimeFormat.format(photo.deviceTimestamp ?? photo.serverTimestamp)}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
          ),
          pw.Text(
            'GPS: ${photo.latitude.toStringAsFixed(6)}, ${photo.longitude.toStringAsFixed(6)} (Ak: ${photo.gpsAccuracyMeters.toStringAsFixed(1)}m)',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
          ),
          pw.Text(
            'SHA: ${photo.integrityHash.substring(0, 16)}...',
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReceiptsGrid(
    List<ExpenseNoteEntity> expenses,
    Map<String, pw.MemoryImage> images,
  ) {
    final receiptRows = <pw.Widget>[];
    for (int i = 0; i < expenses.length; i += 2) {
      final e1 = expenses[i];
      final img1 = images[e1.id];
      final e2 = (i + 1 < expenses.length) ? expenses[i + 1] : null;
      final img2 = e2 != null ? images[e2.id] : null;

      receiptRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildReceiptCard(e1, img1),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: e2 != null
                  ? _buildReceiptCard(e2, img2)
                  : pw.Container(),
            ),
          ],
        ),
      );
      receiptRows.add(pw.SizedBox(height: 10));
    }

    return pw.Column(children: receiptRows);
  }

  pw.Widget _buildReceiptCard(ExpenseNoteEntity exp, pw.MemoryImage? img) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (img != null)
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Image(img, height: 110, fit: pw.BoxFit.contain),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            exp.vendorName,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Nominal: ${_currencyFormat.format(exp.totalAmount)} (${exp.category.label})',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue900),
          ),
          pw.Text(
            'Tgl: ${_dateFormat.format(exp.transactionDate)}',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDocsGrid(
    List<SupportingDocumentEntity> docs,
    Map<String, pw.MemoryImage> images,
  ) {
    return pw.Column(
      children: docs.map((d) {
        final img = images[d.id];
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Row(
            children: [
              if (img != null)
                pw.ClipRRect(
                  horizontalRadius: 3,
                  verticalRadius: 3,
                  child: pw.Image(img, width: 70, height: 70, fit: pw.BoxFit.cover),
                ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(d.title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Jenis: ${d.documentType.label}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text('SHA-256: ${d.sha256.substring(0, 24)}...', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _tableDataCell(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
