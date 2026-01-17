import Foundation
import AppKit
import Carbon.HIToolbox

/// Manages global keyboard shortcuts
@Observable
class GlobalShortcutsService {
    private var quickAddMonitor: Any?
    private var showAppMonitor: Any?

    var onQuickAdd: (() -> Void)?
    var onShowApp: (() -> Void)?

    var isEnabled = true {
        didSet {
            if isEnabled {
                registerShortcuts()
            } else {
                unregisterShortcuts()
            }
        }
    }

    // Shortcut configurations (stored in UserDefaults)
    var quickAddShortcut: KeyboardShortcut = .defaultQuickAdd
    var showAppShortcut: KeyboardShortcut = .defaultShowApp

    init() {
        loadShortcuts()
    }

    deinit {
        unregisterShortcuts()
    }

    // MARK: - Registration

    func registerShortcuts() {
        unregisterShortcuts()
        guard isEnabled else { return }

        // Quick Add: Cmd+Shift+T
        quickAddMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let shortcut = self.quickAddShortcut.asEventShortcut else { return }

            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == shortcut.modifiers &&
               event.keyCode == shortcut.keyCode {
                DispatchQueue.main.async {
                    self.onQuickAdd?()
                }
            }
        }

        // Show App: Cmd+Shift+C
        showAppMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let shortcut = self.showAppShortcut.asEventShortcut else { return }

            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == shortcut.modifiers &&
               event.keyCode == shortcut.keyCode {
                DispatchQueue.main.async {
                    self.onShowApp?()
                }
            }
        }
    }

    func unregisterShortcuts() {
        if let monitor = quickAddMonitor {
            NSEvent.removeMonitor(monitor)
            quickAddMonitor = nil
        }
        if let monitor = showAppMonitor {
            NSEvent.removeMonitor(monitor)
            showAppMonitor = nil
        }
    }

    // MARK: - Persistence

    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: "quickAddShortcut"),
           let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            quickAddShortcut = shortcut
        }

        if let data = UserDefaults.standard.data(forKey: "showAppShortcut"),
           let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            showAppShortcut = shortcut
        }
    }

    func saveShortcuts() {
        if let data = try? JSONEncoder().encode(quickAddShortcut) {
            UserDefaults.standard.set(data, forKey: "quickAddShortcut")
        }

        if let data = try? JSONEncoder().encode(showAppShortcut) {
            UserDefaults.standard.set(data, forKey: "showAppShortcut")
        }

        // Re-register with new shortcuts
        registerShortcuts()
    }
}

/// Represents a keyboard shortcut
struct KeyboardShortcut: Codable {
    var keyCode: UInt16
    var modifiers: EventModifiers

    struct EventModifiers: OptionSet, Codable {
        let rawValue: Int

        static let command = EventModifiers(rawValue: 1 << 0)
        static let shift = EventModifiers(rawValue: 1 << 1)
        static let option = EventModifiers(rawValue: 1 << 2)
        static let control = EventModifiers(rawValue: 1 << 3)
    }

    var asEventShortcut: (keyCode: UInt16, modifiers: NSEvent.ModifierFlags)? {
        var flags: NSEvent.ModifierFlags = []

        if modifiers.contains(.command) { flags.insert(.command) }
        if modifiers.contains(.shift) { flags.insert(.shift) }
        if modifiers.contains(.option) { flags.insert(.option) }
        if modifiers.contains(.control) { flags.insert(.control) }

        return (keyCode, flags)
    }

    var displayString: String {
        var parts: [String] = []

        if modifiers.contains(.control) { parts.append("^") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }

        if let keyString = keyCodeToString(keyCode) {
            parts.append(keyString)
        }

        return parts.joined()
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        let keyMap: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x1D: "0", 0x1E: "9",
            0x1F: "7", 0x20: "8", 0x21: "I", 0x22: "O", 0x23: "P",
            0x25: "L", 0x26: "J", 0x28: "K", 0x2D: "N", 0x2E: "M"
        ]
        return keyMap[keyCode]
    }

    // Default shortcuts
    static let defaultQuickAdd = KeyboardShortcut(keyCode: 0x11, modifiers: [.command, .shift])  // Cmd+Shift+T
    static let defaultShowApp = KeyboardShortcut(keyCode: 0x08, modifiers: [.command, .shift])   // Cmd+Shift+C
}
