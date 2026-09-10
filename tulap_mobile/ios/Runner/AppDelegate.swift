import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "id.tulap.security/device_integrity"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Peta Sebaran Lokasi (Beranda) - key diisi lewat Info.plist
    // "GMSApiKey" (lihat komentar di sana), TIDAK di-hardcode di sini.
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !apiKey.isEmpty
    {
      GMSServices.provideAPIKey(apiKey)
    }

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let securityChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )

    securityChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "isDeviceCompromised" {
        result(self?.isDeviceCompromised() ?? false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func isDeviceCompromised() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    return hasJailbreakFiles() || canWriteRestrictedFiles() || canOpenCydiaURL()
    #endif
  }

  private func hasJailbreakFiles() -> Bool {
    let paths = [
      "/Applications/Cydia.app",
      "/Applications/Sileo.app",
      "/Applications/Zebra.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/usr/bin/ssh",
      "/private/var/lib/apt",
      "/private/var/lib/cydia",
      "/private/var/tmp/cydia.log",
      "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"
    ]
    for path in paths {
      if FileManager.default.fileExists(atPath: path) {
        return true
      }
    }
    return false
  }

  private func canWriteRestrictedFiles() -> Bool {
    let testPath = "/private/jailbreak_test.txt"
    do {
      try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: testPath)
      return true
    } catch {
      return false
    }
  }

  private func canOpenCydiaURL() -> Bool {
    guard let url = URL(string: "cydia://package/com.example.package") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }
}

