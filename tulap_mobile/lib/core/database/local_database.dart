import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// LocalDatabase
/// ----------------------------------------------------------------------
/// Titik inisialisasi TUNGGAL untuk database SQLite lokal Tulap.id.
/// Seluruh fitur (geotag_camera, expense_ocr, sync_queue) berbagi satu
/// instance Database yang sama - didapat lewat `LocalDatabase.instance`,
/// bukan membuka koneksi SQLite terpisah per fitur.
///
/// Skema di sini WAJIB selaras dengan model masing-masing fitur:
///   - geotag_photos  <-> GeotagPhotoModel
///   - expense_notes  <-> ExpenseNoteModel
///   - sync_queue     <-> SyncRecordModel
/// ----------------------------------------------------------------------
class LocalDatabase {
  static const String _dbName = 'tulap_local.db';
  static const int _dbVersion = 2;

  static Database? _database;

  LocalDatabase._();

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Aktifkan foreign key constraint - SQLite mematikannya secara
        // default kecuali diaktifkan eksplisit per koneksi.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // --- Tabel geotag_photos (selaras GeotagPhotoModel) ---
    await db.execute('''
      CREATE TABLE geotag_photos (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        localFilePath TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        gpsAccuracyMeters REAL NOT NULL,
        serverTimestamp TEXT NOT NULL,
        integrityHash TEXT NOT NULL,
        isMockLocationDetected INTEGER NOT NULL DEFAULT 0,
        isRootedDeviceDetected INTEGER NOT NULL DEFAULT 0,
        plusCode TEXT NOT NULL DEFAULT '',
        address TEXT,
        caption TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_geotag_photos_taskId ON geotag_photos(taskId)',
    );

    // --- Tabel expense_notes (selaras ExpenseNoteModel) ---
    await db.execute('''
      CREATE TABLE expense_notes (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        localScanPath TEXT NOT NULL,
        vendorName TEXT NOT NULL,
        transactionDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        taxAmount REAL,
        receiptNumber TEXT,
        category TEXT NOT NULL,
        ocrRawText TEXT NOT NULL,
        ocrConfidence REAL NOT NULL,
        duplicateOfNoteId TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_expense_notes_taskId ON expense_notes(taskId)',
    );

    // --- Tabel sync_queue (selaras SyncRecordModel, pola outbox) ---
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        entityType TEXT NOT NULL,
        entityLocalId TEXT NOT NULL,
        taskId TEXT NOT NULL,
        status TEXT NOT NULL,
        attemptCount INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        lastAttemptAt TEXT,
        lastErrorMessage TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sync_queue_status ON sync_queue(status)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_taskId ON sync_queue(taskId)',
    );

    // --- Tabel task_checklist_items (cache lokal, sumber kebenaran di backend) ---
    // Diisi saat tugas disinkronkan dari server (GET /tasks/:id/checklist),
    // diupdate lokal saat pegawai mencentang item (offline-first), lalu
    // perubahan `isCompleted` didaftarkan ke sync_queue seperti entity
    // lain. Skema selaras dengan Task_Checklist_Item di backend.
    await db.execute('''
      CREATE TABLE task_checklist_items (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        label TEXT NOT NULL,
        "order" INTEGER NOT NULL,
        isMandatory INTEGER NOT NULL DEFAULT 1,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        completedAt TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_checklist_items_taskId ON task_checklist_items(taskId)',
    );

    // --- Tabel tasks (cache lokal ringkas, sumber kebenaran di backend) ---
    // Menyimpan cache tugas terakhir dibuka agar tetap bisa diakses
    // offline (Bagian 4 dokumen requirement awal). Field ini SENGAJA
    // ringkas (tidak menduplikasi seluruh kolom backend) - relasi
    // checklist/foto/nota dihitung dari tabel masing-masing saat dibaca.
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        taskCode TEXT NOT NULL,
        taskName TEXT NOT NULL,
        destination TEXT NOT NULL,
        description TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        budgetAmount REAL NOT NULL,
        status TEXT NOT NULL,
        assigneeId TEXT NOT NULL,
        assigneeName TEXT NOT NULL
      )
    ''');
  }

  /// Ditempatkan agar siap dipakai saat skema perlu berubah di rilis
  /// mendatang - migrasi versi lama ke baru WAJIB non-destruktif
  /// (pakai ALTER TABLE, bukan DROP+CREATE) karena ini data pengguna
  /// yang belum tentu sudah tersinkron ke server.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE geotag_photos ADD COLUMN plusCode TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  /// Dipakai HANYA untuk testing/debugging - menghapus seluruh data
  /// lokal. TIDAK PERNAH dipanggil dari alur produksi normal.
  static Future<void> resetForDebug() async {
    final db = await instance;
    await db.delete('geotag_photos');
    await db.delete('expense_notes');
    await db.delete('sync_queue');
  }
}
