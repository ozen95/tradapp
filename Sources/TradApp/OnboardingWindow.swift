import Cocoa
import SwiftUI

// MARK: - Contrôleur

class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    private override init() {}

    func showIfNeeded() {
        let alreadyOnboarded = UserDefaults.standard.bool(forKey: "v2_onboarded")
        guard !alreadyOnboarded else { return }
        show()
    }

    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = OnboardingView(onComplete: { [weak self] in
            UserDefaults.standard.set(true, forKey: "v2_onboarded")
            self?.window?.orderOut(nil)
            self?.window = nil

            let hotkey = HotkeyManager.hotkeyDisplayString(
                keyCode: AppSettings.shared.hotkeyKeyCode,
                modifiers: AppSettings.shared.hotkeyModifiers
            )
            let flag = Language.find(id: AppSettings.shared.targetLanguage)?.flag ?? "🌐"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                TranslationPopup.shared.show(
                    text: L10n.isFR
                        ? "✓  TradApp est prêt \(flag)\n\nAppuyez sur \(hotkey) dans n'importe quelle app pour traduire."
                        : "✓  TradApp is ready \(flag)\n\nPress \(hotkey) in any app to translate.",
                    sourceLang: nil,
                    originalText: nil
                )
            }
        })

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "TradApp"
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

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var page = 0
    @State private var axGranted = AXIsProcessTrusted()
    @State private var selectedLang = AppSettings.shared.targetLanguage

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // En-tête fixe
            HStack(spacing: 12) {
                Image(systemName: "character.bubble.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.onboardingTitle)
                        .font(.title2.bold())
                    Text(L10n.onboardingSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Contenu de page
            Group {
                switch page {
                case 0: featuresPage
                case 1: accessibilityPage
                case 2: languagePage
                default: howToPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 28)
            .padding(.vertical, 20)

            Divider()

            // Navigation
            HStack {
                // Indicateurs de page
                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.blue : Color.gray.opacity(0.35))
                            .frame(width: 7, height: 7)
                    }
                }

                Spacer()

                if page > 0 {
                    Button(L10n.isFR ? "← Retour" : "← Back") {
                        withAnimation(.easeInOut(duration: 0.2)) { page -= 1 }
                    }
                    .buttonStyle(.bordered)
                }

                if page < totalPages - 1 {
                    Button(L10n.onboardingNext) {
                        withAnimation(.easeInOut(duration: 0.2)) { page += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                } else {
                    Button(L10n.onboardingStart) {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
        }
        .frame(width: 560, height: 500)
    }

    // MARK: - Page 0 : Fonctionnalités

    var featuresPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.isFR ? "Ce que TradApp fait pour vous" : "What TradApp does for you")
                .font(.title3.bold())

            featureRow(icon: "apps.iphone.badge.plus", color: .blue,
                       title: L10n.onboardingF1Title, desc: L10n.onboardingF1Desc)
            featureRow(icon: "globe",                  color: .green,
                       title: L10n.onboardingF2Title, desc: L10n.onboardingF2Desc)
            featureRow(icon: "camera.viewfinder",      color: .orange,
                       title: L10n.onboardingF3Title, desc: L10n.onboardingF3Desc)
            featureRow(icon: "clock.arrow.circlepath", color: .purple,
                       title: L10n.onboardingF4Title, desc: L10n.onboardingF4Desc)

            Spacer()
        }
    }

    // MARK: - Page 1 : Accessibilité

    var accessibilityPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.onboardingAXTitle)
                .font(.title3.bold())
            Text(L10n.onboardingAXDesc)
                .foregroundStyle(.secondary)

            if axGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 18))
                    Text(L10n.onboardingAXGranted)
                        .foregroundStyle(.green)
                        .font(.body.bold())
                }
                .padding(.top, 8)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    stepRow(number: "1", text: L10n.onboardingAXStep1)
                    stepRow(number: "2", text: L10n.onboardingAXStep2)
                    stepRow(number: "3", text: L10n.onboardingAXStep3)
                }
                .padding(.top, 4)

                HStack {
                    Button(L10n.onboardingOpenAX) {
                        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
                        AXIsProcessTrustedWithOptions(opts)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            axGranted = AXIsProcessTrusted()
                        }
                    }
                    .buttonStyle(.bordered)

                    if !axGranted {
                        Text(L10n.onboardingAXMissing)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - Page 2 : Langue

    var languagePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.onboardingLangTitle)
                .font(.title3.bold())
            Text(L10n.onboardingLangDesc)
                .foregroundStyle(.secondary)

            Picker("", selection: $selectedLang) {
                ForEach(Language.all) { lang in
                    Text(lang.displayLabel).tag(lang.id)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 280)
            .onChange(of: selectedLang) { newVal in
                AppSettings.shared.targetLanguage = newVal
                StatusBarController.shared.updateIcon()
                StatusBarController.shared.buildMenu()
            }

            Spacer()
        }
    }

    // MARK: - Page 3 : Comment utiliser

    var howToPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.onboardingHowTitle)
                .font(.title3.bold())

            let hotkey = HotkeyManager.hotkeyDisplayString(
                keyCode: AppSettings.shared.hotkeyKeyCode,
                modifiers: AppSettings.shared.hotkeyModifiers
            )

            VStack(alignment: .leading, spacing: 12) {
                stepRow(number: "1", text: L10n.onboardingHowStep1)
                stepRow(number: "2", text: L10n.onboardingHowStep2 + hotkey)
                stepRow(number: "3", text: L10n.onboardingHowStep3)
            }

            Divider()
                .padding(.top, 4)

            Text(L10n.onboardingTip)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Composants réutilisables

    func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.bold())
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(.blue))
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
