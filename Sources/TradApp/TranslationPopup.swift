import Cocoa
import SwiftUI

// MARK: - Contrôleur de popup

class TranslationPopup: NSObject {
    static let shared = TranslationPopup()

    private var panel: NSPanel?
    private var dismissTimer: Timer?

    private override init() {}

    /// Affiche la traduction avec métadonnées complètes
    func show(text: String, sourceLang: String?, originalText: String?) {
        dismiss()

        let targetLang = AppSettings.shared.targetLanguage
        let contentView = PopupView(
            text: text,
            sourceLang: sourceLang,
            targetLang: targetLang,
            originalText: originalText,
            onDismiss: { [weak self] in self?.dismiss() },
            onCopy: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            },
            onSwap: originalText != nil && sourceLang != nil ? { [weak self] in
                self?.doSwap(originalText: originalText!, targetLang: sourceLang!)
            } : nil
        )

        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = NSRect(x: 0, y: 0, width: 360, height: 140)

        let fitted       = hosting.fittingSize
        let panelWidth:  CGFloat = max(300, min(420, fitted.width))
        let panelHeight: CGFloat = fitted.height + 8

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level             = .floating
        panel.isOpaque          = false
        panel.backgroundColor   = .clear
        panel.hasShadow         = false
        panel.contentView       = hosting
        panel.isMovableByWindowBackground = true

        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - panelWidth - 12
            let y = screen.visibleFrame.maxY - panelHeight - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        self.panel = panel

        dismissTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    /// Popup minimaliste (juste langue source → cible) pour les remplacements en place
    func showMini(sourceLang: String?, targetLang: String) {
        let sl  = sourceLang.flatMap { Language.find(id: $0) }
        let tl  = Language.find(id: targetLang)
        let src = sl?.flag ?? "🌐"
        let dst = tl?.flag ?? "🌐"
        let msg = "\(src) → \(dst)  ✓"
        show(text: msg, sourceLang: sourceLang, originalText: nil)
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        panel?.orderOut(nil)
        panel = nil
    }

    // MARK: - Swap (inverser la traduction)

    private func doSwap(originalText: String, targetLang: String) {
        dismiss()
        StatusBarController.shared.setLoading(true)

        // Traduire l'original vers la langue source détectée
        let savedTarget = AppSettings.shared.targetLanguage
        AppSettings.shared.targetLanguage = targetLang

        TranslationEngine.shared.translate(text: originalText) { [weak self] translated, sourceLang in
            DispatchQueue.main.async {
                AppSettings.shared.targetLanguage = savedTarget
                StatusBarController.shared.setLoading(false)
                if let t = translated {
                    self?.show(text: t, sourceLang: sourceLang, originalText: originalText)
                }
            }
        }
    }
}

// MARK: - Vue SwiftUI de la popup

struct PopupView: View {
    let text: String
    let sourceLang: String?
    let targetLang: String
    let originalText: String?
    let onDismiss: () -> Void
    let onCopy: () -> Void
    let onSwap: (() -> Void)?

    @State private var appeared  = false
    @State private var didCopy   = false

    private var sourceLanguage: Language? { sourceLang.flatMap { Language.find(id: $0) } }
    private var targetLanguage: Language? { Language.find(id: targetLang) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {

                // ── Ligne de méta (langue détectée → cible) ──────────────
                if let sl = sourceLanguage, let tl = targetLanguage, sl.id != tl.id {
                    HStack(spacing: 5) {
                        Text(sl.flag)
                        Text("→")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(tl.flag)
                        Text(L10n.popupFrom)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(sl.nativeName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                // ── Texte traduit ─────────────────────────────────────────
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.blue)
                        .padding(.top, 1)

                    Text(text)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(14)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // ── Boutons d'action ──────────────────────────────────────
                HStack(spacing: 8) {
                    // Copier
                    Button(action: {
                        onCopy()
                        didCopy = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { didCopy = false }
                    }) {
                        Label(didCopy ? L10n.popupCopied : L10n.popupCopy,
                              systemImage: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(didCopy ? .green : .blue)
                    .controlSize(.mini)

                    // Inverser (swap)
                    if let swap = onSwap {
                        Button(action: swap) {
                            Label(L10n.popupSwap, systemImage: "arrow.left.arrow.right")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .padding(.trailing, 24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 6)

            // Fermer
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(7)
        }
        .padding(6)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) { appeared = true }
        }
    }
}
