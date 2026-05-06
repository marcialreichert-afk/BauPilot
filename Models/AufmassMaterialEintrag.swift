import Foundation

struct AufmassMaterialEintrag: Identifiable, Codable, Equatable {
    let id: UUID
    var titel: String
    var datum: Date
    var notiz: String
    var positionen: [AufmassPosition]
    var bild: Data?

    var gesamtMengeAnzeige: String {
        let zahlen = positionen.compactMap {
            Double($0.menge.replacingOccurrences(of: ",", with: "."))
        }
        let summe = zahlen.reduce(0, +)
        if summe == 0 { return "-" }
        return String(format: "%.2f", summe)
    }

    init(
        id: UUID = UUID(),
        titel: String = "",
        datum: Date = Date(),
        notiz: String = "",
        positionen: [AufmassPosition] = [],
        bild: Data? = nil
    ) {
        self.id = id
        self.titel = titel
        self.datum = datum
        self.notiz = notiz
        self.positionen = positionen
        self.bild = bild
    }

    enum CodingKeys: String, CodingKey {
        case id
        case titel
        case datum
        case notiz
        case positionen
        case bild
        case bezeichnung
        case menge
        case einheit
        case bereich
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        titel = try container.decodeIfPresent(String.self, forKey: .titel) ?? ""
        datum = try container.decodeIfPresent(Date.self, forKey: .datum) ?? Date()
        notiz = try container.decodeIfPresent(String.self, forKey: .notiz) ?? ""
        bild = try container.decodeIfPresent(Data.self, forKey: .bild)

        if let neuePositionen = try container.decodeIfPresent([AufmassPosition].self, forKey: .positionen) {
            positionen = neuePositionen
        } else {
            let alteBezeichnung = try container.decodeIfPresent(String.self, forKey: .bezeichnung) ?? ""
            let alteMenge = try container.decodeIfPresent(String.self, forKey: .menge) ?? ""
            let alteEinheit = try container.decodeIfPresent(String.self, forKey: .einheit) ?? ""
            let alterBereich = try container.decodeIfPresent(String.self, forKey: .bereich) ?? ""

            if !alteBezeichnung.isEmpty || !alteMenge.isEmpty || !alteEinheit.isEmpty || !alterBereich.isEmpty {
                positionen = [
                    AufmassPosition(
                        bezeichnung: alteBezeichnung,
                        menge: alteMenge,
                        einheit: alteEinheit.isEmpty ? "Stk" : alteEinheit,
                        bereich: alterBereich,
                        notiz: ""
                    )
                ]
            } else {
                positionen = []
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(titel, forKey: .titel)
        try container.encode(datum, forKey: .datum)
        try container.encode(notiz, forKey: .notiz)
        try container.encode(positionen, forKey: .positionen)
        try container.encodeIfPresent(bild, forKey: .bild)
    }
}
