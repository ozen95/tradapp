import Cocoa
import SwiftUI

// MARK: - Contrôleur de fenêtre

class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var settingsWindow: NSWindow?

    private override init() {}

    func showWindow() {
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(onClose: { [weak self] in
            self?.settingsWindow?.orderOut(nil)
        })

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = L10n.settingsTitle
        w.contentView = NSHostingView(rootView: view)
        w.delegate = self
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.settingsWindow = w
    }

    func windowWillClose(_ notification: Notification) {
        HotkeyManager.shared.resumeAfterRecording()
        settingsWindow = nil
    }
}

// MARK: - Enregistreur de raccourci (NSTextField personnalisé)

class HotkeyRecorderField: NSTextField {
    var onCapture: ((Int, Int) -> Void)?
    private(set) var currentKeyCode: Int
    private(set) var currentModifiers: Int
    private(set) var isRecording = false
    private var eventMonitor: Any?

    init(keyCode: Int, modifiers: Int) {
        self.currentKeyCode   = keyCode
        self.currentModifiers = modifiers
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configure() {
        isEditable   = false
        isSelectable = false
        isBordered   = true
        bezelStyle   = .roundedBezel
        alignment    = .center
        font         = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        toolTip      = L10n.settingsHotkeyHint
        updateDisplay()
    }

    func showHotkey(keyCode: Int, modifiers: Int) {
        currentKeyCode   = keyCode
        currentModifiers = modifiers
        if !isRecording { updateDisplay() }
    }

    private func updateDisplay() {
        stringValue = currentKeyCode == 0
            ? (L10n.isFR ? "Non défini" : "Not set")
            : HotkeyManager.hotkeyDisplayString(keyCode: currentKeyCode, modifiers: currentModifiers)
        textColor = .labelColor
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        if !isRecording { startRecording() }
    }

    private func startRecording() {
        isRecording = true
        stringValue = L10n.settingsHotkeyRecording
        textColor   = .systemBlue

        HotkeyManager.shared.suspendForRecording()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isRecording else { return event }

            if event.keyCode == 53 { // Échap = annuler
                self.cancelRecording()
                return nil
            }

            let modifierKeyCodes: Set<Int> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
            if modifierKeyCodes.contains(Int(event.keyCode)) { return event }

            let kc   = Int(event.keyCode)
            let mods = Int(event.modifierFlags.intersection([.control, .option, .shift, .command]).rawValue)

            self.currentKeyCode   = kc
            self.currentModifiers = mods
            self.isRecording      = false
            self.removeMonitor()
            self.updateDisplay()

            HotkeyManager.shared.resumeAfterRecording(keyCode: kc, modifiers: mods)
            self.onCapture?(kc, mods)
            return nil
        }
    }

    private func cancelRecording() {
        isRecording = false
        removeMonitor()
        updateDisplay()
        HotkeyManager.shared.resumeAfterRecording()
    }

    private func removeMonitor() {
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
    }

    override func resignFirstResponder() -> Bool {
        if isRecording { cancelRecording() }
        return super.resignFirstResponder()
    }
}

// MARK: - NSViewRepresentable pour SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: Int

    func makeCoordinator() -> Coordinator { Coordinator(keyCode: $keyCode, modifiers: $modifiers) }

    func makeNSView(context: Context) -> HotkeyRecorderField {
        let field = HotkeyRecorderField(keyCode: keyCode, modifiers: modifiers)
        field.onCapture = { kc, mods in
            context.coordinator.keyCode   = kc
            context.coordinator.modifiers = mods
        }
        return field
    }

    func updateNSView(_ nsView: HotkeyRecorderField, context: Context) {
        if !nsView.isRecording {
            nsView.showHotkey(keyCode: keyCode, modifiers: modifiers)
        }
    }

    class Coordinator: NSObject {
        @Binding var keyCode: Int
        @Binding var modifiers: Int
        init(keyCode: Binding<Int>, modifiers: Binding<Int>) {
            _keyCode   = keyCode
            _modifiers = modifiers
        }
    }
}

// MARK: - Vue SwiftUI des préférences

struct SettingsView: View {
    let onClose: () -> Void

