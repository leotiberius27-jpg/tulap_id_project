import '../../../expense_ocr/domain/entities/expense_note_entity.dart';
import '../../domain/entities/travel_expense_summary.dart';
import '../../domain/entities/travel_mission_entity.dart';

class TravelExpenseAggregator {
  TravelExpenseSummary aggregateExpenses({
    required TravelMissionEntity travel,
    required List<ExpenseNoteEntity> directExpenses,
    required List<ExpenseNoteEntity> activityExpenses,
  }) {
    // Deduplicate any overlapping notes by id
    final seen = <String>{};
    final uniqueDirect = <ExpenseNoteEntity>[];
    for (final note in directExpenses) {
      if (seen.add(note.id)) {
        uniqueDirect.add(note);
      }
    }

    final uniqueActivity = <ExpenseNoteEntity>[];
    for (final note in activityExpenses) {
      if (seen.add(note.id)) {
        uniqueActivity.add(note);
      }
    }

    final allExpenses = [...uniqueDirect, ...uniqueActivity];

    // Calculate totals
    double directSum = 0.0;
    for (final n in uniqueDirect) {
      directSum += n.totalAmount;
    }

    double activitySum = 0.0;
    for (final n in uniqueActivity) {
      activitySum += n.totalAmount;
    }

    final totalActual = directSum + activitySum;
    final estimated = travel.budgetEstimate.total;
    final variance = estimated - totalActual;

    // Category breakdown
    final breakdown = <ExpenseCategoryEntity, double>{};
    for (final cat in ExpenseCategoryEntity.values) {
      breakdown[cat] = 0.0;
    }
    for (final n in allExpenses) {
      breakdown[n.category] = (breakdown[n.category] ?? 0.0) + n.totalAmount;
    }

    // Detect anomalies
    final anomalies = <TravelExpenseAnomaly>[];

    for (final n in allExpenses) {
      // 1. Date outside travel window
      if (!travel.isDateWithinTravelPeriod(n.transactionDate)) {
        anomalies.add(
          TravelExpenseAnomaly(
            id: 'date_${n.id}',
            title: 'Tanggal Nota di Luar Jadwal',
            description:
                'Nota "${n.vendorName}" (${n.transactionDate.day}/${n.transactionDate.month}/${n.transactionDate.year}) berada di luar jadwal perjalanan (${travel.formattedPeriod}).',
            isBlocker: false,
          ),
        );
      }

      // 2. Duplicate detected
      if (n.isPossibleDuplicate) {
        anomalies.add(
          TravelExpenseAnomaly(
            id: 'dup_${n.id}',
            title: 'Terindikasi Duplikat',
            description:
                'Nota "${n.vendorName}" (Rp ${n.totalAmount.toInt()}) terindikasi duplikasi dengan nota lain.',
            isBlocker: true,
          ),
        );
      }

      // 3. Low OCR confidence unconfirmed
      if (n.verificationStatus == ExpenseVerificationStatus.ocrExtracted &&
          n.ocrConfidence < 0.7) {
        anomalies.add(
          TravelExpenseAnomaly(
            id: 'ocr_${n.id}',
            title: 'Perlu Konfirmasi Nominal',
            description:
                'Hasil pembacaan OCR nota "${n.vendorName}" memiliki tingkat keyakinan rendah dan belum dikonfirmasi.',
            isBlocker: false,
          ),
        );
      }
    }

    return TravelExpenseSummary(
      directExpenses: uniqueDirect,
      activityExpenses: uniqueActivity,
      totalDirectAmount: directSum,
      totalActivityAmount: activitySum,
      totalActualExpense: totalActual,
      estimatedBudget: estimated,
      varianceAmount: variance,
      categoryBreakdown: breakdown,
      anomalies: anomalies,
    );
  }
}
