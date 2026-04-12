import SwiftUI
import PhotosUI
import UIKit
import PDFKit
import CoreText
import Foundation
import Combine

// MARK: - Farben

extension Color {
    static let bauPilotBlue = Color(red: 0.11, green: 0.42, blue: 0.93)
    static let bauPilotBackground = Color(red: 0.93, green: 0.96, blue: 1.00)
    static let bauPilotCard = Color.white
    static let bauPilotText = Color(red: 0.08, green: 0.12, blue: 0.20)
    static let bauPilotSecondaryText = Color(red: 0.38, green: 0.45, blue: 0.56)
    static let bauPilotStroke = Color(red: 0.84, green: 0.89, blue: 0.96)
}


// MARK: - Modelle

enum BaustellenKategorie: String, CaseIterable, Codable, Identifiable {
    case elektro = "Elektro"
    case heizung = "Heizung"
    case sanitär = "Sanitär"
    case mauerwerk = "Mauerwerk"
    case boden = "Boden"
    case fenster = "Fenster"
    case sonstiges = "Sonstiges"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .elektro: return "bolt.fill"
        case .heizung: return "thermometer.sun.fill"
        case .sanitär: return "drop.fill"
        case .mauerwerk: return "square.stack.3d.up.fill"
        case .boden: return "square.grid.3x3.fill"
        case .fenster: return "uiwindow.split.2x1"
        case .sonstiges: return "wrench.and.screwdriver.fill"
        }
    }
}

enum BaustellenStatus: String, CaseIterable, Codable, Identifiable {
    case offen = "Offen"
    case inBearbeitung = "In Bearbeitung"
    case erledigt = "Erledigt"

    var id: String { rawValue }
}

enum Prioritaet: String, CaseIterable, Codable, Identifiable {
    case niedrig = "Niedrig"
    case mittel = "Mittel"
    case hoch = "Hoch"

    var id: String { rawValue }

    var sortierWert: Int {
        switch self {
        case .hoch: return 0
        case .mittel: return 1
        case .niedrig: return 2
        }
    }

    var farbe: Color {
        switch self {
        case .hoch: return .red
        case .mittel: return .orange
        case .niedrig: return .blue
        }
    }
}

enum Sortierung: String, CaseIterable, Identifiable {
    case neuesteZuerst = "Neueste zuerst"
    case aeltesteZuerst = "Älteste zuerst"
    case prioritaetHoch = "Priorität hoch zuerst"
    case prioritaetNiedrig = "Priorität niedrig zuerst"
    case status = "Status zuerst"
    case titel = "Titel A–Z"

    var id: String { rawValue }
}

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
        kategorie: BaustellenKategorie = .sonstiges,
        status: BaustellenStatus = .offen,
        prioritaet: Prioritaet = .mittel,
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

struct Baustelle: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var ort: String
    var kunde: String
    var notiz: String
    var erstelltAm: Date
    var eintraege: [BaustellenEintrag]

    init(
        id: UUID = UUID(),
        name: String = "",
        ort: String = "",
        kunde: String = "",
        notiz: String = "",
        erstelltAm: Date = Date(),
        eintraege: [BaustellenEintrag] = []
    ) {
        self.id = id
        self.name = name
        self.ort = ort
        self.kunde = kunde
        self.notiz = notiz
        self.erstelltAm = erstelltAm
        self.eintraege = eintraege
    }
}

// MARK: - Speicher

final class BaustellenSpeicher: ObservableObject {
    @Published var baustellen: [Baustelle] = [] {
        didSet { speichern() }
    }

    private let key = "baupilot_baustellen_v40"

    init() {
        laden()
    }

