import Foundation

enum SplitAxis: String, Codable {
    case columns
    case rows
}

struct PaneLayout: Codable, Identifiable {
    var id: UUID
    var axis: SplitAxis?
    var fraction: Double
    var children: [PaneLayout]

    static func leaf(id: UUID = UUID()) -> PaneLayout {
        PaneLayout(id: id, axis: nil, fraction: 0.5, children: [])
    }

    static func split(_ axis: SplitAxis, first: PaneLayout, second: PaneLayout, id: UUID = UUID()) -> PaneLayout {
        PaneLayout(id: id, axis: axis, fraction: 0.5, children: [first, second])
    }

    var isLeaf: Bool { children.isEmpty }

    var paneIDs: [UUID] {
        isLeaf ? [id] : children.flatMap(\.paneIDs)
    }

    func adding(_ newPane: UUID, beside target: UUID, axis newAxis: SplitAxis) -> PaneLayout {
        if isLeaf, id == target {
            return .split(newAxis, first: self, second: .leaf(id: newPane))
        }
        var copy = self
        copy.children = children.map { $0.adding(newPane, beside: target, axis: newAxis) }
        return copy
    }

    func removing(_ pane: UUID) -> PaneLayout? {
        if isLeaf { return id == pane ? nil : self }
        guard let childIndex = children.firstIndex(where: { $0.paneIDs.contains(pane) }) else { return self }
        var copy = self
        if let updatedChild = children[childIndex].removing(pane) {
            copy.children[childIndex] = updatedChild
        } else {
            copy.children.remove(at: childIndex)
        }
        if copy.children.count == 1 { return copy.children[0] }
        return copy
    }

    func settingFraction(_ value: Double, for splitID: UUID) -> PaneLayout {
        var copy = self
        if id == splitID, !isLeaf {
            copy.fraction = min(0.82, max(0.18, value))
        } else {
            copy.children = children.map { $0.settingFraction(value, for: splitID) }
        }
        return copy
    }
}

struct SavedTab: Codable, Identifiable {
    var id: UUID
    var title: String
    var layout: PaneLayout
    var directories: [String: String]
}
