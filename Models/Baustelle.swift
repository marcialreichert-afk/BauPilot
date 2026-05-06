import Foundation

struct Baustelle: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var ort: String
    var kunde: String
    var notiz: String
    var erstelltAm: Date
    var eintraege: [BaustellenEintrag]
    var nachweise: [NachweisEintrag]
    var aufmasse: [AufmassMaterialEintrag]

    init(
        id: UUID = UUID(),
        name: String = "",
        ort: String = "",
        kunde: String = "",
        notiz: String = "",
        erstelltAm: Date = Date(),
        eintraege: [BaustellenEintrag] = [],
        nachweise: [NachweisEintrag] = [],
        aufmasse: [AufmassMaterialEintrag] = []
    ) {
        self.id = id
        self.name = name
        self.ort = ort
        self.kunde = kunde
        self.notiz = notiz
        self.erstelltAm = erstelltAm
        self.eintraege = eintraege
        self.nachweise = nachweise
        self.aufmasse = aufmasse
    }
}
