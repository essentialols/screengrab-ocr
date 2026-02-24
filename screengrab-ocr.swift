import AppKit
import Vision

// MARK: - Screen Capture

func captureScreenSelection() -> URL? {
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("screengrab-ocr-\(ProcessInfo.processInfo.processIdentifier).png")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-i", "-s", "-x", tempURL.path]

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        fputs("Error launching screencapture: \(error)\n", stderr)
        return nil
    }

    // Exit status 1 = user pressed Escape
    guard process.terminationStatus == 0 else { return nil }
    guard FileManager.default.fileExists(atPath: tempURL.path) else { return nil }

    return tempURL
}

// MARK: - OCR

func recognizeText(from imageURL: URL) -> String? {
    guard let cgImageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) else {
        fputs("Error loading image\n", stderr)
        return nil
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        fputs("OCR error: \(error)\n", stderr)
        return nil
    }

    let observations = request.results ?? []
    let text = observations
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")

    return text.isEmpty ? nil : text
}

// MARK: - Clipboard

func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

// MARK: - Notification

func showNotification(title: String, body: String) {
    let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
    let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", "display notification \"\(escapedBody)\" with title \"\(escapedTitle)\""]

    try? process.run()
    process.waitUntilExit()
}

// MARK: - Main

let imageURL = captureScreenSelection()

guard let imageURL = imageURL else {
    // User cancelled (Escape) — silent exit
    exit(0)
}

defer {
    try? FileManager.default.removeItem(at: imageURL)
}

guard let text = recognizeText(from: imageURL) else {
    showNotification(title: "OCR Failed", body: "No text recognized — check Screen Recording permission")
    fputs("No text recognized\n", stderr)
    exit(0)
}

copyToClipboard(text)

let lines = text.components(separatedBy: "\n").count
let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
showNotification(title: "Text Copied to Clipboard", body: "\(words) words, \(lines) lines")

print(text)
