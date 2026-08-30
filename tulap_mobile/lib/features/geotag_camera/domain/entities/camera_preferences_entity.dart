import 'dart:convert';

/// Aspect Ratio Kamera
enum CameraAspectRatio {
  ratio4x3('4:3', 'Standar Sensor 4:3', 4 / 3),
  ratio16x9('16:9', 'Layar Lebar 16:9', 16 / 9),
  ratioFull('Penuh', 'Layar Penuh (Full View)', 0.0);

  final String label;
  final String description;
  final double ratioValue;

  const CameraAspectRatio(this.label, this.description, this.ratioValue);
}

/// Preferensi Suara Shutter
enum ShutterSoundPreference {
  system('Ikuti Sistem', 'Sesuai mode hening/dering sistem operasi'),
  enabled('Aktif', 'Selalu bunyikan suara rana saat mengambil foto'),
  disabled('Nonaktif', 'Heningkan suara rana kamera');

  final String label;
  final String description;

  const ShutterSoundPreference(this.label, this.description);
}

/// Mode White Balance Kamera
enum CameraWhiteBalanceMode {
  auto('Otomatis', 'Penyesuaian warna otomatis berbasis sensor'),
  daylight('Siang / Cerah', 'Cahaya matahari luar ruangan (~5500K)'),
  cloudy('Berawan', 'Kondisi mendung / bayangan sejuk (~6500K)'),
  fluorescent('Neon / Fluo', 'Pencahayaan lampu neon / kantor (~4000K)'),
  incandescent('Pijar / Warm', 'Pencahayaan lampu bohlam hangat (~3000K)');

  final String label;
  final String description;

  const CameraWhiteBalanceMode(this.label, this.description);
}

/// Kualitas Kompresi Foto
enum PhotoQualityPreference {
  economy('Hemat', 'Ukuran ~150KB, kompresi efisien untuk daerah minim sinyal'),
  standard('Standar', 'Ukuran ~300-500KB, resolusi seimbang untuk bukti audit resmi'),
  high('Tinggi', 'Ukuran ~1-2MB, detail maksimal untuk survei teknis');

  final String label;
  final String description;

  const PhotoQualityPreference(this.label, this.description);
}

/// Kualitas Perekaman Video
enum VideoQualityPreference {
  q720p('720p HD', 'Resolusi 1280x720, kompresi ringan & hemat kuota'),
  q1080p('1080p FHD', 'Resolusi 1920x1080, standar tajam dokumentasi lapangan');

  final String label;
  final String description;

  const VideoQualityPreference(this.label, this.description);
}

/// Mode Penamaan Berkas Bukti
enum FileNamingMode {
  automatic('Otomatis', 'Format: [Kegiatan]_[YYYYMMDD]_[HHMMSS]_[Urutan]'),
  custom('Kustom', 'Format: [NamaKustom]_[YYYYMMDD]_[Urutan]');

  final String label;
  final String description;

  const FileNamingMode(this.label, this.description);
}

/// CameraPreferencesEntity
/// ----------------------------------------------------------------------
/// Model data terpadu untuk semua preferensi & kontrol kamera Tulap.id (Phase 4).
/// Menjadi Single Source of Truth bagi:
/// - Top Camera Toolbar
/// - Expandable Camera Control Panel
/// - Full Camera Settings Page
/// ----------------------------------------------------------------------
class CameraPreferencesEntity {
  final CameraAspectRatio aspectRatio;
  final bool gridEnabled;
  final int timerSeconds;
  final bool focusGuideEnabled;
  final bool mirrorFrontCamera;
  final ShutterSoundPreference shutterSoundPreference;
  final CameraWhiteBalanceMode whiteBalance;
  final bool levelEnabled;
  final bool videoAudioEnabled;
  final PhotoQualityPreference photoQuality;
  final VideoQualityPreference videoQuality;
  final FileNamingMode fileNamingMode;
  final String? customFilePrefix;
  final bool saveOriginalMedia;
  final bool volumeButtonShutter;
  final String? customCaption;

  const CameraPreferencesEntity({
    this.aspectRatio = CameraAspectRatio.ratioFull,
    this.gridEnabled = false,
    this.timerSeconds = 0,
    this.focusGuideEnabled = true,
    this.mirrorFrontCamera = true,
    this.shutterSoundPreference = ShutterSoundPreference.system,
    this.whiteBalance = CameraWhiteBalanceMode.auto,
    this.levelEnabled = false,
    this.videoAudioEnabled = true,
    this.photoQuality = PhotoQualityPreference.standard,
    this.videoQuality = VideoQualityPreference.q1080p,
    this.fileNamingMode = FileNamingMode.automatic,
    this.customFilePrefix,
    this.saveOriginalMedia = true,
    this.volumeButtonShutter = true,
    this.customCaption,
  });

