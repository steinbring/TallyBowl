import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Run the suggestions_preview integration test on macOS to generate the two
// 1024px source PNGs, then pass their printed paths to this script. Native
// Core Graphics output deliberately removes alpha from iPad/Android assets.
guard CommandLine.arguments.count == 3,
      let opaqueSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, nil),
      let opaque = CGImageSourceCreateImageAtIndex(opaqueSource, 0, nil),
      let macSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL, nil),
      let mac = CGImageSourceCreateImageAtIndex(macSource, 0, nil) else {
  fatalError("Usage: swift tool/generate_icons.swift <opaque.png> <mac.png>")
}
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

func write(_ image: CGImage, size: Int, alpha: Bool, path: URL) throws {
  let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)!
  context.interpolationQuality = .high
  context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
  let destination = CGImageDestinationCreateWithURL(path as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(destination, context.makeImage()!, nil)
  guard CGImageDestinationFinalize(destination) else { fatalError("Could not write \(path.path)") }
}

for platform in ["ios", "macos"] {
  let folder = root.appendingPathComponent("\(platform)/Runner/Assets.xcassets/AppIcon.appiconset")
  let data = try Data(contentsOf: folder.appendingPathComponent("Contents.json"))
  let document = try JSONSerialization.jsonObject(with: data) as! [String: Any]
  var written = Set<String>()
  for entry in document["images"] as! [[String: String]] {
    guard let filename = entry["filename"], written.insert(filename).inserted else { continue }
    let dimension = Double(entry["size"]!.split(separator: "x")[0])!
    let scale = Double(entry["scale"]!.dropLast())!
    try write(platform == "macos" ? mac : opaque, size: Int(dimension * scale), alpha: platform == "macos", path: folder.appendingPathComponent(filename))
  }
}
for (density, size) in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)] {
  try write(opaque, size: size, alpha: false, path: root.appendingPathComponent("android/app/src/main/res/mipmap-\(density)/ic_launcher.png"))
}
print("Generated TallyBowl launcher icons for macOS, iPadOS and Android.")
