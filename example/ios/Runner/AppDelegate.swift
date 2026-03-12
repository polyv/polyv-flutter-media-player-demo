import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // SDK 账号配置由 Flutter 层通过 PlayerInitializer.initialize 统一初始化
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
