import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: render-store-assets APP_ID STORE_DIRECTORY")
}
let app = CommandLine.arguments[1]
let root = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let source = root.appendingPathComponent("source", isDirectory: true)
let output = root.appendingPathComponent("assets", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let aero = app == "aerosloth"
let title = aero ? "AeroSloth" : "TallyBowl!"
let caption = aero ? "Your people.\nOne calm feed." : "How you bowled,\ntonight."
let detail = aero ? "GoToSocial · Bluesky · Mastodon" : "Your personal bowling journal"
let paper = NSColor(calibratedRed: 0.967, green: 0.976, blue: 0.961, alpha: 1)
let ink = aero
    ? NSColor(calibratedRed: 0.137, green: 0.231, blue: 0.212, alpha: 1)
    : NSColor(calibratedRed: 0.086, green: 0.212, blue: 0.220, alpha: 1)
var manifest: [[String: Any]] = []
func image(_ name: String) -> NSImage {
    guard let value = NSImage(contentsOf: source.appendingPathComponent(name)) else {
        fatalError("Missing source artwork: \(name)")
    }
    return value
}
func fit(_ image: NSImage, in rect: NSRect) {
    let ratio = min(rect.width / image.size.width, rect.height / image.size.height)
    let size = NSSize(width: image.size.width * ratio, height: image.size.height * ratio)
    image.draw(in: NSRect(
        x: rect.midX - size.width / 2, y: rect.midY - size.height / 2,
        width: size.width, height: size.height
    ), from: .zero, operation: .sourceOver, fraction: 1)
}
func text(_ value: String, in rect: NSRect, size: CGFloat, weight: NSFont.Weight) {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byWordWrapping
    (value as NSString).draw(in: rect, withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: ink, .paragraphStyle: style
    ])
}
func background(_ name: String) -> NSColor {
    guard let data = try? Data(contentsOf: source.appendingPathComponent(name)),
          let bitmap = NSBitmapImageRep(data: data),
          let color = bitmap.colorAt(x: 0, y: 0) else { return paper }
    return color
}
func render(_ filename: String, width: Int, height: Int,
            background color: NSColor = paper, draw: (NSRect) -> Void) throws {
    try autoreleasepool {
        guard let canvas = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            fatalError("Cannot create store canvas")
        }
        let context = NSGraphicsContext(cgContext: canvas, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        let bounds = NSRect(x: 0, y: 0, width: width, height: height)
        color.setFill()
        NSBezierPath(rect: bounds).fill()
        draw(bounds)
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        guard let cgImage = canvas.makeImage() else { fatalError("Cannot finish store canvas") }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard !bitmap.hasAlpha,
              let bytes = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Cannot encode store PNG")
        }
        let file = output.appendingPathComponent(filename)
        guard !FileManager.default.fileExists(atPath: file.path) else {
            fatalError("Refusing to overwrite an existing store asset")
        }
        try bytes.write(to: file, options: .atomic)
        manifest.append([
            "file": filename, "width": width, "height": height,
            "bytes": bytes.count, "alpha": false
        ])
    }
}
func promo(_ bounds: NSRect) {
    let scale = min(bounds.width / 1024, bounds.height / 500)
    let origin = NSPoint(x: (bounds.width - 1024 * scale) / 2,
                         y: (bounds.height - 500 * scale) / 2)
    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
        NSRect(x: origin.x + x * scale, y: origin.y + y * scale,
               width: w * scale, height: h * scale)
    }
    fit(image("logo.png"), in: rect(36, 348, 104, 104))
    text(title, in: rect(36, 274, 430, 70), size: 53 * scale, weight: .bold)
    text(caption, in: rect(36, 143, 416, 112), size: 34 * scale, weight: .semibold)
    text(detail, in: rect(38, 80, 415, 48), size: 18 * scale, weight: .regular)
    let preview = rect(472, 70, 520, 360)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: preview.insetBy(dx: -6 * scale, dy: -6 * scale),
                 xRadius: 14 * scale, yRadius: 14 * scale).fill()
    fit(image("mac-light.jpg"), in: preview)
}
try render("google-play-icon-512.png", width: 512, height: 512) { fit(image("logo.png"), in: $0) }
try render("google-play-feature-1024x500.png", width: 1024, height: 500, draw: promo)
try render("apple-header-5244x2950.png", width: 5244, height: 2950, draw: promo)
for mode in ["light", "dark"] {
    try render("mac-\(mode)-2880x1800.png", width: 2880, height: 1800,
               background: background("mac-\(mode).jpg")) {
        fit(image("mac-\(mode).jpg"), in: $0)
    }
    try render("ipad-\(mode)-2732x2048.png", width: 2732, height: 2048,
               background: background("ipad-\(mode).jpg")) {
        fit(image("ipad-\(mode).jpg"), in: $0)
    }
    try render("android-\(mode)-1080x1920.png", width: 1080, height: 1920,
               background: background("android-\(mode).jpg")) {
        fit(image("android-\(mode).jpg"), in: $0)
    }
}
let data = try JSONSerialization.data(
    withJSONObject: ["app": title, "assets": manifest], options: [.prettyPrinted, .sortedKeys]
)
try data.write(to: root.appendingPathComponent("assets-manifest.json"), options: .atomic)
print("\(title): rendered \(manifest.count) opaque store assets from public demo artwork.")
