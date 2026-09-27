import AppKit
import SwiftUI

@main
struct ButtershellApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycleDelegate.self) private var appLifecycleDelegate
    @StateObject private var model = WorkspaceModel()

    var body: some Scene {
        WindowGroup {
            MainWindow(model: model)
        }
        .windowStyle(.titleBar)
        .commands {
            ButtershellCommands(model: model)
        }
    }
}

private final class AppLifecycleDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

private struct ButtershellCommands: Commands {
    @ObservedObject var model: WorkspaceModel

    var body: some Commands {
        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Paste") {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v", modifiers: .command)

            Button("Select All") {
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("a", modifiers: .command)
        }

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
