# TradApp

Application de traduction instantanée pour macOS, accessible depuis la barre de menus. Traduit le texte sélectionné ou une zone d'écran en un raccourci clavier, sans quitter l'application en cours.

---

## Fonctionnalités

- **Traduction instantanée** — sélectionne du texte dans n'importe quelle app, appuie sur le raccourci, la traduction s'affiche en popup flottante
- **33 langues** prises en charge avec détection automatique de la langue source
- **OCR intégré** — traduit du texte dans une image ou sur n'importe quelle zone de l'écran (sous-titres, PDF non-sélectionnables, etc.)
- **Double moteur** — Google Translate (sans clé, zéro config) + Gemini 2.0 Flash (optionnel, meilleure qualité)
- **Tons** — formel / familier avec règles spécifiques selon la langue (丁寧語/普通体 en japonais, 존댓말/반말 en coréen, Sie/du en allemand, particules ครับ/ค่ะ en thaï)
- **Historique** — 50 dernières traductions consultables dans une fenêtre dédiée
- **Popup enrichie** — bouton Copier, badge langue source, bouton Swap (inverser source ↔ cible)
- **Raccourcis configurables** — raccourci principal et raccourci OCR indépendants
- **Interface bilingue** — FR/EN automatique selon la locale macOS
- **Onboarding** — 4 pages de prise en main au premier lancement

---

## Langues supportées

🇸🇦 Arabe · 🇨🇳 Chinois simplifié · 🇹🇼 Chinois traditionnel · 🇨🇿 Tchèque · 🇩🇰 Danois · 🇳🇱 Néerlandais · 🇬🇧 Anglais · 🇫🇮 Finnois · 🇫🇷 Français · 🇩🇪 Allemand · 🇬🇷 Grec · 🇮🇱 Hébreu · 🇮🇳 Hindi · 🇭🇺 Hongrois · 🇮🇩 Indonésien · 🇮🇹 Italien · 🇯🇵 Japonais · 🇰🇷 Coréen · 🇲🇾 Malais · 🇳🇴 Norvégien · 🇮🇷 Persan · 🇵🇱 Polonais · 🇧🇷 Portugais · 🇷🇴 Roumain · 🇷🇺 Russe · 🇪🇸 Espagnol · 🇸🇪 Suédois · 🇹🇭 Thaï · 🇹🇷 Turc · 🇺🇦 Ukrainien · 🇵🇰 Ourdou · 🇻🇳 Vietnamien

---

## Prérequis

- macOS 13 Ventura ou supérieur
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 5.9+

---

## Installation

```bash
# Cloner le dépôt
git clone https://github.com/ozen95/tradapp.git
cd tradapp

# Compiler, bundler et installer dans /Applications
bash build.sh
```

Le script compile l'app, crée le bundle, le signe localement et l'ouvre dans `/Applications/TradApp.app`.

> **Note :** lors du premier lancement, macOS demandera l'autorisation d'accessibilité (nécessaire pour lire le texte sélectionné dans d'autres apps). Suis le guide d'onboarding.

---

## Utilisation

### Traduction de texte

1. Sélectionne du texte dans n'importe quelle application
2. Appuie sur le raccourci clavier (défaut : **⌘⇧T** ou configurable dans les préférences)
3. La traduction s'affiche dans une popup flottante

### OCR (texte dans une image / zone d'écran)

1. Appuie sur le raccourci OCR (configurable dans les préférences)
2. Dessine un rectangle sur la zone à traduire
3. Le texte est extrait et traduit automatiquement

### Popup de traduction

| Bouton | Action |
|--------|--------|
| **Copier** | Copie la traduction dans le presse-papiers |
| **Swap** | Échange la langue source et la langue cible |
| Badge langue | Indique la langue détectée automatiquement |

---

## Configuration

Ouvre les préférences depuis l'icône dans la barre de menus → **Préférences**.

| Réglage | Description |
|---------|-------------|
| Langue cible | Parmi les 33 langues disponibles |
| Raccourci principal | Personnalisable (n'importe quelle combinaison) |
| Raccourci OCR | Raccourci dédié à la capture d'écran OCR |
| Clé API Gemini | Optionnel — active le moteur Gemini 2.0 Flash |
| Ton | Formel / Familier |
| Genre (thaï) | Masculin / Féminin — détermine la particule de politesse |

### Activer Gemini (optionnel)

Sans clé API, l'app utilise Google Translate gratuitement. Pour une meilleure qualité :

1. Récupère une clé gratuite sur [Google AI Studio](https://aistudio.google.com/apikey)
2. Colle-la dans **Préférences → Clé API Gemini**

---

## Développement

```bash
# Mode watch — recompile automatiquement à chaque modification
bash watch.sh
```

### Architecture

| Fichier | Rôle |
|---------|------|
| `TranslationEngine.swift` | Google Translate + Gemini, gestion des tons |
| `TranslationController.swift` | Orchestration : AX → keyboard fallback + OCR |
| `HotkeyManager.swift` | Raccourcis clavier globaux via Carbon |
| `OCRManager.swift` | Capture d'écran + reconnaissance Vision.framework |
| `TranslationPopup.swift` | Popup flottante (copie, swap, badge langue) |
| `StatusBarController.swift` | Menu bar : langues, historique, préférences |
| `AppSettings.swift` | Persistance UserDefaults |
| `Languages.swift` | Catalogue des 33 langues |
| `L10n.swift` | Internationalisation FR/EN automatique |
| `TranslationHistory.swift` | Historique 50 entrées |
| `HistoryWindow.swift` | Fenêtre historique avec copie par entrée |
| `SettingsWindow.swift` | Fenêtre préférences |
| `OnboardingWindow.swift` | Onboarding 4 pages au premier lancement |

---

## Stack technique

- **Swift 5** / macOS 13+ / Swift Package Manager
- **Cocoa + AppKit** — UI native, zéro dépendance externe
- **Vision.framework** — OCR natif Apple
- **Carbon HIToolbox** — raccourcis clavier globaux
- **Accessibility API** — lecture du texte sélectionné

---

## Licence

Usage personnel. Projet privé.
