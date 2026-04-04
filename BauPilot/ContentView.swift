import SwiftUI
import Combine
import PhotosUI
import UIKit

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

extension Color {
    static let bauPilotBlue = Color(red: 0.16, green: 0.45, blue: 0.95)
    static let bauPilotLight = Color(red: 0.94, green: 0.97, blue: 1.00)
    static let bauPilotDarkText = Color(red: 0.12, green: 0.16, blue: 0.24)
    static let bauPilotCard = Color(.secondarySystemBackground)
}

enum BaustellenKategorie: String, CaseIterable, Codable, Identifiable {
    case elektro = "Elektro"
    case heizung = "Heizung"
    case sanitär = "Sanitär"
    case mauerwerk = "Mauerwerk"
    case boden = "Boden"
    case fenster = "Fenster"
    case sonstiges = "Sonstiges"

    var id: String { rawValue }
    var anzeigeText: String { rawValue.localized }

    var symbol: String {
        switch self {
        case .elektro: return "bolt.fill"
        case .heizung: return "flame.fill"
        case .sanitär: return "drop.fill"
        case .mauerwerk: return "building.2.fill"
        case .boden: return "square.grid.3x3.fill"
        case .fenster: return "rectangle.split.3x1.fill"
        case .sonstiges: return "hammer.fill"
        }
    }
}

enum BaustellenStatus: String, CaseIterable, Codable, Identifiable {
    case offen = "Offen"
    case inArbeit = "In Arbeit"
    case erledigt = "Erledigt"

    var id: String { rawValue }
    var anzeigeText: String { rawValue.localized }

    var color: Color {
        switch self {
        case .offen: return .red
        case .inArbeit: return .orange
        case .erledigt: return .green
        }
    }

    var symbol: String {
        switch self {
        case .offen: return "exclamationmark.circle.fill"
        case .inArbeit: return "clock.fill"
        case .erledigt: return "checkmark.circle.fill"
        }
    }

    var sortWert: Int {
        switch self {
        case .offen: return 0
        case .inArbeit: return 1
        case .erledigt: return 2
        }
    }
}

enum BaustellenPrioritaet: String, CaseIterable, Codable, Identifiable {
    case niedrig = "Niedrig"
    case mittel = "Mittel"
    case hoch = "Hoch"

    var id: String { rawValue }
    var anzeigeText: String { rawValue.localized }

    var color: Color {
        switch self {
        case .niedrig: return .bauPilotBlue
        case .mittel: return .orange
        case .hoch: return .red
        }
    }

    var symbol: String {
        switch self {
        case .niedrig: return "arrow.down.circle.fill"
        case .mittel: return "equal.circle.fill"
        case .hoch: return "arrow.up.circle.fill"
        }
    }

    var sortWertAbsteigend: Int {
        switch self {
        case .hoch: return 0
        case .mittel: return 1
        case .niedrig: return 2
        }
    }

    var sortWertAufsteigend: Int {
        switch self {
        case .niedrig: return 0
        case .mittel: return 1
        case .hoch: return 2
        }
    }
}

enum Sortierung: String, CaseIterable, Identifiable {
    case neuesteZuerst = "Neueste zuerst"
    case aeltesteZuerst = "Älteste zuerst"
    case prioritaetHoch = "Priorität hoch zuerst"
    case prioritaetNiedrig = "Priorität niedrig zuerst"
    case statusZuerst = "Status zuerst"

    var id: String { rawValue }
    var anzeigeText: String { rawValue.localized }

    var symbol: String {
        switch self {
        case .neuesteZuerst: return "arrow.down.circle"
        case .aeltesteZuerst: return "arrow.up.circle"
        case .prioritaetHoch: return "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .prioritaetNiedrig: return "arrow.down.to.line"
        case .statusZuerst: return "line.3.horizontal.decrease.circle"
        }
    }
}

struct BaustellenEintrag: Identifiable, Codable, Equatable {
    var id = UUID()
    var kategorie: BaustellenKategorie
    var status: BaustellenStatus
    var prioritaet: BaustellenPrioritaet
    var titel: String
    var beschreibung: String
    var erstelltAm: Date
    var fotoPfade: [String]

    var erstelltAmText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: erstelltAm)
    }
}

struct Baustelle: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var erstelltAm: Date = Date()
    var eintraege: [BaustellenEintrag]
}

enum BildSpeicher {
    static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func bildSpeichern(_ data: Data) -> String? {
        let dateiname = UUID().uuidString + ".jpg"
        let url = documentsURL().appendingPathComponent(dateiname)

        do {
            try data.write(to: url, options: .atomic)
            return dateiname
        } catch {
            print("Fehler beim Bildspeichern: \(error)")
            return nil
        }
    }

    static func bildLaden(pfad: String) -> UIImage? {
        let url = documentsURL().appendingPathComponent(pfad)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func bildLoeschen(pfad: String) {
        let url = documentsURL().appendingPathComponent(pfad)
        try? FileManager.default.removeItem(at: url)
    }
}

enum PDFExport {
    static func dateiURL(fuer baustelle: Baustelle) -> URL {
        let saubererName = baustelle.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let dateiname = "Baustellenbericht_\(saubererName).pdf"
        return FileManager.default.temporaryDirectory.appendingPathComponent(dateiname)
    }

    static func datumText(_ datum: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: datum)
    }