    private func laden() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        do {
            baustellen = try JSONDecoder().decode([Baustelle].self, from: data)
        } catch {
            print("Fehler beim Laden: \(error.localizedDescription)")
        }
    }

    private func speichern() {
        do {
            let data = try JSONEncoder().encode(baustellen)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Fehler beim Speichern: \(error.localizedDescription)")
        }
    }

    func addBaustelle(_ baustelle: Baustelle) {
        baustellen.insert(baustelle, at: 0)
    }

    func updateBaustelle(_ baustelle: Baustelle) {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelle.id }) else { return }
        baustellen[index] = baustelle
    }

    func deleteBaustelle(_ baustelle: Baustelle) {
        baustellen.removeAll { $0.id == baustelle.id }
    }

    func addEintrag(_ eintrag: BaustellenEintrag, to baustelleID: UUID) {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        baustellen[index].eintraege.insert(eintrag, at: 0)
    }

    func updateEintrag(_ eintrag: BaustellenEintrag, in baustelleID: UUID) {
        guard let baustellenIndex = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        guard let eintragIndex = baustellen[baustellenIndex].eintraege.firstIndex(where: { $0.id == eintrag.id }) else { return }
        baustellen[baustellenIndex].eintraege[eintragIndex] = eintrag
    }

    func deleteEintraege(at offsets: IndexSet, from gefilterteListe: [BaustellenEintrag], baustelleID: UUID) {
        let ids = offsets.map { gefilterteListe[$0].id }
        guard let baustellenIndex = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        baustellen[baustellenIndex].eintraege.removeAll { ids.contains($0.id) }
    }
}

// MARK: - PDF Export

enum PDFExportHelper {
    static func exportPDF(for baustelle: Baustelle) -> URL? {
        let fileName = "BauPilot-\(safeFileName(baustelle.name.isEmpty ? "Baustelle" : baustelle.name)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 36

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        do {
            try renderer.writePDF(to: url) { context in
                var y: CGFloat = margin

                func newPageIfNeeded(_ neededHeight: CGFloat) {
                    if y + neededHeight > pageHeight - margin {
                        context.beginPage()
                        y = margin
                    }
                }

                func drawText(
                    _ text: String,
                    x: CGFloat,
                    y: CGFloat,
                    width: CGFloat,
                    attributes: [NSAttributedString.Key: Any]
                ) -> CGFloat {
                    let string = NSAttributedString(string: text, attributes: attributes)
                    let framesetter = CTFramesetterCreateWithAttributedString(string as CFAttributedString)
                    let size = CTFramesetterSuggestFrameSizeWithConstraints(
                        framesetter,
                        CFRange(),
                        nil,
                        CGSize(width: width, height: .greatestFiniteMagnitude),
                        nil
                    )
                    let drawRect = CGRect(x: x, y: y, width: width, height: ceil(size.height))
                    string.draw(in: drawRect)
                    return ceil(size.height)
                }

                context.beginPage()

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor(Color.bauPilotBlue)
                ]

                let headingAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]

                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ]

                let smallAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.secondaryLabel
                ]

                y += drawText("BauPilot – Baustellenbericht", x: margin, y: y, width: pageWidth - margin * 2, attributes: titleAttributes)
                y += 12

                let kopf = """
                Baustelle: \(baustelle.name.isEmpty ? "-" : baustelle.name)
                Ort: \(baustelle.ort.isEmpty ? "-" : baustelle.ort)
                Kunde: \(baustelle.kunde.isEmpty ? "-" : baustelle.kunde)
                Erstellt am: \(baustelle.erstelltAm.formatted(date: .abbreviated, time: .omitted))
                Einträge: \(baustelle.eintraege.count)
                """

                y += drawText(kopf, x: margin, y: y, width: pageWidth - margin * 2, attributes: textAttributes)
                y += 16

                if !baustelle.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    y += drawText("Projekt-Notiz", x: margin, y: y, width: pageWidth - margin * 2, attributes: headingAttributes)
                    y += 6
                    y += drawText(
                        SpeechTextFormatter.bullets(baustelle.notiz),
                        x: margin,
                        y: y,
                        width: pageWidth - margin * 2,
                        attributes: textAttributes
                    )
                    y += 16
                }

                for (index, eintrag) in baustelle.eintraege.enumerated() {
                    newPageIfNeeded(220)

                    let headline = "\(index + 1). \(eintrag.titel.isEmpty ? "Ohne Titel" : eintrag.titel)"
                    y += drawText(headline, x: margin, y: y, width: pageWidth - margin * 2, attributes: headingAttributes)
                    y += 4

                    let meta = """
                    Kategorie: \(eintrag.kategorie.rawValue)
                    Status: \(eintrag.status.rawValue)
                    Priorität: \(eintrag.prioritaet.rawValue)
                    Datum: \(eintrag.datum.formatted(date: .abbreviated, time: .shortened))
                    """

                    y += drawText(meta, x: margin, y: y, width: pageWidth - margin * 2, attributes: smallAttributes)
                    y += 8

                    if !eintrag.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        y += drawText("Notiz", x: margin, y: y, width: pageWidth - margin * 2, attributes: headingAttributes)
                        y += 6
                        y += drawText(
                            SpeechTextFormatter.bullets(eintrag.notiz),
                            x: margin,
                            y: y,
                            width: pageWidth - margin * 2,
                            attributes: textAttributes
                        )
                        y += 10
                    }

                    if !eintrag.bilder.isEmpty {
                        let imageSize: CGFloat = 110
                        let spacing: CGFloat = 10
                        let maxColumns = 4

                        for (imgIndex, data) in eintrag.bilder.enumerated() {
                            if let image = UIImage(data: data) {
                                let row = imgIndex / maxColumns
                                let col = imgIndex % maxColumns

                                let drawY = y + CGFloat(row) * (imageSize + spacing)
                                let drawX = margin + CGFloat(col) * (imageSize + spacing)

                                if drawY + imageSize > pageHeight - margin {
                                    context.beginPage()
                                    y = margin
                                }

                                image.draw(in: CGRect(x: drawX, y: drawY, width: imageSize, height: imageSize))
                            }
                        }

                        let rows = Int(ceil(Double(eintrag.bilder.count) / Double(maxColumns)))
                        y += CGFloat(rows) * (imageSize + spacing)
                    }

                    y += 16
                }
            }

            return url
        } catch {
            print("PDF Fehler: \(error.localizedDescription)")
            return nil
        }
    }

    private static func safeFileName(_ text: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return text.components(separatedBy: invalid).joined(separator: "-")
    }
}

