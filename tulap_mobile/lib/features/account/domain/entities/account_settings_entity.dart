/// CameraSettingsEntity
/// ----------------------------------------------------------------------
/// Preferensi konfigurasi tampilan kamera dan watermark geotag yang aman
/// dikustomisasi oleh pengguna. Fitur keamanan utama seperti SHA-256,
/// Anti-Mock GPS, dan validasi lokasi TETAP AKTIF secara permanen di sistem.
/// ----------------------------------------------------------------------
class CameraSettingsEntity {
  final bool showAddress;
  final bool showCoordinates;
  final bool showQrCode;
  final bool saveWatermarkedCopy;

  const CameraSettingsEntity({
    this.showAddress = true,
    this.showCoordinates = true,
    this.showQrCode = true,
    this.saveWatermarkedCopy = true,
  });

  CameraSettingsEntity copyWith({
    bool? showAddress,
    bool? showCoordinates,
    bool? showQrCode,
    bool? saveWatermarkedCopy,
  }) {
    return CameraSettingsEntity(
      showAddress: showAddress ?? this.showAddress,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showQrCode: showQrCode ?? this.showQrCode,
      saveWatermarkedCopy: saveWatermarkedCopy ?? this.saveWatermarkedCopy,
    );
  }

  Map<String, dynamic> toJson() => {
    'showAddress': showAddress,
    'showCoordinates': showCoordinates,
    'showQrCode': showQrCode,
    'saveWatermarkedCopy': saveWatermarkedCopy,
  };

  factory CameraSettingsEntity.fromJson(Map<String, dynamic> json) {
    return CameraSettingsEntity(
      showAddress: json['showAddress'] as bool? ?? true,
      showCoordinates: json['showCoordinates'] as bool? ?? true,
      showQrCode: json['showQrCode'] as bool? ?? true,
      saveWatermarkedCopy: json['saveWatermarkedCopy'] as bool? ?? true,
    );
  }
}

/// NotificationSettingsEntity
/// ----------------------------------------------------------------------
/// Preferensi notifikasi pengguna untuk tugas, antrian sinkronisasi, dan pengingat.
/// ----------------------------------------------------------------------
class NotificationSettingsEntity {
  final bool taskAlerts;
  final bool syncStatusAlerts;
  final bool activityReminders;
  final bool systemAnnouncements;

  const NotificationSettingsEntity({
    this.taskAlerts = true,
    this.syncStatusAlerts = true,
    this.activityReminders = true,
    this.systemAnnouncements = true,
  });

  NotificationSettingsEntity copyWith({
    bool? taskAlerts,
    bool? syncStatusAlerts,
    bool? activityReminders,
    bool? systemAnnouncements,
  }) {
    return NotificationSettingsEntity(
      taskAlerts: taskAlerts ?? this.taskAlerts,
      syncStatusAlerts: syncStatusAlerts ?? this.syncStatusAlerts,
      activityReminders: activityReminders ?? this.activityReminders,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
    );
  }

  Map<String, dynamic> toJson() => {
    'taskAlerts': taskAlerts,
    'syncStatusAlerts': syncStatusAlerts,
    'activityReminders': activityReminders,
    'systemAnnouncements': systemAnnouncements,
  };

  factory NotificationSettingsEntity.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsEntity(
      taskAlerts: json['taskAlerts'] as bool? ?? true,
      syncStatusAlerts: json['syncStatusAlerts'] as bool? ?? true,
      activityReminders: json['activityReminders'] as bool? ?? true,
      systemAnnouncements: json['systemAnnouncements'] as bool? ?? true,
    );
  }
}
