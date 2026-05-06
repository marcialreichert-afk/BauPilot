import Foundation

struct AufmassPosition: Identifiable, Codable, Equatable {
    let id: UUID
    var bezeichnung: String
    var menge: String
    var einheit: String
    var bereich: String
    var notiz: String

    init(
        id: UUID = UUID(),
        bezeichnung: String = "",
        menge: String = "",
        einheit: String = "Stk",
        bereich: String = "",
        notiz: String = ""
    ) {
        self.id = id
        self.bezeichnung = bezeichnung
        self.menge = menge
        self.einheit = einheit
        self.bereich = bereich
        self.notiz = notiz
    }
}

