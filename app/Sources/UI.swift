import Carbon
import SwiftUI

@main
struct InterruptorApp: App {
    @State private var store = DisplayStore()
    @State private var shortcuts = ShortcutStore()
    @State private var hotKey = HotKeyController()

    var body: some Scene {
        MenuBarExtra {
            InterruptorPanel(store: store, shortcuts: shortcuts) {
                hotKey.apply(shortcuts.shortcut)
            }
        .onAppear {
            hotKey.onToggle = { [store] in store.toggleAll() }
            hotKey.apply(shortcuts.shortcut)
            Task { await Updater.promptIfNeeded(silent: true) }
        }
        } label: {
            Image(systemName: store.menuBarSymbol)
                .symbolRenderingMode(.hierarchical)
                .help("Interruptor · \(shortcuts.shortcut.displayString)")
        }
        .menuBarExtraStyle(.window)
    }
}

struct InterruptorPanel: View {
    @Bindable var store: DisplayStore
    @Bindable var shortcuts: ShortcutStore
    var onShortcutChanged: () -> Void

    private var width: CGFloat {
        let n = max(store.displays.count, 1)
        return n == 1 ? 240 : min(120 + CGFloat(n) * 88, 420)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("INTERRUPTOR")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            plate
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            if let err = store.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }

            Divider().opacity(0.3)
            footer
        }
        .frame(width: width)
        .preferredColorScheme(.dark)
        .background { panelBG }
    }

    private var plate: some View {
        Group {
            if store.displays.isEmpty {
                VStack(spacing: 12) {
                    PhysicalSwitch(isOn: false).frame(width: 78, height: 128).opacity(0.35)
                    Text("Sem monitor")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else {
                let multi = store.displays.count > 1
                HStack(alignment: .top, spacing: multi ? 10 : 0) {
                    ForEach(store.displays) { d in
                        VStack(spacing: 10) {
                            Text(d.name)
                                .font(.system(size: multi ? 11 : 13, weight: .semibold, design: .rounded))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: multi ? 88 : 160)
                            Button { store.toggle(d) } label: {
                                PhysicalSwitch(isOn: d.isActive)
                                    .frame(width: multi ? 72 : 84, height: multi ? 118 : 136)
                            }
                            .buttonStyle(.plain)
                            .disabled(!store.apiAvailable)
                            .accessibilityLabel("\(d.name), \(d.isActive ? "ligado" : "desligado")")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, multi ? 12 : 20)
                .padding(.vertical, 16)
            }
        }
        .background { plateChrome }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            ShortcutChip(store: shortcuts, onCommit: onShortcutChanged)
            if shortcuts.shortcut != .default {
                Button {
                    shortcuts.reset()
                    onShortcutChanged()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Resetar atalho")
            }
            Spacer(minLength: 4)
            Button {
                Task { await Updater.promptIfNeeded(silent: false) }
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(String(localized: "update.check", defaultValue: "Verificar atualização"))
            Button { NSApp.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Sair")
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var plateChrome: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(white: 0.14), Color(white: 0.08)],
                startPoint: .top, endPoint: .bottom
            ))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
    }

    @ViewBuilder
    private var panelBG: some View {
        if #available(macOS 26, *) {
            Color.clear.glassEffect(.regular.tint(.black.opacity(0.4)), in: .rect(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.5))
                }
        }
    }
}

struct PhysicalSwitch: View {
    var isOn: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(white: 0.18), Color(white: 0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .shadow(color: .black.opacity(0.55), radius: 8, y: 6)

            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .padding(12)

            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(
                    colors: isOn ? [Color(white: 0.92), Color(white: 0.72)] : [Color(white: 0.55), Color(white: 0.32)],
                    startPoint: isOn ? .bottom : .top,
                    endPoint: isOn ? .top : .bottom
                ))
                .overlay(alignment: isOn ? .top : .bottom) {
                    Capsule().fill(Color.black.opacity(0.18)).frame(width: 22, height: 3.5).padding(8)
                }
                .overlay { Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1) }
                .shadow(color: .black.opacity(0.45), radius: 4, y: isOn ? -2 : 3)
                .rotation3DEffect(.degrees(isOn ? -18 : 18), axis: (x: 1, y: 0, z: 0), perspective: 0.45)
                .padding(.horizontal, 18)
                .padding(.vertical, 22)

            if isOn {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.orange.opacity(0.35), lineWidth: 2)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: isOn)
    }
}

struct ShortcutChip: View {
    @Bindable var store: ShortcutStore
    var onCommit: () -> Void

    var body: some View {
        Button { store.isRecording.toggle() } label: {
            HStack(spacing: 4) {
                Image(systemName: store.isRecording ? "keyboard.fill" : "keyboard")
                    .font(.system(size: 10))
                Text(store.isRecording ? "…" : store.shortcut.displayString)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(store.isRecording ? Color.orange : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(store.isRecording ? Color.orange.opacity(0.15) : Color.white.opacity(0.06))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        store.isRecording ? Color.orange.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .help("Gravar atalho")
        .background {
            if store.isRecording {
                KeyCaptureView { e in
                    if e.keyCode == UInt16(kVK_Escape) { store.isRecording = false; return }
                    if let s = KeyShortcut.from(nsEvent: e) {
                        store.set(s)
                        onCommit()
                    }
                }
                .frame(width: 0, height: 0)
            }
        }
    }
}

private struct KeyCaptureView: NSViewRepresentable {
    var onKey: (NSEvent) -> Void

    func makeNSView(context: Context) -> CaptureNSView {
        let v = CaptureNSView()
        v.onKey = onKey
        DispatchQueue.main.async { v.window?.makeFirstResponder(v) }
        return v
    }

    func updateNSView(_ v: CaptureNSView, context: Context) {
        v.onKey = onKey
        DispatchQueue.main.async {
            guard v.window?.firstResponder !== v else { return }
            v.window?.makeFirstResponder(v)
        }
    }

    final class CaptureNSView: NSView {
        var onKey: ((NSEvent) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with e: NSEvent) { onKey?(e) }
        override func viewDidMoveToWindow() { window?.makeFirstResponder(self) }
    }
}
