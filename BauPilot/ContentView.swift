
import SwiftUI
import PhotosUI
import UIKit
import CoreText
import Foundation
import Combine
import StoreKit

enum HomeBottomTab: String {
    case overview
    case sites
    case proofs
    case materials
}







// MARK: - Main View

struct ContentView: View {
    @StateObject private var speicher = BaustellenSpeicher()
    @StateObject private var store = StoreKitManager.shared
    @State private var suche = ""
    @State private var zeigeNeueBaustelle = false
    @State private var limitFehler: LimitFehler?
    @State private var zeigeBewertungsBanner = false
    @State private var showPaywall = false
    @State private var selectedBottomTab: HomeBottomTab = .overview

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
                LinearGradient(
                    colors: [Color.white, Color.bauPilotBackground, Color.bauPilotBlue.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    HomeHeroHeader(
                        isPro: store.isPro,
                        siteCount: speicher.baustellen.count,
                        maxSites: AppLimits.maxBaustellen,
                        proAction: { showPaywall = true }
                    )
                    SuchLeiste(
                        text: $suche,
                        placeholder: "home.search.placeholder".localized("Baustellen suchen...")
                    )

                    if store.isPro {
                        InfoLimitKarte(
                            text: "home.limit.pro".localized("BauPilot Pro aktiv: Unbegrenzte Baustellen, Einträge, Nachweise und Aufmaß nutzen.")
                        )
                    }

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
                        ProUpgradeCard(
                            isLoading: store.isLoading,
                            upgradeAction: { showPaywall = true },
                            restoreAction: {
                                Task {
                                    await store.restorePurchases()
                                }
                            }
                        )
                    }

                    if selectedBottomTab == .proofs {
                        GlobalNachweiseView(baustellen: speicher.baustellen)

                    } else if selectedBottomTab == .materials {
                        GlobalAufmassView(baustellen: speicher.baustellen)

                    } else if gefilterteBaustellen.isEmpty {
                        LeererStatusView(
                            icon: "building.2.crop.circle",
                            titel: "home.empty.title".localized("Noch keine Baustellen"),
                            text: "home.empty.subtitle".localized("Lege deine erste Baustelle an.")
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("home.title.projects".localized("Baustellen"))
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.bauPilotText)
                                }

                                Spacer()

                                Button {
                                    if speicher.baustellen.count >= AppLimits.maxBaustellen && !store.isPro {
                                        limitFehler = .maxBaustellen
                                    } else {
                                        zeigeNeueBaustelle = true
                                    }
                                } label: {
                                    HStack(spacing: 7) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))

                                        Text("site.new.short".localized("Neu"))
                                            .font(.subheadline.weight(.bold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 11)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.bauPilotBlue, Color.bauPilotBlue.opacity(0.78)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.bauPilotBlue.opacity(0.24), radius: 12, x: 0, y: 6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 4)

                            ScrollView {
                                LazyVStack(spacing: 14) {
                                ForEach(gefilterteBaustellen) { baustelle in
                                    ZStack(alignment: .topTrailing) {
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

                                        Button(role: .destructive) {
                                            speicher.deleteBaustelle(baustelle)
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(.red)
                                                .frame(width: 34, height: 34)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.top, 12)
                                        .padding(.trailing, 12)
                                    }
                                }
                            }
                                .padding(.bottom, 10)
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 92)
                VStack {
                    Spacer()
                    BauPilotBottomBar(
                        selectedTab: selectedBottomTab,
                        overviewAction: { selectedBottomTab = .overview },
                        sitesAction: { selectedBottomTab = .sites },
                        addAction: {
                            if speicher.baustellen.count >= AppLimits.maxBaustellen && !store.isPro {
                                limitFehler = .maxBaustellen
                            } else {
                                zeigeNeueBaustelle = true
                            }
                        },
                        proofsAction: { selectedBottomTab = .proofs },
                        materialsAction: { selectedBottomTab = .materials }
                    )
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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


struct BauPilotBottomBar: View {
    let selectedTab: HomeBottomTab
    let overviewAction: () -> Void
    let sitesAction: () -> Void
    let addAction: () -> Void
    let proofsAction: () -> Void
    let materialsAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            BottomBarItem(
                icon: "house.fill",
                title: "bottom.overview".localized("Überblick"),
                isActive: selectedTab == .overview,
                action: overviewAction
            )

            BottomBarItem(
                icon: "building.2",
                title: "bottom.sites".localized("Baustellen"),
                isActive: selectedTab == .sites,
                action: sitesAction
            )

            Button(action: addAction) {
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(
                        LinearGradient(
                            colors: [Color.bauPilotBlue, Color.bauPilotBlue.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.bauPilotBlue.opacity(0.36), radius: 18, x: 0, y: 9)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .offset(y: -18)

            BottomBarItem(
                icon: "doc.text",
                title: "bottom.proofs".localized("Nachweise"),
                isActive: selectedTab == .proofs,
                action: proofsAction
            )

            BottomBarItem(
                icon: "square.and.pencil",
                title: "bottom.materials".localized("Aufmaß"),
                isActive: selectedTab == .materials,
                action: materialsAction
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(height: 82)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.96))
                .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.bauPilotStroke.opacity(0.8), lineWidth: 1)
        )
    }
}

struct BottomBarItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isActive ? Color.bauPilotBlue : Color.bauPilotSecondaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct GlobalNachweiseView: View {
    let baustellen: [Baustelle]

