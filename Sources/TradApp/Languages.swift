import Foundation

struct Language: Identifiable, Equatable {
    let id: String        // Google Translate code (e.g. "fr", "th", "en")
    let flag: String      // Flag emoji
    let nativeName: String // Name in the language itself
    let englishName: String

    static func find(id: String) -> Language? {
        all.first { $0.id.lowercased() == id.lowercased() }
    }

    var displayLabel: String { "\(flag)  \(nativeName)" }
}

extension Language {
    static let all: [Language] = [
        Language(id: "ar",    flag: "🇸🇦", nativeName: "العربية",          englishName: "Arabic"),
        Language(id: "zh-CN", flag: "🇨🇳", nativeName: "中文（简体）",       englishName: "Chinese (Simplified)"),
        Language(id: "zh-TW", flag: "🇹🇼", nativeName: "中文（繁體）",       englishName: "Chinese (Traditional)"),
        Language(id: "cs",    flag: "🇨🇿", nativeName: "Čeština",          englishName: "Czech"),
        Language(id: "da",    flag: "🇩🇰", nativeName: "Dansk",            englishName: "Danish"),
        Language(id: "nl",    flag: "🇳🇱", nativeName: "Nederlands",       englishName: "Dutch"),
        Language(id: "en",    flag: "🇬🇧", nativeName: "English",          englishName: "English"),
        Language(id: "fi",    flag: "🇫🇮", nativeName: "Suomi",            englishName: "Finnish"),
        Language(id: "fr",    flag: "🇫🇷", nativeName: "Français",         englishName: "French"),
        Language(id: "de",    flag: "🇩🇪", nativeName: "Deutsch",          englishName: "German"),
        Language(id: "el",    flag: "🇬🇷", nativeName: "Ελληνικά",         englishName: "Greek"),
        Language(id: "he",    flag: "🇮🇱", nativeName: "עברית",            englishName: "Hebrew"),
        Language(id: "hi",    flag: "🇮🇳", nativeName: "हिन्दी",            englishName: "Hindi"),
        Language(id: "hu",    flag: "🇭🇺", nativeName: "Magyar",           englishName: "Hungarian"),
        Language(id: "id",    flag: "🇮🇩", nativeName: "Bahasa Indonesia", englishName: "Indonesian"),
        Language(id: "it",    flag: "🇮🇹", nativeName: "Italiano",         englishName: "Italian"),
        Language(id: "ja",    flag: "🇯🇵", nativeName: "日本語",            englishName: "Japanese"),
        Language(id: "ko",    flag: "🇰🇷", nativeName: "한국어",            englishName: "Korean"),
        Language(id: "ms",    flag: "🇲🇾", nativeName: "Bahasa Melayu",    englishName: "Malay"),
        Language(id: "no",    flag: "🇳🇴", nativeName: "Norsk",            englishName: "Norwegian"),
        Language(id: "fa",    flag: "🇮🇷", nativeName: "فارسی",            englishName: "Persian"),
        Language(id: "pl",    flag: "🇵🇱", nativeName: "Polski",           englishName: "Polish"),
        Language(id: "pt",    flag: "🇧🇷", nativeName: "Português",        englishName: "Portuguese"),
        Language(id: "ro",    flag: "🇷🇴", nativeName: "Română",           englishName: "Romanian"),
        Language(id: "ru",    flag: "🇷🇺", nativeName: "Русский",          englishName: "Russian"),
        Language(id: "es",    flag: "🇪🇸", nativeName: "Español",          englishName: "Spanish"),
        Language(id: "sv",    flag: "🇸🇪", nativeName: "Svenska",          englishName: "Swedish"),
        Language(id: "th",    flag: "🇹🇭", nativeName: "ภาษาไทย",          englishName: "Thai"),
        Language(id: "tr",    flag: "🇹🇷", nativeName: "Türkçe",           englishName: "Turkish"),
        Language(id: "uk",    flag: "🇺🇦", nativeName: "Українська",       englishName: "Ukrainian"),
        Language(id: "ur",    flag: "🇵🇰", nativeName: "اردو",             englishName: "Urdu"),
        Language(id: "vi",    flag: "🇻🇳", nativeName: "Tiếng Việt",       englishName: "Vietnamese"),
    ]
}
