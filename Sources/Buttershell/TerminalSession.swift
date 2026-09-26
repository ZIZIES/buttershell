import AppKit
import Combine
import SwiftTerm

@MainActor
final class TerminalSession: NSObject, ObservableObject, LocalProcessTerminalViewDelegate {
    let id: UUID
    let view: LocalProcessTerminalView
    @Published private(set) var currentDirectory: String?
    @Published private(set) var exitCode: Int32?
    @Published private(set) var hasExited = false

    var onExit: ((UUID, Int32?) -> Void)?
    var onDirectoryChange: ((UUID, String?) -> Void)?
    var onTitleChange: ((UUID, String) -> Void)?

    init(id: UUID, currentDirectory: String?, suggestions: [String]) {
        self.id = id
        self.currentDirectory = currentDirectory
        view = LocalProcessTerminalView(frame: .zero)
        super.init()

        view.processDelegate = self
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        view.startProcess(
            executable: shell,
            args: ["-l"],
            environment: ShellIntegration.environment(for: shell, suggestions: suggestions),
            currentDirectory: currentDirectory
        )
    }

    nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        Task { @MainActor [weak self] in
            guard let self, !title.isEmpty else { return }
            self.onTitleChange?(self.id, title)
        }
    }

    nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        let path = directory.flatMap(Self.localPath(from:))
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentDirectory = path
            self.onDirectoryChange?(self.id, path)
        }
    }

    nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.exitCode = exitCode
            self.hasExited = true
            self.onExit?(self.id, exitCode)
        }
    }

    private nonisolated static func localPath(from value: String) -> String? {
        if let url = URL(string: value), url.isFileURL { return url.path }
        return value.hasPrefix("/") ? value : nil
    }

}