// MARK: - Share Sheet

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Hauptansicht

struct ContentView: View {
    @StateObject private var speicher = BaustellenSpeicher()
    @State private var suche = ""
    @State private var zeigeNeueBaustelle = false

    private var gefilterteBaustellen: [Baustelle] {
        speicher.baustellen.filter { baustelle in
            suche.isEmpty ||
            baustelle.name.localizedCaseInsensitiveContains(suche) ||
            baustelle.ort.localizedCaseInsensitiveContains(suche) ||
            baustelle.kunde.localizedCaseInsensitiveContains(suche) ||
            baustelle.notiz.localizedCaseInsensitiveContains(suche)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bauPilotBackground.ignoresSafeArea()

                VStack(spacing: 18) {
                    SuchLeiste(text: $suche, placeholder: "Baustellen suchen...")

                    if gefilterteBaustellen.isEmpty {
                        LeererStatusView(
                            icon: "building.2.crop.circle",
                            titel: "Noch keine Baustellen",
                            text: "Lege deine erste Baustelle an."
                        )
                    } else {
                        List {
                            ForEach(gefilterteBaustellen) { baustelle in
                                NavigationLink {
                                    BaustelleDetailView(speicher: speicher, baustelle: baustelle)
                                } label: {
                                    BaustellenKarte(baustelle: baustelle)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteBaustellen)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .navigationTitle("BauPilot")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.bauPilotBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        zeigeNeueBaustelle = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.bauPilotBlue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .sheet(isPresented: $zeigeNeueBaustelle) {
                BaustelleBearbeitenView(baustelle: Baustelle()) { neueBaustelle in
                    speicher.addBaustelle(neueBaustelle)
                }
            }
        }
    }

    private func deleteBaustellen(at offsets: IndexSet) {
        let objekte = offsets.map { gefilterteBaustellen[$0] }
        objekte.forEach { speicher.deleteBaustelle($0) }
    }
}

// MARK: - Baustellen Detail

struct BaustelleDetailView: View {
    @ObservedObject var speicher: BaustellenSpeicher
    let baustelle: Baustelle

    @StateObject private var speechManager = SpeechManager()

    @State private var suche = ""
    @State private var filterStatus: BaustellenStatus? = nil
    @State private var filterKategorie: BaustellenKategorie? = nil
    @State private var sortierung: Sortierung = .neuesteZuerst

    @State private var zeigeNeuenEintrag = false
    @State private var bearbeiteterEintrag: BaustellenEintrag?

    @State private var zeigeBaustellenBearbeiten = false
    @State private var pdfURL: URL?
    @State private var zeigeShareSheet = false

    private var aktuelleBaustelle: Baustelle {
        speicher.baustellen.first(where: { $0.id == baustelle.id }) ?? baustelle
    }

    private var gefilterteEintraege: [BaustellenEintrag] {
        var result = aktuelleBaustelle.eintraege.filter { eintrag in
            let passtSuche =
                suche.isEmpty ||
                eintrag.titel.localizedCaseInsensitiveContains(suche) ||
                eintrag.notiz.localizedCaseInsensitiveContains(suche)

            let passtStatus =
                filterStatus == nil || eintrag.status == filterStatus

            let passtKategorie =
                filterKategorie == nil || eintrag.kategorie == filterKategorie

            return passtSuche && passtStatus && passtKategorie
        }

        switch sortierung {
        case .neuesteZuerst:
            result.sort { $0.datum > $1.datum }
        case .aeltesteZuerst:
            result.sort { $0.datum < $1.datum }
        case .prioritaetHoch:
            result.sort { $0.prioritaet.sortierWert < $1.prioritaet.sortierWert }
        case .prioritaetNiedrig:
            result.sort { $0.prioritaet.sortierWert > $1.prioritaet.sortierWert }
        case .status:
            result.sort { $0.status.rawValue < $1.status.rawValue }
        case .titel:
            result.sort { $0.titel.localizedCaseInsensitiveCompare($1.titel) == .orderedAscending }
        }

        return result
    }

    var body: some View {
        ZStack {
            Color.bauPilotBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                ProjektInfoKarte(baustelle: aktuelleBaustelle)
                SuchLeiste(text: $suche, placeholder: "Einträge suchen...")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Menu {
                            Button("Alle Status") { filterStatus = nil }
                            ForEach(BaustellenStatus.allCases) { status in
                                Button(status.rawValue) { filterStatus = status }
                            }
                        } label: {
                            FilterChip(titel: filterStatus?.rawValue ?? "Status", icon: "line.3.horizontal.decrease.circle")
                        }

                        Menu {
                            Button("Alle Kategorien") { filterKategorie = nil }
                            ForEach(BaustellenKategorie.allCases) { kategorie in
                                Button(kategorie.rawValue) { filterKategorie = kategorie }
                            }
                        } label: {
                            FilterChip(titel: filterKategorie?.rawValue ?? "Kategorie", icon: "square.grid.2x2")
                        }

                        Menu {
                            ForEach(Sortierung.allCases) { option in
                                Button(option.rawValue) { sortierung = option }
                            }
                        } label: {
                            FilterChip(titel: sortierung.rawValue, icon: "arrow.up.arrow.down")
                        }

                        if filterStatus != nil || filterKategorie != nil || !suche.isEmpty {
                            Button("Zurücksetzen") {
                                filterStatus = nil
                                filterKategorie = nil
                                suche = ""
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                        }
                    }
                }

                if gefilterteEintraege.isEmpty {
                    LeererStatusView(
                        icon: "tray",
                        titel: "Noch keine Einträge",
                        text: "Lege den ersten Eintrag für diese Baustelle an."
                    )
                } else {
                    List {
                        ForEach(gefilterteEintraege) { eintrag in
                            Button {
                                bearbeiteterEintrag = eintrag
                            } label: {
                                EintragKarte(eintrag: eintrag)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            speicher.deleteEintraege(at: offsets, from: gefilterteEintraege, baustelleID: aktuelleBaustelle.id)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .navigationTitle(aktuelleBaustelle.name.isEmpty ? "Baustelle" : aktuelleBaustelle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.bauPilotBackground, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        zeigeBaustellenBearbeiten = true
                    } label: {
                        Label("Baustelle bearbeiten", systemImage: "pencil")
                    }

                    Button {
                        exportierePDF()
                    } label: {
                        Label("PDF exportieren", systemImage: "doc.richtext")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.bauPilotText)
                }

                Button {
                    zeigeNeuenEintrag = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.bauPilotBlue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 4)
                }
            }
        }
        .sheet(isPresented: $zeigeNeuenEintrag) {
            EintragBearbeitenView(
                speechManager: speechManager,
                eintrag: BaustellenEintrag()
            ) { neuerEintrag in
                speicher.addEintrag(neuerEintrag, to: aktuelleBaustelle.id)
            }
        }
        .sheet(item: $bearbeiteterEintrag) { eintrag in
            EintragBearbeitenView(
                speechManager: speechManager,
                eintrag: eintrag
            ) { geaenderterEintrag in
                speicher.updateEintrag(geaenderterEintrag, in: aktuelleBaustelle.id)
            }
        }
        .sheet(isPresented: $zeigeBaustellenBearbeiten) {
            BaustelleBearbeitenView(baustelle: aktuelleBaustelle) { geaendert in
                speicher.updateBaustelle(geaendert)
            }
        }
        .sheet(isPresented: $zeigeShareSheet) {
            if let pdfURL {
                ActivityView(items: [pdfURL])
            }
        }
    }

    private func exportierePDF() {
        pdfURL = PDFExportHelper.exportPDF(for: aktuelleBaustelle)
        zeigeShareSheet = pdfURL != nil
    }
}

// MARK: - Baustelle bearbeiten

struct BaustelleBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var baustelle: Baustelle
    let onSave: (Baustelle) -> Void

    init(baustelle: Baustelle, onSave: @escaping (Baustelle) -> Void) {
        self._baustelle = State(initialValue: baustelle)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Allgemein") {
                    TextField("Baustellenname", text: $baustelle.name)
                    TextField("Ort", text: $baustelle.ort)
                    TextField("Kunde", text: $baustelle.kunde)
                }

                Section("Notiz") {
                    TextEditor(text: $baustelle.notiz)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle("Baustelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        baustelle.notiz = SpeechTextFormatter.format(baustelle.notiz)
                        onSave(baustelle)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Eintrag bearbeiten

struct EintragBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var speechManager: SpeechManager

    @State private var eintrag: BaustellenEintrag
    let onSave: (BaustellenEintrag) -> Void

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var speechBaseText: String = ""

    init(
        speechManager: SpeechManager,
        eintrag: BaustellenEintrag,
        onSave: @escaping (BaustellenEintrag) -> Void
    ) {
        self.speechManager = speechManager
        self._eintrag = State(initialValue: eintrag)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Allgemein") {
                    TextField("Titel", text: $eintrag.titel)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notiz")
                            .font(.subheadline.weight(.semibold))

                        TextEditor(text: $eintrag.notiz)
                            .frame(minHeight: 140)

                        if speechManager.isRecording {
                            Button {
                                let finalText = speechManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !finalText.isEmpty {
                                    eintrag.notiz = SpeechTextFormatter.append(
                                        existing: speechBaseText,
                                        newText: finalText
                                    )
                                } else {
                                    eintrag.notiz = speechBaseText
                                }

                                speechManager.stopRecording()
                                speechManager.recognizedText = ""
                                speechBaseText = eintrag.notiz
                            } label: {
                                Label("Stopp", systemImage: "stop.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        } else {
                            Button {
                                speechBaseText = eintrag.notiz.trimmingCharacters(in: .whitespacesAndNewlines)

                                speechManager.startRecording { text in
                                    let combined = SpeechTextFormatter.append(
                                        existing: speechBaseText,
                                        newText: text
                                    )
                                    if !combined.isEmpty {
                                        eintrag.notiz = combined
                                    }
                                }
                            } label: {
                                Label("Spracheingabe starten", systemImage: "mic.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.bauPilotBlue)
                        }

                        if let errorMessage = speechManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section("Details") {
                    Picker("Kategorie", selection: $eintrag.kategorie) {
                        ForEach(BaustellenKategorie.allCases) { kategorie in
                            Text(kategorie.rawValue).tag(kategorie)
                        }
                    }

                    Picker("Status", selection: $eintrag.status) {
                        ForEach(BaustellenStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    Picker("Priorität", selection: $eintrag.prioritaet) {
                        ForEach(Prioritaet.allCases) { prioritaet in
                            Text(prioritaet.rawValue).tag(prioritaet)
                        }
                    }

                    DatePicker("Datum", selection: $eintrag.datum, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Fotos") {
                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Label("Fotos auswählen", systemImage: "photo.on.rectangle")
                    }

                    if !eintrag.bilder.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(eintrag.bilder.enumerated()), id: \.offset) { index, data in
                                    if let uiImage = UIImage(data: data) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 110, height: 110)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))

                                            Button {
                                                eintrag.bilder.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white, .red)
                                            }
                                            .offset(x: 6, y: -6)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Eintrag")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                speechManager.requestPermissions()
                speechBaseText = eintrag.notiz.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        speechManager.stopRecording()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        let finalText = speechManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if speechManager.isRecording, !finalText.isEmpty {
                            eintrag.notiz = SpeechTextFormatter.append(
                                existing: speechBaseText,
                                newText: finalText
                            )
                        } else {
                            eintrag.notiz = SpeechTextFormatter.format(eintrag.notiz)
                        }

                        speechManager.stopRecording()
                        speechManager.recognizedText = ""
                        onSave(eintrag)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onChange(of: photoItems) { _, neueItems in
                Task {
                    for item in neueItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                eintrag.bilder.append(data)
                            }
                        }
                    }

                    await MainActor.run {
                        photoItems = []
                    }
                }
            }
        }
    }
}

// MARK: - UI Bausteine

struct SuchLeiste: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.bauPilotSecondaryText)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundColor(Color.bauPilotSecondaryText.opacity(0.75))
            )
            .foregroundStyle(Color.bauPilotText)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled(false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.bauPilotCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct FilterChip: View {
    let titel: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(titel)
                .lineLimit(1)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.bauPilotText)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.bauPilotCard)
        .overlay(
            Capsule()
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

struct LeererStatusView: View {
    let icon: String
    let titel: String
    let text: String

    var body: some View {
        Spacer()

        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Color.bauPilotSecondaryText)

            Text(titel)
                .font(.title3.bold())
                .foregroundStyle(Color.bauPilotText)

            Text(text)
                .foregroundStyle(Color.bauPilotSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()

        Spacer()
    }
}

struct BaustellenKarte: View {
    let baustelle: Baustelle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(baustelle.name.isEmpty ? "Ohne Namen" : baustelle.name)
                    .font(.headline)
                    .foregroundStyle(Color.bauPilotText)

                Spacer()

                Text("\(baustelle.eintraege.count) Einträge")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.bauPilotBlue.opacity(0.10))
                    .foregroundStyle(Color.bauPilotBlue)
                    .clipShape(Capsule())
            }

            if !baustelle.ort.isEmpty || !baustelle.kunde.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !baustelle.ort.isEmpty {
                        Label(baustelle.ort, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(Color.bauPilotSecondaryText)
                    }

                    if !baustelle.kunde.isEmpty {
                        Label(baustelle.kunde, systemImage: "person")
                            .font(.subheadline)
                            .foregroundStyle(Color.bauPilotSecondaryText)
                    }
                }
            }

