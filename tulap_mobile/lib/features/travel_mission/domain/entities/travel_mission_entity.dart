import 'package:intl/intl.dart';

enum TravelTransportMode {
  pesawat('Pesawat Terbang'),
  kendaraanDinas('Kendaraan Dinas'),
  kendaraanPribadi('Kendaraan Pribadi'),
  kapal('Kapal Laut / Ferry'),
  transportasiUmum('Transportasi Umum'),
  lainnya('Lainnya');

  final String label;
  const TravelTransportMode(this.label);

  static TravelTransportMode fromString(String? val) {
    if (val == null) return TravelTransportMode.kendaraanDinas;
    final lower = val.toLowerCase();
    if (lower.contains('pesawat') || lower.contains('flight') || lower.contains('air')) {
      return TravelTransportMode.pesawat;
    }
    if (lower.contains('kapal') || lower.contains('boat') || lower.contains('sea')) {
      return TravelTransportMode.kapal;
    }
    if (lower.contains('pribadi')) return TravelTransportMode.kendaraanPribadi;
    if (lower.contains('umum') || lower.contains('bus') || lower.contains('kereta')) {
      return TravelTransportMode.transportasiUmum;
    }
    if (lower.contains('dinas')) return TravelTransportMode.kendaraanDinas;
    return TravelTransportMode.lainnya;
  }
}

enum TravelMissionStatus {
  draft('Draf'),
  planned('Direncanakan'),
  ongoing('Sedang Berjalan'),
  completed('Selesai'),
  lpjIncomplete('LPJ Belum Lengkap'),
  lpjReady('LPJ Siap Dibuat'),
  archived('Diarsipkan');

  final String label;
  const TravelMissionStatus(this.label);

  static TravelMissionStatus fromString(String? val) {
    if (val == null) return TravelMissionStatus.draft;
    final lower = val.toLowerCase();
    for (final status in TravelMissionStatus.values) {
      if (status.name.toLowerCase() == lower || status.label.toLowerCase() == lower) {
        return status;
      }
    }
    if (lower.contains('ongoing') || lower.contains('berjalan')) return TravelMissionStatus.ongoing;
    if (lower.contains('complete') || lower.contains('selesai')) return TravelMissionStatus.completed;
    if (lower.contains('ready') || lower.contains('siap')) return TravelMissionStatus.lpjReady;
    if (lower.contains('archived') || lower.contains('arsip')) return TravelMissionStatus.archived;
    return TravelMissionStatus.draft;
  }
}

class TravelBudgetEstimate {
  final double transportasi;
  final double uangHarian;
  final double penginapan;
  final double bbm;
  final double tol;
  final double parkir;
  final double konsumsi;
  final double lainnya;

  const TravelBudgetEstimate({
    this.transportasi = 0.0,
    this.uangHarian = 0.0,
    this.penginapan = 0.0,
    this.bbm = 0.0,
    this.tol = 0.0,
    this.parkir = 0.0,
    this.konsumsi = 0.0,
    this.lainnya = 0.0,
  });

  double get total =>
      transportasi + uangHarian + penginapan + bbm + tol + parkir + konsumsi + lainnya;

  Map<String, dynamic> toJson() => {
    'transportasi': transportasi,
    'uangHarian': uangHarian,
    'penginapan': penginapan,
    'bbm': bbm,
    'tol': tol,
    'parkir': parkir,
    'konsumsi': konsumsi,
    'lainnya': lainnya,
  };

