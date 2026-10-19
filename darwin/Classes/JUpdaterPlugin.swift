import Foundation
#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import Cocoa
#endif

/// iOS + macOS side of JUpdater: app/device info and opening the update URL.
public class JUpdaterPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #else
    let messenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(name: "com.qtlws.jupdater/native", binaryMessenger: messenger)
    let instance = JUpdaterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformInfo":
      result(platformInfo())
    case "openUrl":
      guard let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let url = URL(string: urlString) else {
        result(false)
        return
      }
      openUrl(url, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func platformInfo() -> [String: Any] {
    let bundle = Bundle.main
    let packageName = bundle.bundleIdentifier ?? ""
    let versionName = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"

    // Per-app state directory (macOS non-sandboxed apps share Application Support, so add the bundle id).
    var supportDir = ""
    if let base = try? FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
      supportDir = base
        .appendingPathComponent(packageName.isEmpty ? "app" : packageName, isDirectory: true)
        .appendingPathComponent("jupdater", isDirectory: true).path
    }

    // Bundle creation date approximates the install time.
    var firstInstallMs: Int = 0
    if let attrs = try? FileManager.default.attributesOfItem(atPath: bundle.bundlePath),
       let created = attrs[.creationDate] as? Date {
      firstInstallMs = Int(created.timeIntervalSince1970 * 1000)
    }

    var info: [String: Any] = [
      "packageName": packageName,
      "versionName": versionName,
      "buildNumber": buildNumber,
      "supportDir": supportDir,
      "brand": "Apple",
      "manufacturer": "Apple",
      "firstInstallTime": firstInstallMs,
    ]

    #if os(iOS)
    info["device"] = machineIdentifier()
    info["model"] = UIDevice.current.model
    info["board"] = ""
    info["osVersion"] = UIDevice.current.systemVersion
    #else
    let hwModel = sysctlString("hw.model")
    info["device"] = hwModel
    info["model"] = hwModel
    info["board"] = sysctlString("hw.machine")
    let v = ProcessInfo.processInfo.operatingSystemVersion
    info["osVersion"] = "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    #endif
    return info
  }

  private func machineIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)
    return mirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
  }

  private func sysctlString(_ name: String) -> String {
    var size = 0
    sysctlbyname(name, nil, &size, nil, 0)
    guard size > 0 else { return "" }
    var buffer = [CChar](repeating: 0, count: size)
    sysctlbyname(name, &buffer, &size, nil, 0)
    let bytes = buffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }
    return String(decoding: bytes, as: UTF8.self)
  }

  private func openUrl(_ url: URL, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      #if os(iOS)
      UIApplication.shared.open(url, options: [:]) { ok in result(ok) }
      #else
      result(NSWorkspace.shared.open(url))
      #endif
    }
  }
}
