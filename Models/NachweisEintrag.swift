import Foundation

struct NachweisEintrag: Identifiable, Codable, Equatable {
    let id: UUID
    var titel: String
    var typ: NachweisTyp
    var notiz: String
    var datum: Date
    var bilder: [Data]

    init(
        id: UUID = UUID(),
        titel: String = "",
        typ: NachweisTyp = .other,
        notiz: String = "",
        datum: Date = Date(),
        bilder: [Data] = []
    ) {
        self.id = id
        self.titel = titel
        self.typ = typ
        self.notiz = notiz
        self.datum = datum
        self.bilder = bilder
    }
}
