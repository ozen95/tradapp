import Cocoa
import ServiceManagement

class StatusBarController: NSObject {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem!
    private var loadingTimer: Timer?
    private var loadingStep = 0

    private override init() {}

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        buildMenu()
    }

    // MARK: - Icône & animation

    func setLoading(_ loading: Bool) {
        if loading {
            loadingStep = 0
            loadingTimer?.invalidate()
            loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.28, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let dots = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
                self.statusItem.button?.title = dots[self.loadingStep % dots.count]
                self.statusItem.button?.image = nil
                self.loadingStep += 1
            }
        } else {
            loadingTimer?.invalidate()
            loadingTimer = nil
            updateIcon()
        }
    }

    func updateIcon() {
        let s = AppSettings.shared
        let flag = Language.find(id: s.targetLanguage)?.flag ?? "🌐"
        statusItem.button?.image = nil
        statusItem.button?.title = s.isEnabled ? flag : "○"
        statusItem.button?.alphaValue = s.isEnabled ? 1.0 : 0.4
        statusItem.button?.font = NSFont.systemFont(ofSize: 15)
    }

    // MARK: - Menu

    func buildMenu() {
        let menu = NSMenu()
        let s = AppSettings.shared

        // Titre
        let title = NSMenuItem(title: "TradApp", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        // Accessibilité
        let axOK = AXIsProcessTrusted()
        let axItem = NSMenuItem(
            title: axOK ? L10n.menuAccessibilityOK : L10n.menuAccessibilityMissing,
            action: axOK ? nil : #selector(openAccessibility),
            keyEquivalent: ""
        )
        axItem.target = self
        axItem.isEnabled = !axOK
        menu.addItem(axItem)

        let relaunchItem = NSMenuItem(title: L10n.menuRelaunch, action: #selector(relaunchApp), keyEquivalent: "")
        relaunchItem.target = self
        menu.addItem(relaunchItem)
        menu.addItem(.separator())

        // Activer / Désactiver
        let hotkeyStr = HotkeyManager.hotkeyDisplayString(
            keyCode: s.hotkeyKeyCode,
            modifiers: s.hotkeyModifiers
        )
        let enableTitle = s.isEnabled ? "\(L10n.menuEnabled)  (\(hotkeyStr))" : L10n.menuDisabled
        let enableItem = NSMenuItem(title: enableTitle, action: #selector(toggleEnabled), keyEquivalent: "")
        enableItem.target = self
        menu.addItem(enableItem)
        menu.addItem(.separator())

        // ── Langue cible (30+ langues dans un sous-menu) ──────────────────
        let currentLang = Language.find(id: s.targetLanguage)
        let langLabel   = currentLang.map { "\($0.flag) \($0.nativeName)" } ?? "🌐"
        let langItem    = NSMenuItem(title: "\(L10n.menuTargetLanguage) \(langLabel)", action: nil, keyEquivalent: "")
        let langMenu    = NSMenu()

        for lang in Language.all {
            let item = NSMenuItem(title: lang.displayLabel, action: #selector(setLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.id
            item.state = (s.targetLanguage == lang.id) ? .on : .off
            langMenu.addItem(item)
        }
        langItem.submenu = langMenu
        menu.addItem(langItem)

        // ── Ton ──────────────────────────────────────────────────────────
        let toneItem = NSMenuItem(title: "\(L10n.menuTone) \(s.tone == "casual" ? L10n.settingsToneCasual : L10n.settingsToneFormal)", action: nil, keyEquivalent: "")
        let toneMenu = NSMenu()
        let casItem  = NSMenuItem(title: L10n.menuToneCasual, action: #selector(setCasual), keyEquivalent: "")
        casItem.target = self; casItem.state = s.tone == "casual" ? .on : .off
        toneMenu.addItem(casItem)
        let polItem = NSMenuItem(title: L10n.menuToneFormal, action: #selector(setPoli), keyEquivalent: "")
        polItem.target = self; polItem.state = s.tone == "poli" ? .on : .off
        toneMenu.addItem(polItem)
        toneItem.submenu = toneMenu
        menu.addItem(toneItem)

        // ── Genre (Thai uniquement) ───────────────────────────────────────
        if s.targetLanguage == "th" {
            let genderLabel = s.speakerGender == "masculin" ? L10n.menuGenderM : L10n.menuGenderF
            let genderItem  = NSMenuItem(title: "\(L10n.menuGender) \(genderLabel)", action: nil, keyEquivalent: "")
            let genderMenu  = NSMenu()
            let mItem = NSMenuItem(title: L10n.menuGenderM, action: #selector(setMasculin), keyEquivalent: "")
            mItem.target = self; mItem.state = s.speakerGender == "masculin" ? .on : .off
            genderMenu.addItem(mItem)
            let fItem = NSMenuItem(title: L10n.menuGenderF, action: #selector(setFeminin), keyEquivalent: "")
            fItem.target = self; fItem.state = s.speakerGender == "feminin" ? .on : .off
            genderMenu.addItem(fItem)
            genderItem.submenu = genderMenu
            menu.addItem(genderItem)
        }

        menu.addItem(.separator())

        // ── OCR ───────────────────────────────────────────────────────────
        let ocrItem = NSMenuItem(title: L10n.menuOCR, action: #selector(startOCR), keyEquivalent: "")
        ocrItem.target = self
        menu.addItem(ocrItem)

        // ── Historique ────────────────────────────────────────────────────
        let histItem = NSMenuItem(title: L10n.menuHistory, action: #selector(openHistory), keyEquivalent: "")
        histItem.target = self
        menu.addItem(histItem)

        menu.addItem(.separator())

        // ── Démarrage automatique ─────────────────────────────────────────
        let loginStatus  = SMAppService.mainApp.status
        let loginEnabled = (loginStatus == .enabled)
        let loginTitle   = loginEnabled ? "✓   \(L10n.menuLaunchAtLogin)" : "      \(L10n.menuLaunchAtLogin)"
        let loginItem    = NSMenuItem(title: loginTitle, action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)

        if loginStatus == .requiresApproval {
            let hint = NSMenuItem(title: "      \(L10n.menuLoginApprovalHint)", action: nil, keyEquivalent: "")
            hint.isEnabled = false
            menu.addItem(hint)
        }

        menu.addItem(.separator())

        // ── Préférences & Quitter ─────────────────────────────────────────
        let settingsItem = NSMenuItem(title: L10n.menuPreferences, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: L10n.menuQuit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func openAccessibility() {
        TranslationPopup.shared.show(text: L10n.isFR ? """
⚙️  Étapes pour activer l'accessibilité :

1. Dans les Réglages qui s'ouvrent :
   • Trouvez TradApp dans la liste
   • S'il est coché → décochez, attendez 2s, recochez
   • S'il est absent → cliquez ＋ et ajoutez TradApp.app

2. Revenez dans le menu et cliquez « Relancer TradApp »
""" : """
⚙️  Steps to enable accessibility:

1. In the Settings that open:
   • Find TradApp in the list
   • If checked → uncheck, wait 2s, re-check
   • If absent → click ＋ and add TradApp.app

2. Come back to the menu and click "Relaunch TradApp"
""", sourceLang: nil, originalText: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    @objc private func relaunchApp() {
        let path = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments  = ["-c", "sleep 0.8 && open '\(path)'"]
        try? task.run()
        NSApp.terminate(nil)
    }

    @objc private func toggleEnabled() {
        AppSettings.shared.isEnabled.toggle()
        updateIcon()
        buildMenu()
    }

    @objc private func setLanguage(_ sender: NSMenuItem) {
        guard let langID = sender.representedObject as? String else { return }
        AppSettings.shared.targetLanguage = langID
        updateIcon()
        buildMenu()
    }

    @objc private func setCasual()    { AppSettings.shared.tone = "casual"; buildMenu() }
    @objc private func setPoli()      { AppSettings.shared.tone = "poli";   buildMenu() }
    @objc private func setMasculin()  { AppSettings.shared.speakerGender = "masculin"; buildMenu() }
    @objc private func setFeminin()   { AppSettings.shared.speakerGender = "feminin";  buildMenu() }

    @objc private func startOCR() {
        TranslationController.shared.handleOCRHotkey()
    }

    @objc private func openHistory() {
        HistoryWindowController.shared.showWindow()
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch { }
        buildMenu()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showWindow()
    }
}
