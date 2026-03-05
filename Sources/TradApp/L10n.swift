import Foundation

// MARK: - Localisation automatique FR / EN selon la locale système

enum L10n {

    static var isFR: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    private static func s(_ fr: String, _ en: String) -> String {
        isFR ? fr : en
    }

    // MARK: - Menu barre d'état

    static var menuAccessibilityOK: String      { s("✓  Accessibilité : OK", "✓  Accessibility: OK") }
    static var menuAccessibilityMissing: String { s("⚠️  Accessibilité non autorisée — cliquez ici", "⚠️  Accessibility not granted — click here") }
    static var menuRelaunch: String             { s("↺  Relancer TradApp", "↺  Relaunch TradApp") }
    static var menuEnabled: String              { s("✓   Activé", "✓   Enabled") }
    static var menuDisabled: String             { s("      Désactivé", "      Disabled") }
    static var menuTargetLanguage: String       { s("Langue →", "Language →") }
    static var menuTone: String                 { s("Ton →", "Tone →") }
    static var menuToneCasual: String           { s("Casual  (décontracté)", "Casual  (relaxed)") }
    static var menuToneFormal: String           { s("Poli  (formel)", "Formal  (polite)") }
    static var menuGender: String               { s("Genre →", "Gender →") }
    static var menuGenderM: String              { s("Masculin  →  ครับ", "Masculine  →  ครับ") }
    static var menuGenderF: String              { s("Féminin   →  ค่ะ", "Feminine   →  ค่ะ") }
    static var menuHistory: String              { s("Historique...", "History...") }
    static var menuLaunchAtLogin: String        { s("Démarrer avec macOS", "Launch at Login") }
    static var menuLoginApprovalHint: String    { s("→ Réglages > Général > Éléments ouverts", "→ Settings > General > Login Items") }
    static var menuPreferences: String          { s("Préférences...", "Preferences...") }
    static var menuQuit: String                 { s("Quitter TradApp", "Quit TradApp") }
    static var menuOCR: String                  { s("🔍  Capturer & Traduire (OCR)...", "🔍  Capture & Translate (OCR)...") }

    // MARK: - Popup

    static var popupCopy: String               { s("Copier", "Copy") }
    static var popupCopied: String             { s("✓ Copié", "✓ Copied") }
    static var popupSwap: String               { s("↔ Inverser", "↔ Swap") }
    static var popupFrom: String               { s("depuis", "from") }
    static var popupErrorConnection: String    { s("⚠️  Erreur — vérifiez votre connexion", "⚠️  Error — check your connection") }
    static var popupErrorNoText: String        { s("Rien à traduire", "Nothing to translate") }
    static var popupErrorNoTextHint: String    { s("Cliquez dans un champ texte, puis appuyez sur ", "Click in a text field, then press ") }
    static var popupAccessibilityMissing: String { s(
        "⚠️  Accessibilité non autorisée\n\nCliquez « Relancer TradApp » dans le menu, accordez l'accès, puis relancez.",
        "⚠️  Accessibility not granted\n\nClick 'Relaunch TradApp' in the menu, grant access, then relaunch."
    ) }
    static var popupOCRInstruction: String     { s("Glissez pour sélectionner une zone à traduire\nÉchap pour annuler", "Drag to select an area to translate\nEsc to cancel") }

    // MARK: - Settings

    static var settingsTitle: String           { s("TradApp — Préférences", "TradApp — Preferences") }
    static var settingsSubtitle: String        { s("Traducteur universel — fonctionne partout", "Universal translator — works everywhere") }
    static var settingsHotkey: String          { s("Raccourci", "Hotkey") }
    static var settingsHotkeyHint: String      { s("Cliquez pour changer · Échap = annuler", "Click to change · Esc = cancel") }
    static var settingsHotkeyRecording: String { s("⌨  appuyez sur un raccourci…", "⌨  press a shortcut…") }
    static var settingsOCRHotkey: String       { s("Raccourci OCR", "OCR Hotkey") }
    static var settingsAutoDirection: String   { s("Auto-direction", "Auto-direction") }
    static var settingsAutoDir1: String        { s("Texte dans la langue cible → popup (lecture)", "Text in target language → popup (read)") }
    static var settingsAutoDir2: String        { s("Autre langue → remplace le texte (écriture)", "Other language → replaces text (write)") }
    static var settingsTargetLang: String      { s("Langue cible", "Target language") }
    static var settingsTone: String            { s("Ton", "Tone") }
    static var settingsToneCasual: String      { s("Casual", "Casual") }
    static var settingsToneFormal: String      { s("Poli", "Formal") }
    static var settingsGender: String          { s("Genre (Thai)", "Gender (Thai)") }
    static var settingsGenderM: String         { s("Masculin  (ครับ)", "Masculine  (ครับ)") }
    static var settingsGenderF: String         { s("Féminin  (ค่ะ)", "Feminine  (ค่ะ)") }
    static var settingsGeminiKey: String       { s("Clé Gemini", "Gemini Key") }
    static var settingsGeminiOptional: String  { s("requis", "required") }
    static var settingsGeminiPlaceholder: String { s("AIzaSy…", "AIzaSy…") }
    static var settingsGeminiHint: String      { s(
        "Clé gratuite sur aistudio.google.com/apikey — 1 500 traductions/jour incluses.",
        "Free key at aistudio.google.com/apikey — 1,500 translations/day included."
    ) }
    static var settingsSave: String            { s("Enregistrer et fermer", "Save and close") }
    static var settingsShow: String            { s("Voir", "Show") }
    static var settingsHide: String            { s("Cacher", "Hide") }

