import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/network/network_info.dart';
import 'tula_position_store.dart';

export 'tula_position_store.dart' show TulaPosition;

/// Layar/konteks yang dikenali Tula. Dipakai untuk memilih quick actions
/// & salinan kontekstual yang tampil di [TulaBottomSheet].
enum TulaScreenContext {
  home,
  taskList,
  taskDetail,
  history,
  lpj,
  receiptReview,
  general,
}

enum TulaInsightSeverity { info, warning }

/// Ringkasan kelengkapan bukti satu tugas (dipakai layar Detail Tugas)
/// agar Tula bisa menampilkan insight nyata berbasis data yang sudah
/// dimuat controller halaman tersebut - BUKAN data tiruan.
@immutable
class TulaTaskSummary {
  final String taskId;
  final String taskTitle;
  final int checklistTotal;
  final int checklistDone;
  final int evidenceCount;
  final bool hasLocationValid;
  final bool hasReceipt;
  final bool hasNote;

  const TulaTaskSummary({
    required this.taskId,
    required this.taskTitle,
    this.checklistTotal = 0,
    this.checklistDone = 0,
    this.evidenceCount = 0,
    this.hasLocationValid = true,
    this.hasReceipt = false,
    this.hasNote = false,
  });

  int get checklistRemaining =>
      (checklistTotal - checklistDone).clamp(0, checklistTotal);

  bool get isComplete =>
      checklistRemaining == 0 && evidenceCount > 0 && hasReceipt;
}

@immutable
class TulaContextData {
  final TulaScreenContext screen;

  /// true untuk tab utama MainShell (Beranda/Tugas/Riwayat/Akun) yang
  /// punya bottom navigation - dipakai TulaOverlay menghitung offset
  /// posisi vertikal tombol.
  final bool hasBottomNav;
  final TulaTaskSummary? taskSummary;

  const TulaContextData(
    this.screen, {
    this.hasBottomNav = false,
    this.taskSummary,
  });
}

/// TulaVisibilityController
/// ----------------------------------------------------------------------
/// Sumber kebenaran tunggal untuk kapan & bagaimana floating assistant
/// Tula tampil di seluruh aplikasi. Dipasang SEKALI di root MaterialApp
/// lewat TulaOverlay - halaman lain tidak perlu (dan tidak boleh)
/// membuat floating button sendiri, cukup daftarkan konteks/suppress
/// lewat controller ini.
///
/// - `pushContext`/`popContext`: halaman yang di-push penuh layar
///   (Detail Tugas, LPJ) mendaftarkan konteksnya di initState/dispose.
///   Tab utama MainShell (Beranda/Tugas/Riwayat/Akun) TIDAK memakai
///   push/pop karena instance-nya hidup selamanya di dalam
///   `IndexedStack` - MainShell cukup memanggil `setBaseContext` saat
///   tab berpindah.
/// - `suppress`/`unsuppress`: dipakai halaman kamera fullscreen (Geotag
///   & OCR) supaya Tula tersembunyi total selama sesi kamera aktif.
/// - Status online dipantau langsung dari `NetworkInfo` yang sudah ada
///   di project (tidak ada dependency atau API baru).
/// ----------------------------------------------------------------------
class TulaVisibilityController extends ChangeNotifier {
  TulaVisibilityController(this._networkInfo, this._positionStore) {
    _networkInfo.isConnected.then((online) {
      _isOnline = online;
      notifyListeners();
    });
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((online) {
      if (_isOnline == online) return;
      _isOnline = online;
      notifyListeners();
    });
    _positionStore.load().then((saved) {
      if (saved != null) _position = saved;
      _positionLoaded = true;
      notifyListeners();
    });
  }

  final NetworkInfo _networkInfo;
  final TulaPositionStore _positionStore;
  StreamSubscription<bool>? _connectivitySub;

  final List<TulaContextData> _contextStack = [
    const TulaContextData(TulaScreenContext.general),
  ];