    static func exportierePDF(fuer baustelle: Baustelle) -> URL? {
        let url = dateiURL(fuer: baustelle)

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40
        let contentWidth = pageWidth - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        do {
            try renderer.writePDF(to: url) { context in
                var y: CGFloat = margin
                var seitenNummer = 1

                func zeichneSeitenkopf(_ baustellenName: String) {
                    let kopfText = String(format: "Baustelle: %@".localized, baustellenName)
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.darkGray
                    ]
                    NSAttributedString(string: kopfText, attributes: attrs).draw(
                        in: CGRect(x: margin, y: 16, width: 300, height: 20)
                    )
                }

                func zeichneSeitenfuss() {
                    let fussText = String(format: "Seite %d".localized, seitenNummer)
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.darkGray
                    ]
                    NSAttributedString(string: fussText, attributes: attrs).draw(
                        in: CGRect(x: pageWidth - margin - 80, y: pageHeight - 24, width: 80, height: 16)
                    )
                }

                func neueSeiteWennNoetig(_ benoetigteHoehe: CGFloat) {
                    if y + benoetigteHoehe > pageHeight - margin - 20 {
                        zeichneSeitenfuss()
                        context.beginPage()
                        seitenNummer += 1
                        zeichneSeitenkopf(baustelle.name)
                        y = margin
                    }
                }

                func zeichneText(
                    _ text: String,
                    font: UIFont,
                    color: UIColor = .black,
                    rect: CGRect
                ) -> CGFloat {
                    let style = NSMutableParagraphStyle()
                    style.lineBreakMode = .byWordWrapping
                    style.alignment = .left

                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: color,
                        .paragraphStyle: style
                    ]

                    let attributed = NSAttributedString(string: text, attributes: attrs)
                    let size = attributed.boundingRect(
                        with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        context: nil
                    )

                    let drawRect = CGRect(
                        x: rect.minX,
                        y: rect.minY,
                        width: rect.width,
                        height: ceil(size.height)
                    )
                    attributed.draw(in: drawRect)
                    return ceil(size.height)
                }

