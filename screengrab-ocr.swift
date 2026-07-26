import Cocoa
import Vision
import Carbon.HIToolbox
import UserNotifications
import os.log

private let log = OSLog(subsystem: "com.ingmarsturm.screengrab-ocr", category: "main")
private let logFile = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Logs/screengrab-ocr.log")

private func debugLog(_ msg: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(msg)\n"
    os_log("%{public}@", log: log, type: .info, msg)
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fh = try? FileHandle(forWritingTo: logFile) {
                fh.seekToEndOfFile()
                fh.write(data)
                fh.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var instance: AppDelegate!

    private var statusItem: NSStatusItem!
    private var hotKeyRef: EventHotKeyRef?
    private var isCapturing = false

    func applicationDidFinishLaunching(_: Notification) {
        AppDelegate.instance = self
        debugLog("=== ScreengrabOCR launched (PID \(ProcessInfo.processInfo.processIdentifier)) ===")

        let nc = UNUserNotificationCenter.current()
        nc.delegate = self
        nc.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        setupStatusItem()
        registerHotKey()

        let hasScreenCapture = CGPreflightScreenCaptureAccess()
        debugLog("Screen capture permission: \(hasScreenCapture)")
        if !hasScreenCapture {
            CGRequestScreenCaptureAccess()
        }
    }

    func applicationWillTerminate(_: Notification) {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
    }

    // Show banners even while this agent app is "frontmost"
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }

    // MARK: - Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "text.viewfinder",
                accessibilityDescription: "ScreengrabOCR"
            )
        }

        let menu = NSMenu()

        let capture = NSMenuItem(
            title: "OCR Screen Region  \u{2318}\u{21E7}2",
            action: #selector(triggerOCR),
            keyEquivalent: ""
        )
        capture.target = self
        menu.addItem(capture)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit ScreengrabOCR",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Global Hotkey (Carbon)

    private func registerHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, _, _ in
            DispatchQueue.main.async { AppDelegate.instance?.triggerOCR() }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, nil, nil)

        // "SOCR" as FourCharCode
        let hotKeyID = EventHotKeyID(signature: OSType(0x534F4352), id: 1)
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_2),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            notify(
                title: "ScreengrabOCR",
                body: "Could not register \u{2318}\u{21E7}2 hotkey (error \(status)). "
                    + "Another app may have claimed it."
            )
        }
    }

    // MARK: - OCR Pipeline

    @objc func triggerOCR() {
        debugLog("triggerOCR called, isCapturing=\(isCapturing)")
        guard !isCapturing else {
            debugLog("BLOCKED: isCapturing is true, skipping")
            return
        }
        isCapturing = true

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            defer {
                DispatchQueue.main.async {
                    self.isCapturing = false
                    debugLog("isCapturing reset to false")
                }
            }

            debugLog("calling captureRegion...")
            guard let imageURL = captureRegion() else {
                debugLog("captureRegion returned nil")
                return
            }
            defer { try? FileManager.default.removeItem(at: imageURL) }

            let fileSize = (try? FileManager.default.attributesOfItem(atPath: imageURL.path)[.size] as? Int) ?? 0
            debugLog("capture file: \(imageURL.lastPathComponent), size=\(fileSize) bytes")

            debugLog("calling ocr...")
            let ocrStart = Date()
            guard let text = ocr(imageURL) else {
                let elapsed = Date().timeIntervalSince(ocrStart)
                debugLog("ocr returned nil after \(String(format: "%.1f", elapsed))s")
                notify(title: "OCR", body: "No text recognized in selection")
                return
            }
            let elapsed = Date().timeIntervalSince(ocrStart)
            debugLog("ocr returned \(text.count) chars in \(String(format: "%.1f", elapsed))s")

            DispatchQueue.main.sync {
                NSPasteboard.general.clearContents()
                let ok = NSPasteboard.general.setString(text, forType: .string)
                debugLog("clipboard setString result: \(ok)")
            }

            let words = text.split(whereSeparator: \.isWhitespace).count
            let lines = text.components(separatedBy: "\n").count
            debugLog("copied \(words) words, \(lines) lines to clipboard")
            notify(title: "Copied to Clipboard", body: "\(words) words, \(lines) lines")
        }
    }

    // MARK: - Screen Capture

    private func captureRegion() -> URL? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("screengrab-\(UUID().uuidString).png")

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        proc.arguments = ["-i", "-s", "-x", url.path]

        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            notify(title: "OCR Error", body: "screencapture failed: \(error.localizedDescription)")
            return nil
        }

        // Exit status 1 = user pressed Escape (normal cancel, no notification)
        guard proc.terminationStatus == 0 else { return nil }

        guard FileManager.default.fileExists(atPath: url.path) else {
            notify(
                title: "OCR Error",
                body: "Screen capture failed. Grant Screen Recording in System Settings > Privacy."
            )
            return nil
        }

        // A blank/tiny capture means permission was silently denied
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        if size < 100 {
            try? FileManager.default.removeItem(at: url)
            notify(
                title: "OCR Error",
                body: "Capture is blank. Grant Screen Recording in System Settings > Privacy."
            )
            return nil
        }

        return url
    }

    // MARK: - OCR (Vision)

    private func ocr(_ url: URL) -> String? {
        debugLog("ocr: loading image from \(url.path)")
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let img = CGImageSourceCreateImageAtIndex(src, 0, nil)
        else {
            debugLog("ocr: FAILED to load CGImage")
            return nil
        }
        debugLog("ocr: image loaded, \(img.width)x\(img.height)")

        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .accurate
        req.usesLanguageCorrection = true

        debugLog("ocr: starting VNImageRequestHandler.perform...")
        do {
            try VNImageRequestHandler(cgImage: img, options: [:]).perform([req])
        } catch {
            debugLog("ocr: Vision THREW: \(error)")
            return nil
        }
        debugLog("ocr: Vision returned \(req.results?.count ?? 0) observations")

        let text = (req.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")

        debugLog("ocr: extracted \(text.count) chars")
        return text.isEmpty ? nil : text
    }

    // MARK: - Notifications

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.threadIdentifier = "screengrab-ocr"

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
        )
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
