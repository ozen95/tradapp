import Foundation

class TranslationEngine {
    static let shared = TranslationEngine()

    private init() {}

    // completion: (texte traduit, langue source détectée)
    func translate(text: String, completion: @escaping (String?, String?) -> Void) {
        let settings = AppSettings.shared
        if !settings.geminiAPIKey.isEmpty {
            translateWithGemini(text: text, settings: settings, completion: completion)
        } else {
            translateWithGoogle(text: text, settings: settings, completion: completion)
        }
    }

    // MARK: - Google Translate (détection de langue incluse, zéro config)

    private func translateWithGoogle(text: String, settings: AppSettings, completion: @escaping (String?, String?) -> Void) {
        let targetLang = settings.targetLanguage.lowercased()

        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(targetLang)&dt=t&q=\(encoded)") else {
            completion(nil, nil)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            // Erreur réseau explicite
            if let error = error {
                print("TradApp: erreur réseau Google — \(error.localizedDescription)")
                completion(nil, nil)
                return
            }

            guard let data = data else {
                completion(nil, nil)
                return
            }

            let (rawText, detectedLang) = self.parseGoogleResponse(data)
            guard var translated = rawText else {
                completion(nil, nil)
                return
            }

            // Particules de politesse thaï
            if settings.targetLanguage == "th" {
                translated = self.applyThaiToneParticle(translated, tone: settings.tone, gender: settings.speakerGender)
            }

            completion(translated, detectedLang)
        }.resume()
    }

    private func parseGoogleResponse(_ data: Data) -> (String?, String?) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let segments = json.first as? [[Any]] else {
            return (nil, nil)
        }
        let text = segments.compactMap { $0.first as? String }.joined()
        // json[2] contient le code langue détecté (ex: "fr", "th", "en")
        let detectedLang = json.count > 2 ? json[2] as? String : nil
        return (text.isEmpty ? nil : text, detectedLang)
    }

    // MARK: - Gemini API + détection Google en parallèle

    private func translateWithGemini(text: String, settings: AppSettings, completion: @escaping (String?, String?) -> Void) {
        let group = DispatchGroup()
        var translatedText: String?
        var detectedLang: String?

        // Détection de langue via Google (rapide, ~100ms)
        group.enter()
        detectSourceLanguage(text: text) { lang in
            detectedLang = lang
            group.leave()
        }

        // Traduction Gemini en parallèle
        group.enter()
        callGeminiAPI(text: text, settings: settings) { t in
            translatedText = t
            group.leave()
        }

        group.notify(queue: .main) {
            // Fallback vers Google si Gemini échoue
            if translatedText == nil {
                self.translateWithGoogle(text: text, settings: settings, completion: completion)
            } else {
                completion(translatedText, detectedLang)
            }
        }
    }

    private func detectSourceLanguage(text: String, completion: @escaping (String?) -> Void) {
        let shortText = String(text.prefix(200))
        guard let encoded = shortText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=en&dt=t&q=\(encoded)") else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
                  json.count > 2,
                  let lang = json[2] as? String else {
                completion(nil)
                return
            }
            completion(lang)
        }.resume()
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

        URLSession.shared.dataTask(with: request) { data, _, _ in
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
        // Nom anglais de la langue cible pour le prompt
        let langEnglish = Language.find(id: settings.targetLanguage)?.englishName ?? settings.targetLanguage
        let isCasual    = settings.tone == "casual"
        let toneDesc    = isCasual ? "casual and natural" : "polite and formal"

        // Instructions spécifiques selon la langue cible
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
