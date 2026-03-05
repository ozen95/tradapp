# TradApp

**T'as la flemme d'ouvrir Google Translate ou ChatGPT juste pour une traduction ?**

TradApp traduit instantanément depuis n'importe quelle app — WhatsApp, Mail, Word, n'importe quoi — sans changer de fenêtre, sans copier-coller, sans perdre le fil de ce que tu faisais.

Un raccourci clavier. La traduction s'affiche. C'est tout.

---

## Le problème

Tu lis un message en japonais. Tu veux répondre en thaï. Tu dois rédiger un email en anglais formel.

Avant : ouvre un navigateur → va sur Google Translate → copie → colle → lis → reviens → recopie.

**Avec TradApp : sélectionne le texte → appuie sur le raccourci → c'est traduit.**

---

## Ce que ça fait

- **Traduction en 1 raccourci** — depuis n'importe quelle app sur ton Mac
- **33 langues** avec détection automatique de la langue source
- **OCR intégré** — traduit du texte dans une image, un sous-titre, un PDF non-sélectionnable
- **Double moteur** — Google Translate (gratuit, zéro config) + Gemini 2.0 Flash (optionnel, meilleure qualité + correction grammaticale)
- **Tons adaptés** — formel / familier avec les bonnes règles selon la langue (丁寧語/普通体 en japonais, 존댓말/반말 en coréen, Sie/du en allemand, ครับ/ค่ะ en thaï)
- **Historique** — retrouve tes 50 dernières traductions en un clic
- **Popup enrichie** — copie, swap source ↔ cible, badge langue détectée
- **Interface FR/EN** automatique selon la locale macOS

---

## Langues supportées

🇸🇦 Arabe · 🇨🇳 Chinois simplifié · 🇹🇼 Chinois traditionnel · 🇨🇿 Tchèque · 🇩🇰 Danois · 🇳🇱 Néerlandais · 🇬🇧 Anglais · 🇫🇮 Finnois · 🇫🇷 Français · 🇩🇪 Allemand · 🇬🇷 Grec · 🇮🇱 Hébreu · 🇮🇳 Hindi · 🇭🇺 Hongrois · 🇮🇩 Indonésien · 🇮🇹 Italien · 🇯🇵 Japonais · 🇰🇷 Coréen · 🇲🇾 Malais · 🇳🇴 Norvégien · 🇮🇷 Persan · 🇵🇱 Polonais · 🇧🇷 Portugais · 🇷🇴 Roumain · 🇷🇺 Russe · 🇪🇸 Espagnol · 🇸🇪 Suédois · 🇹🇭 Thaï · 🇹🇷 Turc · 🇺🇦 Ukrainien · 🇵🇰 Ourdou · 🇻🇳 Vietnamien

---

## Installation (macOS)

**Prérequis :** macOS 13+ · Xcode Command Line Tools (`xcode-select --install`)

```bash
git clone https://github.com/ozen95/tradapp.git
cd tradapp

# Créer le certificat de signature (une seule fois)
bash setup_signing.sh

# Compiler et installer dans /Applications
bash build.sh
```

Au premier lancement, l'onboarding guide pour autoriser l'accessibilité (nécessaire pour lire le texte sélectionné dans les autres apps).

---

## Utilisation

### Traduction de texte
1. Sélectionne du texte dans n'importe quelle app
2. Appuie sur le raccourci (**⌘⇧T** par défaut, configurable)
3. La traduction s'affiche en popup

### OCR (texte dans une image / zone d'écran)
1. Appuie sur le raccourci OCR
2. Dessine un rectangle sur la zone à traduire
3. Le texte est extrait et traduit automatiquement

---

## Configuration

Icône dans la barre de menus → **Préférences**

| Réglage | Description |
|---------|-------------|
| Langue cible | 33 langues disponibles |
| Raccourci principal | N'importe quelle combinaison de touches |
| Raccourci OCR | Raccourci dédié à la capture OCR |
| Clé API Gemini | Optionnel — active Gemini 2.0 Flash (meilleure qualité) |
| Ton | Formel / Familier |
| Genre (thaï) | Masculin / Féminin (particule ครับ/ค่ะ) |

**Sans clé Gemini :** Google Translate — gratuit, aucune configuration.
**Avec clé Gemini :** correction grammaticale + adaptation de ton avancée. Clé gratuite sur [Google AI Studio](https://aistudio.google.com/apikey).

---

## Stack

- Swift 5 / macOS 13+ / Swift Package Manager
- Cocoa + AppKit — UI native, zéro dépendance externe
- Vision.framework — OCR natif Apple
- Carbon HIToolbox — raccourcis clavier globaux
- Accessibility API — lecture du texte sélectionné

---

Usage personnel. Projet privé.
