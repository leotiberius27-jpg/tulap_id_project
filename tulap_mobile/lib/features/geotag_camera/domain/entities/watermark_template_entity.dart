import 'package:flutter/material.dart';

/// StampConfiguration
/// ----------------------------------------------------------------------
/// Konfigurasi preferensi tampilan stamp/watermark yang dipilih pengguna.
///
/// ATURAN KRITIS (Metadata Immutability):
/// Mematikan toggle elemen visual (misalnya mematikan 'showCoordinates' atau
/// 'showOfficerName') HANYA menyembunyikan elemen tersebut dari tampilan visual
/// foto. Seluruh metadata forensik (koordinat, akurasi, timestamp, user ID,
/// mock status, SHA-256) TETAP direkam secara penuh dan permanen di Evidence Record.
/// ----------------------------------------------------------------------
class StampConfiguration {
  final String templateId;
  final int templateVersion;

  // Visual field toggles
  final bool showLocation;
  final bool showDate;
  final bool showTime;
  final bool showCoordinates;
  final bool showGpsAccuracy;
  final bool showTaskName;
  final bool showEvidenceId;
  final bool showOfficerName;
  final bool showMiniMap;
  final bool showQrMaps;
  final bool showHeading;

  const StampConfiguration({
    this.templateId = 'klasik',
    this.templateVersion = 1,
    this.showLocation = true,
    this.showDate = true,
    this.showTime = true,
    this.showCoordinates = true,
    this.showGpsAccuracy = true,
    this.showTaskName = true,
    this.showEvidenceId = true,
    this.showOfficerName = true,
    this.showMiniMap = true,
    this.showQrMaps = true,
    this.showHeading = true,
  });

  StampConfiguration copyWith({
    String? templateId,
    int? templateVersion,
    bool? showLocation,
    bool? showDate,
    bool? showTime,
    bool? showCoordinates,
    bool? showGpsAccuracy,
    bool? showTaskName,
    bool? showEvidenceId,
    bool? showOfficerName,
    bool? showMiniMap,
    bool? showQrMaps,
    bool? showHeading,
  }) {
    return StampConfiguration(
      templateId: templateId ?? this.templateId,
      templateVersion: templateVersion ?? this.templateVersion,
      showLocation: showLocation ?? this.showLocation,
      showDate: showDate ?? this.showDate,
      showTime: showTime ?? this.showTime,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showGpsAccuracy: showGpsAccuracy ?? this.showGpsAccuracy,
      showTaskName: showTaskName ?? this.showTaskName,
      showEvidenceId: showEvidenceId ?? this.showEvidenceId,
      showOfficerName: showOfficerName ?? this.showOfficerName,
      showMiniMap: showMiniMap ?? this.showMiniMap,
      showQrMaps: showQrMaps ?? this.showQrMaps,
      showHeading: showHeading ?? this.showHeading,
    );
  }

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'templateVersion': templateVersion,
    'showLocation': showLocation,
    'showDate': showDate,
    'showTime': showTime,
    'showCoordinates': showCoordinates,
    'showGpsAccuracy': showGpsAccuracy,
    'showTaskName': showTaskName,
    'showEvidenceId': showEvidenceId,
    'showOfficerName': showOfficerName,
    'showMiniMap': showMiniMap,
    'showQrMaps': showQrMaps,
    'showHeading': showHeading,
  };

  factory StampConfiguration.fromJson(Map<String, dynamic> json) {
    return StampConfiguration(
      templateId: json['templateId'] as String? ?? 'klasik',
      templateVersion: json['templateVersion'] as int? ?? 1,
      showLocation: json['showLocation'] as bool? ?? true,
      showDate: json['showDate'] as bool? ?? true,
      showTime: json['showTime'] as bool? ?? true,
      showCoordinates: json['showCoordinates'] as bool? ?? true,
      showGpsAccuracy: json['showGpsAccuracy'] as bool? ?? true,
      showTaskName: json['showTaskName'] as bool? ?? true,
      showEvidenceId: json['showEvidenceId'] as bool? ?? true,
      showOfficerName: json['showOfficerName'] as bool? ?? true,
      showMiniMap: json['showMiniMap'] as bool? ?? true,
      showQrMaps: json['showQrMaps'] as bool? ?? true,
      showHeading: json['showHeading'] as bool? ?? true,
    );
  }
}

/// WatermarkTemplateDefinition
/// ----------------------------------------------------------------------
/// Definisi blueprint untuk setiap gaya template stamp bukti geotag.
/// ----------------------------------------------------------------------
class WatermarkTemplateDefinition {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final IconData icon;
  final bool hasMiniMap;
  final bool hasQrMaps;
  final bool hasHeading;
  final bool isMinimal;
  final double panelHeightFractionPortrait;
  final double panelHeightFractionLandscape;

