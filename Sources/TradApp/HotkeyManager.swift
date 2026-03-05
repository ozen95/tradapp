import Cocoa
import Carbon.HIToolbox

class HotkeyManager {
    static let shared = HotkeyManager()

    // IDs des raccourcis
    static let mainID: UInt32 = 1
    static let ocrID:  UInt32 = 2

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var callbacks:  [UInt32: () -> Void]     = [:]
    private var handlerInstalled = false

    // Callbacks publics
    var onHotkeyPressed: (() -> Void)? {
        didSet { callbacks[HotkeyManager.mainID] = onHotkeyPressed }
    }
    var onOCRPressed: (() -> Void)? {
        didSet { callbacks[HotkeyManager.ocrID] = onOCRPressed }
    }

    private init() {}

    // MARK: - Démarrage

    func start() {
        if !handlerInstalled {
            installEventHandler()
            handlerInstalled = true
        }
        registerHotkey(id: HotkeyManager.mainID,
                       keyCode: AppSettings.shared.hotkeyKeyCode,
                       modifiers: AppSettings.shared.hotkeyModifiers)
        let ocrKC = AppSettings.shared.ocrHotkeyKeyCode
        if ocrKC > 0 {
            registerHotkey(id: HotkeyManager.ocrID,
                           keyCode: ocrKC,
                           modifiers: AppSettings.shared.ocrHotkeyModifiers)
        }
    }

    func stop() {
        for id in hotKeyRefs.keys { unregisterHotkey(id: id) }
    }

    // MARK: - Suspension temporaire (pendant l'enregistrement d'un nouveau raccourci)

    func suspendForRecording() {
        unregisterHotkey(id: HotkeyManager.mainID)
    }

    func resumeAfterRecording(keyCode: Int? = nil, modifiers: Int? = nil) {
        let kc   = keyCode   ?? AppSettings.shared.hotkeyKeyCode
        let mods = modifiers ?? AppSettings.shared.hotkeyModifiers
        registerHotkey(id: HotkeyManager.mainID, keyCode: kc, modifiers: mods)
    }

    // MARK: - Mise à jour définitive

    func updateHotkey(keyCode: Int, modifiers: Int) {
        AppSettings.shared.hotkeyKeyCode   = keyCode
        AppSettings.shared.hotkeyModifiers = modifiers
        unregisterHotkey(id: HotkeyManager.mainID)
        registerHotkey(id: HotkeyManager.mainID, keyCode: keyCode, modifiers: modifiers)
    }

    func updateOCRHotkey(keyCode: Int, modifiers: Int) {
        AppSettings.shared.ocrHotkeyKeyCode   = keyCode
        AppSettings.shared.ocrHotkeyModifiers = modifiers
        unregisterHotkey(id: HotkeyManager.ocrID)
        if keyCode > 0 {
            registerHotkey(id: HotkeyManager.ocrID, keyCode: keyCode, modifiers: modifiers)
        }
    }

    // MARK: - Interne

    private func installEventHandler() {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, refcon) -> OSStatus in
                guard let refcon = refcon, let event = event else { return noErr }
                let mgr = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event, UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hkID
                )
                let id = hkID.id
                DispatchQueue.main.async { mgr.callbacks[id]?() }
                return noErr
            },
            1, &eventSpec, selfPtr, nil
        )
    }

    private func registerHotkey(id: UInt32, keyCode: Int, modifiers: Int) {
        unregisterHotkey(id: id)
        var ref: EventHotKeyRef?
        let hkID   = EventHotKeyID(signature: 0x54524144, id: id)
        let status = RegisterEventHotKey(
            UInt32(keyCode), UInt32(modifiers),
            hkID, GetApplicationEventTarget(), 0, &ref
        )
        if status == noErr, let ref = ref {
            hotKeyRefs[id] = ref
        }
    }

    private func unregisterHotkey(id: UInt32) {
        if let ref = hotKeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotKeyRefs.removeValue(forKey: id)
        }
    }

    // MARK: - Affichage lisible d'un raccourci

    static func hotkeyDisplayString(keyCode: Int, modifiers: Int) -> String {
        var result = ""
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option)  { result += "⌥" }
        if flags.contains(.shift)   { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }

        let keyMap: [Int: String] = [
            // Touches de fonction
            122: "F1",  120: "F2",  99: "F3",  118: "F4",  96: "F5",  97: "F6",
            98:  "F7",  100: "F8",  101: "F9", 109: "F10", 103: "F11", 111: "F12",
            105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17",  79: "F18",
            80:  "F19",  90: "F20",
            // Lettres
            0: "A",  11: "B",  8: "C",  2: "D", 14: "E",  3: "F",  5: "G",
            4: "H",  34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N",
            31: "O", 35: "P", 12: "Q", 15: "R",  1: "S", 17: "T", 32: "U",
            9: "V",  13: "W",  7: "X", 16: "Y",  6: "Z",
            // Spéciales
            49: "Espace", 36: "↩", 48: "⇥", 51: "⌫", 53: "⎋",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]

        result += keyMap[keyCode] ?? "?\(keyCode)"
        return result
    }
}
