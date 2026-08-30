import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../../domain/entities/action_required_entity.dart';
import '../../domain/entities/activity_trend_point.dart';
import '../../domain/entities/dashboard_period.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/entities/expense_category_stat.dart';
import '../../domain/entities/top_location_stat.dart';
import '../../domain/entities/travel_destination_stat.dart';
import '../services/dashboard_insight_engine.dart';

abstract class DashboardLocalDataSource {
  Future<DashboardSummaryEntity> getDashboardAnalytics(DashboardPeriod period);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final Future<Database> Function()? databaseProvider;
  final DashboardInsightEngine insightEngine;

  DashboardLocalDataSourceImpl({
    this.databaseProvider,
    this.insightEngine = const DashboardInsightEngine(),
  });

  Future<Database> get _db =>
      databaseProvider != null ? databaseProvider!() : LocalDatabase.instance;

  @override
  Future<DashboardSummaryEntity> getDashboardAnalytics(DashboardPeriod period) async {
    final db = await _db;

    final startIso = period.startDate.toIso8601String();
    final endIso = period.endDate.toIso8601String();

    // 1. Query Tasks in Period
    final taskRows = await db.rawQuery('''
      SELECT id, taskName, destination, startDate, endDate, status
      FROM tasks
      WHERE startDate >= ? AND startDate <= ?
      ORDER BY startDate DESC
    ''', [startIso, endIso]);

    int activityTotal = taskRows.length;
    int activityCompleted = 0;
    int activityOngoing = 0;
    int revisionNeededCount = 0;

    for (final row in taskRows) {
      final status = (row['status'] as String? ?? '').toLowerCase();
      if (status == 'verified' || status == 'completed') {
        activityCompleted++;
      } else if (status == 'revisionneeded' || status == 'revision_needed') {
        revisionNeededCount++;
        activityOngoing++;
      } else {
        activityOngoing++;
      }
    }

    final activityCompletionRate = activityTotal > 0
        ? double.parse(((activityCompleted / activityTotal) * 100).toStringAsFixed(1))
        : 0.0;

    // 2. Query Geotag Photos in Period
    final photoRows = await db.rawQuery('''
      SELECT id, taskId, latitude, longitude, address, serverTimestamp as capturedAt, syncStatus
      FROM geotag_photos
      WHERE serverTimestamp >= ? AND serverTimestamp <= ?
    ''', [startIso, endIso]);

    final photoCount = photoRows.length;
    final videoCount = 0;
    final evidenceTotal = photoCount;

    // 3. Query Travel Missions in Period
    final travelRows = await db.rawQuery('''
      SELECT id, displayId, destination, departureDate, returnDate, status
      FROM travel_missions
      WHERE departureDate >= ? AND departureDate <= ?
    ''', [startIso, endIso]);

    int travelTotal = travelRows.length;
    int travelCompleted = 0;
    int travelDays = 0;
    int lpjComplete = 0;
    int lpjIncomplete = 0;
    final destinationsMap = <String, int>{};

    for (final row in travelRows) {
      final status = (row['status'] as String? ?? '').toLowerCase();
      final isCompleted = status == 'completed' || status == 'selesai';

      if (isCompleted) {
        travelCompleted++;
        lpjComplete++;
      } else {
        lpjIncomplete++;
      }

      final depStr = row['departureDate'] as String?;
      final retStr = row['returnDate'] as String?;
      if (depStr != null && retStr != null) {
        final dep = DateTime.tryParse(depStr);
        final ret = DateTime.tryParse(retStr);
        if (dep != null && ret != null) {
          final diff = ret.difference(dep).inDays + 1;
          travelDays += diff > 0 ? diff : 1;
        }
      }

      final dest = (row['destination'] as String? ?? 'Lainnya').trim();
      if (dest.isNotEmpty) {
        destinationsMap[dest] = (destinationsMap[dest] ?? 0) + 1;
      }
    }

    final travelDestinations = destinationsMap.entries
        .map((e) => TravelDestinationStat(destination: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // 4. Query Confirmed Expenses in Period
    final expenseRows = await db.rawQuery('''
      SELECT id, totalAmount, category, verificationStatus, createdAt
      FROM expense_notes
      WHERE createdAt >= ? AND createdAt <= ?
    ''', [startIso, endIso]);

    double expenseTotal = 0.0;
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};
    int unconfirmedReceiptCount = 0;

    for (final row in expenseRows) {
      final vStatus = (row['verificationStatus'] as String? ?? '').toLowerCase();
      final isConfirmed = vStatus == 'userconfirmed' ||
          vStatus == 'verified' ||
          vStatus == 'approved';

      if (isConfirmed) {
        final amt = (row['totalAmount'] as num?)?.toDouble() ?? 0.0;
        expenseTotal += amt;
        final cat = _normalizeCategory((row['category'] as String? ?? 'Lainnya'));
        categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + amt;
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      } else {
        unconfirmedReceiptCount++;
      }
    }

    final expenseByCategory = categoryTotals.entries.map((e) {
      final amt = e.value;
      final pct = expenseTotal > 0
          ? double.parse(((amt / expenseTotal) * 100).toStringAsFixed(1))
          : 0.0;
      return ExpenseCategoryStat(
        category: e.key,
        amount: amt,
        percentage: pct,
        count: categoryCounts[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // 5. Query Pending Sync Count
    final syncQueueRows = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue WHERE status = 'PENDING'
    ''');
    final pendingSyncCount = syncQueueRows.isNotEmpty
        ? ((syncQueueRows.first['count'] as num?)?.toInt() ?? 0)
        : 0;

    // 6. Action Required Construction
    final actionRequired = <ActionRequiredEntity>[];

    if (lpjIncomplete > 0) {
      actionRequired.add(
        ActionRequiredEntity(
          type: ActionRequiredType.lpjIncomplete,
          title: '$lpjIncomplete LPJ belum lengkap',
          subtitle: 'Lengkapi dokumen bukti perjalanan dinas',
          count: lpjIncomplete,
          severity: ActionRequiredSeverity.warning,
          filterParams: const {'entityType': 'LPJ', 'status': 'INCOMPLETE'},
        ),
      );
    }

    if (pendingSyncCount > 0) {
      actionRequired.add(
        ActionRequiredEntity(
          type: ActionRequiredType.pendingSync,
          title: '$pendingSyncCount bukti belum tersinkronisasi',
          subtitle: 'Periksa koneksi internet & sinkronkan data',
          count: pendingSyncCount,
          severity: ActionRequiredSeverity.warning,
        ),
      );
    }

    if (unconfirmedReceiptCount > 0) {
      actionRequired.add(
        ActionRequiredEntity(
          type: ActionRequiredType.receiptNeedsReview,
          title: '$unconfirmedReceiptCount nota perlu ditinjau',
          subtitle: 'Periksa hasil pindaian OCR & konfirmasi nominal',
          count: unconfirmedReceiptCount,
          severity: ActionRequiredSeverity.info,
          filterParams: const {'entityType': 'RECEIPT', 'status': 'DRAFT'},
        ),
      );
    }

    if (revisionNeededCount > 0) {
      actionRequired.add(
        ActionRequiredEntity(
          type: ActionRequiredType.activityIncomplete,
          title: '$revisionNeededCount kegiatan perlu perbaikan',
          subtitle: 'Periksa catatan verifikator dan lengkapi bukti',
          count: revisionNeededCount,
          severity: ActionRequiredSeverity.danger,
          filterParams: const {'entityType': 'ACTIVITY', 'status': 'REVISION_NEEDED'},
        ),
      );
    }

    // 7. Compute Activity Trend Points (Daily / Monthly)
    final activityTrend = _computeActivityTrend(taskRows, period);

    // 8. Compute Top Locations
    final topLocations = _computeTopLocations(taskRows, photoRows);

    // 9. Generate Deterministic Traceable Insights
    final insights = insightEngine.generateInsights(
      activityTotal: activityTotal,
      activityCompleted: activityCompleted,
      expenseTotal: expenseTotal,
      topExpenseCategory: expenseByCategory.isNotEmpty ? expenseByCategory.first.category : null,
      topLocation: topLocations.isNotEmpty ? topLocations.first.location : null,
      lpjIncomplete: lpjIncomplete,
      pendingSyncCount: pendingSyncCount,
    );

    return DashboardSummaryEntity(
      period: period,
      activityTotal: activityTotal,
      activityCompleted: activityCompleted,
      activityOngoing: activityOngoing,
      activityCompletionRate: activityCompletionRate,
      photoCount: photoCount,
      videoCount: videoCount,
      evidenceTotal: evidenceTotal,
      travelTotal: travelTotal,
      travelCompleted: travelCompleted,
      travelDays: travelDays,
      expenseTotal: expenseTotal,
      reportCount: activityCompleted,
      lpjComplete: lpjComplete,
      lpjIncomplete: lpjIncomplete,
      actionRequired: actionRequired,
      activityTrend: activityTrend,
      expenseByCategory: expenseByCategory,
      topLocations: topLocations,
      travelDestinations: travelDestinations,
      insights: insights,
      isOfflineDerived: true,
    );
  }

  List<ActivityTrendPoint> _computeActivityTrend(
    List<Map<String, dynamic>> taskRows,
    DashboardPeriod period,
  ) {
    final diffDays = period.endDate.difference(period.startDate).inDays;

    if (diffDays > 60) {
      // Month-based aggregation
      final monthCounts = <String, int>{};
      final monthFormat = DateFormat('MMM', 'id_ID');

      for (final row in taskRows) {
        final startStr = row['startDate'] as String?;
        if (startStr != null) {
          final d = DateTime.tryParse(startStr);
          if (d != null) {
            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
            monthCounts[key] = (monthCounts[key] ?? 0) + 1;
          }
        }
      }

      final points = <ActivityTrendPoint>[];
      var curr = DateTime(period.startDate.year, period.startDate.month, 1);
      while (curr.isBefore(period.endDate) || curr.month == period.endDate.month) {
        final key = '${curr.year}-${curr.month.toString().padLeft(2, '0')}';
        points.add(
          ActivityTrendPoint(
            date: '$key-01',
            label: monthFormat.format(curr),
            count: monthCounts[key] ?? 0,
          ),
        );
        curr = DateTime(curr.year, curr.month + 1, 1);
      }
      return points;
    }

    // Day-based aggregation
    final dayCounts = <String, int>{};
    final dayFormat = DateFormat('d MMM', 'id_ID');

    for (final row in taskRows) {
      final startStr = row['startDate'] as String?;
      if (startStr != null) {
        final d = DateTime.tryParse(startStr);
        if (d != null) {
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          dayCounts[key] = (dayCounts[key] ?? 0) + 1;
        }
      }
    }

    final points = <ActivityTrendPoint>[];
    var curr = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
    final end = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);

    while (!curr.isAfter(end)) {
      final key = '${curr.year}-${curr.month.toString().padLeft(2, '0')}-${curr.day.toString().padLeft(2, '0')}';
      points.add(
        ActivityTrendPoint(
          date: key,
          label: dayFormat.format(curr),
          count: dayCounts[key] ?? 0,
        ),
      );
      curr = curr.add(const Duration(days: 1));
    }

    return points;
  }

  List<TopLocationStat> _computeTopLocations(
    List<Map<String, dynamic>> taskRows,
    List<Map<String, dynamic>> photoRows,
  ) {
    final locationCounts = <String, int>{};
    final latSums = <String, double>{};
    final lngSums = <String, double>{};

    for (final row in taskRows) {
      final dest = row['destination'] as String? ?? 'Wilayah Tugas';
      final loc = _extractCityOrLocation(dest);
      locationCounts[loc] = (locationCounts[loc] ?? 0) + 1;
    }

    for (final row in photoRows) {
      final addr = row['address'] as String? ??
          row['city'] as String? ??
          row['district'] as String?;
      if (addr != null && addr.isNotEmpty) {
        final loc = _extractCityOrLocation(addr);
        locationCounts[loc] = (locationCounts[loc] ?? 0) + 1;
        final lat = (row['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (row['longitude'] as num?)?.toDouble() ?? 0.0;
        if (lat != 0.0 && lng != 0.0) {
          latSums[loc] = (latSums[loc] ?? 0.0) + lat;
          lngSums[loc] = (lngSums[loc] ?? 0.0) + lng;
        }
      }
    }

    return locationCounts.entries.map((e) {
      final loc = e.key;
      final count = e.value;
      final hasCoords = latSums.containsKey(loc) && count > 0;
      return TopLocationStat(
        location: loc,
        count: count,
        latitude: hasCoords ? latSums[loc]! / count : null,
        longitude: hasCoords ? lngSums[loc]! / count : null,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  String _normalizeCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('transport') || c.contains('tiket') || c.contains('taxi')) return 'Transportasi';
    if (c.contains('hotel') || c.contains('inap') || c.contains('penginapan')) return 'Penginapan';
    if (c.contains('bbm') || c.contains('bensin') || c.contains('solar') || c.contains('bahan bakar')) return 'BBM';
    if (c.contains('makan') || c.contains('konsumsi') || c.contains('resto') || c.contains('kuliner')) return 'Konsumsi';
    return 'Lainnya';
  }

  String _extractCityOrLocation(String addr) {
    if (addr.isEmpty) return 'Wilayah Tugas';
    final parts = addr.split(',').map((p) => p.trim()).toList();
    for (final part in parts) {
      final p = part.toLowerCase();
      if (p.contains('mimika') ||
          p.contains('timika') ||
          p.contains('jayapura') ||
          p.contains('nabire') ||
          p.contains('merauke') ||
          p.contains('jakarta') ||
          p.contains('surabaya')) {
        return part;
      }
    }
    return parts.last.isNotEmpty ? parts.last : parts.first;
  }
}
