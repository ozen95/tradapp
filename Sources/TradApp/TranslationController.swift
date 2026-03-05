import Cocoa

class TranslationController {
    static let shared = TranslationController()

    private var isProcessing = false

    private init() {}

    // MARK: - Déclenchement principal (raccourci traduction)

    func handleHotkey() {
        guard AppSettings.shared.isEnabled else { return }
        guard !isProcessing else { return }

        guard AXIsProcessTrusted() else {
            NSSound(named: "Basso")?.play()
            TranslationPopup.shared.show(text: L10n.popupAccessibilityMissing, sourceLang: nil, originalText: nil)
            return
        }

        NSSound(named: "Tink")?.play()
        isProcessing = true
        StatusBarController.shared.setLoading(true)

        let previousClipboard = NSPasteboard.general.string(forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {

            // ── Cas 1 : texte sélectionné via AXUIElement ──────────────────
            if let selectedText = self.readSelectedTextAX() {
                self.doTranslate(text: selectedText) { translated, sourceLang in
                    if let t = translated {
                        if self.isReadingMode(detectedLang: sourceLang) {
                            TranslationPopup.shared.show(text: t, sourceLang: sourceLang, originalText: selectedText)
                        } else {
                            self.pasteViaKeyboard(text: t, restoring: previousClipboard)
                            TranslationPopup.shared.showMini(sourceLang: sourceLang, targetLang: AppSettings.shared.targetLanguage)
                        }
                    } else {
                        self.showError()
                    }
                }
                return
            }

            // ── Cas 2 : champ entier via AXUIElement ───────────────────────
            if let (axElement, axText) = self.readFocusedAXElement() {
                self.doTranslate(text: axText) { translated, sourceLang in
                    if let t = translated {
                        if self.isReadingMode(detectedLang: sourceLang) {
                            TranslationPopup.shared.show(text: t, sourceLang: sourceLang, originalText: axText)
                        } else if !self.writeAXElement(axElement, text: t) {
                            self.pasteViaKeyboard(text: t, restoring: previousClipboard)
                            TranslationPopup.shared.showMini(sourceLang: sourceLang, targetLang: AppSettings.shared.targetLanguage)
                        } else {
                            self.restoreClipboard(previousClipboard)
                            TranslationPopup.shared.showMini(sourceLang: sourceLang, targetLang: AppSettings.shared.targetLanguage)
                        }
                    } else {
                        self.showError()
                    }
                }
                return
            }

            // ── Cas 3 : fallback clavier ────────────────────────────────────
            self.readViaKeyboard(restoring: previousClipboard)
        }
    }

    // MARK: - Déclenchement OCR (raccourci OCR)

    func handleOCRHotkey() {
        guard AppSettings.shared.isEnabled else { return }
        guard !isProcessing else { return }

        isProcessing = true
        StatusBarController.shared.setLoading(true)

        OCRManager.shared.startCapture { [weak self] extractedText in
            guard let self = self else { return }

            guard let text = extractedText, !text.isEmpty else {
                self.finishProcessing()
                let msg = L10n.isFR ? "Aucun texte détecté dans la zone sélectionnée." : "No text detected in the selected area."
                TranslationPopup.shared.show(text: msg, sourceLang: nil, originalText: nil)
                return
            }

            NSSound(named: "Tink")?.play()
            self.doTranslate(text: text) { translated, sourceLang in
                if let t = translated {
                    TranslationPopup.shared.show(text: t, sourceLang: sourceLang, originalText: text)
                } else {
                    self.showError()
                }
            }
        }
    }

    // MARK: - Traduction centralisée (+ historique)

    private func doTranslate(text: String, completion: @escaping (String?, String?) -> Void) {
        TranslationEngine.shared.translate(text: text) { [weak self] translated, sourceLang in
            DispatchQueue.main.async {
                self?.finishProcessing()
                // Messages d'erreur (⚠️) → popup directe, jamais collés dans le champ
                if let t = translated, t.hasPrefix("⚠️") {
                    NSSound(named: "Funk")?.play()
                    TranslationPopup.shared.show(text: t, sourceLang: nil, originalText: nil)
                    return
                }
                if let t = translated {
                    TranslationHistory.shared.add(
                        original:   text,
                        translated: t,
                        sourceLang: sourceLang,
                        targetLang: AppSettings.shared.targetLanguage
                    )
                }
                completion(translated, sourceLang)
            }
        }
    }

    // MARK: - Auto-direction

    private func isReadingMode(detectedLang: String?) -> Bool {
        guard AppSettings.shared.autoDetectDirection,
              let lang = detectedLang else { return false }
        return lang.lowercased() == AppSettings.shared.targetLanguage.lowercased()
    }

    // MARK: - AXUIElement : lecture sélection

    private func readSelectedTextAX() -> String? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        var focusedRaw: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement, kAXFocusedUIElementAttribute as CFString, &focusedRaw
        ) == .success, let raw = focusedRaw else { return nil }

