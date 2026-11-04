// Development CLI, compiled with the SAME shared helper as iPad/macOS.
import Foundation

@main struct RecognitionLab {
    static func main() {
        do {
            guard CommandLine.arguments.count == 3 else {
                throw NSError(domain: "RecognitionLab", code: 1)
            }
            let requestURL = URL(fileURLWithPath: CommandLine.arguments[1])
            let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
            let request = try JSONSerialization.jsonObject(with: Data(contentsOf: requestURL)) as! [String: Any]
            let data = try Data(contentsOf: URL(fileURLWithPath: request["path"] as! String))
            let args = request["args"] as! [String: Any]
            ScoreTextRecognition.recognize(
                data, regions: args["regions"] as? [[String: Double]],
                aspect: (args["aspect"] as? NSNumber)?.doubleValue ?? 1,
                context: args["context"] as? Bool ?? false
            ) { result in
                do {
                    let lines = try result.get()
                    try JSONSerialization.data(withJSONObject: lines, options: [.sortedKeys])
                        .write(to: outputURL, options: .atomic)
                    exit(0)
                } catch { fputs("Native recognition failed\n", stderr); exit(1) }
            }
            RunLoop.main.run()
        } catch { fputs("Invalid recognition lab request\n", stderr); exit(1) }
    }
}