                func zeichneTrennlinie(y: CGFloat) {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: margin, y: y))
                    path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                    UIColor.systemGray4.setStroke()
                    path.lineWidth = 1
                    path.stroke()
                }

                context.beginPage()
                zeichneSeitenkopf(baustelle.name)

                let titelHoehe = zeichneText(
                    "BauPilot – Baustellenbericht".localized,
                    font: .boldSystemFont(ofSize: 24),
                    rect: CGRect(x: margin, y: y, width: contentWidth, height: 100)
                )
                y += titelHoehe + 10

                let infoText = """
                \(String(format: "Baustelle: %@".localized, baustelle.name))
                \(String(format: "Exportiert am: %@".localized, datumText(Date())))
                \(String(format: "Anzahl Einträge: %d".localized, baustelle.eintraege.count))
                """

                let infoHoehe = zeichneText(
                    infoText,
                    font: .systemFont(ofSize: 14),
                    color: .darkGray,
                    rect: CGRect(x: margin, y: y, width: contentWidth, height: 120)
                )
                y += infoHoehe + 20

                zeichneTrennlinie(y: y)
                y += 20

                let sortierteEintraege = baustelle.eintraege.sorted { $0.erstelltAm > $1.erstelltAm }

                if sortierteEintraege.isEmpty {
                    _ = zeichneText(
                        "Keine Einträge vorhanden.".localized,
                        font: .systemFont(ofSize: 15),
                        color: .darkGray,
                        rect: CGRect(x: margin, y: y, width: contentWidth, height: 60)
                    )
                } else {
                    for (index, eintrag) in sortierteEintraege.enumerated() {
                        let style = NSMutableParagraphStyle()
                        style.lineBreakMode = .byWordWrapping

                        let attrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 14),
                            .paragraphStyle: style
                        ]

                        let blockText = """
                        \(index + 1). \(eintrag.titel)

                        \(String(format: "Kategorie: %@".localized, eintrag.kategorie.anzeigeText))
                        \(String(format: "Status: %@".localized, eintrag.status.anzeigeText))
                        \(String(format: "Priorität: %@".localized, eintrag.prioritaet.anzeigeText))
                        \(String(format: "Erstellt am: %@".localized, datumText(eintrag.erstelltAm)))

                        \("Beschreibung:".localized)
                        \(eintrag.beschreibung)
                        """

                        let attributed = NSAttributedString(string: blockText, attributes: attrs)
                        let neededHeight = attributed.boundingRect(
                            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                            context: nil
                        ).height + 30

                        neueSeiteWennNoetig(neededHeight)

                        let titelBlockHoehe = zeichneText(
                            "\(index + 1). \(eintrag.titel)",
                            font: .boldSystemFont(ofSize: 17),
                            rect: CGRect(x: margin, y: y, width: contentWidth, height: 60)
                        )
                        y += titelBlockHoehe + 8

                        let metaText = """
                        \(String(format: "Kategorie: %@".localized, eintrag.kategorie.anzeigeText))
                        \(String(format: "Status: %@".localized, eintrag.status.anzeigeText))
                        \(String(format: "Priorität: %@".localized, eintrag.prioritaet.anzeigeText))
                        \(String(format: "Erstellt am: %@".localized, datumText(eintrag.erstelltAm)))
                        """

                        let metaHoehe = zeichneText(
                            metaText,
                            font: .systemFont(ofSize: 13),
                            color: .darkGray,
                            rect: CGRect(x: margin, y: y, width: contentWidth, height: 100)
                        )
                        y += metaHoehe + 10

                        _ = zeichneText(
                            "Beschreibung:".localized,
                            font: .boldSystemFont(ofSize: 14),
                            rect: CGRect(x: margin, y: y, width: contentWidth, height: 30)
                        )
                        y += 22

                        let beschreibungHoehe = zeichneText(
                            eintrag.beschreibung,
                            font: .systemFont(ofSize: 14),
                            rect: CGRect(x: margin, y: y, width: contentWidth, height: 500)
                        )
                        y += beschreibungHoehe + 18

                        zeichneTrennlinie(y: y)
                        y += 18
                    }
                }

                zeichneSeitenfuss()
            }

            return url
        } catch {
            print("Fehler beim PDF-Export: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

final class BaustellenSpeicher: ObservableObject {
    @Published var baustellen: [Baustelle] = [] {
        didSet {
            speichern()
        }
    }

    private let key = "baustellen_free_only_v1_baupilot"

    init() {
        laden()
    }

    private func laden() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        do {
            baustellen = try JSONDecoder().decode([Baustelle].self, from: data)
        } catch {
            print("Fehler beim Laden: \(error)")
            baustellen = []
        }
    }

    private func speichern() {
        do {
            let data = try JSONEncoder().encode(baustellen)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }

    @discardableResult
    func baustelleHinzufuegen(name: String) -> Bool {
        let sauber = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sauber.isEmpty else { return false }

        baustellen.append(Baustelle(name: sauber, eintraege: []))
        return true
    }

    func baustelleLoeschen(at offsets: IndexSet) {
        let zuLoeschendeBaustellen = offsets.map { baustellen[$0] }

        for baustelle in zuLoeschendeBaustellen {
            for eintrag in baustelle.eintraege {
                for pfad in eintrag.fotoPfade {
                    BildSpeicher.bildLoeschen(pfad: pfad)
                }
            }
        }

        baustellen.remove(atOffsets: offsets)
    }

    func indexVonBaustelle(_ baustelle: Baustelle) -> Int? {
        baustellen.firstIndex(where: { $0.id == baustelle.id })
    }

    @discardableResult
    func eintragHinzufuegen(
        in baustelle: Baustelle,
        kategorie: BaustellenKategorie,
        status: BaustellenStatus,
        prioritaet: BaustellenPrioritaet,
        titel: String,
        beschreibung: String,
        fotoDatenListe: [Data]
    ) -> Bool {
        guard let index = indexVonBaustelle(baustelle) else { return false }

        let fotoPfade = fotoDatenListe.compactMap { BildSpeicher.bildSpeichern($0) }

        let neuerEintrag = BaustellenEintrag(
            kategorie: kategorie,
            status: status,
            prioritaet: prioritaet,
            titel: titel,
            beschreibung: beschreibung,
            erstelltAm: Date(),
            fotoPfade: fotoPfade
        )

        baustellen[index].eintraege.insert(neuerEintrag, at: 0)
        return true
    }

    func aktualisieren(
        in baustelle: Baustelle,
        eintrag: BaustellenEintrag,
        kategorie: BaustellenKategorie,
        status: BaustellenStatus,
        prioritaet: BaustellenPrioritaet,
        titel: String,
        beschreibung: String,
        fotoDatenListe: [Data]
    ) {
        guard let baustellenIndex = indexVonBaustelle(baustelle) else { return }
        guard let eintragIndex = baustellen[baustellenIndex].eintraege.firstIndex(where: { $0.id == eintrag.id }) else { return }

        for alterPfad in baustellen[baustellenIndex].eintraege[eintragIndex].fotoPfade {
            BildSpeicher.bildLoeschen(pfad: alterPfad)
        }

        let neuePfade = fotoDatenListe.compactMap { BildSpeicher.bildSpeichern($0) }

        baustellen[baustellenIndex].eintraege[eintragIndex].kategorie = kategorie
        baustellen[baustellenIndex].eintraege[eintragIndex].status = status
        baustellen[baustellenIndex].eintraege[eintragIndex].prioritaet = prioritaet
        baustellen[baustellenIndex].eintraege[eintragIndex].titel = titel
        baustellen[baustellenIndex].eintraege[eintragIndex].beschreibung = beschreibung
        baustellen[baustellenIndex].eintraege[eintragIndex].fotoPfade = neuePfade
    }

    func eintraegeLoeschen(in baustelle: Baustelle, at offsets: IndexSet, aus gefilterterListe: [BaustellenEintrag]) {
        guard let index = indexVonBaustelle(baustelle) else { return }

        let idsZumLoeschen = offsets.map { gefilterterListe[$0].id }
        let zuLoeschendeEintraege = baustellen[index].eintraege.filter { idsZumLoeschen.contains($0.id) }

        for eintrag in zuLoeschendeEintraege {
            for pfad in eintrag.fotoPfade {
                BildSpeicher.bildLoeschen(pfad: pfad)
            }
        }

        baustellen[index].eintraege.removeAll { idsZumLoeschen.contains($0.id) }
    }

    func aktuelleBaustelle(_ baustelle: Baustelle) -> Baustelle? {
        guard let index = indexVonBaustelle(baustelle) else { return nil }
        return baustellen[index]
    }
}

final class BaustellenEinstellungen: ObservableObject {
    @Published var baustellenName: String {
        didSet {
            UserDefaults.standard.set(baustellenName, forKey: key)
        }
    }

    private let key = "baustellen_name_v2_baupilot"

    init() {
        let gespeicherterName = UserDefaults.standard.string(forKey: key)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let gespeicherterName, !gespeicherterName.isEmpty {
            self.baustellenName = gespeicherterName
        } else {
            self.baustellenName = "BauPilot"
        }
    }

    func setzeBaustellenName(_ neuerName: String) {
        let sauber = neuerName.trimmingCharacters(in: .whitespacesAndNewlines)
        baustellenName = sauber.isEmpty ? "BauPilot" : sauber
    }
}

struct BauPilotBrandHeader: View {
    let appName: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.bauPilotBlue)
                    .frame(width: 52, height: 52)

                Image(systemName: "checklist")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(appName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.bauPilotBlue)

                Text("Baustellen einfach dokumentieren".localized)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct ContentView: View {
    @StateObject private var speicher = BaustellenSpeicher()
    @StateObject private var einstellungen = BaustellenEinstellungen()

    @State private var zeigeNeueBaustelle = false
    @State private var zeigeEinstellungen = false
    @State private var loeschKandidat: Baustelle?

    private var anzahlBaustellen: Int {
        speicher.baustellen.count
    }

    private var anzahlEintraegeGesamt: Int {
        speicher.baustellen.reduce(0) { $0 + $1.eintraege.count }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    BauPilotBrandHeader(appName: einstellungen.baustellenName)

                    Text("Dokumentiere Baustellen übersichtlich mit Einträgen, Fotos und PDF-Export.".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 10)

                HStack(spacing: 12) {
                    UebersichtKarte(
                        titel: "Baustellen".localized,
                        wertText: "\(anzahlBaustellen)",
                        farbe: .bauPilotBlue,
                        symbol: "building.2.fill"
                    )

                    UebersichtKarte(
                        titel: "Einträge".localized,
                        wertText: "\(anzahlEintraegeGesamt)",
                        farbe: .green,
                        symbol: "list.bullet.rectangle"
                    )
                }
                .padding(.horizontal)

                if speicher.baustellen.isEmpty {
                    Spacer(minLength: 40)

                    LeererStatusView(
                        symbol: "building.2.crop.circle",
                        titel: "Noch keine Baustelle angelegt".localized,
                        text: "Lege deine erste Baustelle an und starte mit der Dokumentation.".localized
                    )

                    Button {
                        zeigeNeueBaustelle = true
                    } label: {
                        Label("Baustelle anlegen".localized, systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaerButtonStyle())
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                } else {
                    List {
                        ForEach(speicher.baustellen) { baustelle in
                            NavigationLink {
                                BaustellenDetailView(
                                    speicher: speicher,
                                    baustelle: baustelle
                                )
                            } label: {
                                BaustelleKarteView(
                                    baustelle: speicher.aktuelleBaustelle(baustelle) ?? baustelle
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    loeschKandidat = baustelle
                                } label: {
                                    Label("Löschen".localized, systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        zeigeEinstellungen = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        zeigeNeueBaustelle = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.bauPilotBlue)
                    }
                }
            }
            .sheet(isPresented: $zeigeNeueBaustelle) {
                NeueBaustelleView(speicher: speicher)
            }
            .sheet(isPresented: $zeigeEinstellungen) {
                BaustellenEinstellungenView(einstellungen: einstellungen)
            }
            .alert("Baustelle löschen?".localized, isPresented: Binding(
                get: { loeschKandidat != nil },
                set: { if !$0 { loeschKandidat = nil } }
            )) {
                Button("Abbrechen".localized, role: .cancel) {
                    loeschKandidat = nil
                }
                Button("Löschen".localized, role: .destructive) {
                    if let kandidat = loeschKandidat,
                       let index = speicher.baustellen.firstIndex(where: { $0.id == kandidat.id }) {
                        speicher.baustelleLoeschen(at: IndexSet(integer: index))
                    }
                    loeschKandidat = nil
                }
            } message: {
                Text("Diese Baustelle und alle zugehörigen Einträge werden entfernt.".localized)
            }
        }
    }
}

struct NeueBaustelleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var speicher: BaustellenSpeicher

    @State private var name = ""
    @State private var zeigeFehler = false
    @State private var fehlerText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Baustellenname".localized) {
                    TextField("z. B. EFH Musterstraße".localized, text: $name)
                }
            }
            .navigationTitle("Neue Baustelle".localized)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern".localized) {
                        let sauber = name.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !sauber.isEmpty else {
                            fehlerText = "Bitte einen Namen für die Baustelle eingeben.".localized
                            zeigeFehler = true
                            return
                        }

                        if speicher.baustelleHinzufuegen(name: sauber) {
                            dismiss()
                        } else {
                            fehlerText = "Baustelle konnte nicht angelegt werden.".localized
                            zeigeFehler = true
                        }
                    }
                }
            }
            .alert("Hinweis".localized, isPresented: $zeigeFehler) {
                Button("OK".localized, role: .cancel) { }
            } message: {
                Text(fehlerText)
            }
        }
    }
}

