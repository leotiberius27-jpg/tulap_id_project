import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/entities/expense_note_entity.dart';
import 'package:tulap_mobile/features/task_detail/domain/entities/task_entity.dart';
import 'package:tulap_mobile/features/travel_mission/data/services/travel_completeness_service.dart';
import 'package:tulap_mobile/features/travel_mission/domain/entities/supporting_document_entity.dart';
import 'package:tulap_mobile/features/travel_mission/domain/entities/travel_mission_entity.dart';

void main() {
  late TravelCompletenessService service;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    service = TravelCompletenessService();
  });

  group('TravelCompletenessService Tests', () {
    final now = DateTime(2026, 8, 28);

    final mission = TravelMissionEntity(
      id: 'travel-1',
      displayId: 'PD-20260828-0001',
      userId: 'user-1',
      assignmentLetterNumber: 'ST/001/2026',
      assignmentLetterDate: now,
      title: 'Koordinasi Lapangan',
      purpose: 'Pelaksanaan koordinasi',
      origin: 'Timika',
      destination: 'Jayapura',
      departureDate: now,
      returnDate: now.add(const Duration(days: 2)),
      transportMode: TravelTransportMode.pesawat,
      status: TravelMissionStatus.ongoing,
      budgetEstimate: const TravelBudgetEstimate(),
      personnelSnapshot: const TravelPersonnelSnapshot(fullName: 'Leo Tiberius'),
      createdAt: now,
    );

    test('should return incomplete with blockers when no activities or docs exist', () {
      final result = service.evaluateCompleteness(
        travel: mission,
        linkedTasks: [],
        directExpenses: [],
        allExpenses: [],
        evidencePhotos: [],
        supportingDocuments: [],
      );

      expect(result.isReadyForLpj, isFalse);
      expect(result.blockers.isNotEmpty, isTrue);
      expect(result.percentage, lessThan(50));
    });

    test('should return 100% and ready when all mandatory documents & activities are present', () {
      final task = TaskEntity(
        id: 'task-1',
        taskCode: 'TSK-001',
        taskName: 'Supervisi Lapangan',
        destination: 'Jayapura',
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        budgetAmount: 1000000,
        status: TaskStatusEntity.completed,
        assigneeId: 'user-1',
        assigneeName: 'Leo Tiberius',
        checklistItems: const [],
        geotagPhotoCount: 1,
        expenseNoteCount: 1,
        travelId: 'travel-1',
        createdAt: now,
      );

      const photo = GeotagPhotoModelWrapper(
        id: 'photo-1',
        taskId: 'task-1',
        localFilePath: '/storage/photo1.jpg',
      );

      final exp = ExpenseNoteEntity(
        id: 'exp-1',
        taskId: 'task-1',
        travelId: 'travel-1',
        localScanPath: '/storage/receipt1.jpg',
        vendorName: 'Hotel Horison',
        transactionDate: now,
        totalAmount: 750000,
        category: ExpenseCategoryEntity.penginapan,
        ocrRawText: 'Hotel Horison 750.000',
        ocrConfidence: 0.95,
        createdAt: now,
      );

      final docLetter = SupportingDocumentEntity(
        id: 'doc-1',
        travelMissionId: 'travel-1',
        documentType: SupportingDocumentType.assignmentLetter,
        title: 'Surat Tugas Resmi',
        filePath: '/storage/st.pdf',
        sha256: 'sha_st',
        createdAt: now,
      );

      final docSppd = SupportingDocumentEntity(
        id: 'doc-2',
        travelMissionId: 'travel-1',
        documentType: SupportingDocumentType.sppd,
        title: 'Lembar SPPD Terverifikasi',
        filePath: '/storage/sppd.pdf',
        sha256: 'sha_sppd',
        createdAt: now,
      );

      final docTicket = SupportingDocumentEntity(
        id: 'doc-3',
        travelMissionId: 'travel-1',
        documentType: SupportingDocumentType.ticket,
        title: 'Tiket Pesawat Garuda',
        filePath: '/storage/ticket.pdf',
        sha256: 'sha_ticket',
        createdAt: now,
      );

      final docBoarding = SupportingDocumentEntity(
        id: 'doc-4',
        travelMissionId: 'travel-1',
        documentType: SupportingDocumentType.boardingPass,
        title: 'Boarding Pass GA-654',
        filePath: '/storage/boarding.jpg',
        sha256: 'sha_bp',
        createdAt: now,
      );

      final result = service.evaluateCompleteness(
        travel: mission,
        linkedTasks: [task],
        directExpenses: [exp],
        allExpenses: [exp],
        evidencePhotos: [photo],
        supportingDocuments: [docLetter, docSppd, docTicket, docBoarding],
      );

      expect(result.percentage, equals(100));
      expect(result.isReadyForLpj, isTrue);
      expect(result.blockers.isEmpty, isTrue);
    });
  });
}
