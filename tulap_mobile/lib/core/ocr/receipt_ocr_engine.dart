import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// ReceiptOcrEngine
/// ----------------------------------------------------------------------
/// Wrapper tipis di atas Google ML Kit Text Recognition (on-device,
/// tidak butuh koneksi internet - penting untuk kondisi lapangan yang
/// sering blank spot, sesuai prinsip offline-first Tulap.id).
///
/// Engine ini HANYA bertugas mengekstrak teks mentah dari gambar.
/// Interpretasi teks menjadi field terstruktur (vendor, nominal,
/// tanggal) adalah tanggung jawab ReceiptParser - dipisah agar parser
/// bisa diuji secara independen tanpa perlu gambar asli.
/// ----------------------------------------------------------------------
class ReceiptOcrEngine {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Menjalankan OCR pada file gambar di [imagePath], mengembalikan
  /// teks mentah hasil pembacaan beserta blok-blok teks (dipakai
  /// parser untuk analisis posisi, mis. nominal biasanya berada di
  /// baris dengan font lebih besar/bold pada nota thermal).
  Future<RecognizedText> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return _recognizer.processImage(inputImage);
  }

  void dispose() {
    _recognizer.close();
  }
}
