import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tulap_mobile/core/theme/app_theme.dart';
import 'package:tulap_mobile/features/evidence_verification/domain/entities/evidence_verification_result.dart';

class EvidenceTechnicalDetailsPage extends StatelessWidget {
  final EvidenceVerificationResult result;

  const EvidenceTechnicalDetailsPage({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMMM yyyy, HH:mm:ss', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Teknis & Kriptografi'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          _buildCard(
            context: context,
            title: 'IDENTIFIKASI BUKTI',
            icon: Icons.fingerprint_rounded,
            children: [
              _buildRow('Short Evidence ID', result.shortEvidenceId, isMonospace: true),
              _buildRow('Photo UUID', result.photoId, isMonospace: true),
              _buildRow('Task ID', result.taskId, isMonospace: true),
              _buildRow('Kegiatan', result.taskTitle ?? '-'),
              _buildRow('Petugas', '${result.officerName} (${result.agencyName})'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _buildCard(
            context: context,
            title: 'INTEGRITAS KRIPTOGRAFI (SHA-256)',
            icon: Icons.enhanced_encryption_rounded,
            children: [
              _buildHashRow(
                context: context,
                label: 'Final Evidence SHA-256',
                hash: result.computedFinalHash.isNotEmpty
                    ? result.computedFinalHash
                    : result.storedFinalHash,
                isValid: result.isFinalHashValid,
              ),
              if (result.storedOriginalHash != null &&
                  result.storedOriginalHash!.isNotEmpty)
                _buildHashRow(
                  context: context,
                  label: 'Original Raw Photo SHA-256',
                  hash: result.computedOriginalHash ?? result.storedOriginalHash!,
                  isValid: result.isOriginalHashValid ?? true,
                ),
              _buildRow(
                'Status Integritas',
                result.isFinalHashValid ? 'Sesuai (Untampered)' : 'GAGAL / File Telah Dimodifikasi',
                valueColor: result.isFinalHashValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              _buildRow(
                'Waktu Audit',
                df.format(result.verifiedAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _buildCard(
            context: context,
            title: 'TELEMETRI & GEOLOKASI',
            icon: Icons.satellite_alt_rounded,
            children: [
              _buildRow('Latitude', result.latitude.toStringAsFixed(7)),
              _buildRow('Longitude', result.longitude.toStringAsFixed(7)),
              _buildRow('GPS Accuracy', '±${result.gpsAccuracyMeters.toStringAsFixed(1)} meter'),
              _buildRow('Plus Code (OLC)', result.plusCode),
              _buildRow('Alamat Terekam', result.address ?? 'Tidak tersedia (Offline)'),
              _buildRow(
                'Deteksi Mock Location',
                result.isMockLocationDetected ? 'TERDETEKSI (TIDAK VALID)' : 'Tidak Terdeteksi (Otentik)',
                valueColor: result.isMockLocationDetected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _buildCard(
            context: context,
            title: 'WAKTU & PROVENSI SISTEM',
            icon: Icons.schedule_rounded,
            children: [
              _buildRow(
                'Waktu Pengambilan (Perangkat)',
                result.deviceTimestamp != null ? df.format(result.deviceTimestamp!) : '-',
              ),
              _buildRow(
                'Timestamp Acuan / Server',
                df.format(result.serverTimestamp),
              ),
              _buildRow(
                'Integritas Perangkat',
                result.isRootedDeviceDetected ? 'COMPROMISED / ROOTED' : 'Aman (Original Android OS)',
                valueColor: result.isRootedDeviceDetected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
              _buildRow(
                'Sinkronisasi Cloud',
                result.isSynced ? 'Tersinkronisasi ke Cloud Server' : 'Tersimpan Lokal (Menunggu Antrian Outbox)',
                valueColor: result.isSynced ? const Color(0xFF6366F1) : const Color(0xFF38BDF8),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF006EE6)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF006EE6),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isMonospace = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: isMonospace ? 'monospace' : null,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashRow({
    required BuildContext context,
    required String label,
    required String hash,
    required bool isValid,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 15),
                tooltip: 'Salin Hash',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: hash));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SHA-256 berhasil disalin ke clipboard.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              hash.isNotEmpty ? hash : 'Belum dihitung',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isValid ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