struct BaustellenDetailView: View {
    @ObservedObject var speicher: BaustellenSpeicher
    let baustelle: Baustelle

    @State private var zeigeNeuenEintrag = false
    @State private var statusFilter: BaustellenStatus? = nil
    @State private var kategorieFilter: BaustellenKategorie? = nil
    @State private var suchtext = ""
    @State private var sortierung: Sortierung = .neuesteZuerst
    @State private var zeigePDFSheet = false
    @State private var pdfURL: URL?
    @State private var zeigePDFFehler = false
    @State private var loeschEintrag: BaustellenEintrag?

    private var aktuelleBaustelle: Baustelle? {
        speicher.aktuelleBaustelle(baustelle)
    }

    private var alleEintraege: [BaustellenEintrag] {
        aktuelleBaustelle?.eintraege ?? []
    }

    private var gefilterteEintraege: [BaustellenEintrag] {
        let gefiltert = alleEintraege.filter { eintrag in
            let passtStatus = statusFilter == nil || eintrag.status == statusFilter
            let passtKategorie = kategorieFilter == nil || eintrag.kategorie == kategorieFilter

            let trimmed = suchtext.trimmingCharacters(in: .whitespacesAndNewlines)
            let passtSuche = trimmed.isEmpty ||
                eintrag.titel.localizedCaseInsensitiveContains(trimmed) ||
                eintrag.beschreibung.localizedCaseInsensitiveContains(trimmed)

            return passtStatus && passtKategorie && passtSuche
        }

        switch sortierung {
        case .neuesteZuerst:
            return gefiltert.sorted { $0.erstelltAm > $1.erstelltAm }
        case .aeltesteZuerst:
            return gefiltert.sorted { $0.erstelltAm < $1.erstelltAm }
        case .prioritaetHoch:
            return gefiltert.sorted {
                if $0.prioritaet.sortWertAbsteigend == $1.prioritaet.sortWertAbsteigend {
                    return $0.erstelltAm > $1.erstelltAm
                }
                return $0.prioritaet.sortWertAbsteigend < $1.prioritaet.sortWertAbsteigend
            }
        case .prioritaetNiedrig:
            return gefiltert.sorted {
                if $0.prioritaet.sortWertAufsteigend == $1.prioritaet.sortWertAufsteigend {
                    return $0.erstelltAm > $1.erstelltAm
                }
                return $0.prioritaet.sortWertAufsteigend < $1.prioritaet.sortWertAufsteigend
            }
        case .statusZuerst:
            return gefiltert.sorted {
                if $0.status.sortWert == $1.status.sortWert {
                    return $0.erstelltAm > $1.erstelltAm
                }
                return $0.status.sortWert < $1.status.sortWert
            }
        }
    }