    @State private var geminiKey     = AppSettings.shared.geminiAPIKey
    @State private var targetLang    = AppSettings.shared.targetLanguage
    @State private var tone          = AppSettings.shared.tone
    @State private var gender        = AppSettings.shared.speakerGender
    @State private var hotkeyKC     = AppSettings.shared.hotkeyKeyCode
    @State private var hotkeyMods   = AppSettings.shared.hotkeyModifiers
    @State private var ocrKC        = AppSettings.shared.ocrHotkeyKeyCode
    @State private var ocrMods      = AppSettings.shared.ocrHotkeyModifiers
    @State private var autoDetect   = AppSettings.shared.autoDetectDirection
    @State private var showKey      = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // En-tête
            HStack(spacing: 10) {
                Image(systemName: "character.bubble.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TradApp").font(.headline)
                    Text(L10n.settingsSubtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 16)

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 14) {

                // ── Raccourci traduction ──────────────────────────────────
                GridRow {
                    Text(L10n.settingsHotkey)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    HStack(spacing: 10) {
                        HotkeyRecorderView(keyCode: $hotkeyKC, modifiers: $hotkeyMods)
                            .frame(width: 110, height: 26)
                        Text(L10n.settingsHotkeyHint)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // ── Raccourci OCR ─────────────────────────────────────────
                GridRow {
                    Text(L10n.settingsOCRHotkey)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    HStack(spacing: 10) {
                        HotkeyRecorderView(keyCode: $ocrKC, modifiers: $ocrMods)
                            .frame(width: 110, height: 26)
                        Text(L10n.isFR ? "Optionnel — capture + OCR" : "Optional — capture + OCR")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // ── Auto-direction ────────────────────────────────────────
                GridRow {
                    Text(L10n.settingsAutoDirection)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    HStack(spacing: 8) {
                        Toggle("", isOn: $autoDetect)
                            .labelsHidden()
                            .toggleStyle(.switch)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L10n.settingsAutoDir1).font(.caption)
                            Text(L10n.settingsAutoDir2).font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                }

                // ── Langue cible ──────────────────────────────────────────
                GridRow {
                    Text(L10n.settingsTargetLang)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    Picker("", selection: $targetLang) {
                        ForEach(Language.all) { lang in
                            Text(lang.displayLabel).tag(lang.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 280)
                }

                // ── Ton ───────────────────────────────────────────────────
                GridRow {
                    Text(L10n.settingsTone)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    Picker("", selection: $tone) {
                        Text(L10n.settingsToneCasual).tag("casual")
                        Text(L10n.settingsToneFormal).tag("poli")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 280)
                }

                // ── Genre (Thai uniquement) ───────────────────────────────
                GridRow {
                    Text(L10n.settingsGender)
                        .foregroundStyle(targetLang == "th" ? .secondary : .tertiary)
                        .gridColumnAlignment(.trailing)
                    Picker("", selection: $gender) {
                        Text(L10n.settingsGenderM).tag("masculin")
                        Text(L10n.settingsGenderF).tag("feminin")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 280)
                    .disabled(targetLang != "th")
                    .opacity(targetLang == "th" ? 1 : 0.35)
                }
            }
            .padding(.vertical, 16)

            Divider()

            // ── Clé API Gemini ─────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(L10n.settingsGeminiKey).foregroundStyle(.secondary)
                    Text(L10n.settingsGeminiOptional)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                .padding(.top, 12)

                HStack {
                    if showKey {
                        TextField("", text: $geminiKey).textFieldStyle(.roundedBorder)
                    } else {
                        SecureField(L10n.settingsGeminiPlaceholder, text: $geminiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button(showKey ? L10n.settingsHide : L10n.settingsShow) { showKey.toggle() }
                        .font(.caption)
                }

                Text(L10n.settingsGeminiHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            Spacer()

            HStack {
                Spacer()
                Button(L10n.settingsSave) {
                    saveSettings()
                    StatusBarController.shared.buildMenu()
                    onClose()
                }
                .keyboardShortcut(.return)
            }
            .padding(.top, 12)
        }
        .padding(20)
        .frame(width: 520, height: 500)
    }

    private func saveSettings() {
        AppSettings.shared.targetLanguage      = targetLang
        AppSettings.shared.tone                = tone
        AppSettings.shared.speakerGender       = gender
        AppSettings.shared.geminiAPIKey        = geminiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        AppSettings.shared.autoDetectDirection = autoDetect
        HotkeyManager.shared.updateHotkey(keyCode: hotkeyKC, modifiers: hotkeyMods)
        HotkeyManager.shared.updateOCRHotkey(keyCode: ocrKC, modifiers: ocrMods)
        StatusBarController.shared.updateIcon()
    }
}
