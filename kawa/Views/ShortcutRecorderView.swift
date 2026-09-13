import SwiftUI
import AppKit
import Carbon

final class ShortcutRecorderNSView: NSView {
    var sourceId: String = ""
    var currentCombo: KeyCombo? {
        didSet {
            updateUI()
        }
    }
    var onComboChanged: ((KeyCombo?) -> Void)?

    private var isRecording = false {
        didSet {
            updateUI()
        }
    }

    private let label = NSTextField(labelWithString: "")
    private let clearButton = NSButton()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1

        label.alignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
        clearButton.target = self
        clearButton.action = #selector(clearClicked)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clearButton)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            clearButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 4),
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 16),
            clearButton.heightAnchor.constraint(equalToConstant: 16),

            heightAnchor.constraint(equalToConstant: 28),
            widthAnchor.constraint(equalToConstant: 140),
        ])

        updateUI()
    }

    @objc private func clearClicked() {
        onComboChanged?(nil)
        window?.makeFirstResponder(nil)
    }

    private var isUserClick = false

    override var acceptsFirstResponder: Bool {
        return isUserClick
    }

    override func mouseDown(with event: NSEvent) {
        if isRecording {
            window?.makeFirstResponder(nil)
        } else {
            isUserClick = true
            window?.makeFirstResponder(self)
            isUserClick = false
        }
    }

    override func becomeFirstResponder() -> Bool {
        isRecording = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Escape cancels recording
        if event.keyCode == 53 {
            window?.makeFirstResponder(nil)
            return
        }

        // Delete/Backspace without modifiers clears the shortcut
        if event.keyCode == 51 && event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty {
            onComboChanged?(nil)
            window?.makeFirstResponder(nil)
            return
        }

        let mods = KeyCombo.carbonModifiers(from: event.modifierFlags)
        let fKeys: Set<UInt16> = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111]
        let isFunctionKey = fKeys.contains(event.keyCode)

        // Require at least one modifier key or function key
        if mods != 0 || isFunctionKey {
            let combo = KeyCombo(keyCode: event.keyCode, carbonModifiers: mods)
            onComboChanged?(combo)
            window?.makeFirstResponder(nil)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        window?.makeFirstResponder(nil)
    }

    private func updateUI() {
        if isRecording {
            label.stringValue = "Type shortcut..."
            label.textColor = .controlAccentColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
            clearButton.isHidden = true
        } else if let combo = currentCombo {
            label.stringValue = combo.displayString
            label.textColor = .labelColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            clearButton.isHidden = false
        } else {
            label.stringValue = "Record shortcut"
            label.textColor = .secondaryLabelColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            clearButton.isHidden = true
        }
    }
}

struct ShortcutRecorderView: NSViewRepresentable {
    let sourceId: String
    @ObservedObject var shortcutManager = ShortcutManager.shared

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.sourceId = sourceId
        view.currentCombo = shortcutManager.shortcut(for: sourceId)
        view.onComboChanged = { [weak shortcutManager] newCombo in
            shortcutManager?.setShortcut(newCombo, for: sourceId)
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.sourceId = sourceId
        nsView.currentCombo = shortcutManager.shortcut(for: sourceId)
    }
}