    private var anzahlOffen: Int {
        alleEintraege.filter { $0.status == .offen }.count
    }

    private var anzahlInArbeit: Int {
        alleEintraege.filter { $0.status == .inArbeit }.count
    }

    private var anzahlErledigt: Int {
        alleEintraege.filter { $0.status == .erledigt }.count
    }

    private var anzahlEintraege: Int {
        alleEintraege.count
    }

    var body: some View {
        VStack(spacing: 12) {
            kopfbereich
            uebersicht
            suchLeiste
            sortierLeiste
            statusFilterLeiste
            kategorieFilterLeiste

            if gefilterteEintraege.isEmpty {
                Spacer()

                if alleEintraege.isEmpty {
                    LeererStatusView(
                        symbol: "list.bullet.rectangle",
                        titel: "Noch keine Einträge vorhanden".localized,
                        text: "Lege den ersten Eintrag für diese Baustelle an.".localized
                    )
                } else {
                    LeererStatusView(
                        symbol: "magnifyingglass.circle.fill",
                        titel: "Keine Einträge gefunden".localized,
                        text: "Passe Suche, Filter oder Sortierung an.".localized
                    )
                }

                Spacer()
            } else {
                List {
                    ForEach(gefilterteEintraege) { eintrag in
                        NavigationLink {
                            EintragDetailView(
                                speicher: speicher,
                                baustelle: baustelle,
                                eintragID: eintrag.id
                            )
                        } label: {
                            EintragKarteView(eintrag: eintrag)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                loeschEintrag = eintrag
                            } label: {
                                Label("Löschen".localized, systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(aktuelleBaustelle?.name ?? baustelle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    guard let aktuelle = aktuelleBaustelle else { return }
                    pdfURL = PDFExport.exportierePDF(fuer: aktuelle)
                    zeigePDFSheet = pdfURL != nil
                    zeigePDFFehler = pdfURL == nil
                } label: {
                    Image(systemName: "doc.richtext")
                }

                Button {
                    zeigeNeuenEintrag = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.bauPilotBlue)
                }
            }
        }
        .sheet(isPresented: $zeigeNeuenEintrag) {
            NeuerEintragView(
                speicher: speicher,
                baustelle: baustelle
            )
        }
        .sheet(isPresented: $zeigePDFSheet) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
        .alert("PDF-Fehler".localized, isPresented: $zeigePDFFehler) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text("Das PDF konnte nicht erstellt werden.".localized)
        }
        .alert("Eintrag löschen?".localized, isPresented: Binding(
            get: { loeschEintrag != nil },
            set: { if !$0 { loeschEintrag = nil } }
        )) {
            Button("Abbrechen".localized, role: .cancel) {
                loeschEintrag = nil
            }
            Button("Löschen".localized, role: .destructive) {
                if let kandidat = loeschEintrag,
                   let index = gefilterteEintraege.firstIndex(where: { $0.id == kandidat.id }) {
                    speicher.eintraegeLoeschen(in: baustelle, at: IndexSet(integer: index), aus: gefilterteEintraege)
                }
                loeschEintrag = nil
            }
        } message: {
            Text("Dieser Eintrag wird dauerhaft entfernt.".localized)
        }
    }

    private var kopfbereich: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(aktuelleBaustelle?.name ?? baustelle.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Label(
                    String(format: "%lld Einträge".localized, Int64(anzahlEintraege)),
                    systemImage: "list.bullet.rectangle"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)

                Spacer()
            }

            Text("Erstelle Einträge, füge Fotos hinzu und exportiere einen PDF-Bericht.".localized)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var uebersicht: some View {
        HStack(spacing: 12) {
            UebersichtKarte(
                titel: "Offen".localized,
                wertText: "\(anzahlOffen)",
                farbe: .red,
                symbol: "exclamationmark.circle.fill"
            )

            UebersichtKarte(
                titel: "In Arbeit".localized,
                wertText: "\(anzahlInArbeit)",
                farbe: .orange,
                symbol: "clock.fill"
            )

            UebersichtKarte(
                titel: "Erledigt".localized,
                wertText: "\(anzahlErledigt)",
                farbe: .green,
                symbol: "checkmark.circle.fill"
            )
        }
        .padding(.horizontal)
    }

    private var suchLeiste: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Suche nach Titel oder Beschreibung".localized, text: $suchtext)

            if !suchtext.isEmpty {
                Button {
                    suchtext = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private var sortierLeiste: some View {
        Menu {
            Picker("Sortierung".localized, selection: $sortierung) {
                ForEach(Sortierung.allCases) { eintrag in
                    Label(eintrag.anzeigeText, systemImage: eintrag.symbol)
                        .tag(eintrag)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down.circle")
                Text(String(format: "Sortierung: %@".localized, sortierung.anzeigeText))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    private var statusFilterLeiste: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(
                    titel: "Alle Status".localized,
                    isSelected: statusFilter == nil
                ) {
                    statusFilter = nil
                }

                ForEach(BaustellenStatus.allCases) { status in
                    FilterChip(
                        titel: status.anzeigeText,
                        isSelected: statusFilter == status
                    ) {
                        statusFilter = status
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var kategorieFilterLeiste: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(
                    titel: "Alle Kategorien".localized,
                    isSelected: kategorieFilter == nil
                ) {
                    kategorieFilter = nil
                }

                ForEach(BaustellenKategorie.allCases) { kategorie in
                    FilterChip(
                        titel: kategorie.anzeigeText,
                        isSelected: kategorieFilter == kategorie
                    ) {
                        kategorieFilter = kategorie
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct BaustellenEinstellungenView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var einstellungen: BaustellenEinstellungen
    @State private var name: String

    init(einstellungen: BaustellenEinstellungen) {
        self.einstellungen = einstellungen
        _name = State(initialValue: einstellungen.baustellenName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("App-Name".localized) {
                    TextField("z. B. BauPilot".localized, text: $name)
                }

                Section {
                    Button("Standardname wiederherstellen".localized) {
                        name = "BauPilot"
                    }
                    .foregroundColor(.bauPilotBlue)
                }
            }
            .navigationTitle("Einstellungen".localized)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern".localized) {
                        einstellungen.setzeBaustellenName(name)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EintragDetailView: View {
    @ObservedObject var speicher: BaustellenSpeicher
    let baustelle: Baustelle
    let eintragID: UUID

    @State private var zeigeBearbeiten = false

    private var aktuellerEintrag: BaustellenEintrag? {
        guard let aktuelleBaustelle = speicher.aktuelleBaustelle(baustelle) else { return nil }
        return aktuelleBaustelle.eintraege.first(where: { $0.id == eintragID })
    }

    var body: some View {
        Group {
            if let eintrag = aktuellerEintrag {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !eintrag.fotoPfade.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(eintrag.fotoPfade.enumerated()), id: \.offset) { _, pfad in
                                        if let uiImage = BildSpeicher.bildLaden(pfad: pfad) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 260, height: 220)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                                .allowsHitTesting(false)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(eintrag.titel)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack(spacing: 8) {
                                InfoChip(
                                    text: eintrag.status.anzeigeText,
                                    systemImage: eintrag.status.symbol,
                                    color: eintrag.status.color
                                )

                                InfoChip(
                                    text: eintrag.prioritaet.anzeigeText,
                                    systemImage: eintrag.prioritaet.symbol,
                                    color: eintrag.prioritaet.color
                                )
                            }

                            InfoZeile(
                                titel: "Kategorie".localized,
                                wert: eintrag.kategorie.anzeigeText,
                                symbol: eintrag.kategorie.symbol,
                                farbe: .bauPilotBlue
                            )

                            InfoZeile(
                                titel: "Erstellt am".localized,
                                wert: eintrag.erstelltAmText,
                                symbol: "calendar",
                                farbe: .gray
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Beschreibung".localized)
                                    .font(.headline)

                                Text(eintrag.beschreibung)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Details".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Bearbeiten".localized) {
                            zeigeBearbeiten = true
                        }
                    }
                }
                .sheet(isPresented: $zeigeBearbeiten) {
                    EintragBearbeitenView(
                        speicher: speicher,
                        baustelle: baustelle,
                        eintrag: eintrag
                    )
                }
            } else {
                LeererStatusView(
                    symbol: "exclamationmark.triangle.fill",
                    titel: "Eintrag nicht gefunden".localized,
                    text: "Der Eintrag wurde möglicherweise gelöscht.".localized
                )
                .padding()
            }
        }
    }
}

struct NeuerEintragView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var speicher: BaustellenSpeicher
    let baustelle: Baustelle

    @State private var kategorie: BaustellenKategorie = .elektro
    @State private var status: BaustellenStatus = .offen
    @State private var prioritaet: BaustellenPrioritaet = .mittel
    @State private var titel = ""
    @State private var beschreibung = ""
    @State private var fotoDatenListe: [Data] = []

    @State private var zeigeHinweis = false
    @State private var hinweisText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Titel".localized) {
                    TextField("z. B. Bad EG fertigstellen".localized, text: $titel)
                }

                Section("Kategorie".localized) {
                    Picker("Kategorie".localized, selection: $kategorie) {
                        ForEach(BaustellenKategorie.allCases) { kategorie in
                            Text(kategorie.anzeigeText).tag(kategorie)
                        }
                    }
                }

                Section("Status".localized) {
                    Picker("Status".localized, selection: $status) {
                        ForEach(BaustellenStatus.allCases) { status in
                            Text(status.anzeigeText).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Priorität".localized) {
                    Picker("Priorität".localized, selection: $prioritaet) {
                        ForEach(BaustellenPrioritaet.allCases) { prioritaet in
                            Text(prioritaet.anzeigeText).tag(prioritaet)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Beschreibung".localized) {
                    TextEditor(text: $beschreibung)
                        .frame(minHeight: 140)
                }

                Section("Fotos".localized) {
                    FotoAuswahlMehrfachView(
                        fotoDatenListe: $fotoDatenListe
                    )
                }
            }
            .navigationTitle("Neuer Eintrag".localized)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern".localized) {
                        let saubererTitel = titel.trimmingCharacters(in: .whitespacesAndNewlines)
                        let saubereBeschreibung = beschreibung.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !saubererTitel.isEmpty, !saubereBeschreibung.isEmpty else {
                            hinweisText = "Bitte Titel und Beschreibung ausfüllen.".localized
                            zeigeHinweis = true
                            return
                        }

                        let erfolg = speicher.eintragHinzufuegen(
                            in: baustelle,
                            kategorie: kategorie,
                            status: status,
                            prioritaet: prioritaet,
                            titel: saubererTitel,
                            beschreibung: saubereBeschreibung,
                            fotoDatenListe: fotoDatenListe
                        )

                        if erfolg {
                            dismiss()
                        } else {
                            hinweisText = "Eintrag konnte nicht gespeichert werden.".localized
                            zeigeHinweis = true
                        }
                    }
                }
            }
            .alert("Hinweis".localized, isPresented: $zeigeHinweis) {
                Button("OK".localized, role: .cancel) { }
            } message: {
                Text(hinweisText)
            }
        }
    }
}

struct EintragBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var speicher: BaustellenSpeicher

    let baustelle: Baustelle
    let eintrag: BaustellenEintrag

    @State private var kategorie: BaustellenKategorie
    @State private var status: BaustellenStatus
    @State private var prioritaet: BaustellenPrioritaet
    @State private var titel: String
    @State private var beschreibung: String
    @State private var fotoDatenListe: [Data]

    @State private var zeigeHinweis = false
    @State private var hinweisText = ""

    init(speicher: BaustellenSpeicher, baustelle: Baustelle, eintrag: BaustellenEintrag) {
        self.speicher = speicher
        self.baustelle = baustelle
        self.eintrag = eintrag
        _kategorie = State(initialValue: eintrag.kategorie)
        _status = State(initialValue: eintrag.status)
        _prioritaet = State(initialValue: eintrag.prioritaet)
        _titel = State(initialValue: eintrag.titel)
        _beschreibung = State(initialValue: eintrag.beschreibung)
        _fotoDatenListe = State(initialValue: eintrag.fotoPfade.compactMap { pfad in
            guard let uiImage = BildSpeicher.bildLaden(pfad: pfad) else { return nil }
            return uiImage.jpegData(compressionQuality: 0.75)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Titel".localized) {
                    TextField("Titel".localized, text: $titel)
                }

                Section("Kategorie".localized) {
                    Picker("Kategorie".localized, selection: $kategorie) {
                        ForEach(BaustellenKategorie.allCases) { kategorie in
                            Text(kategorie.anzeigeText).tag(kategorie)
                        }
                    }
                }

                Section("Status".localized) {
                    Picker("Status".localized, selection: $status) {
                        ForEach(BaustellenStatus.allCases) { status in
                            Text(status.anzeigeText).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Priorität".localized) {
                    Picker("Priorität".localized, selection: $prioritaet) {
                        ForEach(BaustellenPrioritaet.allCases) { prioritaet in
                            Text(prioritaet.anzeigeText).tag(prioritaet)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Beschreibung".localized) {
                    TextEditor(text: $beschreibung)
                        .frame(minHeight: 140)
                }

                Section("Fotos".localized) {
                    FotoAuswahlMehrfachView(
                        fotoDatenListe: $fotoDatenListe
                    )
                }

                Section("Erstellt am".localized) {
                    Text(eintrag.erstelltAmText)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Bearbeiten".localized)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern".localized) {
                        let saubererTitel = titel.trimmingCharacters(in: .whitespacesAndNewlines)
                        let saubereBeschreibung = beschreibung.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !saubererTitel.isEmpty, !saubereBeschreibung.isEmpty else {
                            hinweisText = "Bitte Titel und Beschreibung ausfüllen.".localized
                            zeigeHinweis = true
                            return
                        }

                        speicher.aktualisieren(
                            in: baustelle,
                            eintrag: eintrag,
                            kategorie: kategorie,
                            status: status,
                            prioritaet: prioritaet,
                            titel: saubererTitel,
                            beschreibung: saubereBeschreibung,
                            fotoDatenListe: fotoDatenListe
                        )

                        dismiss()
                    }
                }
            }
            .alert("Hinweis".localized, isPresented: $zeigeHinweis) {
                Button("OK".localized, role: .cancel) { }
            } message: {
                Text(hinweisText)
            }
        }
    }
}

struct FotoAuswahlMehrfachView: View {
    @Binding var fotoDatenListe: [Data]

    @State private var photoItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if fotoDatenListe.isEmpty {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 34))
                                .foregroundColor(.secondary)

                            Text("Noch keine Fotos gewählt".localized)
                                .foregroundColor(.secondary)
                        }
                    }
                    .allowsHitTesting(false)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(fotoDatenListe.enumerated()), id: \.offset) { index, data in
                            ZStack(alignment: .topTrailing) {
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 180, height: 180)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .allowsHitTesting(false)
                                }

                                Button {
                                    fotoDatenListe.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(6)
                                }
                            }
                        }
                    }
                }
            }

            PhotosPicker(
                selection: $photoItems,
                maxSelectionCount: nil,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Fotos auswählen".localized)
                    Spacer()
                    Text("\(fotoDatenListe.count)")
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding()
                .background(Color.bauPilotBlue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .onChange(of: photoItems) { _, newItems in
                Task {
                    var neueBilder: [Data] = []

                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let komprimiert = komprimiereBild(data: data) {
                            neueBilder.append(komprimiert)
                        }
                    }

                    await MainActor.run {
                        fotoDatenListe = neueBilder
                    }
                }
            }

            Text(String(format: "%lld Fotos ausgewählt".localized, Int64(fotoDatenListe.count)))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func komprimiereBild(data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }

        let maxSeite: CGFloat = 1600
        let originalSize = image.size

        let skalierung = min(maxSeite / originalSize.width, maxSeite / originalSize.height, 1)
        let neueGroesse = CGSize(
            width: originalSize.width * skalierung,
            height: originalSize.height * skalierung
        )

        let renderer = UIGraphicsImageRenderer(size: neueGroesse)
        let neuesBild = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: neueGroesse))
        }

        return neuesBild.jpegData(compressionQuality: 0.75)
    }
}

