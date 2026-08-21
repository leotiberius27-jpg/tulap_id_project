package id.tulap.tulap_mobile

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
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
///
/// PENTING: FlutterFragmentActivity (bukan FlutterActivity biasa) -
/// package `local_auth` (Masuk Cepat dengan Biometrik) MEWAJIBKAN
/// androidx.fragment.app.FragmentActivity untuk menampilkan dialog
/// prompt biometrik Android; dengan FlutterActivity biasa method
/// `authenticate()`-nya crash di runtime.
/// ----------------------------------------------------------------------
class MainActivity : FlutterFragmentActivity() {
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
