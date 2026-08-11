// =====================================================================
// TULAP.ID - IMPLEMENTASI NATIF ANDROID UNTUK RootDetector
// =====================================================================
// CARA PAKAI: file ini BUKAN bagian dari folder `android/` yang
// dihasilkan `flutter create` (folder itu tidak ada di arsip ini,
// lihat README.md - dibuat sendiri oleh developer saat setup project
// nyata). Setelah menjalankan `flutter create .`, TIMPA file
// `android/app/src/main/kotlin/<package_id_anda>/MainActivity.kt`
// bawaan dengan isi file ini, LALU sesuaikan baris `package` di bawah
// agar SAMA PERSIS dengan `applicationId` di
// `android/app/build.gradle` project Anda (bawaan Flutter biasanya
// `com.example.tulap_mobile` kecuali diubah saat `flutter create`).
// =====================================================================

package id.tulap.tulap_mobile

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// MainActivity
/// ----------------------------------------------------------------------
/// Menjawab MethodChannel `id.tulap.security/device_integrity` yang
/// dipanggil RootDetector (lib/core/security/root_detector.dart) lewat
/// method `isDeviceCompromised`. Deteksi root di sini SENGAJA sederhana
/// (heuristik umum, bukan library deteksi root komersial) - cukup
/// untuk menaikkan usaha yang dibutuhkan pemalsu GPS, sejalan dengan
/// catatan RootDetector.dart bahwa sumber deteksi bisa diganti kapan
/// pun (mis. `safe_device`) tanpa mengubah kode pemanggil.
/// ----------------------------------------------------------------------
class MainActivity : FlutterActivity() {
    private val CHANNEL = "id.tulap.security/device_integrity"

    private val ROOT_INDICATOR_PATHS = arrayOf(
        "/system/app/Superuser.apk",
        "/sbin/su",
        "/system/bin/su",
        "/system/xbin/su",
        "/data/local/xbin/su",
        "/data/local/bin/su",
        "/system/sd/xbin/su",
        "/system/bin/failsafe/su",
        "/data/local/su",
        "/su/bin/su",
        "/system/xbin/busybox",
    )

    private val ROOT_MANAGEMENT_PACKAGES = arrayOf(
        "com.noshufou.android.su",
        "com.koushikdutta.superuser",
        "eu.chainfire.supersu",
        "com.topjohnwu.magisk",
        "com.kingroot.kinguser",
        "com.kingo.root",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isDeviceCompromised") {
                result.success(isDeviceCompromised())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isDeviceCompromised(): Boolean {
        return hasTestKeysBuildTag() || hasRootBinary() || hasRootManagementApp()
    }

    /// Build resmi dari pabrikan pakai "release-keys" - "test-keys"
    /// menandakan custom/dev build, indikasi awal umum perangkat
    /// dimodifikasi.
    private fun hasTestKeysBuildTag(): Boolean {
        val tags = Build.TAGS
        return tags != null && tags.contains("test-keys")
    }

    private fun hasRootBinary(): Boolean {
        return ROOT_INDICATOR_PATHS.any { path -> File(path).exists() }
    }

    private fun hasRootManagementApp(): Boolean {
        val pm = packageManager
        return ROOT_MANAGEMENT_PACKAGES.any { packageName ->
            try {
                pm.getPackageInfo(packageName, 0)
                true
            } catch (e: Exception) {
                false
            }
        }
    }
}