    // MARK: - Historique

    static var historyTitle: String  { s("Historique des traductions", "Translation History") }
    static var historyEmpty: String  { s("Aucune traduction pour l'instant", "No translations yet") }
    static var historyClear: String  { s("Tout effacer", "Clear all") }
    static var historyClose: String  { s("Fermer", "Close") }
    static var historyCopy: String   { s("Copier", "Copy") }

    // MARK: - Onboarding

    static var onboardingTitle: String    { s("Bienvenue dans TradApp", "Welcome to TradApp") }
    static var onboardingSubtitle: String { s("Traduit en un raccourci, partout sur votre Mac.", "Translates with a shortcut, everywhere on your Mac.") }
    static var onboardingNext: String     { s("Suivant →", "Next →") }
    static var onboardingStart: String    { s("C'est parti !", "Let's go!") }
    static var onboardingOpenAX: String   { s("Ouvrir Accessibilité", "Open Accessibility") }
    static var onboardingAXGranted: String { s("✓  Accessibilité accordée", "✓  Accessibility granted") }
    static var onboardingAXMissing: String { s("Non accordée", "Not granted") }

    static var onboardingF1Title: String  { s("Fonctionne partout", "Works everywhere") }
    static var onboardingF1Desc: String   { s("Dans WhatsApp, Mail, Notes, Word, et toute autre app.", "In WhatsApp, Mail, Notes, Word, and any other app.") }
    static var onboardingF2Title: String  { s("30+ langues", "30+ languages") }
    static var onboardingF2Desc: String   { s("Français, Anglais, Japonais, Arabe, Thai et bien plus.", "French, English, Japanese, Arabic, Thai and many more.") }
    static var onboardingF3Title: String  { s("Traduction OCR", "OCR Translation") }
    static var onboardingF3Desc: String   { s("Capturez une zone d'écran et traduisez le texte d'une image.", "Capture a screen area and translate text from an image.") }
    static var onboardingF4Title: String  { s("Historique", "History") }
    static var onboardingF4Desc: String   { s("Retrouvez toutes vos traductions récentes.", "Find all your recent translations.") }

    static var onboardingAXTitle: String  { s("Autoriser l'accessibilité", "Grant Accessibility") }
    static var onboardingAXDesc: String   { s(
        "TradApp a besoin de l'accessibilité pour lire et injecter du texte dans vos apps.",
        "TradApp needs accessibility to read and inject text in your apps."
    ) }
    static var onboardingAXStep1: String  { s("Cliquez le bouton ci-dessous", "Click the button below") }
    static var onboardingAXStep2: String  { s("Déverrouillez et cochez TradApp", "Unlock and check TradApp") }
    static var onboardingAXStep3: String  { s("Revenez ici et cliquez Suivant", "Come back here and click Next") }

    static var onboardingLangTitle: String { s("Choisissez votre langue", "Choose your language") }
    static var onboardingLangDesc: String  { s("Vers quelle langue souhaitez-vous traduire ?", "Which language do you want to translate into?") }

    static var onboardingHowTitle: String  { s("Comment ça marche", "How it works") }
    static var onboardingHowStep1: String  { s("Cliquez dans un champ texte de n'importe quelle app", "Click in any text field in any app") }
    static var onboardingHowStep2: String  { s("Appuyez sur ", "Press ") }
    static var onboardingHowStep3: String  { s("Le texte est traduit et remplacé automatiquement", "Text is translated and replaced automatically") }
    static var onboardingTip: String       { s(
        "💡 Sélectionnez une partie du texte pour ne traduire que la sélection.",
        "💡 Select part of the text to translate only the selection."
    ) }
}
