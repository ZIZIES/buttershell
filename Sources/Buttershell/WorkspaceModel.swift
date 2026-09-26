import Foundation
import Combine

@MainActor
final class WorkspaceModel: ObservableObject {
    @Published private(set) var tabs: [SavedTab] = []
    @Published var activeTabID: UUID?
    @Published var activePaneID: UUID?
    @Published var isCommandPalettePresented = false
    @Published var closeWindowWhenShellExits = UserDefaults.standard.object(forKey: "closeWindowWhenShellExits") as? Bool ?? true {
        didSet { UserDefaults.standard.set(closeWindowWhenShellExits, forKey: "closeWindowWhenShellExits") }
    }

    private var sessions: [UUID: TerminalSession] = [:]
    var onLastTabClosed: (() -> Void)?

    var activeTab: SavedTab? { tabs.first { $0.id == activeTabID } }
    var activeSession: TerminalSession? { activePaneID.flatMap { sessions[$0] } }

    func session(for paneID: UUID) -> TerminalSession? { sessions[paneID] }

    init() {
        if let data = UserDefaults.standard.data(forKey: "workspace.v1"),
           let restored = try? JSONDecoder().decode([SavedTab].self, from: data) {
            tabs = restored
        }
        if tabs.isEmpty {
            let pane = PaneLayout.leaf()
            tabs = [SavedTab(id: UUID(), title: "shell", layout: pane, directories: [:])]
        }

        for tab in tabs {
            for paneID in tab.layout.paneIDs {
                makeSession(id: paneID, directory: tab.directories[paneID.uuidString])
            }
        }
        activeTabID = tabs.first?.id
        activePaneID = tabs.first?.layout.paneIDs.first
        persist()
    }

    func addTab() {
        let pane = PaneLayout.leaf()
        let tab = SavedTab(id: UUID(), title: "shell \(tabs.count + 1)", layout: pane, directories: [:])
        tabs.append(tab)
        activeTabID = tab.id
        activePaneID = pane.id
        makeSession(id: pane.id, directory: nil)
        persist()
    }

    func ensureTabExists() {
        if tabs.isEmpty { addTab() }
    }

    func closeActiveTab() {
        guard let activeTabID else { return }
        closeTab(activeTabID)
    }

    func closeTab(_ id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        for paneID in tab.layout.paneIDs {
            if let session = sessions.removeValue(forKey: paneID), !session.hasExited {
                session.view.terminate()
            }
        }
        tabs.removeAll { $0.id == id }
        if tabs.isEmpty {
            activeTabID = nil
            activePaneID = nil
            persist()
            onLastTabClosed?()
            return
        }
        if activeTabID == id {
            activeTabID = tabs[0].id
            activePaneID = tabs[0].layout.paneIDs.first
        }
        persist()
    }

    func splitActivePane(using axis: SplitAxis) {
        guard let tabID = activeTabID, let paneID = activePaneID,
              let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        let newPaneID = UUID()
        var tab = tabs[index]
        tab.layout = tab.layout.adding(newPaneID, beside: paneID, axis: axis)
        tabs[index] = tab
        makeSession(id: newPaneID, directory: sessions[paneID]?.currentDirectory)
        activePaneID = newPaneID
        persist()
    }

    func closeActivePane() {
        guard let tabID = activeTabID, let paneID = activePaneID,
              let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        if tabs[index].layout.isLeaf {
            closeTab(tabID)
            return
        }
        if let session = sessions.removeValue(forKey: paneID), !session.hasExited {
            session.view.terminate()
        }
        var tab = tabs[index]
        tab.layout = tab.layout.removing(paneID) ?? .leaf()
        tab.directories.removeValue(forKey: paneID.uuidString)
        tabs[index] = tab
        activePaneID = tab.layout.paneIDs.first
        persist()
    }

    func focusNextPane() {
        guard let tab = activeTab, let activePaneID else { return }
        let paneIDs = tab.layout.paneIDs
        guard let current = paneIDs.firstIndex(of: activePaneID), !paneIDs.isEmpty else { return }
        self.activePaneID = paneIDs[(current + 1) % paneIDs.count]
    }

    func selectPane(_ id: UUID) {
        guard activeTab?.layout.paneIDs.contains(id) == true else { return }
        activePaneID = id
    }

    func setSplitFraction(_ fraction: Double, splitID: UUID) {
        guard let activeTabID, let index = tabs.firstIndex(where: { $0.id == activeTabID }) else { return }
        tabs[index].layout = tabs[index].layout.settingFraction(fraction, for: splitID)
        persist()
    }

    func setThemeAction() {
        isCommandPalettePresented = true
    }

    func handleShellExit(sessionID: UUID, code: Int32?) {
        guard let tab = tabs.first(where: { $0.layout.paneIDs.contains(sessionID) }) else { return }
        if closeWindowWhenShellExits {
            if tab.layout.paneIDs.count == 1 {
                closeTab(tab.id)
            } else {
                removeExitedPane(sessionID, from: tab)
            }
        }
    }

    func insert(_ command: String) {
        activeSession?.view.send(txt: command)
        isCommandPalettePresented = false
    }

    func recordDirectory(_ id: UUID, path: String?) {
        guard let tabIndex = tabs.firstIndex(where: { $0.layout.paneIDs.contains(id) }) else { return }
        if let path { tabs[tabIndex].directories[id.uuidString] = path }
        persist()
    }

    func recordTitle(_ id: UUID, title: String) {
        guard let tabIndex = tabs.firstIndex(where: { $0.layout.paneIDs.contains(id) }) else { return }
        tabs[tabIndex].title = title
        persist()
    }

    private func removeExitedPane(_ paneID: UUID, from tab: SavedTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        var updated = tabs[index]
        guard let layout = updated.layout.removing(paneID) else {
            closeTab(tab.id)
            return
        }
        updated.layout = layout
        updated.directories.removeValue(forKey: paneID.uuidString)
        tabs[index] = updated
        sessions.removeValue(forKey: paneID)
        if activePaneID == paneID { activePaneID = layout.paneIDs.first }
        persist()
    }

    private func makeSession(id: UUID, directory: String?) {
        let session = TerminalSession(id: id, currentDirectory: directory, suggestions: StarterCommand.bundled.map(\.command))
        session.onExit = { [weak self] id, code in self?.handleShellExit(sessionID: id, code: code) }
        session.onDirectoryChange = { [weak self] id, path in self?.recordDirectory(id, path: path) }
        session.onTitleChange = { [weak self] id, title in self?.recordTitle(id, title: title) }
        sessions[id] = session
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(tabs) else { return }
        UserDefaults.standard.set(data, forKey: "workspace.v1")
    }
}
