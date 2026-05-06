import SwiftUI
import PhotosUI
import UIKit
import CoreText
import Foundation
import Combine
import StoreKit







// MARK: - Main View

struct ContentView: View {
    @StateObject private var speicher = BaustellenSpeicher()
    @StateObject private var store = StoreKitManager.shared
    @State private var suche = ""
    @State private var zeigeNeueBaustelle = false
    @State private var limitFehler: LimitFehler?
    @State private var zeigeBewertungsBanner = false
    @State private var showPaywall = false

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
                    SuchLeiste(
                        text: $suche,
                        placeholder: "home.search.placeholder".localized("Baustellen suchen...")
                    )

                    InfoLimitKarte(
                        text: store.isPro
                        ? "home.limit.pro".localized("BauPilot Pro aktiv: Unbegrenzte Baustellen, Einträge, Nachweise und Aufmaß nutzen.")
                        : "home.limit.site.free".localized("Kostenlose Version: bis zu \(AppLimits.maxBaustellen) Baustellen, \(AppLimits.maxEintraegeProBaustelle) Einträge pro Baustelle, \(AppLimits.maxNachweiseProBaustelle) Nachweise pro Baustelle und \(AppLimits.maxAufmasseProBaustelle) Aufmaß / Material pro Baustelle.")
                    )

                    if zeigeBewertungsBanner {
                        BewertungsBanner(
                            bewertenAction: {
                                requestAppStoreReview()
                                zeigeBewertungsBanner = false
                                UserDefaults.standard.set(true, forKey: "baupilot.ratingBannerDone")
                            },
                            spaeterAction: {
                                zeigeBewertungsBanner = false
                                UserDefaults.standard.set(Date(), forKey: "baupilot.ratingBannerLaterDate")
                            }
                        )
                    }

