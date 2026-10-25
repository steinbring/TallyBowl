import CoreGraphics
import CoreText
import Foundation
import ImageIO
import Vision

/// Shared local Vision pipeline for macOS and iPadOS. Coordinates use an
/// upright image and a top-left origin, matching the Android bridge.
enum ScoreTextRecognition {
  static func recognize(
    _ data: Data, regions: [[String: Double]]?, aspect: Double,
    completion: @escaping (Result<[[String: Any]], Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let outcome: Result<[[String: Any]], Error> = Result {
        try autoreleasepool { try read(data, regions: regions, aspect: aspect) }
      }
      DispatchQueue.main.async { completion(outcome) }
    }
  }

  private static func read(_ data: Data, regions: [[String: Double]]?, aspect: Double) throws
    -> [[String: Any]]
  {
    guard data.count <= 40 * 1024 * 1024, aspect.isFinite, (1...3).contains(aspect),
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: 4096,
        ] as CFDictionary)
    else { throw failure() }
    let areas = regions ?? [["x": 0, "y": 0, "width": 1, "height": 1]]
    guard !areas.isEmpty, areas.count <= 20 else { throw failure() }
    let expression = try NSRegularExpression(pattern: "\\S+")
    var lines: [[String: Any]] = []
    for area in areas {
      guard let x = area["x"], let y = area["y"], let w = area["width"], let h = area["height"],
        [x, y, w, h].allSatisfy({ $0.isFinite }), x >= 0, y >= 0, w > 0, h > 0,
        x + w <= 1.000001, y + h <= 1.000001
      else { throw failure() }
      let rect = CGRect(
        x: x * Double(image.width), y: y * Double(image.height), width: w * Double(image.width),
        height: h * Double(image.height)
      )
      .integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
      guard let crop = image.cropping(to: rect) else { throw failure() }
      var input = crop
      var header = 0
      var displayHeight = crop.height
      if regions != nil || aspect != 1 {
        header = regions == nil ? 0 : 48
        displayHeight = regions == nil ? max(1, Int(Double(crop.height) / aspect)) : 128
        let width =
          regions == nil
          ? crop.width
          : min(640, max(128, Int(Double(crop.width) / Double(crop.height) * 128 * 2.5)))
        guard
          let context = CGContext(
            data: nil, width: width, height: displayHeight + header, bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw failure() }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: displayHeight + header))
        context.interpolationQuality = .high
        context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: displayHeight))
        if header > 0 {
          // An upright contextual label avoids upside-down readings of sparse
          // symbols. Its observations are excluded from the returned content.
          let font = CTFontCreateWithName("Helvetica" as CFString, 18, nil)
          let label = NSAttributedString(
            string: "Bowling frame",
            attributes: [
              NSAttributedString.Key(kCTFontAttributeName as String): font,
              NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(
                gray: 0, alpha: 1),
            ])
          context.textPosition = CGPoint(x: 8, y: displayHeight + 16)
          CTLineDraw(CTLineCreateWithAttributedString(label), context)
        }
        guard let scaled = context.makeImage() else { throw failure() }
        input = scaled
      }
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = false
      request.recognitionLanguages = ["en-US"]
      try VNImageRequestHandler(cgImage: input, orientation: .up, options: [:]).perform([request])
      func geometry(_ text: String, _ box: CGRect) -> [String: Any] {
        let top = (1 - box.maxY) * Double(input.height) - Double(header)
        return [
          "text": text, "x": (rect.minX + box.minX * rect.width) / Double(image.width),
          "y": (rect.minY + top / Double(displayHeight) * rect.height) / Double(image.height),
          "width": box.width * rect.width / Double(image.width),
          "height": box.height * Double(input.height) / Double(displayHeight) * rect.height
            / Double(image.height),
        ]
      }
      for observation in request.results ?? [] {
        if (1 - observation.boundingBox.maxY) * Double(input.height) < Double(header) - 1 {
          continue
        }
        guard let text = observation.topCandidates(1).first else { continue }
        var line = geometry(text.string, observation.boundingBox)
        line["confidence"] = Double(text.confidence)
        var words: [[String: Any]] = []
        for match in expression.matches(
          in: text.string, range: NSRange(text.string.startIndex..., in: text.string))
        {
          guard let range = Range(match.range, in: text.string),
            let box = try? text.boundingBox(for: range)?.boundingBox
          else { continue }
          words.append(geometry(String(text.string[range]), box))
        }
        line["elements"] = words
        lines.append(line)
      }
      if regions != nil {
        for stroke in dashStrokes(crop) {
          let mark: [String: Any] = [
            "text": "-", "stroke": true, "x": (rect.minX + stroke.minX) / Double(image.width),
            "y": (rect.minY + stroke.minY) / Double(image.height),
            "width": stroke.width / Double(image.width),
            "height": stroke.height / Double(image.height),
          ]
          var line = mark
          line["elements"] = [mark]
          lines.append(line)
        }
      }
    }
    return lines
  }

  private static func failure() -> NSError { NSError(domain: "TallyBowlRecognition", code: 1) }

  private static func dashStrokes(_ source: CGImage) -> [CGRect] {
    let scale = min(1, 512 / Double(max(source.width, source.height)))
    let w = max(1, Int(Double(source.width) * scale))
    let h = max(1, Int(Double(source.height) * scale))
    var pixels = [UInt8](repeating: 0, count: w * h * 4)
    let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
      guard
        let context = CGContext(
          data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue)
      else { return false }
      context.draw(source, in: CGRect(x: 0, y: 0, width: w, height: h))
      return true
    }
    guard rendered else { return [] }
    func foreground(_ i: Int) -> Bool {
      let r = Int(pixels[i * 4])
      let g = Int(pixels[i * 4 + 1])
      let b = Int(pixels[i * 4 + 2])
      return min(r, g, b) >= 165 && max(r, g, b) - min(r, g, b) <= 80
    }
    var horizontal = [Bool](repeating: false, count: w * h)
    for y in 0..<h {
      var x = 0
      while x < w {
        if !foreground(y * w + x) {
          x += 1
          continue
        }
        let begin = x
        while x < w && foreground(y * w + x) { x += 1 }
        if x - begin >= max(5, Int(Double(w) * 0.06)) {
          for mark in begin..<x { horizontal[y * w + mark] = true }
        }
      }
    }
    var seen = [Bool](repeating: false, count: w * h)
    var queue = [Int](repeating: 0, count: w * h)
    var found: [CGRect] = []
    for seed in 0..<w * h {
      if seen[seed] || !horizontal[seed] { continue }
      var head = 0
      var tail = 1
      var left = w
      var right = 0
      var top = h
      var bottom = 0
      queue[0] = seed
      seen[seed] = true
      while head < tail {
        let position = queue[head]
        head += 1
        let x = position % w
        let y = position / w
        left = min(left, x)
        right = max(right, x)
        top = min(top, y)
        bottom = max(bottom, y)
        for dy in -1...1 {
          for dx in -1...1 {
            let nx = x + dx
            let ny = y + dy
            if nx < 0 || nx >= w || ny < 0 || ny >= h { continue }
            let next = ny * w + nx
            if !seen[next] && horizontal[next] {
              seen[next] = true
              queue[tail] = next
              tail += 1
            }
          }
        }
      }
      let width = right - left + 1
      let height = bottom - top + 1
      let ratio = Double(width) / Double(height)
      let middle = Double(top + bottom) / 2 / Double(h)
      if Double(width) >= max(5, Double(w) * 0.06) && height >= 2
        && Double(height) <= Double(h) * 0.20 && (1.6...8).contains(ratio)
        && (0.25...0.75).contains(middle) && Double(tail) >= Double(width * height) * 0.45
      {
        found.append(
          CGRect(
            x: Double(left) / scale, y: Double(top) / scale, width: Double(width) / scale,
            height: Double(height) / scale))
      }
    }
    var merged: [CGRect] = []
    for rect in found.sorted(by: { $0.minY < $1.minY }) {
      if let index = merged.firstIndex(where: { prior in
        min(prior.maxX, rect.maxX) - max(prior.minX, rect.minX) >= min(prior.width, rect.width)
          * 0.8 && rect.minY - prior.maxY <= Double(source.height) * 0.08
      }) {
        merged[index] = merged[index].union(rect)
      } else {
        merged.append(rect)
      }
    }
    return Array(merged.sorted { $0.width * $0.height > $1.width * $1.height }.prefix(3))
  }
}
