import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Rebuild native launcher sizes from the committed brand master. macOS uses
// an inset rounded tile; iPad and Android assets are deliberately opaque.
// Run from any directory: swift tool/generate_icons.swift [master.png]
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let master =
  CommandLine.arguments.count > 1
  ? URL(fileURLWithPath: CommandLine.arguments[1])
  : root.appendingPathComponent("assets/branding/tallybowl-logo.png")
guard let source = CGImageSourceCreateWithURL(master as CFURL, nil),
  let logo = CGImageSourceCreateImageAtIndex(source, 0, nil),
  logo.width == logo.height
else {
  fatalError("Provide a square logo PNG: \(master.path)")
}

func write(size: Int, mac: Bool, path: URL) throws {
  let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: mac
      ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)!
  context.interpolationQuality = .high
  let inset = mac ? Double(size) / 16 : 0
  let rect = CGRect(
    x: inset, y: inset, width: Double(size) - 2 * inset, height: Double(size) - 2 * inset)
  if mac {
    context.addPath(
      CGPath(
        roundedRect: rect, cornerWidth: Double(size) * 0.19,
        cornerHeight: Double(size) * 0.19, transform: nil))
    context.clip()
  }
  context.draw(logo, in: rect)
  let destination = CGImageDestinationCreateWithURL(
    path as CFURL, UTType.png.identifier as CFString, 1, nil)!
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
    try write(
      size: Int(dimension * scale), mac: platform == "macos",
      path: folder.appendingPathComponent(filename))
  }
}
for (density, size) in [
  ("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192),
] {
  try write(
    size: size, mac: false,
    path: root.appendingPathComponent("android/app/src/main/res/mipmap-\(density)/ic_launcher.png"))
}
print("Generated TallyBowl bowler icons for macOS, iPadOS and Android from \(master.path).")
