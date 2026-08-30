import '../../domain/entities/search_result_entity.dart';

/// SemanticSearchService (Foundation Only)
/// ----------------------------------------------------------------------
/// Antarmuka arsitektural untuk pengembangan masa depan (Vector Search / Embeddings).
/// Sesuai Prinsip Fase 10: "SEMANTIC SEARCH: FOUNDATION ONLY".
/// Tidak menggunakan AI pihak ketiga secara sembarangan untuk data arsip privat.
/// ----------------------------------------------------------------------
abstract class SemanticSearchService {
  /// Menghasilkan representasi embedding vektor untuk query pencarian
  Future<List<double>> generateQueryEmbedding(String query);

  /// Pencarian kemiripan semantik berbasis representasi vektor
  Future<List<SearchResultEntity>> searchSimilar({
    required List<double> queryVector,
    double threshold = 0.75,
    int limit = 10,
  });
}

class SemanticSearchFoundationImpl implements SemanticSearchService {
  @override
  Future<List<double>> generateQueryEmbedding(String query) async {
    // Foundation stub: Menyiapkan struktur vektor 384-dimensi untuk model on-device masa depan
    return List<double>.filled(384, 0.0);
  }

  @override
  Future<List<SearchResultEntity>> searchSimilar({
    required List<double> queryVector,
    double threshold = 0.75,
    int limit = 10,
  }) async {
    // Foundation stub: Mengembalikan list kosong sampai model on-device diaktifkan di masa depan
    return const [];
  }
}
