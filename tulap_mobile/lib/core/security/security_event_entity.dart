/// SecurityEventType
/// ----------------------------------------------------------------------
/// Selaras dengan `SecurityEventType` di backend
/// (`tulap_backend/src/modules/audit/dto/report-security-event.dto.ts`).
/// ----------------------------------------------------------------------
enum SecurityEventType {
  mockLocationBlocked,
  rootDeviceBlocked;

  /// Nilai string yang dikirim ke backend - HARUS persis sama dengan
  /// enum `SecurityEventType` di `report-security-event.dto.ts`.
  String get apiValue {
    switch (this) {
      case SecurityEventType.mockLocationBlocked:
        return 'MOCK_LOCATION_BLOCKED';
      case SecurityEventType.rootDeviceBlocked:
        return 'ROOT_DEVICE_BLOCKED';
    }
  }
}

/// SecurityEventEntity
/// ----------------------------------------------------------------------
/// Satu baris jejak percobaan capture yang DIBLOKIR karena integritas
/// lokasi/perangkat gagal (mock location / root device). Dicatat lokal
/// dulu (pola outbox, sama seperti GeotagPhotoEntity) sebelum didaftarkan
/// ke sync queue, supaya percobaan ini tetap tercatat bahkan jika device
/// sedang offline saat mendeteksinya - Bagian 21 & 31 spesifikasi.
/// ----------------------------------------------------------------------
class SecurityEventEntity {
  final String id;
  final String taskId;
  final SecurityEventType eventType;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String? deviceInfo;
  final DateTime detectedAt;

  const SecurityEventEntity({
    required this.id,
    required this.taskId,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.deviceInfo,
    required this.detectedAt,
  });
}
