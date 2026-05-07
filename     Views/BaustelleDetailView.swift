import SwiftUI
import PhotosUI
import UIKit
import Foundation
import Combine

struct BaustelleDetailView: View {
    @ObservedObject var speicher: BaustellenSpeicher
    @Environment(\.dismiss) private var dismiss
    let baustelle: Baustelle

    @StateObject private var speechManager = SpeechManager()

    @State private var suche = ""
    @State private var filterStatus: BaustellenStatus? = nil
    @State private var filterKategorie: BaustellenKategorie? = nil
    @State private var sortierung: Sortierung = .newestFirst

    @State private var zeigeNeuenEintrag = false
    @State private var bearbeiteterEintrag: BaustellenEintrag?

    @State private var zeigeNeuenNachweis = false
    @State private var bearbeiteterNachweis: NachweisEintrag?

    @State private var zeigeNeuesAufmass = false
    @State private var bearbeitetesAufmass: AufmassMaterialEintrag?

    @State private var zeigeBaustellenBearbeiten = false
    @State private var pdfURL: URL?
    @State private var zeigeShareSheet = false
    @State private var pdfFehler = false
    @State private var limitFehler: LimitFehler?

    private var aktuelleBaustelle: Baustelle {
        speicher.baustellen.first(where: { $0.id == baustelle.id }) ?? baustelle
    }

    private var gefilterteEintraege: [BaustellenEintrag] {
        var result = aktuelleBaustelle.eintraege.filter { eintrag in
            let passtSuche = suche.isEmpty ||
            eintrag.titel.localizedCaseInsensitiveContains(suche) ||
            eintrag.notiz.localizedCaseInsensitiveContains(suche)

            let passtStatus = filterStatus == nil || eintrag.status == filterStatus
            let passtKategorie = filterKategorie == nil || eintrag.kategorie == filterKategorie

            return passtSuche && passtStatus && passtKategorie
        }

        switch sortierung {
        case .newestFirst:
            result.sort { $0.datum > $1.datum }
        case .oldestFirst:
            result.sort { $0.datum < $1.datum }
        case .priorityHighFirst:
            result.sort { $0.prioritaet.sortierWert < $1.prioritaet.sortierWert }
        case .priorityLowFirst:
            result.sort { $0.prioritaet.sortierWert > $1.prioritaet.sortierWert }
        case .statusFirst:
            result.sort { $0.status.localizedName < $1.status.localizedName }
        case .titleAZ:
            result.sort { $0.titel.localizedCaseInsensitiveCompare($1.titel) == .orderedAscending }
        }

        return result
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.bauPilotBackground, Color.bauPilotBlue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    BaustelleDetailHero(
                        baustelle: aktuelleBaustelle,
                        backAction: { dismiss() },
                        editAction: { zeigeBaustellenBearbeiten = true },
                        pdfAction: { exportierePDF() }
                    )

                    Button {
                        print("PDF Export Button unter Hero getippt")
                        exportierePDF()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 17, weight: .bold))

                            Text("action.export_pdf".localized("PDF exportieren"))
                                .font(.subheadline.weight(.bold))

                            Spacer()

                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(Color.bauPilotBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.bauPilotBlue.opacity(0.22), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)

                    BaustelleOverviewStats(
                        eintraege: aktuelleBaustelle.eintraege.count,
                        nachweise: aktuelleBaustelle.nachweise.count,
                        aufmass: aktuelleBaustelle.aufmasse.count,
                        maengel: 0
                    )

                    SuchLeiste(
                        text: $suche,
                        placeholder: "site.search.placeholder".localized("Einträge suchen...")
                    )