  const WatermarkTemplateDefinition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.hasMiniMap = false,
    this.hasQrMaps = false,
    this.hasHeading = false,
    this.isMinimal = false,
    this.panelHeightFractionPortrait = 0.22,
    this.panelHeightFractionLandscape = 0.25,
  });
}

/// TemplateCatalog
/// ----------------------------------------------------------------------
/// Katalog 6 template resmi Tulap.id:
/// 1. KLASIK: Geotag seimbang dengan Mini Map, Lokasi, Waktu, & GPS
/// 2. PELAPORAN: Dokumentasi formal institusi dengan ID Bukti & Data Petugas
/// 3. TANGGAL & WAKTU: Tampilan minimalis dengan Tanggal/Waktu dominan
/// 4. LOKASI + QR: Navigasi lapangan dengan Mini Map & QR Google Maps
/// 5. KOMPAK: Stamp teringkas untuk menjaga visibilitas foto maksimal
/// 6. KOMPAS / TEKNIS: Inspeksi lapangan teknis dengan Kompas & Elevasi
/// ----------------------------------------------------------------------
class TemplateCatalog {
  static const WatermarkTemplateDefinition klasik =
      WatermarkTemplateDefinition(
    id: 'klasik',
    name: 'Klasik',
    subtitle: 'Standar Geotag',
    description: 'Mini map, alamat 2-baris, waktu, akurasi GPS, & koordinat.',
    icon: Icons.map_outlined,
    hasMiniMap: true,
    hasQrMaps: false,
    panelHeightFractionPortrait: 0.22,
    panelHeightFractionLandscape: 0.25,
  );

  static const WatermarkTemplateDefinition pelaporan =
      WatermarkTemplateDefinition(
    id: 'pelaporan',
    name: 'Pelaporan',
    subtitle: 'Dokumentasi Formal',
    description: 'ID Bukti resmi, nama petugas, NIP, instansi, & QR lokasi.',
    icon: Icons.assignment_outlined,
    hasMiniMap: false,
    hasQrMaps: true,
    panelHeightFractionPortrait: 0.24,
    panelHeightFractionLandscape: 0.26,
  );

  static const WatermarkTemplateDefinition tanggalWaktu =
      WatermarkTemplateDefinition(
    id: 'tanggal_waktu',
    name: 'Tanggal & Waktu',
    subtitle: 'Minimalis Bersih',
    description: 'Tanggal & jam besar dominan, alamat ringkas, & akurasi.',
    icon: Icons.access_time_rounded,
    hasMiniMap: false,
    hasQrMaps: false,
    isMinimal: true,
    panelHeightFractionPortrait: 0.18,
    panelHeightFractionLandscape: 0.20,
  );

  static const WatermarkTemplateDefinition lokasiQr =
      WatermarkTemplateDefinition(
    id: 'lokasi_qr',
    name: 'Lokasi + QR',
    subtitle: 'Navigasi Presisi',
    description: 'Mini map, koordinat presisi, & QR Google Maps kontras tinggi.',
    icon: Icons.qr_code_2_rounded,
    hasMiniMap: true,
    hasQrMaps: true,
    panelHeightFractionPortrait: 0.25,
    panelHeightFractionLandscape: 0.28,
  );

  static const WatermarkTemplateDefinition kompak =
      WatermarkTemplateDefinition(
    id: 'kompak',
    name: 'Kompak',
    subtitle: 'Panel Ramping',
    description: 'Overlay teringkas 1 baris untuk visibilitas foto maksimal.',
    icon: Icons.view_compact_outlined,
    hasMiniMap: false,
    hasQrMaps: false,
    isMinimal: true,
    panelHeightFractionPortrait: 0.16,
    panelHeightFractionLandscape: 0.18,
  );

  static const WatermarkTemplateDefinition kompasTeknis =
      WatermarkTemplateDefinition(
    id: 'kompas_teknis',
    name: 'Kompas / Teknis',
    subtitle: 'Survey & Teknis',
    description: 'Arah hadap kompas, elevasi MDPL, koordinat, & waktu.',
    icon: Icons.explore_outlined,
    hasMiniMap: false,
    hasQrMaps: false,
    hasHeading: true,
    panelHeightFractionPortrait: 0.22,
    panelHeightFractionLandscape: 0.24,
  );

  static const List<WatermarkTemplateDefinition> all = [
    klasik,
    pelaporan,
    tanggalWaktu,
    lokasiQr,
    kompak,
    kompasTeknis,
  ];

  static WatermarkTemplateDefinition getById(String? id) {
    if (id == null || id.isEmpty) return klasik;
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => klasik,
    );
  }
}