            if !baustelle.notiz.isEmpty {
                Text(baustelle.notiz)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.bauPilotCard)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
        .padding(.vertical, 6)
    }
}

struct ProjektInfoKarte: View {
    let baustelle: Baustelle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(baustelle.name.isEmpty ? "Ohne Namen" : baustelle.name)
                .font(.title3.bold())
                .foregroundStyle(Color.bauPilotText)

            if !baustelle.ort.isEmpty {
                Label(baustelle.ort, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
            }

            if !baustelle.kunde.isEmpty {
                Label(baustelle.kunde, systemImage: "person")
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
            }

            if !baustelle.notiz.isEmpty {
                Divider()

                Text(baustelle.notiz)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bauPilotCard)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
    }
}

struct EintragKarte: View {
    let eintrag: BaustellenEintrag

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Label(eintrag.kategorie.rawValue, systemImage: eintrag.kategorie.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bauPilotBlue)

                Spacer()

                Text(eintrag.status.rawValue)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusFarbe.opacity(0.14))
                    .foregroundStyle(statusFarbe)
                    .clipShape(Capsule())
            }

            Text(eintrag.titel.isEmpty ? "Ohne Titel" : eintrag.titel)
                .font(.headline)
                .foregroundStyle(Color.bauPilotText)

            if !eintrag.notiz.isEmpty {
                Text(eintrag.notiz)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
                    .lineLimit(3)
            }

            if !eintrag.bilder.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(eintrag.bilder.enumerated()), id: \.offset) { _, data in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }

            HStack {
                Text("Priorität: \(eintrag.prioritaet.rawValue)")
                    .foregroundStyle(eintrag.prioritaet.farbe)

                Spacer()

                Text(eintrag.datum.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(Color.bauPilotSecondaryText)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.bauPilotCard)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
        .padding(.vertical, 6)
    }

    private var statusFarbe: Color {
        switch eintrag.status {
        case .offen: return .orange
        case .inBearbeitung: return .blue
        case .erledigt: return .green
        }
    }
}

#Preview {
    ContentView()
}
