import Cocoa
import FlutterMacOS
import Vision
import ImageIO
import AVFoundation

class MainFlutterWindow: NSWindow {
  private var visionChannel: FlutterMethodChannel?
  private var camera: ScoreCameraWindow?

  override func awakeFromNib() {
    let controller = FlutterViewController()
    contentViewController = controller
    setContentSize(NSSize(width: 1240, height: 850))
    minSize = NSSize(width: 560, height: 600)
    RegisterGeneratedPlugins(registry: controller)
    let channel = FlutterMethodChannel(name: "app.jws.tallybowl/vision", binaryMessenger: controller.engine.binaryMessenger)
    visionChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "recognizeText":
        guard let args = call.arguments as? [String: Any], let bytes = args["bytes"] as? FlutterStandardTypedData else {
          result(FlutterError(code: "invalid_image", message: "Select an image first.", details: nil)); return
        }
        recognizeScoreText(bytes.data, regions: args["regions"] as? [[String: Double]], aspect: args["aspect"] as? Double ?? 1, context: args["context"] as? Bool ?? false, result: result)
      case "capturePhoto":
        guard let self = self else { result(nil); return }
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async {
            guard granted else { result(FlutterError(code: "camera_permission", message: "Allow camera access in System Settings, or select a photo instead.", details: nil)); return }
            guard self.camera == nil else { result(FlutterError(code: "camera_busy", message: "The camera is already open.", details: nil)); return }
            self.camera = ScoreCameraWindow { [weak owner = self] data, error in
              owner?.camera = nil
              if let error = error { result(FlutterError(code: "camera", message: error, details: nil)) }
              else if let data = data { result(FlutterStandardTypedData(bytes: data)) }
              else { result(nil) }
            }
            self.camera?.showWindow(nil)
            self.camera?.window?.makeKeyAndOrderFront(nil)
          }
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
    super.awakeFromNib()
  }
}

private func recognizeScoreText(_ data: Data, regions: [[String: Double]]?, aspect: Double, context: Bool, result: @escaping FlutterResult) {
  ScoreTextRecognition.recognize(data, regions: regions, aspect: aspect, context: context) { outcome in
    switch outcome {
    case .success(let lines): result(lines)
    case .failure: result(FlutterError(code:"recognition",message:"This image could not be read. Try a clearer photo or enter the frames manually.",details:nil))
    }
  }
}

private class ScoreCameraWindow: NSWindowController, NSWindowDelegate, AVCapturePhotoCaptureDelegate {
  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "app.jws.tallybowl.camera")
  private let output = AVCapturePhotoOutput()
  private let preview = NSView()
  private let shutter = NSButton(title: "Take photo", target: nil, action: nil)
  private let completion: (Data?, String?) -> Void
  private var completed = false
  init(completion: @escaping (Data?, String?) -> Void) {
    self.completion = completion
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 620), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
    window.title = "TallyBowl! · Scoreboard camera"
    window.minSize = NSSize(width: 640, height: 480)
    super.init(window: window)
    window.delegate = self
    window.center()
    guard let content = window.contentView else { return }
    preview.frame = NSRect(x: 0, y: 72, width: 800, height: 548)
    preview.autoresizingMask = [.width, .height]
    content.addSubview(preview)
    shutter.frame = NSRect(x: 320, y: 20, width: 160, height: 36)
    shutter.bezelStyle = .rounded
    shutter.autoresizingMask = [.minXMargin, .maxXMargin, .maxYMargin]
    shutter.target = self
    shutter.action = #selector(takePhoto)
    shutter.isEnabled = false
    content.addSubview(shutter)
    DispatchQueue.main.async { [weak self] in self?.prepare() }
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  private func prepare() {
    guard !completed else { return }
    do {
      guard let device = AVCaptureDevice.default(for: .video) else { finish(nil, "No camera is available. Select an existing photo instead."); return }
      let input = try AVCaptureDeviceInput(device: device)
      session.beginConfiguration()
      session.sessionPreset = .photo
      guard session.canAddInput(input), session.canAddOutput(output) else { session.commitConfiguration(); finish(nil, "This camera could not be opened."); return }
      session.addInput(input)
      session.addOutput(output)
      session.commitConfiguration()
      preview.wantsLayer = true
      let layer = AVCaptureVideoPreviewLayer(session: session)
      layer.videoGravity = .resizeAspect
      layer.frame = preview.bounds
      layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
      preview.layer?.addSublayer(layer)
      sessionQueue.async { [weak self] in
        guard let self = self else { return }
        self.session.startRunning()
        DispatchQueue.main.async { if !self.completed { self.shutter.isEnabled = true } }
      }
    } catch { finish(nil, "The camera could not be opened. Try selecting a photo instead.") }
  }
  @objc private func takePhoto() {
    shutter.isEnabled = false
    output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
  }
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    DispatchQueue.main.async { self.finish(photo.fileDataRepresentation(), error == nil ? nil : "The photo could not be captured.") }
  }
  func windowWillClose(_ notification: Notification) { finish(nil, nil) }
  private func finish(_ data: Data?, _ error: String?) {
    guard !completed else { return }
    completed = true
    sessionQueue.async { [session] in session.stopRunning() }
    window?.close()
    completion(data, error)
  }
}