  factory TravelBudgetEstimate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TravelBudgetEstimate();
    return TravelBudgetEstimate(
      transportasi: (json['transportasi'] as num?)?.toDouble() ?? 0.0,
      uangHarian: (json['uangHarian'] as num?)?.toDouble() ?? 0.0,
      penginapan: (json['penginapan'] as num?)?.toDouble() ?? 0.0,
      bbm: (json['bbm'] as num?)?.toDouble() ?? 0.0,
      tol: (json['tol'] as num?)?.toDouble() ?? 0.0,
      parkir: (json['parkir'] as num?)?.toDouble() ?? 0.0,
      konsumsi: (json['konsumsi'] as num?)?.toDouble() ?? 0.0,
      lainnya: (json['lainnya'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TravelPersonnelSnapshot {
  final String fullName;
  final String? employeeNumber;
  final String? position;
  final String? unitName;
  final List<String> additionalPersonnel;

  const TravelPersonnelSnapshot({
    required this.fullName,
    this.employeeNumber,
    this.position,
    this.unitName,
    this.additionalPersonnel = const [],
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'employeeNumber': employeeNumber,
    'position': position,
    'unitName': unitName,
    'additionalPersonnel': additionalPersonnel,
  };

  factory TravelPersonnelSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TravelPersonnelSnapshot(fullName: 'Petugas Lapangan');
    }
    return TravelPersonnelSnapshot(
      fullName: (json['fullName'] as String?) ?? 'Petugas Lapangan',
      employeeNumber: json['employeeNumber'] as String?,
      position: json['position'] as String?,
      unitName: json['unitName'] as String?,
      additionalPersonnel: (json['additionalPersonnel'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class TravelMissionEntity {
  final String id;
  final String displayId; // PD-20260828-XXXX
  final String userId;
  final String? organizationId;

  // Dasar Penugasan
  final String assignmentLetterNumber;
  final DateTime assignmentLetterDate;
  final String title;
  final String purpose;

  // Lokasi
  final String origin;
  final String destination;
  final List<String> destinations;

  // Waktu
  final DateTime departureDate;
  final DateTime returnDate;

  // Transportasi & Estimasi
  final TravelTransportMode transportMode;
  final String? transportDetails;
  final TravelMissionStatus status;
  final TravelBudgetEstimate budgetEstimate;
  final String? notes;
  final TravelPersonnelSnapshot personnelSnapshot;

  final String syncStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TravelMissionEntity({
    required this.id,
    required this.displayId,
    required this.userId,
    this.organizationId,
    required this.assignmentLetterNumber,
    required this.assignmentLetterDate,
    required this.title,
    required this.purpose,
    required this.origin,
    required this.destination,
    this.destinations = const [],
    required this.departureDate,
    required this.returnDate,
    required this.transportMode,
    this.transportDetails,
    required this.status,
    required this.budgetEstimate,
    this.notes,
    required this.personnelSnapshot,
    this.syncStatus = 'LOCAL_ONLY',
    required this.createdAt,
    this.updatedAt,
  });

  int get durationDays {
    final start = DateTime(departureDate.year, departureDate.month, departureDate.day);
    final end = DateTime(returnDate.year, returnDate.month, returnDate.day);
    final diff = end.difference(start).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  String get formattedPeriod {
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    final shortFormatter = DateFormat('dd', 'id_ID');
    final monthYearFormatter = DateFormat('MMM yyyy', 'id_ID');

    if (departureDate.year == returnDate.year && departureDate.month == returnDate.month) {
      if (departureDate.day == returnDate.day) {
        return formatter.format(departureDate);
      }
      return '${shortFormatter.format(departureDate)}–${shortFormatter.format(returnDate)} ${monthYearFormatter.format(returnDate)}';
    }
    return '${formatter.format(departureDate)} – ${formatter.format(returnDate)}';
  }

  bool isDateWithinTravelPeriod(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(departureDate.year, departureDate.month, departureDate.day);
    final end = DateTime(returnDate.year, returnDate.month, returnDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  TravelMissionEntity copyWith({
    String? title,
    String? purpose,
    String? assignmentLetterNumber,
    DateTime? assignmentLetterDate,
    String? origin,
    String? destination,
    List<String>? destinations,
    DateTime? departureDate,
    DateTime? returnDate,
    TravelTransportMode? transportMode,
    String? transportDetails,
    TravelMissionStatus? status,
    TravelBudgetEstimate? budgetEstimate,
    String? notes,
    TravelPersonnelSnapshot? personnelSnapshot,
    String? syncStatus,
    DateTime? updatedAt,
  }) {
    return TravelMissionEntity(
      id: id,
      displayId: displayId,
      userId: userId,
      organizationId: organizationId,
      assignmentLetterNumber: assignmentLetterNumber ?? this.assignmentLetterNumber,
      assignmentLetterDate: assignmentLetterDate ?? this.assignmentLetterDate,
      title: title ?? this.title,
      purpose: purpose ?? this.purpose,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      destinations: destinations ?? this.destinations,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      transportMode: transportMode ?? this.transportMode,
      transportDetails: transportDetails ?? this.transportDetails,
      status: status ?? this.status,
      budgetEstimate: budgetEstimate ?? this.budgetEstimate,
      notes: notes ?? this.notes,
      personnelSnapshot: personnelSnapshot ?? this.personnelSnapshot,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