                    if !AppConfig.isProUser {
                        InfoLimitKarte(
                            text: "home.limit.site.free".localized("Kostenlose Version: bis zu \(AppLimits.maxEintraegeProBaustelle) Einträge, \(AppLimits.maxNachweiseProBaustelle) Nachweise und \(AppLimits.maxAufmasseProBaustelle) Aufmaß / Material pro Baustelle.")
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("site.section.entries".localized("Einträge"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.bauPilotText)

                            Spacer()

                            Button {
                                if aktuelleBaustelle.eintraege.count >= AppLimits.maxEintraegeProBaustelle {
                                    limitFehler = .maxEintraegeProBaustelle
                                } else {
                                    zeigeNeuenEintrag = true
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color.bauPilotBlue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.bauPilotBlue.opacity(0.22), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                Menu {
                                    Button("filter.all_status".localized("Alle Status")) { filterStatus = nil }
                                    ForEach(BaustellenStatus.allCases) { status in
                                        Button(status.localizedName) { filterStatus = status }
                                    }
                                } label: {
                                    FilterChip(
                                        titel: filterStatus?.localizedName ?? "filter.status".localized("Status"),
                                        icon: "line.3.horizontal.decrease.circle"
                                    )
                                }

                                Menu {
                                    Button("filter.all_categories".localized("Alle Kategorien")) { filterKategorie = nil }
                                    ForEach(BaustellenKategorie.allCases) { kategorie in
                                        Button(kategorie.localizedName) { filterKategorie = kategorie }
                                    }
                                } label: {
                                    FilterChip(
                                        titel: filterKategorie?.localizedName ?? "filter.category".localized("Kategorie"),
                                        icon: "square.grid.2x2"
                                    )
                                }

                                Menu {
                                    ForEach(Sortierung.allCases) { option in
                                        Button(option.localizedName) { sortierung = option }
                                    }
                                } label: {
                                    FilterChip(
                                        titel: sortierung.localizedName,
                                        icon: "arrow.up.arrow.down"
                                    )
                                }

                                if filterStatus != nil || filterKategorie != nil || !suche.isEmpty {
                                    Button("filter.reset".localized("Zurücksetzen")) {
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
                            LeererBereichKarte(
                                icon: "tray",
                                titel: "site.empty.entries.title".localized("Noch keine Einträge"),
                                text: "site.empty.entries.subtitle".localized("Lege den ersten Eintrag für diese Baustelle an.")
                            )
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(gefilterteEintraege) { eintrag in
                                    Button {
                                        bearbeiteterEintrag = eintrag
                                    } label: {
                                        EintragKarte(eintrag: eintrag)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            speicher.deleteEintrag(eintrag, from: aktuelleBaustelle.id)
                                        } label: {
                                            Label("entry.delete".localized("Eintrag löschen"), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("site.section.proofs".localized("Nachweise"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.bauPilotText)

                            Spacer()

                            Button {
                                if aktuelleBaustelle.nachweise.count >= AppLimits.maxNachweiseProBaustelle {
                                    limitFehler = .maxNachweiseProBaustelle
                                } else {
                                    zeigeNeuenNachweis = true
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color.bauPilotBlue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.bauPilotBlue.opacity(0.22), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        if aktuelleBaustelle.nachweise.isEmpty {
                            LeererBereichKarte(
                                icon: "doc.text",
                                titel: "site.empty.proofs.title".localized("Noch keine Nachweise"),
                                text: "site.empty.proofs.subtitle".localized("Zum Beispiel Druckprüfung, Befüllung oder Inbetriebnahme.")
                            )
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(aktuelleBaustelle.nachweise) { nachweis in
                                    Button {
                                        bearbeiteterNachweis = nachweis
                                    } label: {
                                        NachweisKarte(nachweis: nachweis)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            speicher.deleteNachweis(nachweis, from: aktuelleBaustelle.id)
                                        } label: {
                                            Label("proof.delete".localized("Nachweis löschen"), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("site.section.materials".localized("Aufmaß / Material"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.bauPilotText)

                            Spacer()

                            Button {
                                if aktuelleBaustelle.aufmasse.count >= AppLimits.maxAufmasseProBaustelle {
                                    limitFehler = .maxAufmasseProBaustelle
                                } else {
                                    zeigeNeuesAufmass = true
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color.bauPilotBlue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.bauPilotBlue.opacity(0.22), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        if aktuelleBaustelle.aufmasse.isEmpty {
                            LeererBereichKarte(
                                icon: "shippingbox",
                                titel: "site.empty.materials.title".localized("Noch kein Aufmaß / Material"),
                                text: "site.empty.materials.subtitle".localized("Einfach halten: Titel, Positionen und optional Foto vom Blatt.")
                            )
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(aktuelleBaustelle.aufmasse) { aufmass in
                                    Button {
                                        bearbeitetesAufmass = aufmass
                                    } label: {
                                        AufmassKarte(aufmass: aufmass)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            speicher.deleteAufmass(aufmass, from: aktuelleBaustelle.id)
                                        } label: {
                                            Label("material.delete".localized("Aufmaß / Material löschen"), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $zeigeNeuenEintrag) {
            EintragBearbeitenView(
                speechManager: speechManager,
                eintrag: BaustellenEintrag()
            ) { neuerEintrag in
                if let fehler = speicher.addEintrag(neuerEintrag, to: aktuelleBaustelle.id) {
                    limitFehler = fehler
                }
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
        .sheet(isPresented: $zeigeNeuenNachweis) {
            NachweisBearbeitenView(nachweis: NachweisEintrag()) { neuerNachweis in
                if let fehler = speicher.addNachweis(neuerNachweis, to: aktuelleBaustelle.id) {
                    limitFehler = fehler
                }
            }
        }
        .sheet(item: $bearbeiteterNachweis) { nachweis in
            NachweisBearbeitenView(nachweis: nachweis) { geaenderterNachweis in
                speicher.updateNachweis(geaenderterNachweis, in: aktuelleBaustelle.id)
            }
        }
        .sheet(isPresented: $zeigeNeuesAufmass) {
            AufmassBearbeitenView(aufmass: AufmassMaterialEintrag()) { neuesAufmass in
                if let fehler = speicher.addAufmass(neuesAufmass, to: aktuelleBaustelle.id) {
                    limitFehler = fehler
                }
            }
        }
        .sheet(item: $bearbeitetesAufmass) { aufmass in
            AufmassBearbeitenView(aufmass: aufmass) { geaendertesAufmass in
                speicher.updateAufmass(geaendertesAufmass, in: aktuelleBaustelle.id)
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
        .alert("pdf.error.title".localized("PDF konnte nicht erstellt werden"), isPresented: $pdfFehler) {
            Button("nav.ok".localized("OK"), role: .cancel) { }
        } message: {
            Text("pdf.error.message".localized("Bitte versuche es erneut oder prüfe, ob die Baustelle Inhalte enthält."))
        }
        .alert("common.notice".localized("Hinweis"), isPresented: Binding(
            get: { limitFehler != nil },
            set: { if !$0 { limitFehler = nil } }
        )) {
            Button("nav.ok".localized("OK"), role: .cancel) { limitFehler = nil }
        } message: {
            Text(limitFehler?.errorDescription ?? "")
        }
    }

    private func exportierePDF() {
        print("PDF Button gedrückt")

        guard let url = PDFExportHelper.exportPDF(for: aktuelleBaustelle) else {
            print("PDF konnte nicht erstellt werden")
            pdfFehler = true
            return
        }

        print("PDF erstellt: \(url)")
        pdfURL = url

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            zeigeShareSheet = true
        }
    }
}

struct BaustelleDetailHero: View {
    let baustelle: Baustelle
    let backAction: () -> Void
    let editAction: () -> Void
    let pdfAction: () -> Void

    private var erledigtCount: Int {
        baustelle.eintraege.filter { $0.status == .done }.count
    }

    private var progress: Double {
        guard !baustelle.eintraege.isEmpty else { return 0 }
        return Double(erledigtCount) / Double(baustelle.eintraege.count)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.bauPilotText)
                        .frame(width: 42, height: 42)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text("site.title".localized("Baustelle"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.bauPilotBlue)

                    Text(baustelle.name.isEmpty ? "common.unnamed".localized("Ohne Namen") : baustelle.name)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(Color.bauPilotText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Color.clear
                    .frame(width: 42, height: 42)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        if !baustelle.ort.isEmpty {
                            Label(baustelle.ort, systemImage: "mappin.and.ellipse")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.88))
                        }

                        if !baustelle.kunde.isEmpty {
                            Label(baustelle.kunde, systemImage: "person.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.88))
                        }

                        Text("site.progress.title".localized("Projektfortschritt"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.top, 4)
                    }

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.22))
                            .frame(height: 8)

                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(18, geo.size.width * progress), height: 8)
                    }
                }
                .frame(height: 8)

                HStack(spacing: 10) {
                    DetailHeroStat(title: "home.site.entries".localized("Einträge"), value: "\(baustelle.eintraege.count)", icon: "doc.text.fill")

                    DetailHeroStat(title: "home.site.proofs".localized("Nachweise"), value: "\(baustelle.nachweise.count)", icon: "checklist")

                    DetailHeroStat(title: "home.site.materials.short".localized("Aufmaß"), value: "\(baustelle.aufmasse.count)", icon: "shippingbox.fill")
                }
            }
            .padding(20)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color.bauPilotBlue, Color(red: 0.04, green: 0.24, blue: 0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(Color.white.opacity(0.13))
                        .frame(width: 180, height: 180)
                        .offset(x: 125, y: -70)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 92, weight: .bold))
                        .foregroundStyle(.white.opacity(0.14))
                        .offset(x: 112, y: 55)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.bauPilotBlue.opacity(0.22), radius: 22, x: 0, y: 12)
        }
    }
}

struct DetailHeroStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

struct BaustelleOverviewStats: View {
    let eintraege: Int
    let nachweise: Int
    let aufmass: Int
    let maengel: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                DetailStatCard(
                    icon: "doc.text.fill",
                    title: "site.section.entries".localized("Einträge"),
                    value: "\(eintraege)",
                    iconColor: Color.bauPilotBlue
                )

                DetailStatCard(
                    icon: "checkmark.shield.fill",
                    title: "site.section.proofs".localized("Nachweise"),
                    value: "\(nachweise)",
                    iconColor: .green
                )

                DetailStatCard(
                    icon: "shippingbox.fill",
                    title: "home.site.materials.short".localized("Aufmaß"),
                    value: "\(aufmass)",
                    iconColor: .orange
                )

                DetailStatCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "defects.title.short".localized("Mängel"),
                    value: "\(maengel)",
                    iconColor: .red
                )
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

struct DetailStatCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 38, height: 38)
                .background(iconColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 13))

            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.bauPilotText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.bauPilotText)
            }
        }
        .frame(width: 92, height: 106)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.bauPilotStroke.opacity(0.7), lineWidth: 1)
        )
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
