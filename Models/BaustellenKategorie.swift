import Foundation

enum BaustellenKategorie: String, CaseIterable, Codable, Identifiable {
    case electrical
    case heating
    case plumbing
    case masonry
    case flooring
    case windows
    case other

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .electrical: return "category.electrical"
        case .heating: return "category.heating"
        case .plumbing: return "category.plumbing"
        case .masonry: return "category.masonry"
        case .flooring: return "category.flooring"
        case .windows: return "category.windows"
        case .other: return "category.other"
        }
    }

    var localizedName: String {
        switch self {
        case .electrical: return localizedKey.localized("Elektro")
        case .heating: return localizedKey.localized("Heizung")
        case .plumbing: return localizedKey.localized("Sanitär")
        case .masonry: return localizedKey.localized("Mauerwerk")
        case .flooring: return localizedKey.localized("Boden")
        case .windows: return localizedKey.localized("Fenster")
        case .other: return localizedKey.localized("Sonstiges")
        }
    }

    var symbolName: String {
        switch self {
        case .electrical: return "bolt.fill"
        case .heating: return "thermometer.sun.fill"
        case .plumbing: return "drop.fill"
        case .masonry: return "square.stack.3d.up.fill"
        case .flooring: return "square.grid.3x3.fill"
        case .windows: return "uiwindow.split.2x1"
        case .other: return "wrench.and.screwdriver.fill"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()

        switch value {
        case "electrical", "elektro":
            self = .electrical
        case "heating", "heizung":
            self = .heating
        case "plumbing", "sanitär", "sanitar", "sanitaer":
            self = .plumbing
        case "masonry", "mauerwerk":
            self = .masonry
        case "flooring", "boden":
            self = .flooring
        case "windows", "fenster":
            self = .windows
        default:
            self = .other
        }
    }
}
