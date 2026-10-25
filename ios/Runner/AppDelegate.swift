import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var visionChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TallyBowlVision")!
    let channel = FlutterMethodChannel(name: "app.jws.tallybowl/vision", binaryMessenger: registrar.messenger())
    visionChannel = channel
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any], let bytes = args["bytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "invalid_image", message: "Select an image first.", details: nil)); return
      }
      let regions = args["regions"] as? [[String: Double]]
      let aspect = args["aspect"] as? Double ?? 1
      ScoreTextRecognition.recognize(bytes.data, regions: regions, aspect: aspect) { outcome in
        switch outcome {
        case .success(let lines): result(lines)
        case .failure: result(FlutterError(code:"recognition",message:"This image could not be read. Try a clearer photo or enter the frames manually.",details:nil))
        }
      }
    }
  }
}
