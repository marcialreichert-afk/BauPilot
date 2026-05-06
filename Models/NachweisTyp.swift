import Foundation

enum NachweisTyp: String, CaseIterable, Codable, Identifiable {
    case pressureTest
    case filling
    case commissioning
    case inspectionReport
    case acceptance
    case other

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .pressureTest: return "proof_type.pressure_test"
        case .filling: return "proof_type.filling"
        case .commissioning: return "proof_type.commissioning"
        case .inspectionReport: return "proof_type.inspection_report"
        case .acceptance: return "proof_type.acceptance"
        case .other: return "proof_type.other"
        }
    }

    var localizedName: String {
        switch self {
        case .pressureTest: return localizedKey.localized("Druckprüfung")
        case .filling: return localizedKey.localized("Befüllung")
        case .commissioning: return localizedKey.localized("Inbetriebnahme")
        case .inspectionReport: return localizedKey.localized("Prüfprotokoll")
        case .acceptance: return localizedKey.localized("Abnahme")
        case .other: return localizedKey.localized("Sonstiges")
        }
    }

    var symbolName: String {
        switch self {
        case .pressureTest: return "gauge.with.dots.needle.33percent"
        case .filling: return "drop.fill"
        case .commissioning: return "play.circle.fill"
        case .inspectionReport: return "doc.text.magnifyingglass"
        case .acceptance: return "checkmark.seal.fill"
        case .other: return "doc.fill"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()

        switch value {
        case "pressuretest", "pressure_test", "druckprüfung", "druckpruefung":
            self = .pressureTest
        case "filling", "befüllung", "befuellung":
            self = .filling
        case "commissioning", "inbetriebnahme":
            self = .commissioning
        case "inspectionreport", "inspection_report", "prüfprotokoll", "pruefprotokoll":
            self = .inspectionReport
        case "acceptance", "abnahme":
            self = .acceptance
        default:
            self = .other
        }
    }
}
