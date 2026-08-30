import 'package:intl/intl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../expense_ocr/data/datasources/expense_ocr_local_datasource.dart';
import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import '../../../geotag_camera/domain/entities/geotag_photo_entity.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/data/datasources/timeline_local_datasource.dart';
import '../../../task_detail/domain/entities/activity_note_entity.dart';
import '../../../task_detail/domain/entities/timeline_event_entity.dart';
import '../../domain/entities/report_draft_data.dart';
import '../../domain/entities/report_template_entity.dart';

class ReportDataAssembler {
  final GeotagCameraLocalDataSource _cameraLocalDataSource;
  final ExpenseOcrLocalDataSource _expenseLocalDataSource;
  final TimelineLocalDataSource _timelineLocalDataSource;
  final AuthRepository _authRepository;

  ReportDataAssembler({
    required GeotagCameraLocalDataSource cameraLocalDataSource,
    required ExpenseOcrLocalDataSource expenseLocalDataSource,
    required TimelineLocalDataSource timelineLocalDataSource,
    required AuthRepository authRepository,
  })  : _cameraLocalDataSource = cameraLocalDataSource,
        _expenseLocalDataSource = expenseLocalDataSource,
        _timelineLocalDataSource = timelineLocalDataSource,
        _authRepository = authRepository;

  Future<ReportDraftData> assemble(TaskEntity task) async {
    // 1. Ambil bukti dokumentasi foto/video
    final photos = await _cameraLocalDataSource.getPhotosByTask(task.id);

    // 2. Ambil bukti pengeluaran keuangan (konfirmasi)
    final expenses = await _expenseLocalDataSource.getNotesByTask(task.id);

    // 3. Ambil linimasa kejadian (urut kronologis)
    final timelineModels = await _timelineLocalDataSource.getEventsByTask(task.id);
    // Filter noise teknis internal (hanya simpan kejadian resmi)
    final cleanTimeline = timelineModels
        .where((e) =>
            e.eventType != TimelineEventType.syncCompleted &&
            !e.title.toLowerCase().contains('retry') &&
            !e.title.toLowerCase().contains('sqlite'))
        .toList();

    // 4. Ambil profil user saat ini (untuk snapshot identitas pelaksana)
    final user = await _authRepository.getStoredUser();

    // 5. Hitung total realisasi pengeluaran numerik
    final totalExpense = expenses.fold<double>(
      0.0,
      (sum, note) => sum + note.totalAmount,
    );

    final photoCount = photos.where((p) => !p.isVideo).length;
    final videoCount = photos.where((p) => p.isVideo).length;
    final receiptCount = expenses.length;

    // 6. Buat narasi ringkasan deterministik (tidak mengarang fakta)
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final startStr = dateFormat.format(task.startDate);
    final endStr = dateFormat.format(task.endDate);
    final dateRangeStr = task.startDate.year == task.endDate.year &&
            task.startDate.month == task.endDate.month &&
            task.startDate.day == task.endDate.day
        ? startStr
        : '$startStr s/d $endStr';

    final StringBuffer narrativeBuffer = StringBuffer();
    narrativeBuffer.write(
      'Kegiatan "${task.taskName}" (No. Tugas: ${task.taskCode}) dilaksanakan pada periode $dateRangeStr dengan lokasi tujuan di ${task.destination}. ',
    );

    if (task.description != null && task.description!.isNotEmpty) {
      narrativeBuffer.write('${task.description!}. ');
    }

    narrativeBuffer.write(
      'Selama pelaksanaan kegiatan lapangan, telah terdokumentasi sebanyak $photoCount foto bukti geotag terverifikasi',
    );

    if (videoCount > 0) {
      narrativeBuffer.write(', $videoCount rekaman video kondisi lapangan');
    }

    if (receiptCount > 0) {
      narrativeBuffer.write(
        ', serta $receiptCount bukti nota transaksi keuangan dengan total realisasi pengeluaran sebesar ${currencyFormat.format(totalExpense)}',
      );
    } else {
      narrativeBuffer.write(', tanpa catatan pengeluaran biaya tambahan');
    }

    narrativeBuffer.write('. Seluruh data tersimpan secara sah dalam sistem Tulap.id.');

    final reportTitle = 'LAPORAN PELAKSANAAN TUGAS LAPANGAN\n${task.taskName.toUpperCase()}';

    return ReportDraftData(
      task: task,
      user: user,
      title: reportTitle,
      narrative: narrativeBuffer.toString(),
      selectedEvidence: photos,
      selectedExpenses: expenses,
      selectedTimelineEvents: cleanTimeline,
      selectedNotes: const [],
      template: ReportTemplateEntity.defaultActivity.copyWith(
        institutionName: user?.instansiName ?? 'PEMERINTAH KABUPATEN MIMIKA',
        workUnit: 'DINAS KOMUNIKASI DAN INFORMATIKA',
      ),
      supervisorName: 'Nama Atasan / PPK',
      supervisorTitle: 'Pejabat Pembuat Komitmen',
      implementerName: user?.fullName ?? task.assigneeName,
      implementerTitle: user?.nip != null && user!.nip!.isNotEmpty
          ? 'NIP. ${user.nip}'
          : 'Pelaksana Lapangan',
      assembledAt: DateTime.now(),
    );
  }
}