struct BaustelleKarteView: View {
    let baustelle: Baustelle

    private var anzahlOffen: Int {
        baustelle.eintraege.filter { $0.status == .offen }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.bauPilotBlue)

                    Text(baustelle.name)
                        .font(.headline)
                }

                Spacer()

                Text("\(baustelle.eintraege.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.bauPilotBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.bauPilotBlue.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                Label(
                    String(format: "%lld Einträge".localized, Int64(baustelle.eintraege.count)),
                    systemImage: "list.bullet.rectangle"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)

                Label(
                    String(format: "%lld offen".localized, Int64(anzahlOffen)),
                    systemImage: "exclamationmark.circle"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct InfoZeile: View {
    let titel: String
    let wert: String
    let symbol: String
    let farbe: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundColor(farbe)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(titel)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(wert)
                    .font(.body)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct InfoChip: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
                .fontWeight(.semibold)
        }
        .font(.caption)
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct UebersichtKarte: View {
    let titel: String
    let wertText: String
    let farbe: Color
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundColor(farbe)

            Text(wertText)
                .font(.title2)
                .fontWeight(.bold)

            Text(titel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct EintragKarteView: View {
    let eintrag: BaustellenEintrag

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !eintrag.fotoPfade.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(eintrag.fotoPfade.enumerated()), id: \.offset) { _, pfad in
                            if let uiImage = BildSpeicher.bildLaden(pfad: pfad) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 140)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }

            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: eintrag.kategorie.symbol)
                        .foregroundColor(.bauPilotBlue)

                    Text(eintrag.kategorie.anzeigeText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: eintrag.status.symbol)
                    Text(eintrag.status.anzeigeText)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(eintrag.status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(eintrag.status.color.opacity(0.12))
                .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Image(systemName: eintrag.prioritaet.symbol)
                Text(String(format: "Priorität: %@".localized, eintrag.prioritaet.anzeigeText))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(eintrag.prioritaet.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(eintrag.prioritaet.color.opacity(0.12))
            .clipShape(Capsule())

            Text(eintrag.titel)
                .font(.headline)

            Text(eintrag.beschreibung)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            Text(eintrag.erstelltAmText)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FilterChip: View {
    let titel: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titel)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.bauPilotBlue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct LeererStatusView: View {
    let symbol: String
    let titel: String
    let text: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 56))
                .foregroundColor(.bauPilotBlue)

            Text(titel)
                .font(.title3)
                .fontWeight(.semibold)

            Text(text)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct PrimaerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.bauPilotBlue.opacity(0.8) : Color.bauPilotBlue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }
}

#Preview {
    ContentView()
}
