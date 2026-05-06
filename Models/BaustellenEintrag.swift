import Foundation

struct BaustellenEintrag: Identifiable, Codable, Equatable {
    let id: UUID
    var titel: String
    var notiz: String
    var kategorie: BaustellenKategorie
    var status: BaustellenStatus
    var prioritaet: Prioritaet
    var datum: Date
    var bilder: [Data]

    init(
        id: UUID = UUID(),
        titel: String = "",
        notiz: String = "",
        kategorie: BaustellenKategorie = .other,
        status: BaustellenStatus = .open,
        prioritaet: Prioritaet = .medium,
        datum: Date = Date(),
        bilder: [Data] = []
    ) {
        self.id = id
        self.titel = titel
        self.notiz = notiz
        self.kategorie = kategorie
        self.status = status
        self.prioritaet = prioritaet
        self.datum = datum
        self.bilder = bilder
    }
}
