import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Baca android/key.properties (digitignore, TIDAK PERNAH dikomit) untuk
// signing rilis sungguhan. Jika file tsb tidak ada (mis. clone baru,
// CI tanpa keystore), keystoreProperties tetap kosong - signingConfigs
// di bawah otomatis fallback ke debug key, supaya `flutter build apk
// --release` tetap bisa jalan tanpa keystore, sama seperti sebelumnya.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Peta Sebaran Lokasi (Beranda) pakai google_maps_flutter - API key SELALU
// dibaca dari android/local.properties (sudah digitignore bawaan Flutter,
// TIDAK PERNAH dikomit), baris "MAPS_API_KEY=...". Jika belum diisi,
// manifestPlaceholders jatuh ke string kosong - APK tetap bisa dibuild,
// hanya SDK Peta akan menolak render (lihat LocationDistributionMapPage
// untuk pesan fallback-nya).
val localPropertiesFile = rootProject.file("local.properties")
val localProperties = Properties()
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val mapsApiKey = localProperties.getProperty("MAPS_API_KEY", "")

android {
    namespace = "id.tulap.tulap_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "id.tulap.tulap_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // rootProject.file (BUKAN file()) - key.properties &
                // upload-keystore.jks sama-sama di android/ (rootProject),
                // bukan di android/app/ (project modul ini) - file() polos
                // resolve relatif ke android/app/ dan gagal menemukan
                // keystore-nya (dikonfirmasi lewat build yang gagal).
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Pakai keystore rilis sungguhan jika key.properties ada
            // (lihat RUNBOOK.md untuk cara generate keystore sendiri),
            // fallback ke debug key jika tidak - supaya build tetap
            // jalan di clone/CI baru tanpa keystore tersedia.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