                    if !store.isPro {
                        VStack(spacing: 10) {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    if store.isLoading {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "crown.fill")
                                    }

                                    Text("paywall.cta.home".localized("BauPilot Pro freischalten"))
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.white)
                                .background(Color.bauPilotBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(store.isLoading)

                            Button("paywall.restore.short".localized("Käufe wiederherstellen")) {
                                Task {
                                    await store.restorePurchases()
                                }
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.bauPilotBlue)
                        }
                    }

                    if gefilterteBaustellen.isEmpty {
                        LeererStatusView(
                            icon: "building.2.crop.circle",
                            titel: "home.empty.title".localized("Noch keine Baustellen"),
                            text: "home.empty.subtitle".localized("Lege deine erste Baustelle an.")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(gefilterteBaustellen) { baustelle in
                                    NavigationLink {
                                        BaustelleDetailView(speicher: speicher, baustelle: baustelle)
                                    } label: {
                                        BaustellenKarte(baustelle: baustelle)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            speicher.deleteBaustelle(baustelle)
                                        } label: {
                                            Label("site.delete".localized("Baustelle löschen"), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .navigationTitle("app.name".localized("BauPilot"))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.bauPilotBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if speicher.baustellen.count >= AppLimits.maxBaustellen {
                            limitFehler = .maxBaustellen
                        } else {
                            zeigeNeueBaustelle = true
                        }
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
                    if let fehler = speicher.addBaustelle(neueBaustelle) {
                        limitFehler = fehler
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("common.notice".localized("Hinweis"), isPresented: Binding(
                get: { limitFehler != nil },
                set: { if !$0 { limitFehler = nil } }
            )) {
                Button("nav.ok".localized("OK"), role: .cancel) { limitFehler = nil }
            } message: {
                Text(limitFehler?.errorDescription ?? "")
            }
            .onAppear {
                AppConfig.clearOldLocalProFlag()
                pruefeBewertungsBanner()
                Task {
                    await store.updatePurchasedStatus()
                }
            }

            .alert("store.alert.title".localized("StoreKit"), isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("nav.ok".localized("OK"), role: .cancel) { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }
    private func pruefeBewertungsBanner() {
        let alreadyDone = UserDefaults.standard.bool(forKey: "baupilot.ratingBannerDone")
        guard !alreadyDone else { return }

        let launchCountKey = "baupilot.launchCount"
        let newLaunchCount = UserDefaults.standard.integer(forKey: launchCountKey) + 1
        UserDefaults.standard.set(newLaunchCount, forKey: launchCountKey)

        if let laterDate = UserDefaults.standard.object(forKey: "baupilot.ratingBannerLaterDate") as? Date {
            let tageSeitSpaeter = Calendar.current.dateComponents([.day], from: laterDate, to: Date()).day ?? 0
            guard tageSeitSpaeter >= 7 else { return }
        }

        zeigeBewertungsBanner = newLaunchCount >= 3
    }

    private func requestAppStoreReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
    }
}


struct BewertungsBanner: View {
    let bewertenAction: () -> Void
    let spaeterAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "star.bubble.fill")
                    .font(.title2)
                    .foregroundStyle(Color.bauPilotBlue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("rating.banner.title".localized("Gefällt dir BauPilot?"))
                        .font(.headline)
                        .foregroundStyle(Color.bauPilotText)

                    Text("rating.banner.text".localized("Hilf uns mit einer kurzen Bewertung im App Store."))
                        .font(.subheadline)
                        .foregroundStyle(Color.bauPilotSecondaryText)
                }
            }

            HStack(spacing: 10) {
                Button {
                    bewertenAction()
                } label: {
                    Text("rating.banner.rate".localized("Bewertung abgeben"))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.bauPilotBlue)

                Button {
                    spaeterAction()
                } label: {
                    Text("rating.banner.later".localized("Später"))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.bauPilotCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}



// MARK: - OCR Row

struct OCRVorschlagRow: View {
    @Binding var vorschlag: OCRAufmassVorschlag

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vorschlag.originalZeile)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(
                "material.field.description".localized("Bezeichnung"),
                text: $vorschlag.bezeichnung
            )

            HStack {
                TextField(
                    "material.field.quantity".localized("Menge"),
                    text: $vorschlag.menge
                )
                .keyboardType(.decimalPad)

                TextField(
                    "material.field.unit".localized("Einheit"),
                    text: $vorschlag.einheit
                )
            }

            TextField(
                "material.field.area".localized("Bereich / Raum"),
                text: $vorschlag.bereich
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - UI Components

struct BereichBlock<Content: View>: View {
    let titel: String
    let buttonTitel: String
    let buttonIcon: String
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titel)
                .font(.title3.bold())
                .foregroundStyle(Color.bauPilotText)

            Button(action: action) {
                Label(buttonTitel, systemImage: buttonIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.bauPilotBlue)

            content
        }
    }
}




struct AufmassKarte: View {
    let aufmass: AufmassMaterialEintrag

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("material.title".localized("Aufmaß / Material"), systemImage: "shippingbox.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bauPilotBlue)

                Spacer()

                MiniInfoChip(
                    text: "\(aufmass.positionen.count) \("material.positions.short".localized("Positionen"))",
                    icon: "list.bullet"
                )
            }

            Text(aufmass.titel.isEmpty ? "material.empty.title".localized("Ohne Bezeichnung") : aufmass.titel)
                .font(.headline)
                .foregroundStyle(Color.bauPilotText)

            HStack {
                MiniInfoChip(text: aufmass.gesamtMengeAnzeige, icon: "number")
                Text(aufmass.datum.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.bauPilotSecondaryText)
            }

            if !aufmass.positionen.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(aufmass.positionen.prefix(3)) { position in
                        Text("• \(position.bezeichnung.isEmpty ? "-" : position.bezeichnung)")
                            .font(.subheadline)
                            .foregroundStyle(Color.bauPilotSecondaryText)
                    }

                    if aufmass.positionen.count > 3 {
                        Text("+ \(aufmass.positionen.count - 3) \("material.positions.more".localized("weitere"))")
                            .font(.caption)
                            .foregroundStyle(Color.bauPilotSecondaryText)
                    }
                }
            }

            if !aufmass.notiz.isEmpty {
                Text(aufmass.notiz)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
                    .lineLimit(3)
            }

            if let data = aufmass.bild, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
    }
}

#Preview {
    ContentView()
}
