# google_mlkit_text_recognition (dipakai untuk Scan Nota OCR) mereferensikan
# recognizer varian bahasa lain (Chinese/Devanagari/Japanese/Korean) secara
# reflektif, tapi app ini hanya memakai recognizer Latin default (nota
# Indonesia) - dependency paket bahasa lain itu memang sengaja tidak
# ditambahkan. R8 (build --release pertama yang benar-benar menjalankan
# minifikasi) memperingatkan kelas-kelas itu "hilang"; aman diabaikan
# karena tidak pernah benar-benar dipanggil saat runtime. Daftar ini
# persis seperti yang disarankan otomatis oleh Android Gradle Plugin di
# build/app/outputs/mapping/release/missing_rules.txt.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
