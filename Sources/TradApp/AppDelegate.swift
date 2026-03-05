import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        StatusBarController.shared.setup()

        // Raccourci principal : traduction
        HotkeyManager.shared.onHotkeyPressed = {
            TranslationController.shared.handleHotkey()
        }

        // Raccourci OCR
        HotkeyManager.shared.onOCRPressed = {
            TranslationController.shared.handleOCRHotkey()
        }

        HotkeyManager.shared.start()

        handleLaunch()
    }

    private func handleLaunch() {
        // Onboarding en priorité si jamais effectué
        let alreadyOnboarded = UserDefaults.standard.bool(forKey: "v2_onboarded")

        if !alreadyOnboarded {
            // Migrer l'ancienne clé d'onboarding si l'utilisateur avait v1
            let hadV1 = UserDefaults.standard.bool(forKey: "v1_configured")
            if hadV1 {
                // Utilisateur existant : marquer comme onboardé, juste vérifier les permissions
                UserDefaults.standard.set(true, forKey: "v2_onboarded")
                checkPermissionsForExistingUser()
            } else {
                // Nouvel utilisateur : afficher l'onboarding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    OnboardingWindowController.shared.show()
                }
            }
        } else {
            // Utilisateur connu : vérifier les permissions en silence
            checkPermissionsForExistingUser()
        }
    }

    private func checkPermissionsForExistingUser() {
        if !AXIsProcessTrusted() {
            showAccessibilityAlert()
        } else {
            // Activer le démarrage auto au premier lancement (si pas déjà fait)
            let autoLaunchConfigured = UserDefaults.standard.bool(forKey: "autoLaunchConfigured")
            if !autoLaunchConfigured {
                UserDefaults.standard.set(true, forKey: "autoLaunchConfigured")
                try? SMAppService.mainApp.register()
            }
        }
    }

    private func showAccessibilityAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.activate(ignoringOtherApps: true)

            let alert = NSAlert()
            alert.messageText     = L10n.isFR ? "Étape unique — 30 secondes" : "One-time setup — 30 seconds"
            alert.informativeText = L10n.isFR ? """
TradApp doit accéder à l'accessibilité pour lire et écrire dans vos apps.

1. Cliquez le cadenas 🔒 pour déverrouiller
2. Cochez ✓ TradApp dans la liste
3. Quittez TradApp et relancez-le
""" : """
TradApp needs accessibility access to read and write in your apps.

1. Click the lock 🔒 to unlock
2. Check ✓ TradApp in the list
3. Quit TradApp and relaunch it
"""
            alert.addButton(withTitle: L10n.isFR ? "Ouvrir Accessibilité" : "Open Accessibility")
            alert.addButton(withTitle: L10n.isFR ? "Plus tard" : "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
                AXIsProcessTrustedWithOptions(options)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
