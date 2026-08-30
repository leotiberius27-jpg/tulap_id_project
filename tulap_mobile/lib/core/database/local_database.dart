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
  static const int _dbVersion = 12;

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
    // --- Tabel geotag_photos (selaras GeotagPhotoModel & Unified Evidence Engine) ---
    await db.execute('''
      CREATE TABLE geotag_photos (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        userId TEXT,
        mediaType TEXT NOT NULL DEFAULT 'PHOTO',
        localFilePath TEXT NOT NULL,
        originalFilePath TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        gpsAccuracyMeters REAL NOT NULL,
        altitude REAL,
        heading REAL,
        serverTimestamp TEXT NOT NULL,
        deviceTimestamp TEXT,
        durationSeconds INTEGER NOT NULL DEFAULT 0,
        integrityHash TEXT NOT NULL,
        originalHash TEXT,
        finalHash TEXT,
        shortEvidenceId TEXT,
        verificationStatus TEXT NOT NULL DEFAULT 'RECORDED',
        verifiedAt TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
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
        userId TEXT,
        localScanPath TEXT NOT NULL,
        localOriginalPath TEXT,
        remoteScanUrl TEXT,
        vendorName TEXT NOT NULL,
        transactionDate TEXT NOT NULL,
        transactionTime TEXT,
        totalAmount REAL NOT NULL,
        subtotal REAL,
        taxAmount REAL,
        discountAmount REAL,
        serviceCharge REAL,
        receiptNumber TEXT,
        category TEXT NOT NULL,
        paymentMethod TEXT,
        notes TEXT,
        ocrRawText TEXT NOT NULL,
        ocrConfidence REAL NOT NULL,
        source TEXT NOT NULL DEFAULT 'camera',
        verificationStatus TEXT NOT NULL DEFAULT 'userConfirmed',
        originalSha256 TEXT,
        processedSha256 TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        serverTimestamp TEXT,
        duplicateOfNoteId TEXT,
        travelId TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_expense_notes_taskId ON expense_notes(taskId)',
    );
    await db.execute(
      'CREATE INDEX idx_expense_notes_travelId ON expense_notes(travelId)',
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
        travelId TEXT,
        startedAt TEXT,
        completedAt TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_tasks_travelId ON tasks(travelId)');

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

    // --- Tabel activity_reports (Laporan Kegiatan Cerdas & LPJ Foundation) ---
    await db.execute('''
      CREATE TABLE activity_reports (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        userId TEXT,
        reportCode TEXT NOT NULL,
        reportType TEXT NOT NULL DEFAULT 'ACTIVITY_REPORT',
        templateId TEXT NOT NULL DEFAULT 'default_activity',
        templateVersion INTEGER NOT NULL DEFAULT 1,
        title TEXT NOT NULL,
        summary TEXT,
        narrative TEXT,
        periodStart TEXT,
        periodEnd TEXT,
        versionNumber INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'GENERATED',
        pdfLocalPath TEXT,
        pdfRemoteUrl TEXT,
        contentSnapshotJson TEXT NOT NULL,
        reportSha256 TEXT NOT NULL,
        totalExpense REAL NOT NULL DEFAULT 0.0,
        evidenceCount INTEGER NOT NULL DEFAULT 0,
        receiptCount INTEGER NOT NULL DEFAULT 0,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        serverTimestamp TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_reports_taskId ON activity_reports(taskId)',
    );
    await db.execute(
      'CREATE INDEX idx_reports_createdAt ON activity_reports(createdAt)',
    );

    // --- Tabel travel_missions (Misi Perjalanan Dinas & SPPD Foundation) ---
    await db.execute('''
      CREATE TABLE travel_missions (
        id TEXT PRIMARY KEY,
        displayId TEXT NOT NULL,
        userId TEXT NOT NULL,
        organizationId TEXT,
        assignmentLetterNumber TEXT NOT NULL,
        assignmentLetterDate TEXT NOT NULL,
        title TEXT NOT NULL,
        purpose TEXT NOT NULL,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        destinations TEXT,
        departureDate TEXT NOT NULL,
        returnDate TEXT NOT NULL,
        transportMode TEXT NOT NULL,
        transportDetails TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        budgetEstimate TEXT,
        notes TEXT,
        personnelSnapshot TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_travel_userId ON travel_missions(userId)');
    await db.execute('CREATE INDEX idx_travel_status ON travel_missions(status)');
    await db.execute('CREATE INDEX idx_travel_dates ON travel_missions(departureDate, returnDate)');

    // --- Tabel supporting_documents (Dokumen Pendukung SPPD / Perjalanan) ---
    await db.execute('''
      CREATE TABLE supporting_documents (
        id TEXT PRIMARY KEY,
        travelMissionId TEXT NOT NULL,
        activityId TEXT,
        documentType TEXT NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        remoteUrl TEXT,
        sha256 TEXT NOT NULL,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_docs_travelId ON supporting_documents(travelMissionId)');
    await db.execute('CREATE INDEX idx_docs_docType ON supporting_documents(documentType)');

    // --- Tabel lpj_packages (Paket Laporan Pertanggungjawaban Resmi) ---
    await db.execute('''
      CREATE TABLE lpj_packages (
        id TEXT PRIMARY KEY,
        travelMissionId TEXT NOT NULL,
        packageCode TEXT NOT NULL,
        versionNumber INTEGER NOT NULL DEFAULT 1,
        title TEXT NOT NULL,
        pdfLocalPath TEXT,
        pdfRemoteUrl TEXT,
        packageSha256 TEXT NOT NULL,
        completenessScore REAL NOT NULL DEFAULT 0.0,
        totalActualExpense REAL NOT NULL DEFAULT 0.0,
        activityCount INTEGER NOT NULL DEFAULT 0,
        evidenceCount INTEGER NOT NULL DEFAULT 0,
        receiptCount INTEGER NOT NULL DEFAULT 0,
        documentCount INTEGER NOT NULL DEFAULT 0,
        contentSnapshotJson TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'generated',
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_lpj_travelId ON lpj_packages(travelMissionId)');
    await db.execute('CREATE INDEX idx_lpj_packageCode ON lpj_packages(packageCode)');

    // --- Tabel search_index (Proyeksi Indeks Pencarian Terpadu Phase 10) ---
    await db.execute('''
      CREATE TABLE search_index (
        entityId TEXT PRIMARY KEY,
        entityType TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        searchableText TEXT NOT NULL,
        normalizedText TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT,
        district TEXT,
        city TEXT,
        province TEXT,
        category TEXT,
        status TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
        thumbnailPath TEXT,
        parentId TEXT,
        metadataJson TEXT,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_search_index_type ON search_index(entityType)');
    await db.execute('CREATE INDEX idx_search_index_date ON search_index(date)');
    await db.execute('CREATE INDEX idx_search_index_location ON search_index(location)');
    await db.execute('CREATE INDEX idx_search_index_status ON search_index(status)');
    await db.execute('CREATE INDEX idx_search_index_category ON search_index(category)');
    await db.execute('CREATE INDEX idx_search_index_parentId ON search_index(parentId)');

    // --- Tabel recent_searches (Riwayat Kata Kunci Pencarian Pengguna) ---
    await db.execute('''
      CREATE TABLE recent_searches (
        id TEXT PRIMARY KEY,
        query TEXT NOT NULL UNIQUE,
        searchedAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_recent_searches_time ON recent_searches(searchedAt DESC)');
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

    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN originalFilePath TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN deviceTimestamp TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN originalHash TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN finalHash TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN shortEvidenceId TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN verificationStatus TEXT NOT NULL DEFAULT 'RECORDED'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN verifiedAt TEXT");
      } catch (_) {}
    }

    if (oldVersion < 8) {
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN userId TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN mediaType TEXT NOT NULL DEFAULT 'PHOTO'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN durationSeconds INTEGER NOT NULL DEFAULT 0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN altitude REAL");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE geotag_photos ADD COLUMN heading REAL");
      } catch (_) {}
    }

    if (oldVersion < 9) {
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN userId TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN localOriginalPath TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN remoteScanUrl TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN transactionTime TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN subtotal REAL");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN discountAmount REAL");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN serviceCharge REAL");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN paymentMethod TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN notes TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN source TEXT NOT NULL DEFAULT 'camera'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN verificationStatus TEXT NOT NULL DEFAULT 'userConfirmed'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN originalSha256 TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN processedSha256 TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN createdAt TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN updatedAt TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_notes ADD COLUMN serverTimestamp TEXT");
      } catch (_) {}
    }

    if (oldVersion < 10) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS activity_reports (
            id TEXT PRIMARY KEY,
            taskId TEXT NOT NULL,
            userId TEXT,
            reportCode TEXT NOT NULL,
            reportType TEXT NOT NULL DEFAULT 'ACTIVITY_REPORT',
            templateId TEXT NOT NULL DEFAULT 'default_activity',
            templateVersion INTEGER NOT NULL DEFAULT 1,
            title TEXT NOT NULL,
            summary TEXT,
            narrative TEXT,
            periodStart TEXT,
            periodEnd TEXT,
            versionNumber INTEGER NOT NULL DEFAULT 1,
            status TEXT NOT NULL DEFAULT 'GENERATED',
            pdfLocalPath TEXT,
            pdfRemoteUrl TEXT,
            contentSnapshotJson TEXT NOT NULL,
            reportSha256 TEXT NOT NULL,
            totalExpense REAL NOT NULL DEFAULT 0.0,
            evidenceCount INTEGER NOT NULL DEFAULT 0,
            receiptCount INTEGER NOT NULL DEFAULT 0,
            syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
            createdAt TEXT NOT NULL,
            updatedAt TEXT,
            serverTimestamp TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_reports_taskId ON activity_reports(taskId)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_reports_createdAt ON activity_reports(createdAt)',
        );
      } catch (_) {}
    }

    if (oldVersion < 11) {
      try {
        await db.execute(
          "ALTER TABLE tasks ADD COLUMN travelId TEXT",
        );
      } catch (_) {}
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tasks_travelId ON tasks(travelId)',
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE expense_notes ADD COLUMN travelId TEXT",
        );
      } catch (_) {}
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expense_notes_travelId ON expense_notes(travelId)',
        );
      } catch (_) {}

      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS travel_missions (
            id TEXT PRIMARY KEY,
            displayId TEXT NOT NULL,
            userId TEXT NOT NULL,
            organizationId TEXT,
            assignmentLetterNumber TEXT NOT NULL,
            assignmentLetterDate TEXT NOT NULL,
            title TEXT NOT NULL,
            purpose TEXT NOT NULL,
            origin TEXT NOT NULL,
            destination TEXT NOT NULL,
            destinations TEXT,
            departureDate TEXT NOT NULL,
            returnDate TEXT NOT NULL,
            transportMode TEXT NOT NULL,
            transportDetails TEXT,
            status TEXT NOT NULL DEFAULT 'draft',
            budgetEstimate TEXT,
            notes TEXT,
            personnelSnapshot TEXT,
            syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_travel_userId ON travel_missions(userId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_travel_status ON travel_missions(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_travel_dates ON travel_missions(departureDate, returnDate)');
      } catch (_) {}

      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS supporting_documents (
            id TEXT PRIMARY KEY,
            travelMissionId TEXT NOT NULL,
            activityId TEXT,
            documentType TEXT NOT NULL,
            title TEXT NOT NULL,
            filePath TEXT NOT NULL,
            remoteUrl TEXT,
            sha256 TEXT NOT NULL,
            syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_docs_travelId ON supporting_documents(travelMissionId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_docs_docType ON supporting_documents(documentType)');
      } catch (_) {}

      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS lpj_packages (
            id TEXT PRIMARY KEY,
            travelMissionId TEXT NOT NULL,
            packageCode TEXT NOT NULL,
            versionNumber INTEGER NOT NULL DEFAULT 1,
            title TEXT NOT NULL,
            pdfLocalPath TEXT,
            pdfRemoteUrl TEXT,
            packageSha256 TEXT NOT NULL,
            completenessScore REAL NOT NULL DEFAULT 0.0,
            totalActualExpense REAL NOT NULL DEFAULT 0.0,
            activityCount INTEGER NOT NULL DEFAULT 0,
            evidenceCount INTEGER NOT NULL DEFAULT 0,
            receiptCount INTEGER NOT NULL DEFAULT 0,
            documentCount INTEGER NOT NULL DEFAULT 0,
            contentSnapshotJson TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'generated',
            syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_lpj_travelId ON lpj_packages(travelMissionId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_lpj_packageCode ON lpj_packages(packageCode)');
      } catch (_) {}
    }

    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS search_index (
            entityId TEXT PRIMARY KEY,
            entityType TEXT NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT,
            searchableText TEXT NOT NULL,
            normalizedText TEXT NOT NULL,
            date TEXT NOT NULL,
            location TEXT,
            district TEXT,
            city TEXT,
            province TEXT,
            category TEXT,
            status TEXT,
            syncStatus TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
            thumbnailPath TEXT,
            parentId TEXT,
            metadataJson TEXT,
            updatedAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_index_type ON search_index(entityType)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_index_date ON search_index(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_index_location ON search_index(location)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_index_status ON search_index(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_index_category ON search_index(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_index_parentId ON search_index(parentId)');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS recent_searches (
            id TEXT PRIMARY KEY,
            query TEXT NOT NULL UNIQUE,
            searchedAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recent_searches_time ON recent_searches(searchedAt DESC)');
      } catch (_) {}
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
    try {
      await db.delete('activity_reports');
    } catch (_) {}
    try {
      await db.delete('travel_missions');
      await db.delete('supporting_documents');
      await db.delete('lpj_packages');
    } catch (_) {}
    try {
      await db.delete('search_index');
      await db.delete('recent_searches');
    } catch (_) {}
  }
}
