import SwiftUI

struct MainWindow: View {
    @ObservedObject var model: WorkspaceModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("colorTheme") private var selectedThemeRaw = ColorTheme.midnight.rawValue

    private var theme: ColorTheme { ColorTheme(rawValue: selectedThemeRaw) ?? .midnight }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)

            if let tab = model.activeTab {
                render(tab.layout)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(8)
            }

            footer
        }
        .frame(minWidth: 740, minHeight: 460)
        .background(theme.swiftUIColor.ignoresSafeArea())
        .tint(Color(nsColor: theme.accent))
        .overlay {
            if model.isCommandPalettePresented {
                paletteOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(5)
            }
        }
        .animation(.easeOut(duration: 0.14), value: model.isCommandPalettePresented)
        .onAppear {
            model.ensureTabExists()
            model.onLastTabClosed = { dismiss() }
        }
    }

    private var titleBar: some View {
        HStack(spacing: 9) {
            HStack(spacing: 5) {
                ForEach(model.tabs) { tab in
                    HStack(spacing: 0) {
                        Button {
                            model.activeTabID = tab.id
                            model.activePaneID = tab.layout.paneIDs.first
                        } label: {
                            Text(tab.title)
                                .lineLimit(1)
                                .font(.system(size: 12, weight: model.activeTabID == tab.id ? .semibold : .regular))
                                .frame(maxWidth: 112, alignment: .leading)
                                .padding(.leading, 11)
                                .padding(.trailing, 7)
                                .frame(height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            model.closeTab(tab.id)
                        } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .frame(width: 24, height: 30)
                        }
                        .buttonStyle(.plain)
                        .opacity(model.tabs.count > 1 ? 0.65 : 0)
                    }
                    .frame(height: 30)
                    .background {
                        Capsule()
                            .fill(model.activeTabID == tab.id ? .white.opacity(0.15) : .white.opacity(0.045))
                    }
                    .help(tab.title)
                }
            }

            Button(action: model.addTab) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("New tab · ⌘T")

            Spacer(minLength: 8)

            Button { model.isCommandPalettePresented = true } label: {
                Label("Commands", systemImage: "sparkle.magnifyingglass")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 9)
                    .frame(height: 28)
            }
            .buttonStyle(GlassButtonStyle())
            .help("Find starter commands and app actions · ⌘K")

            Button { model.splitActivePane(using: .columns) } label: {
                Image(systemName: "rectangle.split.2x1")
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(GlassButtonStyle())
            .help("Split right · ⌘⇧D")

            Button { model.splitActivePane(using: .rows) } label: {
                Image(systemName: "rectangle.split.1x2")
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(GlassButtonStyle())
            .help("Split below · ⌘⇧E")

            Menu {
                ForEach(ColorTheme.allCases) { option in
                    Button {
                        selectedThemeRaw = option.rawValue
                    } label: {
                        if option == theme {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Text(option.label)
                        }
                    }
                }
                Divider()
                Toggle("Close window when the last shell exits", isOn: $model.closeWindowWhenShellExits)
            } label: {
                Image(systemName: "circle.lefthalf.filled")
                    .frame(width: 30, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Colors and shell exit behavior")
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "command")
                .foregroundStyle(Color(nsColor: theme.accent))
            Text("⌘K commands")
            Text("·")
            Text("⌘⇧D split right")
            Text("·")
            Text("⌘⇧E split below")
            Spacer()
            if let path = model.activeSession?.currentDirectory {
                Text(path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 240, alignment: .trailing)
            }
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
    }

    private func render(_ node: PaneLayout) -> AnyView {
        if node.isLeaf {
            if let session = model.session(for: node.id) {
                return AnyView(TerminalPane(
                    session: session,
                    isActive: model.activePaneID == node.id,
                    theme: theme,
                    onSelect: { model.selectPane(node.id) },
                    onClose: {
                        model.selectPane(node.id)
                        model.closeActivePane()
                    }
                ))
            }
            return AnyView(EmptyView())
        }
        guard node.children.count == 2 else { return AnyView(EmptyView()) }
        return AnyView(GeometryReader { geometry in
                let first = node.children[0]
                let second = node.children[1]
                if node.axis == .columns {
                    HStack(spacing: 0) {
                        render(first)
                            .frame(width: max(150, (geometry.size.width - 6) * node.fraction))
                        SplitHandle(axis: .columns, initialFraction: node.fraction) { value in
                            model.setSplitFraction(value, splitID: node.id)
                        }
                        render(second)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        render(first)
                            .frame(height: max(100, (geometry.size.height - 6) * node.fraction))
                        SplitHandle(axis: .rows, initialFraction: node.fraction) { value in
                            model.setSplitFraction(value, splitID: node.id)
                        }
                        render(second)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            })
    }

    private var paletteOverlay: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture { model.isCommandPalettePresented = false }
            CommandPalette(model: model)
                .padding(.top, 34)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct SplitHandle: View {
    let axis: SplitAxis
    let initialFraction: Double
    let onChange: (Double) -> Void
    @State private var dragStart: Double?

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(.white.opacity(0.15))
                .overlay(Capsule().fill(.white.opacity(0.24)).padding(axis == .columns ? .vertical : .horizontal, 3))
                .frame(width: axis == .columns ? 6 : 34, height: axis == .rows ? 6 : 34)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if dragStart == nil { dragStart = initialFraction }
                            let extent = axis == .columns ? geometry.size.width : geometry.size.height
                            guard extent > 0 else { return }
                            let change = axis == .columns ? value.translation.width : value.translation.height
                            onChange((dragStart ?? initialFraction) + Double(change / extent))
                        }
                        .onEnded { _ in dragStart = nil }
                )
                .onHover { hovering in
                    if hovering {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        }
        .frame(width: axis == .columns ? 8 : nil, height: axis == .rows ? 8 : nil)
    }
}

private struct CommandPalette: View {
    @ObservedObject var model: WorkspaceModel
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var commands: [StarterCommand] {
        StarterCommand.bundled
            .compactMap { command -> (StarterCommand, Int)? in command.score(for: query).map { (command, $0) } }
            .sorted { $0.1 == $1.1 ? $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedAscending : $0.1 < $1.1 }
            .map(\.0)
    }

    private var actions: [(String, String, String)] {
        [
            ("new-tab", "New tab", "Open a fresh shell · ⌘T"),
            ("split-right", "Split right", "Add a side-by-side shell · ⌘⇧D"),
            ("split-below", "Split below", "Add a shell underneath · ⌘⇧E"),
            ("focus-next", "Focus next pane", "Move focus to the next split · ⌘⇧]"),
            ("close-pane", "Close pane", "Close the focused split"),
            ("close-tab", "Close tab", "Close the current tab · ⌘W")
        ].filter { query.isEmpty || "\($0.1) \($0.2)".localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Find a command or action", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($searchFocused)
                    .onKeyPress(.escape) {
                        model.isCommandPalettePresented = false
                        return .handled
                    }
                Text("ESC")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)

            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)

            ScrollView {
                VStack(spacing: 3) {
                    if !actions.isEmpty {
                        sectionTitle("APP ACTIONS")
                        ForEach(actions, id: \.0) { action in
                            paletteRow(title: action.1, detail: action.2, command: nil) {
                                run(action.0)
                            }
                        }
                    }
                    if !commands.isEmpty {
                        sectionTitle("STARTER COMMANDS")
                        ForEach(commands) { command in
                            paletteRow(title: command.name, detail: command.detail, command: command.command) {
                                model.insert(command.command)
                            }
                        }
                    }
                    if actions.isEmpty && commands.isEmpty {
                        Text("no matches — try a command, git, files, or split")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(24)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 420)

            HStack {
                Text("commands are inserted at the prompt; press return when you’re ready")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.08))
        }
        .frame(width: 560)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.19), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 14)
        .onAppear { searchFocused = true }
        .onChange(of: model.isCommandPalettePresented) { _, isPresented in
            if !isPresented { query = "" }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 9)
        .padding(.top, 9)
        .padding(.bottom, 3)
    }

    private func paletteRow(title: String, detail: String, command: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 12, weight: .semibold))
                    Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if let command {
                    Text(command)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PaletteRowButtonStyle())
    }

    private func run(_ id: String) {
        model.isCommandPalettePresented = false
        switch id {
        case "new-tab": model.addTab()
        case "split-right": model.splitActivePane(using: .columns)
        case "split-below": model.splitActivePane(using: .rows)
        case "focus-next": model.focusNextPane()
        case "close-pane": model.closeActivePane()
        case "close-tab": model.closeActiveTab()
        default: break
        }
    }
}

private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.white.opacity(0.08), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.68 : 1)
    }
}

private struct PaletteRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? .white.opacity(0.14) : .white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}
