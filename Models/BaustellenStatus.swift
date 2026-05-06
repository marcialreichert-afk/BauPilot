import Foundation

enum BaustellenStatus: String, CaseIterable, Codable, Identifiable {
    case open
    case inProgress
    case done

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .open: return "status.open"
        case .inProgress: return "status.in_progress"
        case .done: return "status.done"
        }
    }

    var localizedName: String {
        switch self {
        case .open: return localizedKey.localized("Offen")
        case .inProgress: return localizedKey.localized("In Bearbeitung")
        case .done: return localizedKey.localized("Erledigt")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()

        switch value {
        case "open", "offen":
            self = .open
        case "inprogress", "in_progress", "in bearbeitung", "in arbeit":
            self = .inProgress
        case "done", "erledigt":
            self = .done
        default:
            self = .open
        }
    }
}
