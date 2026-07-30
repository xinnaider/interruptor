import AppKit
import Carbon
import CoreGraphics
import Darwin
import Foundation
import Observation

// MARK: - SkyLight

private let skylight = dlopen(
    "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
    RTLD_LAZY
)

private typealias DisplayListFunc = @convention(c) (
    UInt32, UnsafeMutablePointer<CGDirectDisplayID>?, UnsafeMutablePointer<UInt32>
) -> CGError
private typealias ConfigDisplayFunc = @convention(c) (
    CGDisplayConfigRef, CGDirectDisplayID, Bool
) -> CGError

private func loadSym<T>(_ name: String) -> T? {
    guard let h = skylight,
          let s = dlsym(h, name) ?? dlsym(UnsafeMutableRawPointer(bitPattern: -2), name)
    else { return nil }
    return unsafeBitCast(s, to: T.self)
}

private let SLSGetActiveDisplayList: DisplayListFunc? = loadSym("SLSGetActiveDisplayList")
private let SLSGetDisplayList: DisplayListFunc? = loadSym("SLSGetDisplayList")
private let SLSConfigureDisplayEnabled: ConfigDisplayFunc? = loadSym("SLSConfigureDisplayEnabled")

enum DisplayBridge {
    static var isSupported: Bool {
        SLSConfigureDisplayEnabled != nil && SLSGetDisplayList != nil
    }

    static func activeIDs() -> [CGDirectDisplayID] { ids(SLSGetActiveDisplayList) }
    static func allIDs() -> [CGDirectDisplayID] { ids(SLSGetDisplayList) }

    static func setEnabled(_ id: CGDirectDisplayID, enabled: Bool) -> Bool {
        guard let configure = SLSConfigureDisplayEnabled else { return false }
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else { return false }
        guard configure(config, id, enabled) == .success else {
            CGCancelDisplayConfiguration(config)
            return false
        }
        return CGCompleteDisplayConfiguration(config, .forSession) == .success
    }

    static func hardwareKey(_ id: CGDirectDisplayID) -> String {
        "\(CGDisplayVendorNumber(id))_\(CGDisplayModelNumber(id))_\(CGDisplaySerialNumber(id))"
    }

    static func isBuiltin(_ id: CGDirectDisplayID) -> Bool { CGDisplayIsBuiltin(id) != 0 }

    private static func ids(_ fn: DisplayListFunc?) -> [CGDirectDisplayID] {
        guard let fn else { return [] }
        var n: UInt32 = 0
        guard fn(0, nil, &n) == .success, n > 0 else { return [] }
        var buf = [CGDirectDisplayID](repeating: 0, count: Int(n))
        guard fn(n, &buf, &n) == .success else { return [] }
        return Array(buf.prefix(Int(n)))
    }
}

enum DisplayNames {
    private static let key = "interruptor.displayNames"
    private static var cache: [String: String] = {
        (UserDefaults.standard.dictionary(forKey: key) as? [String: String]) ?? [:]
    }()

    static func name(for id: CGDirectDisplayID) -> String {
        cache[DisplayBridge.hardwareKey(id)] ?? "Monitor"
    }

    static func refresh() {
        for s in NSScreen.screens {
            guard let id = screenID(s), !DisplayBridge.isBuiltin(id) else { continue }
            let n = s.localizedName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !n.isEmpty else { continue }
            cache[DisplayBridge.hardwareKey(id)] = n
        }
        UserDefaults.standard.set(cache, forKey: key)
    }

    private static func screenID(_ s: NSScreen) -> CGDirectDisplayID? {
        s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}

// MARK: - Store

struct ManagedDisplay: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let name: String
    let isActive: Bool
    var hardwareKey: String { DisplayBridge.hardwareKey(id) }
}

@Observable
@MainActor
final class DisplayStore {
    private(set) var displays: [ManagedDisplay] = []
    private(set) var apiAvailable = DisplayBridge.isSupported
    private(set) var lastError: String?

    private let disabledKey = "interruptor.disabledKeys"
    private var disabledKeys: Set<String>

