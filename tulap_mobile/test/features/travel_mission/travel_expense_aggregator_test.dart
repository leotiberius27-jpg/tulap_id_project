import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/features/expense_ocr/domain/entities/expense_note_entity.dart';
import 'package:tulap_mobile/features/travel_mission/data/services/travel_expense_aggregator.dart';
import 'package:tulap_mobile/features/travel_mission/domain/entities/travel_mission_entity.dart';

void main() {
  late TravelExpenseAggregator aggregator;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    aggregator = TravelExpenseAggregator();
  });

  group('TravelExpenseAggregator Tests', () {
    final now = DateTime(2026, 8, 28);

    final mission = TravelMissionEntity(
      id: 'travel-1',
      displayId: 'PD-20260828-0001',
      userId: 'user-1',
      assignmentLetterNumber: 'ST/001/2026',
      assignmentLetterDate: now,
      title: 'Koordinasi SPPD',
      purpose: 'Pelaksanaan koordinasi',
      origin: 'Timika',
      destination: 'Jayapura',
      departureDate: now,
      returnDate: now.add(const Duration(days: 2)),
      transportMode: TravelTransportMode.pesawat,
      status: TravelMissionStatus.ongoing,
      budgetEstimate: const TravelBudgetEstimate(
        transportasi: 2000000,
        penginapan: 1000000,
      ),
      personnelSnapshot: const TravelPersonnelSnapshot(fullName: 'Leo Tiberius'),
      createdAt: now,
    );

    test('should aggregate direct and activity expenses without duplicate double counting', () {
      final directExp = ExpenseNoteEntity(
        id: 'exp-direct-1',
        taskId: 'travel-1',
        travelId: 'travel-1',
        localScanPath: '/storage/taxi.jpg',
        vendorName: 'Bandara Mozes Kilangin (Taxi)',
        transactionDate: now,
        totalAmount: 150000,
        category: ExpenseCategoryEntity.transportasiLain,
        ocrRawText: 'Taxi 150.000',
        ocrConfidence: 0.9,
        createdAt: now,
      );

      final actExp = ExpenseNoteEntity(
        id: 'exp-act-1',
        taskId: 'task-1',
        travelId: 'travel-1',
        localScanPath: '/storage/hotel.jpg',
        vendorName: 'Hotel Horison Ultima',
        transactionDate: now.add(const Duration(days: 1)),
        totalAmount: 850000,
        category: ExpenseCategoryEntity.penginapan,
        ocrRawText: 'Hotel Horison 850.000',
        ocrConfidence: 0.95,
        createdAt: now,
      );

      final summary = aggregator.aggregateExpenses(
        travel: mission,
        directExpenses: [directExp],
        activityExpenses: [actExp],
      );

      expect(summary.totalActualExpense, equals(1000000.0));
      expect(summary.estimatedBudget, equals(3000000.0));
      expect(summary.varianceAmount, equals(2000000.0));
      expect(summary.totalReceiptCount, equals(2));
      expect(summary.anomalies.isEmpty, isTrue);
    });

    test('should flag anomaly when receipt date is outside travel departure-return window', () {
      final outOfWindowExp = ExpenseNoteEntity(
        id: 'exp-invalid-date',
        taskId: 'travel-1',
        travelId: 'travel-1',
        localScanPath: '/storage/cafe.jpg',
        vendorName: 'Cafe Luar Jadwal',
        transactionDate: DateTime(2026, 9, 10), // Jauh setelah returnDate
        totalAmount: 200000,
        category: ExpenseCategoryEntity.konsumsi,
        ocrRawText: 'Cafe Luar 200.000',
        ocrConfidence: 0.9,
        createdAt: now,
      );

      final summary = aggregator.aggregateExpenses(
        travel: mission,
        directExpenses: [outOfWindowExp],
        activityExpenses: [],
      );

      expect(summary.anomalies.isNotEmpty, isTrue);
      expect(summary.anomalies.first.id, equals('date_exp-invalid-date'));
    });
  });
}
