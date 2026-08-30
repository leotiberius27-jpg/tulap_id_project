import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/lpj_package_entity.dart';

class LpjPackagePreviewPage extends StatefulWidget {
  final LpjPackageEntity package;

  const LpjPackagePreviewPage({super.key, required this.package});

  @override
  State<LpjPackagePreviewPage> createState() => _LpjPackagePreviewPageState();
}

class _LpjPackagePreviewPageState extends State<LpjPackagePreviewPage> {
  bool _isVerifying = false;
  bool? _isHashValid;

  @override
  void initState() {
    super.initState();
    _verifyIntegrity();
  }

  Future<void> _verifyIntegrity() async {
    if (widget.package.pdfLocalPath == null ||
        !File(widget.package.pdfLocalPath!).existsSync()) {
      return;
    }

    setState(() => _isVerifying = true);
    final bytes = await File(widget.package.pdfLocalPath!).readAsBytes();
    final computedSha = sha256.convert(bytes).toString();

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _isHashValid = (computedSha.toLowerCase() == widget.package.packageSha256.toLowerCase());
    });
  }

  Future<void> _handleShare() async {
    if (widget.package.pdfLocalPath != null &&
        File(widget.package.pdfLocalPath!).existsSync()) {
      await Share.shareXFiles(
        [XFile(widget.package.pdfLocalPath!)],
        text: 'Paket LPJ Resmi Perjalanan Dinas: ${widget.package.title} (${widget.package.packageCode})',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File PDF belum tersedia di penyimpanan lokal.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfFile = widget.package.pdfLocalPath != null
        ? File(widget.package.pdfLocalPath!)
        : null;
    final fileExists = pdfFile != null && pdfFile.existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.package.packageCode} (${widget.package.versionLabel})',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Paket LPJ Perjalanan Dinas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Bagikan PDF',
            onPressed: fileExists ? _handleShare : null,
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppColors.textPrimary),
            tooltip: 'Cetak Dokumen',
            onPressed: fileExists
                ? () async {
                    final bytes = await pdfFile.readAsBytes();
                    await Printing.layoutPdf(
                      onLayout: (_) => bytes,
                      name: '${widget.package.packageCode}.pdf',
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // SHA-256 Verification Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _isHashValid == true
                ? AppColors.successSoft
                : (_isHashValid == false
                    ? AppColors.dangerSoft
                    : AppColors.background),
            child: Row(
              children: [
                Icon(
                  _isHashValid == true
                      ? Icons.verified
                      : (_isHashValid == false ? Icons.error : Icons.hourglass_top),
                  color: _isHashValid == true
                      ? AppColors.success
                      : (_isHashValid == false ? AppColors.danger : AppColors.textSecondary),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isVerifying
                            ? 'Memverifikasi Integritas SHA-256...'
                            : (_isHashValid == true
                                ? 'Integritas Terverifikasi Otentik'
                                : 'Checksum Tidak Sesuai'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isHashValid == true
                              ? AppColors.success
                              : (_isHashValid == false ? AppColors.danger : AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        'SHA-256: ${widget.package.packageSha256.substring(0, 20)}...',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${widget.package.completenessPercentage}% Lengkap',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // PDF Document Viewer
          Expanded(
            child: fileExists
                ? PdfPreview(
                    build: (format) => pdfFile.readAsBytes(),
                    allowPrinting: false,
                    allowSharing: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: '${widget.package.packageCode}.pdf',
                  )
                : const Center(
                    child: Text(
                      'File dokumen PDF tidak ditemukan di perangkat.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
