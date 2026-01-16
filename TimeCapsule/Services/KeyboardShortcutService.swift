import Foundation
import Carbon
import OSLog

final class KeyboardShortcutService {
    static let shared = KeyboardShortcutService()
    private let logger = Logger.service

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    private init() {}

    // MARK: - Registration

    func registerHotKey(keyCode: Int, modifiers: UInt, callback: @escaping () -> Void) -> Bool {
        // Unregister existing hotkey
        unregisterHotKey()

        self.callback = callback

        var hotKeyID = EventHotKeyID(signature: FourCharCode("TCAP".utf8.reduce(0) { $0 << 8 + UInt32($1) }), id: 1)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<KeyboardShortcutService>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                service.callback?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            logger.error("Failed to install event handler: \(status)")
            return false
        }

        let registerStatus = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus == noErr {
            logger.info("Registered hotkey: keyCode=\(keyCode), modifiers=\(modifiers)")
            return true
        } else {
            logger.error("Failed to register hotkey: \(registerStatus)")
            return false
        }
    }

    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
            logger.info("Unregistered hotkey")
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        callback = nil
    }

    // MARK: - Utility

    static func modifierFlagsToCarbon(_ flags: UInt) -> UInt {
        var carbonModifiers: UInt = 0

        if flags & (1 << 8) != 0 { // Shift
            carbonModifiers |= UInt(shiftKey)
        }
        if flags & (1 << 11) != 0 { // Command
            carbonModifiers |= UInt(cmdKey)
        }
        if flags & (1 << 13) != 0 { // Option
            carbonModifiers |= UInt(optionKey)
        }
        if flags & (1 << 14) != 0 { // Control
            carbonModifiers |= UInt(controlKey)
        }

        return carbonModifiers
    }

    deinit {
        unregisterHotKey()
    }
}
