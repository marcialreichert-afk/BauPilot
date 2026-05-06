import Foundation

enum Sortierung: String, CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst
    case priorityHighFirst
    case priorityLowFirst
    case statusFirst
    case titleAZ

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .newestFirst:
            return "sort.newest_first".localized("Neueste zuerst")
        case .oldestFirst:
            return "sort.oldest_first".localized("Älteste zuerst")
        case .priorityHighFirst:
            return "sort.priority_high_first".localized("Priorität hoch zuerst")
        case .priorityLowFirst:
            return "sort.priority_low_first".localized("Priorität niedrig zuerst")
        case .statusFirst:
            return "sort.status_first".localized("Status zuerst")
        case .titleAZ:
            return "sort.title_az".localized("Titel A–Z")
        }
    }
}
