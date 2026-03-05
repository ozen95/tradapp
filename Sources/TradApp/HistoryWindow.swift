import Cocoa
import SwiftUI

// MARK: - Contrôleur

class HistoryWindowController: NSObject, NSWindowDelegate {
    static let shared = HistoryWindowController()
    private var window: NSWindow?

    private override init() {}

    func showWindow() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = HistoryView(onClose: { [weak self] in
            self?.window?.orderOut(nil)
        })

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 520),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = L10n.historyTitle
        w.minSize = NSSize(width: 400, height: 300)
        w.contentView = NSHostingView(rootView: view)
        w.delegate = self
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

// MARK: - Vue principale

struct HistoryView: View {
    let onClose: () -> Void
    @ObservedObject private var history = TranslationHistory.shared
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
                Text(L10n.historyTitle)
                    .font(.headline)
                Spacer()
                Text("\(history.entries.count) entrée\(history.entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !history.entries.isEmpty {
                    Button(L10n.historyClear) { showClearConfirm = true }
                        .foregroundStyle(.red)
                        .buttonStyle(.plain)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if history.entries.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 44))
                        .foregroundStyle(.tertiary)
                    Text(L10n.historyEmpty)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(history.entries) { entry in
                    HistoryEntryRow(entry: entry)
                        .listRowSeparator(.visible)
                }
                .listStyle(.plain)
            }

            Divider()

            HStack {
                Spacer()
                Button(L10n.historyClose) { onClose() }
                    .keyboardShortcut(.return)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .alert(L10n.historyClear, isPresented: $showClearConfirm) {
            Button(L10n.historyClear, role: .destructive) { history.clear() }
            Button(L10n.isFR ? "Annuler" : "Cancel", role: .cancel) {}
        } message: {
            Text(L10n.isFR ? "Toutes les traductions seront supprimées." : "All translations will be deleted.")
        }
    }
}

// MARK: - Ligne d'historique

struct HistoryEntryRow: View {
    let entry: TranslationEntry
    @State private var copied = false

    var sourceLang: Language? { entry.sourceLang.flatMap { Language.find(id: $0) } }
    var targetLang: Language? { Language.find(id: entry.targetLang) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Ligne de méta-données
            HStack(spacing: 4) {
                if let sl = sourceLang {
                    Text(sl.flag)
                        .font(.system(size: 13))
                }
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                if let tl = targetLang {
                    Text(tl.flag)
                        .font(.system(size: 13))
                }
                Spacer()
                Text(entry.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Texte original
            Text(entry.originalText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Texte traduit
            Text(entry.translatedText)
                .font(.body)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Bouton copier
            HStack {
                Spacer()
                Button(copied ? L10n.popupCopied : L10n.historyCopy) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.translatedText, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(copied ? .green : .blue)
            }
        }
        .padding(.vertical, 6)
    }
}
