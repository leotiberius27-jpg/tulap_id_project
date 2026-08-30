import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tulap_mobile/features/travel_mission/domain/entities/travel_mission_entity.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('TravelMissionEntity & Duration', () {
    final now = DateTime(2026, 8, 28);
    final returnDate = DateTime(2026, 8, 30);

    final mission = TravelMissionEntity(
      id: 'travel-1',
      displayId: 'PD-20260828-0001',
      userId: 'user-1',
      assignmentLetterNumber: 'ST/001/2026',
      assignmentLetterDate: now,
      title: 'Koordinasi SPPD & LPJ Lapangan',
      purpose: 'Uji Coba Sistem Terpadu',
      origin: 'Timika',
      destination: 'Jayapura',
      departureDate: now,
      returnDate: returnDate,
      transportMode: TravelTransportMode.pesawat,
      status: TravelMissionStatus.ongoing,
      budgetEstimate: const TravelBudgetEstimate(
        transportasi: 2500000,
        uangHarian: 1500000,
        penginapan: 1000000,
      ),
      personnelSnapshot: const TravelPersonnelSnapshot(
        fullName: 'Leo Tiberius',
        employeeNumber: '198501012010011001',
        position: 'Pengawas Teknis',
        unitName: 'Dinas Kominfo',
      ),
      createdAt: now,
    );

    test('should calculate duration in days correctly', () {
      expect(mission.durationDays, equals(3));
    });

    test('should verify if transaction date is within travel period', () {
      expect(mission.isDateWithinTravelPeriod(DateTime(2026, 8, 28)), isTrue);
      expect(mission.isDateWithinTravelPeriod(DateTime(2026, 8, 29)), isTrue);
      expect(mission.isDateWithinTravelPeriod(DateTime(2026, 8, 30)), isTrue);
      expect(mission.isDateWithinTravelPeriod(DateTime(2026, 8, 27)), isFalse);
      expect(mission.isDateWithinTravelPeriod(DateTime(2026, 9, 1)), isFalse);
    });

    test('should calculate total budget estimate correctly', () {
      expect(mission.budgetEstimate.total, equals(5000000.0));
    });
  });
}
