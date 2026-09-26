import AppKit
import SwiftUI

enum ColorTheme: String, CaseIterable, Identifiable {
    case midnight
    case ocean
    case ember
    case moss
    case orchid

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var background: NSColor {
        return switch self {
        case .midnight: NSColor(srgbRed: 0.055, green: 0.065, blue: 0.10, alpha: 1)
        case .ocean: NSColor(srgbRed: 0.035, green: 0.09, blue: 0.12, alpha: 1)
        case .ember: NSColor(srgbRed: 0.12, green: 0.055, blue: 0.055, alpha: 1)
        case .moss: NSColor(srgbRed: 0.055, green: 0.09, blue: 0.065, alpha: 1)
        case .orchid: NSColor(srgbRed: 0.095, green: 0.055, blue: 0.12, alpha: 1)
        }
    }

    var foreground: NSColor { NSColor(srgbRed: 0.88, green: 0.91, blue: 0.97, alpha: 1) }

    var accent: NSColor {
        return switch self {
        case .midnight: NSColor(srgbRed: 0.54, green: 0.62, blue: 1, alpha: 1)
        case .ocean: NSColor(srgbRed: 0.25, green: 0.78, blue: 0.79, alpha: 1)
        case .ember: NSColor(srgbRed: 1, green: 0.48, blue: 0.30, alpha: 1)
        case .moss: NSColor(srgbRed: 0.58, green: 0.84, blue: 0.44, alpha: 1)
        case .orchid: NSColor(srgbRed: 0.83, green: 0.53, blue: 0.95, alpha: 1)
        }
    }

    var swiftUIColor: Color { Color(nsColor: background) }
}