        let focused = unsafeBitCast(raw, to: AXUIElement.self)

        var selectedRaw: AnyObject?
        guard AXUIElementCopyAttributeValue(
            focused, kAXSelectedTextAttribute as CFString, &selectedRaw
        ) == .success, let selected = selectedRaw as? String, !selected.isEmpty else { return nil }

        return selected
    }

    // MARK: - AXUIElement : lecture + écriture champ entier

    private func readFocusedAXElement() -> (AXUIElement, String)? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        var focusedRaw: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement, kAXFocusedUIElementAttribute as CFString, &focusedRaw
        ) == .success, let raw = focusedRaw else { return nil }

        let focused = unsafeBitCast(raw, to: AXUIElement.self)

        var valueRaw: AnyObject?
        guard AXUIElementCopyAttributeValue(
            focused, kAXValueAttribute as CFString, &valueRaw
        ) == .success, let text = valueRaw as? String, !text.isEmpty else { return nil }

        return (focused, text)
    }

    private func writeAXElement(_ element: AXUIElement, text: String) -> Bool {
        return AXUIElementSetAttributeValue(
            element, kAXValueAttribute as CFString, text as CFString
        ) == .success
    }

    // MARK: - Simulation clavier (fallback)

    private func readViaKeyboard(restoring previous: String?) {
        NSPasteboard.general.clearContents()
        KeyboardSimulator.shared.selectAll()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            KeyboardSimulator.shared.copySelection()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let fieldText = NSPasteboard.general.string(forType: .string)

                if let text = fieldText, !text.isEmpty {
                    self.doTranslate(text: text) { translated, sourceLang in
                        if let t = translated {
                            if self.isReadingMode(detectedLang: sourceLang) {
                                KeyboardSimulator.shared.deselect()
                                self.restoreClipboard(previous)
                                TranslationPopup.shared.show(text: t, sourceLang: sourceLang, originalText: text)
                            } else {
                                self.pasteViaKeyboard(text: t, restoring: previous)
                                TranslationPopup.shared.showMini(sourceLang: sourceLang, targetLang: AppSettings.shared.targetLanguage)
                            }
                        } else {
                            self.restoreClipboard(previous)
                            self.showError()
                        }
                    }
                } else {
                    self.finishProcessing()
                    // Dernier recours : traduire le presse-papiers
                    if let clipText = previous, !clipText.isEmpty {
                        TranslationEngine.shared.translate(text: clipText) { translated, sourceLang in
                            DispatchQueue.main.async {
                                if let t = translated {
                                    TranslationHistory.shared.add(
                                        original: clipText, translated: t,
                                        sourceLang: sourceLang,
                                        targetLang: AppSettings.shared.targetLanguage
                                    )
                                    TranslationPopup.shared.show(text: t, sourceLang: sourceLang, originalText: clipText)
                                }
                            }
                        }
                    } else {
                        let hotkey = HotkeyManager.hotkeyDisplayString(
                            keyCode: AppSettings.shared.hotkeyKeyCode,
                            modifiers: AppSettings.shared.hotkeyModifiers
                        )
                        TranslationPopup.shared.show(
                            text: "\(L10n.popupErrorNoText)\n\n\(L10n.popupErrorNoTextHint)\(hotkey)",
                            sourceLang: nil,
                            originalText: nil
                        )
                    }
                }
            }
        }
    }

    private func pasteViaKeyboard(text: String, restoring previous: String?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        KeyboardSimulator.shared.paste()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.restoreClipboard(previous)
        }
    }

    // MARK: - Utilitaires

    private func showError() {
        NSSound(named: "Funk")?.play()
        TranslationPopup.shared.show(text: L10n.popupErrorConnection, sourceLang: nil, originalText: nil)
    }

    private func finishProcessing() {
        isProcessing = false
        StatusBarController.shared.setLoading(false)
    }

    private func restoreClipboard(_ previous: String?) {
        guard let text = previous else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
