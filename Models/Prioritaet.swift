import SwiftUI

enum Prioritaet: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .low: return "priority.low"
        case .medium: return "priority.medium"
        case .high: return "priority.high"
        }
    }

    var localizedName: String {
        switch self {
        case .low: return localizedKey.localized("Niedrig")
        case .medium: return localizedKey.localized("Mittel")
        case .high: return localizedKey.localized("Hoch")
        }
    }

    var sortierWert: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    var farbe: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()

        switch value {
        case "low", "niedrig":
            self = .low
        case "medium", "mittel":
            self = .medium
        case "high", "hoch":
            self = .high
        default:
            self = .medium
        }
    }
}
