class DashboardInsightEngine {
  const DashboardInsightEngine();

  List<String> generateInsights({
    required int activityTotal,
    required int activityCompleted,
    required double expenseTotal,
    String? topExpenseCategory,
    String? topLocation,
    required int lpjIncomplete,
    required int pendingSyncCount,
  }) {
    final list = <String>[];

    if (activityTotal > 0) {
      if (activityCompleted == activityTotal) {
        list.add('Seluruh $activityTotal kegiatan lapangan pada periode ini telah selesai diverifikasi.');
      } else {
        list.add('$activityCompleted dari $activityTotal kegiatan lapangan telah selesai dilaksanakan.');
      }
    }

    if (topLocation != null && topLocation.isNotEmpty && topLocation != 'Wilayah Tugas') {
      list.add('Pusat kegiatan utama pada periode ini terkonsentrasi di $topLocation.');
    }

    if (expenseTotal > 0 && topExpenseCategory != null && topExpenseCategory.isNotEmpty) {
      list.add('Alokasi pengeluaran terbesar tercatat pada pos $topExpenseCategory.');
    }

    if (lpjIncomplete > 0) {
      list.add('Terdapat $lpjIncomplete berkas LPJ perjalanan yang perlu dilengkapi dokumen pendukungnya.');
    }

    if (pendingSyncCount > 0) {
      list.add('$pendingSyncCount data bukti tersimpan di perangkat dan siap disinkronkan saat terhubung internet.');
    }

    return list;
  }
}
