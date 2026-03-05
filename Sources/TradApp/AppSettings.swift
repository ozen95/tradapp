import Foundation

final class AppSettings {
    static let shared = AppSettings()

    // MARK: - Langue cible (codes Google Translate lowercase, ex: "th", "en", "fr")

    var targetLanguage: String {
        get {
            let stored = UserDefaults.standard.string(forKey: "targetLanguage") ?? "th"
            // Migration depuis anciens codes uppercase (TH → th, EN → en, ES → es)
            switch stored {
            case "TH": return "th"
            case "EN": return "en"
            case "ES": return "es"
            default:   return stored
            }
        }
        set { UserDefaults.standard.set(newValue, forKey: "targetLanguage") }
    }

    // MARK: - Ton & genre

    var tone: String {
        get { UserDefaults.standard.string(forKey: "tone") ?? "casual" }
        set { UserDefaults.standard.set(newValue, forKey: "tone") }
    }

    var speakerGender: String {
        get { UserDefaults.standard.string(forKey: "speakerGender") ?? "masculin" }
        set { UserDefaults.standard.set(newValue, forKey: "speakerGender") }
    }

    // MARK: - Activation

    var isEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: "isEnabled") != nil else { return true }
            return UserDefaults.standard.bool(forKey: "isEnabled")
        }
        set { UserDefaults.standard.set(newValue, forKey: "isEnabled") }
    }

    // MARK: - API Gemini

    var geminiAPIKey: String {
        get { UserDefaults.standard.string(forKey: "geminiAPIKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "geminiAPIKey") }
    }

    // MARK: - Raccourci principal (traduction)

    var hotkeyKeyCode: Int {
        get {
            guard UserDefaults.standard.object(forKey: "hotkeyKeyCode") != nil else { return 105 } // F13
            return UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
        }
        set { UserDefaults.standard.set(newValue, forKey: "hotkeyKeyCode") }
    }

    var hotkeyModifiers: Int {
        get { UserDefaults.standard.integer(forKey: "hotkeyModifiers") }
        set { UserDefaults.standard.set(newValue, forKey: "hotkeyModifiers") }
    }

    // MARK: - Raccourci OCR (0 = non défini)

    var ocrHotkeyKeyCode: Int {
        get { UserDefaults.standard.integer(forKey: "ocrHotkeyKeyCode") }
        set { UserDefaults.standard.set(newValue, forKey: "ocrHotkeyKeyCode") }
    }

    var ocrHotkeyModifiers: Int {
        get { UserDefaults.standard.integer(forKey: "ocrHotkeyModifiers") }
        set { UserDefaults.standard.set(newValue, forKey: "ocrHotkeyModifiers") }
    }

    // MARK: - Auto-détection de direction

    var autoDetectDirection: Bool {
        get {
            guard UserDefaults.standard.object(forKey: "autoDetectDirection") != nil else { return true }
            return UserDefaults.standard.bool(forKey: "autoDetectDirection")
        }
        set { UserDefaults.standard.set(newValue, forKey: "autoDetectDirection") }
    }

    private init() {}
}
