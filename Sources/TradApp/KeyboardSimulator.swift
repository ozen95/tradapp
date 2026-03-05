import Cocoa

class KeyboardSimulator {
    static let shared = KeyboardSimulator()

    private init() {}

    private func sendKey(_ keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }

        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        down?.flags = modifiers
        down?.post(tap: .cgAnnotatedSessionEventTap)

        let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        up?.flags = modifiers
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }

    /// Cmd+A — tout sélectionner
    func selectAll() {
        sendKey(0, modifiers: .maskCommand)
    }

    /// Cmd+C — copier la sélection
    func copySelection() {
        sendKey(8, modifiers: .maskCommand)
    }

    /// Cmd+V — coller (remplace la sélection si elle existe)
    func paste() {
        sendKey(9, modifiers: .maskCommand)
    }

    /// → — déplacer le curseur à la fin (désélectionne sans modifier)
    func deselect() {
        sendKey(124) // keyCode flèche droite
    }
}