  CameraPreferencesEntity copyWith({
    CameraAspectRatio? aspectRatio,
    bool? gridEnabled,
    int? timerSeconds,
    bool? focusGuideEnabled,
    bool? mirrorFrontCamera,
    ShutterSoundPreference? shutterSoundPreference,
    CameraWhiteBalanceMode? whiteBalance,
    bool? levelEnabled,
    bool? videoAudioEnabled,
    PhotoQualityPreference? photoQuality,
    VideoQualityPreference? videoQuality,
    FileNamingMode? fileNamingMode,
    String? customFilePrefix,
    bool? saveOriginalMedia,
    bool? volumeButtonShutter,
    String? customCaption,
  }) {
    return CameraPreferencesEntity(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      gridEnabled: gridEnabled ?? this.gridEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      focusGuideEnabled: focusGuideEnabled ?? this.focusGuideEnabled,
      mirrorFrontCamera: mirrorFrontCamera ?? this.mirrorFrontCamera,
      shutterSoundPreference:
          shutterSoundPreference ?? this.shutterSoundPreference,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      levelEnabled: levelEnabled ?? this.levelEnabled,
      videoAudioEnabled: videoAudioEnabled ?? this.videoAudioEnabled,
      photoQuality: photoQuality ?? this.photoQuality,
      videoQuality: videoQuality ?? this.videoQuality,
      fileNamingMode: fileNamingMode ?? this.fileNamingMode,
      customFilePrefix: customFilePrefix ?? this.customFilePrefix,
      saveOriginalMedia: saveOriginalMedia ?? this.saveOriginalMedia,
      volumeButtonShutter: volumeButtonShutter ?? this.volumeButtonShutter,
      customCaption: customCaption ?? this.customCaption,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aspectRatio': aspectRatio.name,
      'gridEnabled': gridEnabled,
      'timerSeconds': timerSeconds,
      'focusGuideEnabled': focusGuideEnabled,
      'mirrorFrontCamera': mirrorFrontCamera,
      'shutterSoundPreference': shutterSoundPreference.name,
      'whiteBalance': whiteBalance.name,
      'levelEnabled': levelEnabled,
      'videoAudioEnabled': videoAudioEnabled,
      'photoQuality': photoQuality.name,
      'videoQuality': videoQuality.name,
      'fileNamingMode': fileNamingMode.name,
      'customFilePrefix': customFilePrefix,
      'saveOriginalMedia': saveOriginalMedia,
      'volumeButtonShutter': volumeButtonShutter,
      'customCaption': customCaption,
    };
  }

  factory CameraPreferencesEntity.fromMap(Map<String, dynamic> map) {
    return CameraPreferencesEntity(
      aspectRatio: CameraAspectRatio.values.firstWhere(
        (e) => e.name == map['aspectRatio'],
        orElse: () => CameraAspectRatio.ratio4x3,
      ),
      gridEnabled: map['gridEnabled'] as bool? ?? false,
      timerSeconds: map['timerSeconds'] as int? ?? 0,
      focusGuideEnabled: map['focusGuideEnabled'] as bool? ?? true,
      mirrorFrontCamera: map['mirrorFrontCamera'] as bool? ?? true,
      shutterSoundPreference: ShutterSoundPreference.values.firstWhere(
        (e) => e.name == map['shutterSoundPreference'],
        orElse: () => ShutterSoundPreference.system,
      ),
      whiteBalance: CameraWhiteBalanceMode.values.firstWhere(
        (e) => e.name == map['whiteBalance'],
        orElse: () => CameraWhiteBalanceMode.auto,
      ),
      levelEnabled: map['levelEnabled'] as bool? ?? false,
      videoAudioEnabled: map['videoAudioEnabled'] as bool? ?? true,
      photoQuality: PhotoQualityPreference.values.firstWhere(
        (e) => e.name == map['photoQuality'],
        orElse: () => PhotoQualityPreference.standard,
      ),
      videoQuality: VideoQualityPreference.values.firstWhere(
        (e) => e.name == map['videoQuality'],
        orElse: () => VideoQualityPreference.q1080p,
      ),
      fileNamingMode: FileNamingMode.values.firstWhere(
        (e) => e.name == map['fileNamingMode'],
        orElse: () => FileNamingMode.automatic,
      ),
      customFilePrefix: map['customFilePrefix'] as String?,
      saveOriginalMedia: map['saveOriginalMedia'] as bool? ?? true,
      volumeButtonShutter: map['volumeButtonShutter'] as bool? ?? true,
      customCaption: map['customCaption'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CameraPreferencesEntity.fromJson(String source) =>
      CameraPreferencesEntity.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
