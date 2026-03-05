import Cocoa
import Vision

// MARK: - Manager principal OCR

class OCRManager: NSObject {
    static let shared = OCRManager()

    private var overlayWindow: OCROverlayWindow?
    private var completion: ((String?) -> Void)?

    private override init() {}

    /// Lance la capture interactive → OCR → retourne le texte reconnu
    func startCapture(completion: @escaping (String?) -> Void) {
        self.completion = completion
        DispatchQueue.main.async { self.showOverlay() }
    }

    private func showOverlay() {
        guard let screen = NSScreen.main else {
            completion?(nil)
            return
        }

        let selectionView = OCRSelectionView()
        selectionView.onCapture = { [weak self] screenRect in
            self?.captureAndRecognize(screenRect: screenRect)
        }
        selectionView.onCancel = { [weak self] in
            self?.hideOverlay()
            self?.completion?(nil)
        }

        let win = OCROverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.backgroundColor = .clear
        win.isOpaque = false
        win.level = .screenSaver
        win.contentView = selectionView
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.overlayWindow = win
    }

    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    private func captureAndRecognize(screenRect: CGRect) {
        hideOverlay()

        // Capturer la région d'écran
        guard let cgImage = CGWindowListCreateImage(
            screenRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            DispatchQueue.main.async { self.completion?(nil) }
            return
        }

        recognizeText(in: cgImage)
    }

    private func recognizeText(in image: CGImage) {
        let request = VNRecognizeTextRequest { [weak self] req, _ in
            let observations = req.results as? [VNRecognizedTextObservation] ?? []
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            DispatchQueue.main.async {
                self?.completion?(text.isEmpty ? nil : text)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // Langues reconnues nativement par Vision
        request.recognitionLanguages = [
            "en-US", "fr-FR", "es-ES", "de-DE", "it-IT", "pt-BR",
            "zh-Hans", "zh-Hant", "ja-JP", "ko-KR", "ar-SA",
            "ru-RU", "nl-NL", "uk-UA", "vi-VN"
        ]

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

// MARK: - Fenêtre overlay (peut devenir key window)

class OCROverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Vue de sélection (NSView)

class OCRSelectionView: NSView {
    var onCapture: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var selectionRect: NSRect?
    private var keyMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NSCursor.crosshair.push()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Échap
                self?.onCancel?()
                return nil
            }
            return event
        }
    }

    override func removeFromSuperview() {
        NSCursor.pop()
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        super.removeFromSuperview()
    }

    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool { true }

    // MARK: - Dessin

    override func draw(_ dirtyRect: NSRect) {
        // Fond semi-transparent
        NSColor.black.withAlphaComponent(0.45).setFill()
        dirtyRect.fill()

        if let rect = selectionRect {
            // Zone sélectionnée — effacer le fond (transparence)
            NSColor.clear.setFill()
            rect.fill()

            // Bordure blanche
            NSColor.white.withAlphaComponent(0.95).setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2
            path.stroke()

            // Coins accentués
            drawCornerHandles(rect: rect)
        }

        // Instructions centrées en haut
        drawInstructions()
    }

    private func drawCornerHandles(rect: NSRect) {
        let len: CGFloat = 12
        let lw: CGFloat  = 3
        NSColor.white.setStroke()

        let corners: [(NSPoint, NSPoint, NSPoint)] = [
            (NSPoint(x: rect.minX, y: rect.minY),
             NSPoint(x: rect.minX + len, y: rect.minY),
             NSPoint(x: rect.minX, y: rect.minY + len)),
            (NSPoint(x: rect.maxX, y: rect.minY),
             NSPoint(x: rect.maxX - len, y: rect.minY),
             NSPoint(x: rect.maxX, y: rect.minY + len)),
            (NSPoint(x: rect.minX, y: rect.maxY),
             NSPoint(x: rect.minX + len, y: rect.maxY),
             NSPoint(x: rect.minX, y: rect.maxY - len)),
            (NSPoint(x: rect.maxX, y: rect.maxY),
             NSPoint(x: rect.maxX - len, y: rect.maxY),
             NSPoint(x: rect.maxX, y: rect.maxY - len)),
        ]

        for (origin, h, v) in corners {
            let p = NSBezierPath()
            p.lineWidth = lw
            p.move(to: h); p.line(to: origin); p.line(to: v)
            p.stroke()
        }
    }

    private func drawInstructions() {
        let text = L10n.popupOCRInstruction as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.white,
            .shadow: {
                let s = NSShadow()
                s.shadowColor = NSColor.black.withAlphaComponent(0.8)
                s.shadowBlurRadius = 4
                s.shadowOffset = NSSize(width: 0, height: -1)
                return s
            }()
        ]
        let size = text.size(withAttributes: attrs)
        let x = (bounds.width - size.width) / 2
        let y = bounds.height - size.height - 50
        text.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
    }

    // MARK: - Gestion souris

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        selectionRect = nil
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint, let win = window else {
            startPoint = nil; selectionRect = nil
            return
        }

        let current = convert(event.locationInWindow, from: nil)
        let localRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        startPoint = nil
        selectionRect = nil

        guard localRect.width > 10 && localRect.height > 10 else { return }

        // Convertir en coordonnées écran (CoreGraphics, origine haut-gauche)
        let screenRect = win.convertToScreen(localRect)
        guard let screen = NSScreen.main else { return }
        let flippedY = screen.frame.height - screenRect.maxY
        let cgRect = CGRect(x: screenRect.minX, y: flippedY, width: screenRect.width, height: screenRect.height)

        onCapture?(cgRect)
    }
}