    private var alleNachweise: [(Baustelle, NachweisEintrag)] {
        baustellen.flatMap { baustelle in
            baustelle.nachweise.map { (baustelle, $0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("bottom.proofs".localized("Nachweise"))
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.bauPilotText)

            if alleNachweise.isEmpty {
                LeererStatusView(
                    icon: "doc.text.magnifyingglass",
                    titel: "proof.empty.title".localized("Keine Nachweise vorhanden"),
                    text: "proof.empty.subtitle".localized("Erstelle Nachweise innerhalb einer Baustelle.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(alleNachweise.enumerated()), id: \.offset) { _, element in
                            let baustelle = element.0
                            let nachweis = element.1

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(nachweis.titel.isEmpty ? "Nachweis" : nachweis.titel)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.bauPilotText)

                                    Spacer()

                                    MiniInfoChip(
                                        text: baustelle.name,
                                        icon: "building.2.fill"
                                    )
                                }

                                if !nachweis.notiz.isEmpty {
                                    Text(nachweis.notiz)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.bauPilotSecondaryText)
                                        .lineLimit(3)
                                }
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 26)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
                            )
                        }
                    }
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct GlobalAufmassView: View {
    let baustellen: [Baustelle]

    private var alleAufmasse: [(Baustelle, AufmassMaterialEintrag)] {
        baustellen.flatMap { baustelle in
            baustelle.aufmasse.map { (baustelle, $0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("bottom.materials".localized("Aufmaß"))
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.bauPilotText)

            if alleAufmasse.isEmpty {
                LeererStatusView(
                    icon: "shippingbox",
                    titel: "material.empty.global.title".localized("Kein Aufmaß vorhanden"),
                    text: "material.empty.global.subtitle".localized("Erstelle Aufmaß-Einträge innerhalb einer Baustelle.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(alleAufmasse.enumerated()), id: \.offset) { _, element in
                            let baustelle = element.0
                            let aufmass = element.1

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(aufmass.titel.isEmpty ? "Aufmaß" : aufmass.titel)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.bauPilotText)

                                    Spacer()

                                    MiniInfoChip(
                                        text: baustelle.name,
                                        icon: "building.2.fill"
                                    )
                                }

                                Text(aufmass.gesamtMengeAnzeige)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.bauPilotBlue)

                                if !aufmass.notiz.isEmpty {
                                    Text(aufmass.notiz)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.bauPilotSecondaryText)
                                        .lineLimit(3)
                                }
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 26)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
                            )
                        }
                    }
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct HomeHeroHeader: View {
    let isPro: Bool
    let siteCount: Int
    let maxSites: Int
    let proAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button {
                    // später: Menü / Einstellungen
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.bauPilotText)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 0) {
                    Text("Bau")
                        .foregroundStyle(Color.bauPilotBlue)
                    Text("Pilot")
                        .foregroundStyle(Color.bauPilotText)
                }
                .font(.system(size: 24, weight: .black, design: .rounded))

                Spacer()

                Color.clear
                    .frame(width: 42, height: 42)
            }
            .padding(.horizontal, 4)

            ZStack(alignment: .trailing) {
                LinearGradient(
                    colors: [Color.bauPilotBlue, Color(red: 0.04, green: 0.24, blue: 0.68)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.13))
                    .frame(width: 190, height: 190)
                    .offset(x: 80, y: -60)

                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 230, height: 155)
                    .rotationEffect(.degrees(-16))
                    .offset(x: 96, y: 42)

                Image(systemName: "building.2.fill")
                    .font(.system(size: 86, weight: .bold))
                    .foregroundStyle(.white.opacity(0.16))
                    .offset(x: 20, y: 18)

                VStack(alignment: .leading, spacing: 10) {
                    Text("home.hero.greeting".localized("Guten Morgen,"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))

                    Text("home.hero.name".localized("BauPilot Nutzer"))
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("home.hero.ready".localized("Bereit für einen erfolgreichen Baustellentag."))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 172)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.bauPilotBlue.opacity(0.25), radius: 22, x: 0, y: 12)
        }
    }
}

