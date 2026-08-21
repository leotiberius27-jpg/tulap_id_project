import '../../task_detail/domain/entities/task_entity.dart';

/// HomeCategory
/// ----------------------------------------------------------------------
/// Kategori filter pill di Beranda, DITURUNKAN dari nama tugas yang
/// sudah ada - skema `Task_SPPD` backend belum punya kolom kategori
/// sendiri, jadi ini murni bantuan navigasi visual (mengelompokkan data
/// yang sudah ada), BUKAN data baru dari server. Tugas yang tidak cocok
/// kata kunci mana pun otomatis masuk `lainnya`, tidak pernah hilang
/// dari daftar "Semua".
/// ----------------------------------------------------------------------
enum HomeCategory { semua, perjalananDinas, inspeksi, survei, lainnya }

extension HomeCategoryX on HomeCategory {
  String get label {
    switch (this) {
      case HomeCategory.semua:
        return 'Semua';
      case HomeCategory.perjalananDinas:
        return 'Perjalanan Dinas';
      case HomeCategory.inspeksi:
        return 'Inspeksi';
      case HomeCategory.survei:
        return 'Survei';
      case HomeCategory.lainnya:
        return 'Lainnya';
    }
  }
}

HomeCategory categorizeTask(TaskEntity task) {
  final name = task.taskName.toLowerCase();
  if (name.contains('inspeksi') || name.contains('pemeriksaan')) {
    return HomeCategory.inspeksi;
  }
  if (name.contains('survei') || name.contains('survey')) {
    return HomeCategory.survei;
  }
  if (name.contains('dinas') ||
      name.contains('perjalanan') ||
      name.contains('sppd') ||
      name.contains('kunjungan')) {
    return HomeCategory.perjalananDinas;
  }
  return HomeCategory.lainnya;
}
