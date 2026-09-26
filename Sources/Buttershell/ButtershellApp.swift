import SwiftUI

@main
struct ButtershellApp: App {
    @StateObject private var model = WorkspaceModel()

    var body: some Scene {
        WindowGroup {
            MainWindow(model: model)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            ButtershellCommands(model: model)
        }
    }
}

private struct ButtershellCommands: Commands {
    @ObservedObject var model: WorkspaceModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Tab") { model.addTab() }
                .keyboardShortcut("t", modifiers: .command)
            Button("Command Palette") { model.isCommandPalettePresented = true }
                .keyboardShortcut("k", modifiers: .command)
        }

        CommandMenu("Pane") {
            Button("Split Right") { model.splitActivePane(using: .columns) }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Button("Split Below") { model.splitActivePane(using: .rows) }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            Button("Focus Next Pane") { model.focusNextPane() }
                .keyboardShortcut("]", modifiers: [.command, .shift])
            Divider()
            Button("Close Pane") { model.closeActivePane() }
            Button("Close Tab") { model.closeActiveTab() }
                .keyboardShortcut("w", modifiers: .command)
        }
    }
}
