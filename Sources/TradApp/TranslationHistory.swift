import Foundation

struct TranslationEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let originalText: String
    let translatedText: String
    let sourceLang: String?   // Code langue détectée (ex: "fr")
    let targetLang: String    // Code langue cible (ex: "th")

    init(originalText: String, translatedText: String, sourceLang: String?, targetLang: String) {
        self.id             = UUID()
        self.date           = Date()
        self.originalText   = originalText
        self.translatedText = translatedText
        self.sourceLang     = sourceLang
        self.targetLang     = targetLang
    }
}

final class TranslationHistory: ObservableObject {
    static let shared = TranslationHistory()

    @Published private(set) var entries: [TranslationEntry] = []

    private let maxEntries  = 50
    private let storageKey  = "translationHistory_v2"

    private init() { load() }

    func add(original: String, translated: String, sourceLang: String?, targetLang: String) {
        // Ne pas sauvegarder les messages d'erreur ou les instructions
        guard !translated.hasPrefix("⚠️") else { return }
        guard !original.isEmpty, !translated.isEmpty else { return }

        let entry = TranslationEntry(
            originalText:   original,
            translatedText: translated,
            sourceLang:     sourceLang,
            targetLang:     targetLang
        )
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func clear() {
        entries = []
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TranslationEntry].self, from: data) else { return }
        entries = decoded
    }
}