struct HomeStatPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.76))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

struct ProUpgradeCard: View {
    let isLoading: Bool
    let upgradeAction: () -> Void
    let restoreAction: () -> Void

    var body: some View {
        Button(action: upgradeAction) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.bauPilotBlue)
                    .frame(width: 30, height: 30)
                    .background(Color.bauPilotBlue.opacity(0.10))
                    .clipShape(Circle())

                Text("paywall.cta.compact".localized("Pro freischalten"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.bauPilotText)
                    .lineLimit(1)

                Spacer()

                Text("paywall.upgrade.short".localized("Upgrade"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.bauPilotBlue)
                    .clipShape(Capsule())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.bauPilotStroke.opacity(0.9), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct BewertungsBanner: View {
    let bewertenAction: () -> Void
    let spaeterAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.bauPilotBlue.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "star.bubble.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color.bauPilotBlue)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("rating.banner.title".localized("Gefällt dir BauPilot?"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.bauPilotText)

                    Text("rating.banner.text".localized("Hilf uns mit einer kurzen Bewertung im App Store."))
                        .font(.subheadline)
                        .foregroundStyle(Color.bauPilotSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button {
                    bewertenAction()
                } label: {
                    Text("rating.banner.rate".localized("Bewertung abgeben"))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.bauPilotBlue)

                Button {
                    spaeterAction()
                } label: {
                    Text("rating.banner.later".localized("Später"))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(Color.bauPilotBlue)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.bauPilotCard)
                .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.bauPilotStroke.opacity(0.9), lineWidth: 1)
        )
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(titel)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.bauPilotText)

                Spacer()
            }

            Button(action: action) {
                Label(buttonTitel, systemImage: buttonIcon)
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.bauPilotBlue)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.bauPilotCard)
                .shadow(color: .black.opacity(0.055), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.bauPilotStroke.opacity(0.85), lineWidth: 1)
        )
    }
}




struct AufmassKarte: View {
    let aufmass: AufmassMaterialEintrag

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bauPilotBlue.opacity(0.11))
                        .frame(width: 46, height: 46)

                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.bauPilotBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("material.title".localized("Aufmaß / Material"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.bauPilotBlue)

                    Text(aufmass.titel.isEmpty ? "material.empty.title".localized("Ohne Bezeichnung") : aufmass.titel)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.bauPilotText)
                        .lineLimit(2)
                }

                Spacer()

                MiniInfoChip(
                    text: "\(aufmass.positionen.count) \("material.positions.short".localized("Positionen"))",
                    icon: "list.bullet"
                )
            }

            if !aufmass.positionen.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(aufmass.positionen.prefix(3)) { position in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.bauPilotBlue.opacity(0.22))
                                .frame(width: 7, height: 7)
                                .padding(.top, 7)

                            Text(position.bezeichnung.isEmpty ? "-" : position.bezeichnung)
                                .font(.subheadline)
                                .foregroundStyle(Color.bauPilotSecondaryText)
                                .lineLimit(1)

                            Spacer()
                        }
                    }

                    if aufmass.positionen.count > 3 {
                        Text("+ \(aufmass.positionen.count - 3) \("material.positions.more".localized("weitere"))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.bauPilotBlue)
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
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                    )
            }

            HStack {
                MiniInfoChip(text: aufmass.gesamtMengeAnzeige, icon: "number")

                Spacer()

                Text(aufmass.datum.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.bauPilotSecondaryText)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.bauPilotCard)
                .shadow(color: .black.opacity(0.065), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.bauPilotStroke.opacity(0.9), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
