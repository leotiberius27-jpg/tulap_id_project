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
  static const int _dbVersion = 6;

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

    // --- Tabel tasks (cache & working storage kegiatan lapangan) ---
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
        assigneeName TEXT NOT NULL,
        isSelfCreated INTEGER NOT NULL DEFAULT 0,
        syncStatus TEXT NOT NULL DEFAULT 'SYNCED',
        syncVersion INTEGER NOT NULL DEFAULT 1,
        startedAt TEXT,
        completedAt TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // --- Tabel activity_timeline_events (linimasa kejadian otomatis) ---
    await db.execute('''
      CREATE TABLE activity_timeline_events (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        eventType TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        eventTimestamp TEXT NOT NULL,
        metadataJson TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY'
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_timeline_taskId ON activity_timeline_events(taskId)',
    );
    await db.execute(
      'CREATE INDEX idx_timeline_timestamp ON activity_timeline_events(eventTimestamp)',
    );

    // --- Tabel activity_notes (Catatan Lapangan) ---
    await db.execute('''
      CREATE TABLE activity_notes (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY'
      )
    ''');
    await db.execute('CREATE INDEX idx_notes_taskId ON activity_notes(taskId)');

    // --- Tabel notifications (Pusat Notifikasi Tulap.id) ---
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        relatedEntityType TEXT,
        relatedEntityId TEXT,
        actionType TEXT,
        actionPayload TEXT,
        priority TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        readAt TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_notifications_userId ON notifications(userId)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_createdAt ON notifications(createdAt)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_isRead ON notifications(isRead)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_category ON notifications(category)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_type ON notifications(type)',
    );
  }

  /// Migrasi non-destruktif antar versi database
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
    if (oldVersion < 3) {
      // 1. Tambahkan tabel activity_timeline_events
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_timeline_events (
          id TEXT PRIMARY KEY,
          taskId TEXT NOT NULL,
          eventType TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          eventTimestamp TEXT NOT NULL,
          metadataJson TEXT,
          syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY'
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_timeline_taskId ON activity_timeline_events(taskId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_timeline_timestamp ON activity_timeline_events(eventTimestamp)',
      );

      // 2. Tambahkan kolom ke tabel tasks (dengan try-catch agar aman jika sudah ada)
      try {
        await db.execute(
          "ALTER TABLE tasks ADD COLUMN isSelfCreated INTEGER NOT NULL DEFAULT 0",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE tasks ADD COLUMN syncStatus TEXT NOT NULL DEFAULT 'SYNCED'",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE tasks ADD COLUMN syncVersion INTEGER NOT NULL DEFAULT 1",
        );
      } catch (_) {}
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_notes (
          id TEXT PRIMARY KEY,
          taskId TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT,
          syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY'
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_taskId ON activity_notes(taskId)',
      );
    }

    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE tasks ADD COLUMN startedAt TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE tasks ADD COLUMN completedAt TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE tasks ADD COLUMN createdAt TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE tasks ADD COLUMN updatedAt TEXT");
      } catch (_) {}
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          category TEXT NOT NULL,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          relatedEntityType TEXT,
          relatedEntityId TEXT,
          actionType TEXT,
          actionPayload TEXT,
          priority TEXT NOT NULL,
          isRead INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          readAt TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_userId ON notifications(userId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_createdAt ON notifications(createdAt)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_isRead ON notifications(isRead)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_category ON notifications(category)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type)',
      );
    }
  }

  /// Dipakai HANYA untuk testing/debugging
  static Future<void> resetForDebug() async {
    final db = await instance;
    await db.delete('geotag_photos');
    await db.delete('expense_notes');
    await db.delete('sync_queue');
    await db.delete('activity_timeline_events');
    await db.delete('activity_notes');
    await db.delete('notifications');
  }
}
