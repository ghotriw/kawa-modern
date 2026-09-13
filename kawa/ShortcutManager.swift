import Cocoa
import Carbon
import Combine

struct KeyCombo: Codable, Equatable, Hashable {
    var keyCode: UInt16
    var carbonModifiers: UInt32

    var displayString: String {
        var str = ""
        if (carbonModifiers & UInt32(controlKey)) != 0 { str += "⌃" }
        if (carbonModifiers & UInt32(optionKey)) != 0 { str += "⌥" }
        if (carbonModifiers & UInt32(shiftKey)) != 0 { str += "⇧" }
        if (carbonModifiers & UInt32(cmdKey)) != 0 { str += "⌘" }
        str += Self.keyName(for: keyCode)
        return str
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        return mods
    }

    static func carbonModifiersFromLegacyCocoa(_ flags: Int) -> UInt32 {
        var mods: UInt32 = 0
        if (flags & 262144) != 0 { mods |= UInt32(controlKey) }
        if (flags & 524288) != 0 { mods |= UInt32(optionKey) }
        if (flags & 131072) != 0 { mods |= UInt32(shiftKey) }
        if (flags & 1048576) != 0 { mods |= UInt32(cmdKey) }
        return mods
    }

    static func keyName(for code: UInt16) -> String {
        let special: [UInt16: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        if let name = special[code] { return name }

        let letters: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M",
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7",
            28: "8", 25: "9", 29: "0",
            27: "-", 24: "=", 33: "[", 30: "]", 42: "\\", 41: ";", 39: "\u{0027}",
            43: ",", 47: ".", 44: "/", 50: "`"
        ]
        return letters[code] ?? "?"
    }
}

final class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()

    @Published private(set) var shortcuts: [String: KeyCombo] = [:]
    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "kawa_show_notifications")
            if showNotifications {
                NotificationManager.shared.requestAuthorization()
            }
        }
    }

    private var registeredRefs: [String: EventHotKeyRef] = [:]
    private var idToSource: [UInt32: String] = [:]
    private var sourceToId: [String: UInt32] = [:]
    private var nextHotKeyId: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    private let storageKey = "kawa_shortcuts_v2"

    private init() {
        let legacyDomain = UserDefaults.standard.persistentDomain(forName: "net.noraesae.Kawa")
        if let notifSetting = UserDefaults.standard.object(forKey: "kawa_show_notifications") as? Bool {
            self.showNotifications = notifSetting
        } else if let legacyNotif = legacyDomain?["kawa_show_notifications"] as? Bool {
            self.showNotifications = legacyNotif
            UserDefaults.standard.set(legacyNotif, forKey: "kawa_show_notifications")
        } else {
            self.showNotifications = false
        }

        loadSavedShortcuts()
        installCarbonHandler()
        bindAll()
    }

    private func installCarbonHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { (_, eventRef, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if status == noErr {
                DispatchQueue.main.async {
                    ShortcutManager.shared.handleHotKey(id: hotKeyID.id)
                }
            }
            return noErr
        }
        InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &spec, nil, &eventHandler)
    }

    private func handleHotKey(id: UInt32) {
        guard let sourceId = idToSource[id] else { return }
        let sources = InputSourceManager.shared.sources.isEmpty
            ? InputSourceManager.fetchSources()
            : InputSourceManager.shared.sources
        guard let source = sources.first(where: { $0.id == sourceId }) else { return }

        source.select()

        if showNotifications {
            NotificationManager.shared.notify(source: source)
        }
    }

    private func loadSavedShortcuts() {
        var loaded: [String: KeyCombo] = [:]
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: KeyCombo].self, from: data),
           !decoded.isEmpty {
            loaded = decoded
        } else {
            // Check legacy domain (net.noraesae.Kawa) for v2 format or legacy MASShortcut format
            let legacyDomain = UserDefaults.standard.persistentDomain(forName: "net.noraesae.Kawa") ?? [:]
            if let legacyData = legacyDomain[storageKey] as? Data,
               let decoded = try? JSONDecoder().decode([String: KeyCombo].self, from: legacyData),
               !decoded.isEmpty {
                loaded = decoded
            } else {
                // Migrate from legacy MASShortcut format
                for (key, val) in legacyDomain {
                    guard key.hasPrefix("com-apple-keylayout-"), let data = val as? Data else { continue }
                    if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                       let objects = plist["$objects"] as? [Any] {
                        for obj in objects {
                            if let dict = obj as? [String: Any],
                               let keyCode = dict["KeyCode"] as? Int,
                               let flags = dict["ModifierFlags"] as? Int {
                                let carbonMods = KeyCombo.carbonModifiersFromLegacyCocoa(flags)
                                let originalSourceId = key.replacingOccurrences(of: "-", with: ".")
                                loaded[originalSourceId] = KeyCombo(keyCode: UInt16(keyCode), carbonModifiers: carbonMods)
                            }
                        }
                    }
                }
            }
        }

        // Only keep shortcuts for input sources that actually exist on this Mac
        let validSources = Set(InputSourceManager.fetchSources().map { $0.id })
        var sanitized: [String: KeyCombo] = [:]
        var usedCombos = Set<KeyCombo>()
        for (sourceId, combo) in loaded where validSources.contains(sourceId) {
            if !usedCombos.contains(combo) {
                usedCombos.insert(combo)
                sanitized[sourceId] = combo
            }
        }

        self.shortcuts = sanitized
        saveShortcuts()
    }

    private func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func shortcut(for sourceId: String) -> KeyCombo? {
        return shortcuts[sourceId]
    }

    func setShortcut(_ combo: KeyCombo?, for sourceId: String) {
        unbind(sourceId: sourceId)

        if let combo = combo {
            // Conflict resolution: remove this combo from any other layout that used it
            for (otherId, otherCombo) in shortcuts where otherId != sourceId && otherCombo == combo {
                unbind(sourceId: otherId)
                shortcuts.removeValue(forKey: otherId)
            }

            shortcuts[sourceId] = combo
            bind(sourceId: sourceId, combo: combo)
        } else {
            shortcuts.removeValue(forKey: sourceId)
        }

        saveShortcuts()
    }

    private func bind(sourceId: String, combo: KeyCombo) {
        let hotKeyId: UInt32
        if let existing = sourceToId[sourceId] {
            hotKeyId = existing
        } else {
            hotKeyId = nextHotKeyId
            nextHotKeyId += 1
            sourceToId[sourceId] = hotKeyId
            idToSource[hotKeyId] = sourceId
        }

        let eventHotKeyID = EventHotKeyID(signature: 0x4B415741 /* 'KAWA' */, id: hotKeyId)
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            UInt32(combo.keyCode),
            combo.carbonModifiers,
            eventHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            registeredRefs[sourceId] = ref
        } else {
            print("[Kawa] Failed to register hotkey for \(sourceId), status: \(status)")
        }
    }

    private func unbind(sourceId: String) {
        if let ref = registeredRefs.removeValue(forKey: sourceId) {
            UnregisterEventHotKey(ref)
        }
    }

    func bindAll() {
        for (sourceId, combo) in shortcuts {
            bind(sourceId: sourceId, combo: combo)
        }
    }
}