    var menuBarSymbol: String {
        let on = displays.contains(where: \.isActive)
        if #available(macOS 15.0, *) {
            return on ? "lightswitch.on" : "lightswitch.off"
        }
        return on ? "display" : "display.trianglebadge.exclamationmark"
    }

    init() {
        disabledKeys = Set(UserDefaults.standard.stringArray(forKey: disabledKey) ?? [])
        refresh()
        registerCallback()
        reapplyDisabled()
    }

    func refresh() {
        DisplayNames.refresh()
        let active = Set(DisplayBridge.activeIDs())
        var seen = Set<String>()
        var out: [ManagedDisplay] = []
        for id in DisplayBridge.allIDs() {
            if DisplayBridge.isBuiltin(id) || CGDisplayVendorNumber(id) == 0 { continue }
            let hk = DisplayBridge.hardwareKey(id)
            guard seen.insert(hk).inserted else { continue }
            out.append(ManagedDisplay(id: id, name: DisplayNames.name(for: id), isActive: active.contains(id)))
        }
        displays = out.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func toggle(_ d: ManagedDisplay) { setActive(d, !d.isActive) }

    func toggleAll() {
        let turnOn = !displays.contains(where: \.isActive)
        for d in displays where d.isActive != turnOn { setActive(d, turnOn) }
    }

    private func setActive(_ d: ManagedDisplay, _ on: Bool) {
        guard apiAvailable else { lastError = "API indisponível"; return }
        if !on, DisplayBridge.activeIDs().filter({ $0 != d.id }).isEmpty {
            lastError = "Único display ativo"
            return
        }
        remember(d.hardwareKey, disabled: !on)
        let id = d.id
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = DisplayBridge.setEnabled(id, enabled: on)
            DispatchQueue.main.async {
                self.lastError = ok ? nil : (on ? "Falha ao religar" : "Falha ao cortar")
                self.refresh()
            }
        }
    }

    private func remember(_ hk: String, disabled: Bool) {
        if disabled { disabledKeys.insert(hk) } else { disabledKeys.remove(hk) }
        UserDefaults.standard.set(Array(disabledKeys), forKey: disabledKey)
    }

    private func reapplyDisabled() {
        for id in DisplayBridge.activeIDs() where !DisplayBridge.isBuiltin(id) {
            scheduleDisableIfNeeded(id)
        }
    }

    private func registerCallback() {
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback({ id, flags, info in
            guard !flags.contains(.beginConfigurationFlag),
                  flags.contains(.addFlag) || flags.contains(.removeFlag),
                  let info else { return }
            let store = Unmanaged<DisplayStore>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async {
                if flags.contains(.addFlag) { store.scheduleDisableIfNeeded(id) }
                store.refresh()
            }
        }, ptr)
    }

    private func scheduleDisableIfNeeded(_ id: CGDirectDisplayID) {
        guard !DisplayBridge.isBuiltin(id),
              disabledKeys.contains(DisplayBridge.hardwareKey(id)) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if CGDisplayIsActive(id) != 0 {
                _ = DisplayBridge.setEnabled(id, enabled: false)
                self.refresh()
            }
        }
    }
}

// MARK: - Shortcut

struct KeyShortcut: Equatable, Codable {
    var keyCode: UInt32
    var modifiers: UInt32
    var label: String

    static let `default` = KeyShortcut(
        keyCode: UInt32(kVK_ANSI_I),
        modifiers: UInt32(controlKey | optionKey | cmdKey),
        label: "I"
    )

    var displayString: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        return s + label
    }

    static func from(nsEvent e: NSEvent) -> KeyShortcut? {
        let pure: Set<UInt16> = [
            UInt16(kVK_Command), UInt16(kVK_Shift), UInt16(kVK_Option), UInt16(kVK_Control),
            UInt16(kVK_RightCommand), UInt16(kVK_RightShift), UInt16(kVK_RightOption),
            UInt16(kVK_RightControl), UInt16(kVK_Function)
        ]
        if pure.contains(e.keyCode) { return nil }
        var m: UInt32 = 0
        let f = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if f.contains(.control) { m |= UInt32(controlKey) }
        if f.contains(.option) { m |= UInt32(optionKey) }
        if f.contains(.shift) { m |= UInt32(shiftKey) }
        if f.contains(.command) { m |= UInt32(cmdKey) }
        guard m != 0 else { return nil }
        let raw = (e.charactersIgnoringModifiers ?? "").uppercased()
        let label = raw.isEmpty ? "Key\(e.keyCode)" : raw
        return KeyShortcut(keyCode: UInt32(e.keyCode), modifiers: m, label: label)
    }
}

@Observable
@MainActor
final class ShortcutStore {
    private let key = "interruptor.shortcut"
    private(set) var shortcut: KeyShortcut
    var isRecording = false

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(KeyShortcut.self, from: data) {
            shortcut = s
        } else {
            shortcut = .default
        }
    }

    func set(_ s: KeyShortcut) {
        shortcut = s
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: key)
        }
        isRecording = false
    }

    func reset() { set(.default) }
}

@MainActor
final class HotKeyController {
    var onToggle: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var handlerReady = false

    func apply(_ s: KeyShortcut) {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef); self.hotKeyRef = nil }
        if !handlerReady {
            var type = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            let ud = Unmanaged.passUnretained(self).toOpaque()
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (_, event, ud) -> OSStatus in
                    guard let ud else { return noErr }
                    var id = EventHotKeyID()
                    GetEventParameter(
                        event, EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID), nil,
                        MemoryLayout<EventHotKeyID>.size, nil, &id
                    )
                    guard id.id == 1 else { return noErr }
                    let c = Unmanaged<HotKeyController>.fromOpaque(ud).takeUnretainedValue()
                    DispatchQueue.main.async { c.onToggle?() }
                    return noErr
                },
                1, &type, ud, &handlerRef
            )
            handlerReady = true
        }
        var ref: EventHotKeyRef?
        if RegisterEventHotKey(
            s.keyCode, s.modifiers,
            EventHotKeyID(signature: OSType(0x494E5452), id: 1),
            GetApplicationEventTarget(), 0, &ref
        ) == noErr {
            hotKeyRef = ref
        }
    }
}
