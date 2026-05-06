import SwiftUI
import PhotosUI
import UIKit
import Foundation
import Combine

struct BaustelleDetailView: View {
    @ObservedObject var speicher: BaustellenSpeicher
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
    @State private var pdfURL: IdentifiableURL?
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
            Color.bauPilotBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ProjektInfoKarte(baustelle: aktuelleBaustelle)

                    SuchLeiste(
                        text: $suche,
                        placeholder: "site.search.placeholder".localized("Einträge suchen...")
                    )

                    InfoLimitKarte(
                        text: AppConfig.isProUser
                        ? "home.limit.pro".localized("BauPilot Pro aktiv: Unbegrenzte Einträge, Nachweise und Aufmaß für diese Baustelle nutzen.")
                        : "home.limit.site.free".localized("Kostenlose Version: bis zu \(AppLimits.maxEintraegeProBaustelle) Einträge, \(AppLimits.maxNachweiseProBaustelle) Nachweise und \(AppLimits.maxAufmasseProBaustelle) Aufmaß / Material pro Baustelle.")
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("site.section.entries".localized("Einträge"))
                            .font(.title3.bold())
                            .foregroundStyle(Color.bauPilotText)

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

                        Button {
                            if aktuelleBaustelle.eintraege.count >= AppLimits.maxEintraegeProBaustelle {
                                limitFehler = .maxEintraegeProBaustelle
                            } else {
                                zeigeNeuenEintrag = true
                            }
                        } label: {
                            Label("site.add.entry".localized("Eintrag hinzufügen"), systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.bauPilotBlue)

                        if gefilterteEintraege.isEmpty {
                            LeererBereichKarte(
                                icon: "tray",
                                titel: "site.empty.entries.title".localized("Noch keine Einträge"),
                                text: "site.empty.entries.subtitle".localized("Lege den ersten Eintrag für diese Baustelle an.")
                            )
                        } else {
                            LazyVStack(spacing: 10) {
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

                    BereichBlock(
                        titel: "site.section.proofs".localized("Nachweise"),
                        buttonTitel: "site.add.proof".localized("Nachweis hinzufügen"),
                        buttonIcon: "doc.badge.plus"
                    ) {
                        if aktuelleBaustelle.nachweise.count >= AppLimits.maxNachweiseProBaustelle {
                            limitFehler = .maxNachweiseProBaustelle
                        } else {
                            zeigeNeuenNachweis = true
                        }
                    } content: {
                        if aktuelleBaustelle.nachweise.isEmpty {
                            LeererBereichKarte(
                                icon: "doc.text",
                                titel: "site.empty.proofs.title".localized("Noch keine Nachweise"),
                                text: "site.empty.proofs.subtitle".localized("Zum Beispiel Druckprüfung, Befüllung oder Inbetriebnahme.")
                            )
                        } else {
                            LazyVStack(spacing: 10) {
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

                    BereichBlock(
                        titel: "site.section.materials".localized("Aufmaß / Material"),
                        buttonTitel: "site.add.material".localized("Aufmaß / Material hinzufügen"),
                        buttonIcon: "shippingbox.fill"
                    ) {
                        if aktuelleBaustelle.aufmasse.count >= AppLimits.maxAufmasseProBaustelle {
                            limitFehler = .maxAufmasseProBaustelle
                        } else {
                            zeigeNeuesAufmass = true
                        }
                    } content: {
                        if aktuelleBaustelle.aufmasse.isEmpty {
                            LeererBereichKarte(
                                icon: "shippingbox",
                                titel: "site.empty.materials.title".localized("Noch kein Aufmaß / Material"),
                                text: "site.empty.materials.subtitle".localized("Einfach halten: Titel, Positionen und optional Foto vom Blatt.")
                            )
                        } else {
                            LazyVStack(spacing: 10) {
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
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(aktuelleBaustelle.name.isEmpty ? "site.title".localized("Baustelle") : aktuelleBaustelle.name)
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
                        Label("site.edit".localized("Baustelle bearbeiten"), systemImage: "pencil")
                    }

                    Button {
                        exportierePDF()
                    } label: {
                        Label("action.export_pdf".localized("PDF exportieren"), systemImage: "doc.richtext")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.bauPilotText)
                }
            }
        }
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
        .sheet(item: $pdfURL) { item in
            ActivityView(items: [item.url])
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
        let baustelleSnapshot = aktuelleBaustelle

        pdfURL = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let url = PDFExportHelper.exportPDF(for: baustelleSnapshot)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard let url else {
                    pdfURL = nil
                    return
                }
                pdfURL = IdentifiableURL(url: url)
            }
        }
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