  int _suppressCount = 0;
  bool _isOnline = true;
  bool _hasInsight = false;
  TulaInsightSeverity? _insightSeverity;
  String? _insightMessage;
  bool _isSheetOpen = false;
  bool _isTemporarilyHidden = false;

  /// Default sebelum posisi tersimpan berhasil dimuat (kanan bawah,
  /// mendekati posisi aman paling bawah) - lihat Bagian 1 spesifikasi
  /// upgrade Tula draggable.
  TulaPosition _position = const TulaPosition(isLeft: false, verticalRatio: 1.0);
  bool _positionLoaded = false;

  TulaContextData get current => _contextStack.last;
  bool get isSuppressed => _suppressCount > 0;
  bool get isOnline => _isOnline;
  bool get hasInsight => _hasInsight;
  TulaInsightSeverity? get insightSeverity => _insightSeverity;
  String? get insightMessage => _insightMessage;
  bool get isSheetOpen => _isSheetOpen;
  bool get isTemporarilyHidden => _isTemporarilyHidden;
  TulaPosition get position => _position;
  bool get positionLoaded => _positionLoaded;

  /// Insight dianggap kritis (revisi, sync gagal, bukti wajib belum
  /// lengkap) - dalam kondisi ini peek mode TIDAK boleh aktif (Bagian 10).
  bool get isInsightCritical => _hasInsight && _insightSeverity == TulaInsightSeverity.warning;

  void setSheetOpen(bool open) {
    if (_isSheetOpen == open) return;
    _isSheetOpen = open;
    notifyListeners();
  }

  /// Dipanggil TulaOverlay setelah drag selesai & animasi snap dimulai -
  /// posisi disimpan sekali per drag (bukan tiap frame, Bagian 24 -
  /// performa).
  void updatePosition(TulaPosition position) {
    _position = position.clamped();
    notifyListeners();
    _positionStore.save(_position);
  }

  void hideTemporarily() {
    if (_isTemporarilyHidden) return;
    _isTemporarilyHidden = true;
    notifyListeners();
  }

  void unhide() {
    if (!_isTemporarilyHidden) return;
    _isTemporarilyHidden = false;
    notifyListeners();
  }

  /// Dipanggil MainShell tiap kali tab Beranda/Tugas/Riwayat/Akun dipilih.
  void setBaseContext(TulaContextData data) {
    _contextStack[0] = data;
    notifyListeners();
  }

  /// Dipanggil halaman fullscreen yang di-push (Detail Tugas, LPJ, dst).
  void pushContext(TulaContextData data) {
    _contextStack.add(data);
    notifyListeners();
  }

  /// Memperbarui data konteks paling atas tanpa menambah entri baru -
  /// dipakai untuk menyegarkan ringkasan (mis. checklist berubah) tanpa
  /// merusak susunan stack.
  void updateTop(TulaContextData data) {
    if (_contextStack.length <= 1) return;
    _contextStack[_contextStack.length - 1] = data;
    notifyListeners();
  }

  void popContext() {
    if (_contextStack.length <= 1) return;
    _contextStack.removeLast();
    notifyListeners();
  }

  void suppress() {
    _suppressCount++;
    notifyListeners();
  }

  void unsuppress() {
    if (_suppressCount > 0) _suppressCount--;
    notifyListeners();
  }

  /// [message] adalah teks pendek (1-2 baris, Bagian 15) untuk ditampilkan
  /// sekilas lewat TulaInsightBubble ketika insight baru muncul - BUKAN
  /// dipakai untuk badge saja. Kirim `null` jika tidak ada salinan
  /// kontekstual yang perlu ditonjolkan (badge tetap muncul dari [has]).
  void setInsight({
    required bool has,
    TulaInsightSeverity? severity,
    String? message,
  }) {
    if (_hasInsight == has &&
        _insightSeverity == severity &&
        _insightMessage == message) {
      return;
    }
    _hasInsight = has;
    _insightSeverity = severity;
    _insightMessage = has ? message : null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
