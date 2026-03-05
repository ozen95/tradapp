import Foundation

class TranslationEngine {
    static let shared = TranslationEngine()

    private init() {}

    // completion: (texte traduit, langue source détectée)
    func translate(text: String, completion: @escaping (String?, String?) -> Void) {
        let settings = AppSettings.shared
        guard !settings.geminiAPIKey.isEmpty else {
            completion("⚠️ Clé API Gemini manquante — ouvre les Préférences pour l'ajouter.", nil)
            return
        }
        translateWithGemini(text: text, settings: settings, completion: completion)
    }

    // MARK: - Gemini API

    private func translateWithGemini(text: String, settings: AppSettings, completion: @escaping (String?, String?) -> Void) {
        callGeminiAPI(text: text, settings: settings) { translated in
            DispatchQueue.main.async {
                completion(translated, nil)
            }
        }
    }

    private func callGeminiAPI(text: String, settings: AppSettings, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(settings.geminiAPIKey)") else {
            completion(nil)
            return
        }

        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": buildGeminiPrompt(text: text, settings: settings)]]]],
            "generationConfig": ["temperature": 0.3, "maxOutputTokens": 1024]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("TradApp: erreur Gemini — \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                completion(nil)
                return
            }
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }

    private func buildGeminiPrompt(text: String, settings: AppSettings) -> String {
        let langEnglish = Language.find(id: settings.targetLanguage)?.englishName ?? settings.targetLanguage
        let isCasual    = settings.tone == "casual"
        let toneDesc    = isCasual ? "casual and natural" : "polite and formal"

        var langSpecific = ""
        switch settings.targetLanguage {
        case "th":
            let particle = settings.speakerGender == "masculin" ? "ครับ" : "ค่ะ"
            let casNote  = isCasual ? "Use นะ, เลย for casual endings." : "End sentences with \(particle)."
            langSpecific = "\(casNote) "
        case "ja":
            langSpecific = isCasual ? "Use 普通体 (plain form). " : "Use 丁寧語 (polite -ます/-です form). "
        case "ko":
            langSpecific = isCasual ? "Use 반말 (informal speech). " : "Use 존댓말 (formal speech). "
        case "de":
            langSpecific = isCasual ? "Use 'du' form. " : "Use 'Sie' form. "
        default:
            break
        }

        return """
You are a universal translation assistant. \
Auto-detect the source language. \
Correct grammar errors, translate to \(langEnglish), tone: \(toneDesc). \
\(langSpecific)If the text is already in the target language, only correct it. \
Reply ONLY with the final translated text, no quotes, no explanation.

Text: \(text)
"""
    }

    // MARK: - Particules de politesse thaï

    private func applyThaiToneParticle(_ text: String, tone: String, gender: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let particles = ["ครับ", "ค่ะ", "คะ", "นะ", "เลย", "อ่ะ", "นะครับ", "นะค่ะ", "เนาะ", "จ้า", "จ้ะ"]
        if particles.contains(where: { result.hasSuffix($0) }) {
            return result
        }
        if result.count < 2 { return result }

        if tone == "poli" {
            result += gender == "masculin" ? "ครับ" : "ค่ะ"
        }
        return result
    }
}
