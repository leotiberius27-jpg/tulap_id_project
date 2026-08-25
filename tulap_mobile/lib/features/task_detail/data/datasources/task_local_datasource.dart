import 'package:sqflite/sqflite.dart';
import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

/// TaskLocalDataSource
/// ----------------------------------------------------------------------
/// Menyimpan cache tugas & checklist secara lokal di database SQLite.
/// Mendukung operasional offline-first penuh, termasuk penyediaan data
/// tugas awal jika perangkat belum terhubung ke server.
/// ----------------------------------------------------------------------
class TaskLocalDataSource {
  final Database _database;
  TaskLocalDataSource(this._database);

  Future<void> cacheTask(TaskModel task) async {
    await _database.insert(
      'tasks',
      task.toCacheMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TaskModel?> getCachedTask(String taskId) async {
    var rows = await _database.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );

    if (rows.isEmpty) {
      await _ensureSampleTasksSeeded();
      rows = await _database.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
    }

    if (rows.isEmpty) return null;

    final checklistItems = await getChecklistItems(taskId);
    final photoCountResult = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM geotag_photos WHERE taskId = ?',
      [taskId],
    );
    final noteCountResult = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM expense_notes WHERE taskId = ?',
      [taskId],
    );

    return TaskModel.fromCacheMap(
      rows.first,
      checklistItems,
      Sqflite.firstIntValue(photoCountResult) ?? 0,
      Sqflite.firstIntValue(noteCountResult) ?? 0,
    );
  }

  Future<List<TaskModel>> getAllCachedTasks() async {
    var rows = await _database.query('tasks', orderBy: 'startDate DESC');
    if (rows.isEmpty) {
      await _ensureSampleTasksSeeded();
      rows = await _database.query('tasks', orderBy: 'startDate DESC');
    }

    final List<TaskModel> result = [];
    for (final row in rows) {
      final taskId = row['id'] as String;
      final checklist = await getChecklistItems(taskId);
      final photoCountResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM geotag_photos WHERE taskId = ?',
        [taskId],
      );
      final noteCountResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM expense_notes WHERE taskId = ?',
        [taskId],
      );
      result.add(
        TaskModel.fromCacheMap(
          row,
          checklist,
          Sqflite.firstIntValue(photoCountResult) ?? 0,
          Sqflite.firstIntValue(noteCountResult) ?? 0,
        ),
      );
    }
    return result;
  }

  Future<void> cacheChecklistItems(List<ChecklistItemModel> items) async {
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        'task_checklist_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChecklistItemModel>> getChecklistItems(String taskId) async {
    final rows = await _database.query(
      'task_checklist_items',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: '"order" ASC',
    );
    return rows.map((row) => ChecklistItemModel.fromJson(row)).toList();
  }

  Future<void> updateChecklistItemLocal(String itemId, bool isCompleted) async {
    await _database.update(
      'task_checklist_items',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> _ensureSampleTasksSeeded() async {
    final countResult = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM tasks',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count > 0) return;

    final sampleTasks = [
      TaskModel(
        id: 'TL-202608-0001',
        taskCode: 'TLP-2026-08-001',
        taskName: 'Monitoring Kendaraan Dinas',
        destination: 'Jl. Cenderawasih, Timika',
        description:
            'Pemeriksaan kelayakan operasional dan fisik kendaraan dinas BPKAD Kabupaten Mimika.',
        startDate: DateTime.now().subtract(const Duration(hours: 2)),
        endDate: DateTime.now().add(const Duration(hours: 4)),
        budgetAmount: 1500000,
        status: TaskStatusEntity.ongoing,
        assigneeId: 'usr_local_01',
        assigneeName: 'Leonardo',
        checklistItems: const [
          ChecklistItemModel(
            id: 'chk-01',
            taskId: 'TL-202608-0001',
            label: 'Pemeriksaan fisik eksterior kendaraan',
            order: 1,
            isMandatory: true,
            isCompleted: true,
          ),
          ChecklistItemModel(
            id: 'chk-02',
            taskId: 'TL-202608-0001',
            label: 'Cek odometer dan indikator bahan bakar',
            order: 2,
            isMandatory: true,
            isCompleted: true,
          ),
          ChecklistItemModel(
            id: 'chk-03',
            taskId: 'TL-202608-0001',
            label: 'Dokumentasi foto geotag kamera lapangan',
            order: 3,
            isMandatory: true,
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'chk-04',
            taskId: 'TL-202608-0001',
            label: 'Pencatatan nota pengeluaran BBM & servis',
            order: 4,
            isMandatory: false,
            isCompleted: false,
          ),
        ],
        geotagPhotoCount: 4,
        expenseNoteCount: 0,
      ),
      TaskModel(
        id: 'TL-202608-0002',
        taskCode: 'TLP-2026-08-002',
        taskName: 'Survey Aset Tanah',
        destination: 'Kecamatan Mimika Baru',
        description:
            'Verifikasi tapal batas dan koordinat GPS aset tanah pemerintah daerah.',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        budgetAmount: 2500000,
        status: TaskStatusEntity.draft,
        assigneeId: 'usr_local_01',
        assigneeName: 'Leonardo',
        checklistItems: const [
          ChecklistItemModel(
            id: 'chk-05',
            taskId: 'TL-202608-0002',
            label: 'Pengukuran batas tanah dengan patok',
            order: 1,
            isMandatory: true,
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'chk-06',
            taskId: 'TL-202608-0002',
            label: 'Pengambilan foto geotag sudut batas',
            order: 2,
            isMandatory: true,
            isCompleted: false,
          ),
        ],
        geotagPhotoCount: 0,
        expenseNoteCount: 0,
      ),
      TaskModel(
        id: 'TL-202608-0003',
        taskCode: 'TLP-2026-08-003',
        taskName: 'Pemeriksaan Aset Bangunan',
        destination: 'Distrik Kuala Kencana',
        description: 'Audit kondisi struktural fasilitas gedung perkantoran.',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        budgetAmount: 3000000,
        status: TaskStatusEntity.verified,
        assigneeId: 'usr_local_01',
        assigneeName: 'Leonardo',
        checklistItems: const [
          ChecklistItemModel(
            id: 'chk-07',
            taskId: 'TL-202608-0003',
            label: 'Inspeksi pondasi dan dinding',
            order: 1,
            isMandatory: true,
            isCompleted: true,
          ),
        ],
        geotagPhotoCount: 0,
        expenseNoteCount: 0,
      ),
    ];

    for (final task in sampleTasks) {
      await cacheTask(task);
      await cacheChecklistItems(
        task.checklistItems
            .map((e) => ChecklistItemModel.fromEntity(e))
            .toList(),
      );
    }

    // Seed 4 sample geotag photos untuk task TL-202608-0001
    final samplePhotos = [
      {
        'id': 'photo-sample-01',
        'taskId': 'TL-202608-0001',
        'localFilePath': 'assets/images/referensi/01.png',
        'latitude': -4.546123,
        'longitude': 136.887421,
        'gpsAccuracyMeters': 5.0,
        'serverTimestamp': DateTime.now()
            .subtract(const Duration(minutes: 45))
            .toIso8601String(),
        'integrityHash': 'sha256_mock_hash_photo_1',
        'isMockLocationDetected': 0,
        'isRootedDeviceDetected': 0,
        'plusCode': '6P28+3Q Timika',
        'address': 'Jl. Cenderawasih, Timika, Papua',
        'caption': '1. Tampak Depan Kendaraan Dinas',
      },
      {
        'id': 'photo-sample-02',
        'taskId': 'TL-202608-0001',
        'localFilePath': 'assets/images/referensi/02.png',
        'latitude': -4.546135,
        'longitude': 136.887430,
        'gpsAccuracyMeters': 6.0,
        'serverTimestamp': DateTime.now()
            .subtract(const Duration(minutes: 35))
            .toIso8601String(),
        'integrityHash': 'sha256_mock_hash_photo_2',
        'isMockLocationDetected': 0,
        'isRootedDeviceDetected': 0,
        'plusCode': '6P28+3Q Timika',
        'address': 'Jl. Cenderawasih, Timika, Papua',
        'caption': '2. Dashboard & Odometer Kendaraan',
      },
      {
        'id': 'photo-sample-03',
        'taskId': 'TL-202608-0001',
        'localFilePath': 'assets/images/hero_illustration.png',
        'latitude': -4.546110,
        'longitude': 136.887410,
        'gpsAccuracyMeters': 4.5,
        'serverTimestamp': DateTime.now()
            .subtract(const Duration(minutes: 25))
            .toIso8601String(),
        'integrityHash': 'sha256_mock_hash_photo_3',
        'isMockLocationDetected': 0,
        'isRootedDeviceDetected': 0,
        'plusCode': '6P28+3Q Timika',
        'address': 'Jl. Cenderawasih, Timika, Papua',
        'caption': '3. Pemeriksaan Kondisi Samping & Ban',
      },
      {
        'id': 'photo-sample-04',
        'taskId': 'TL-202608-0001',
        'localFilePath': 'assets/images/referensi/01.png',
        'latitude': -4.546140,
        'longitude': 136.887440,
        'gpsAccuracyMeters': 5.5,
        'serverTimestamp': DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toIso8601String(),
        'integrityHash': 'sha256_mock_hash_photo_4',
        'isMockLocationDetected': 0,
        'isRootedDeviceDetected': 0,
        'plusCode': '6P28+3Q Timika',
        'address': 'Jl. Cenderawasih, Timika, Papua',
        'caption': '4. Nomor Polisi & Bukti Fisik Kendaraan',
      },
    ];

    for (final photo in samplePhotos) {
      await _database.insert(
        'geotag_photos',
        photo,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
