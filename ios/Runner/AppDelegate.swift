import Flutter
import UIKit
import Vision
import ImageIO

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
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let request = VNRecognizeTextRequest()
          request.recognitionLevel = .accurate
          request.usesLanguageCorrection = false
          request.recognitionLanguages = ["en-US"]
          guard let source = CGImageSourceCreateWithData(bytes.data as CFData, nil),
                let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: 4096
                ] as CFDictionary) else {
            throw NSError(domain: "TallyBowl", code: 1)
          }
          try VNImageRequestHandler(cgImage: image, orientation: .up, options: [:]).perform([request])
          let lines: [[String: Any]] = (request.results ?? []).compactMap { observation in
            guard let text = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            return ["text": text.string, "confidence": Double(text.confidence), "x": box.minX, "y": 1 - box.maxY, "width": box.width, "height": box.height]
          }
          DispatchQueue.main.async { result(lines) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "recognition", message: "This image could not be read. Try a clearer photo or enter the frames manually.", details: nil)) }
        }
      }
    }
  }
}
