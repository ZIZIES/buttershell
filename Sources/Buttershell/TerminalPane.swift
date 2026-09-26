import AppKit
import SwiftUI
import SwiftTerm

struct TerminalPane: View {
    @ObservedObject var session: TerminalSession
    let isActive: Bool
    let theme: ColorTheme
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(nsColor: theme.accent))
                    .frame(width: 7, height: 7)
                Text(directoryName)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                Spacer()
                if session.hasExited {
                    Text("shell ended · ⌘T for a new tab")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close pane")
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(.ultraThinMaterial)

            TerminalHost(session: session, theme: theme)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: theme.background))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(nsColor: theme.accent).opacity(isActive ? 0.72 : 0.14), lineWidth: isActive ? 1.5 : 0.8)
                        .allowsHitTesting(false)
                }
                .onTapGesture(perform: onSelect)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var directoryName: String {
        guard let path = session.currentDirectory else { return "shell" }
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? path : name
    }
}

private struct TerminalHost: NSViewRepresentable {
    let session: TerminalSession
    let theme: ColorTheme

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        configure(session.view)
        return session.view
    }

    func updateNSView(_ view: LocalProcessTerminalView, context: Context) {
        configure(view)
    }

    private func configure(_ view: LocalProcessTerminalView) {
        view.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        view.nativeForegroundColor = theme.foreground
        view.nativeBackgroundColor = theme.background.withAlphaComponent(0.96)
    }
}
