import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../domain/entities/supporting_document_entity.dart';
import '../../domain/entities/travel_completeness_result.dart';
import '../../domain/entities/travel_mission_entity.dart';
import '../../domain/entities/travel_policy_entity.dart';

class TravelCompletenessService {
  TravelCompletenessResult evaluateCompleteness({
    required TravelMissionEntity travel,
    required List<TaskEntity> linkedTasks,
    required List<ExpenseNoteEntity> directExpenses,
    required List<ExpenseNoteEntity> allExpenses,
    required List<GeotagPhotoModelWrapper> evidencePhotos,
    required List<SupportingDocumentEntity> supportingDocuments,
    TravelPolicyEntity policy = TravelPolicyEntity.standard,
  }) {
    final items = <CompletenessChecklistItem>[];
    final blockers = <String>[];
    final warnings = <String>[];

    // 1. Dasar Penugasan (Surat Tugas)
    final hasAssignmentDoc = supportingDocuments.any(
      (d) => d.documentType == SupportingDocumentType.assignmentLetter,
    );
    final hasAssignmentInfo =
        travel.assignmentLetterNumber.trim().isNotEmpty;
    final assignmentCompleted = hasAssignmentInfo && hasAssignmentDoc;

    items.add(
      CompletenessChecklistItem(
        id: 'assignment_letter',
        label: 'Surat Tugas & Dasar Penugasan',
        description: assignmentCompleted
            ? 'Nomor: ${travel.assignmentLetterNumber} (Terlampir)'
            : 'Nomor atau file lampiran surat tugas belum lengkap',
        isMandatory: policy.requireAssignmentLetter,
        isCompleted: assignmentCompleted,
        statusDetail: assignmentCompleted
            ? 'Lengkap'
            : (hasAssignmentInfo ? 'File belum diunggah' : 'Nomor belum diisi'),
      ),
    );

    if (policy.requireAssignmentLetter && !assignmentCompleted) {
      blockers.add('Surat Tugas belum lengkap (Nomor dan Lampiran File wajib ada).');
    }

    // 2. Data Perjalanan & Personil
    final hasTravelInfo =
        travel.origin.trim().isNotEmpty &&
        travel.destination.trim().isNotEmpty &&
        travel.personnelSnapshot.fullName.trim().isNotEmpty;

    items.add(
      CompletenessChecklistItem(
        id: 'travel_info',
        label: 'Data Perjalanan & Personil',
        description: hasTravelInfo
            ? '${travel.origin} -> ${travel.destination} (${travel.durationDays} Hari) - ${travel.personnelSnapshot.fullName}'
            : 'Informasi rute atau personil belum lengkap',
        isMandatory: true,
        isCompleted: hasTravelInfo,
        statusDetail: hasTravelInfo ? 'Lengkap' : 'Belum Lengkap',
      ),
    );

    if (!hasTravelInfo) {
      blockers.add('Informasi rute perjalanan atau personil pelaksana belum lengkap.');
    }

    // 3. Kegiatan Lapangan Terhubung
    final hasLinkedActivity = linkedTasks.isNotEmpty;
    items.add(
      CompletenessChecklistItem(
        id: 'linked_activities',
        label: 'Kegiatan Lapangan',
        description: hasLinkedActivity
            ? '${linkedTasks.length} kegiatan lapangan terhubung'
            : 'Belum ada kegiatan/tugas lapangan yang ditautkan ke perjalanan dinas',
        isMandatory: policy.requireActivity,
        isCompleted: hasLinkedActivity,
        statusDetail: hasLinkedActivity ? '${linkedTasks.length} Kegiatan' : 'Belum Ada',
      ),
    );

    if (policy.requireActivity && !hasLinkedActivity) {
      blockers.add('Minimal 1 kegiatan lapangan wajib ditautkan ke perjalanan dinas ini.');
    }

    // 4. Bukti Dokumentasi Visual (Foto Geotag)
    final totalPhotos = evidencePhotos.length +
        linkedTasks.fold<int>(0, (sum, t) => sum + t.geotagPhotoCount);
    final hasEvidence = totalPhotos > 0;

    items.add(
      CompletenessChecklistItem(
        id: 'evidence_photos',
        label: 'Dokumentasi Visual / Foto Geotag',
        description: hasEvidence
            ? '$totalPhotos bukti foto/video tercatat di kegiatan'
            : 'Belum ada dokumentasi foto ber-watermark/geotag',
        isMandatory: policy.requireEvidencePhoto,
        isCompleted: hasEvidence,
        statusDetail: hasEvidence ? '$totalPhotos Bukti' : 'Belum Ada',
      ),
    );

    if (policy.requireEvidencePhoto && !hasEvidence) {
      blockers.add('Belum ada dokumentasi foto ber-geotag di kegiatan lapangan.');
    }

    // 5. Nota Pengeluaran & Kuitansi Riil
    final totalExpensesCount = allExpenses.length;
    final hasExpenses = totalExpensesCount > 0;

    items.add(
      CompletenessChecklistItem(
        id: 'expense_receipts',
        label: 'Nota & Kuitansi Pengeluaran',
        description: hasExpenses
            ? '$totalExpensesCount nota pengeluaran tercatat'
            : 'Belum ada nota/kuitansi pengeluaran yang dicatat',
        isMandatory: policy.requireExpenseReceipt,
        isCompleted: hasExpenses,
        statusDetail: hasExpenses ? '$totalExpensesCount Nota' : '0 Nota',
      ),
    );

    if (policy.requireExpenseReceipt && !hasExpenses) {
      warnings.add('Belum ada nota pengeluaran yang dicatat untuk perjalanan ini.');
    }

    // 6. Tiket / Boarding Pass (Jika Moda Pesawat / Kereta / Transportasi Umum)
    final isFlightOrPublic =
        travel.transportMode == TravelTransportMode.pesawat ||
        travel.transportMode == TravelTransportMode.transportasiUmum ||
        travel.transportMode == TravelTransportMode.kapal;

    if (isFlightOrPublic) {
      final hasTicketDoc = supportingDocuments.any(
        (d) =>
            d.documentType == SupportingDocumentType.ticket ||
            d.documentType == SupportingDocumentType.boardingPass,
      );

      items.add(
        CompletenessChecklistItem(
          id: 'ticket_boarding_pass',
          label: 'Tiket Perjalanan / Boarding Pass',
          description: hasTicketDoc
              ? 'Tiket/boarding pass telah dilampirkan'
              : 'Disarankan melampirkan tiket/boarding pass untuk moda ${travel.transportMode.label}',
          isMandatory: policy.requireTicketIfFlight,
          isCompleted: hasTicketDoc,
          statusDetail: hasTicketDoc ? 'Terlampir' : 'Belum Terlampir',
        ),
      );

      if (policy.requireTicketIfFlight && !hasTicketDoc) {
        warnings.add('Tiket / boarding pass belum dilampirkan.');
      }
    }

    // 7. Laporan Ringkas / Narasi Pelaksanaan
    final hasNarrativeOrReport =
        (travel.notes != null && travel.notes!.trim().length >= 10) ||
        linkedTasks.any((t) => t.status == TaskStatusEntity.completed);

    items.add(
      CompletenessChecklistItem(
        id: 'activity_narrative',
        label: 'Ringkasan & Catatan Hasil',
        description: hasNarrativeOrReport
            ? 'Catatan/laporan hasil perjalanan dinas tersedia'
            : 'Catatan ringkasan hasil penugasan belum diisi',
        isMandatory: policy.requireActivityReport,
        isCompleted: hasNarrativeOrReport,
        statusDetail: hasNarrativeOrReport ? 'Tersedia' : 'Belum Diisi',
      ),
    );

    if (policy.requireActivityReport && !hasNarrativeOrReport) {
      warnings.add('Catatan ringkasan hasil penugasan belum diisi.');
    }

    // Hitung score & percentage
    final completedCount = items.where((i) => i.isCompleted).length;
    final totalCount = items.length;
    final score = totalCount > 0 ? completedCount / totalCount : 1.0;
    final percentage = (score * 100).round();

    final isReadyForLpj = blockers.isEmpty;

    return TravelCompletenessResult(
      score: score,
      percentage: percentage,
      isReadyForLpj: isReadyForLpj,
      items: items,
      blockers: blockers,
      warnings: warnings,
    );
  }
}

/// Generic wrapper if raw photo entities are passed
class GeotagPhotoModelWrapper {
  final String id;
  final String taskId;
  final String localFilePath;
  final bool isVideo;

  const GeotagPhotoModelWrapper({
    required this.id,
    required this.taskId,
    required this.localFilePath,
    this.isVideo = false,
  });
}
