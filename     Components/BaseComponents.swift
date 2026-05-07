import SwiftUI


struct SuchLeiste: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.bauPilotBlue.opacity(0.10))
                    .frame(width: 34, height: 34)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.bauPilotBlue)
            }

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundColor(Color.bauPilotSecondaryText.opacity(0.72))
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.bauPilotText)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled(false)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.bauPilotSecondaryText.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bauPilotCard)
                .shadow(color: .black.opacity(0.055), radius: 16, x: 0, y: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.bauPilotStroke.opacity(0.9), lineWidth: 1)
        )
    }
}

struct FilterChip: View {
    let titel: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.bauPilotBlue)

            Text(titel)
                .lineLimit(1)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.bauPilotText)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color.bauPilotStroke.opacity(0.9), lineWidth: 1)
        )
    }
}


struct InfoLimitKarte: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.bauPilotBlue.opacity(0.10))
                    .frame(width: 34, height: 34)

                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.bauPilotBlue)
            }

            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.bauPilotSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bauPilotCard)
                .shadow(color: .black.opacity(0.045), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.bauPilotStroke.opacity(0.9), lineWidth: 1)
        )
    }
}


struct LeererStatusView: View {
    let icon: String
    let titel: String
    let text: String

    var body: some View {
        Spacer()

        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.bauPilotBlue.opacity(0.16), Color.bauPilotBlue.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)

                Image(systemName: icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.bauPilotBlue)
            }

            VStack(spacing: 8) {
                Text(titel)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bauPilotText)
                    .multilineTextAlignment(.center)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34)
                .fill(Color.bauPilotCard)
                .shadow(color: .black.opacity(0.065), radius: 22, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34)
                .stroke(Color.bauPilotStroke.opacity(0.85), lineWidth: 1)
        )
        .padding(.top, 40)

        Spacer()
    }
}


struct LeererBereichKarte: View {
    let icon: String
    let titel: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.bauPilotBlue.opacity(0.10))
                    .frame(width: 54, height: 54)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.bauPilotBlue)
            }

            Text(titel)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.bauPilotText)
                .multilineTextAlignment(.center)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.bauPilotSecondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.bauPilotCard)
                .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.bauPilotStroke.opacity(0.85), lineWidth: 1)
        )
    }
}

struct MiniInfoChip: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))

            Text(text)
                .lineLimit(1)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.bauPilotBlue)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.bauPilotBlue.opacity(0.10))
        )
        .overlay(
            Capsule()
                .stroke(Color.bauPilotBlue.opacity(0.12), lineWidth: 1)
        )
    }
}


struct BaustellenKarte: View {
    let baustelle: Baustelle

    private var fortschritt: Double {
        let gesamt = baustelle.eintraege.count
        guard gesamt > 0 else { return 0.0 }

        let erledigt = baustelle.eintraege.filter { eintrag in
            eintrag.status == .done
        }.count

        return Double(erledigt) / Double(gesamt)
    }

    private var prozentText: String {
        "\(Int(fortschritt * 100))%"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.bauPilotBlue.opacity(0.22),
                                Color.bauPilotBlue.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)

                Image(systemName: "building.2.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.bauPilotBlue)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(baustelle.name.isEmpty ? "common.unnamed".localized("Ohne Namen") : baustelle.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.bauPilotText)
                            .lineLimit(1)

                        if !baustelle.ort.isEmpty {
                            Text(baustelle.ort)
                                .font(.subheadline)
                                .foregroundStyle(Color.bauPilotSecondaryText)
                                .lineLimit(1)
                        }

                        if !baustelle.kunde.isEmpty {
                            Text(baustelle.kunde)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.bauPilotSecondaryText.opacity(0.9))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 6)

                    Text(prozentText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.bauPilotText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 7)

                            Capsule()
                                .fill(Color.bauPilotBlue)
                                .frame(width: max(16, geo.size.width * fortschritt), height: 7)
                        }
                    }
                    .frame(height: 7)

                    HStack(spacing: 8) {
                        Text("\(baustelle.eintraege.count) \("home.site.entries".localized("Einträge"))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.bauPilotBlue)
                            .lineLimit(1)

                        Text("•")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.bauPilotSecondaryText.opacity(0.7))

                        Text("\(baustelle.nachweise.count) \("home.site.proofs".localized("Nachweise"))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.bauPilotSecondaryText)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.075), radius: 18, x: 0, y: 9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.bauPilotStroke.opacity(0.75), lineWidth: 1)
        )
    }
}


struct ProjektInfoKarte: View {
    let baustelle: Baustelle

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(baustelle.name.isEmpty ? "common.unnamed".localized("Ohne Namen") : baustelle.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.bauPilotText)

                    Text("site.project.overview".localized("Projektübersicht"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.bauPilotSecondaryText)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.bauPilotBlue.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "building.2.fill")
                        .foregroundStyle(Color.bauPilotBlue)
                }
            }

            HStack(spacing: 10) {
                DashboardInfoCard(
                    title: "home.site.entries".localized("Einträge"),
                    value: "\(baustelle.eintraege.count)",
                    icon: "list.bullet.rectangle"
                )

                DashboardInfoCard(
                    title: "home.site.proofs".localized("Nachweise"),
                    value: "\(baustelle.nachweise.count)",
                    icon: "doc.text.fill"
                )

                DashboardInfoCard(
                    title: "home.site.materials.short".localized("Aufmaß"),
                    value: "\(baustelle.aufmasse.count)",
                    icon: "shippingbox.fill"
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                if !baustelle.ort.isEmpty {
                    Label(baustelle.ort, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(Color.bauPilotSecondaryText)
                }

                if !baustelle.kunde.isEmpty {
                    Label(baustelle.kunde, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.bauPilotSecondaryText)
                }
            }

            if !baustelle.notiz.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("site.note".localized("Notiz"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.bauPilotText)

                    Text(baustelle.notiz)
                        .font(.subheadline)
                        .foregroundStyle(Color.bauPilotSecondaryText)
                        .lineLimit(4)
                }
                .padding(14)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.white, Color.bauPilotBackground.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.bauPilotStroke.opacity(0.85), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)
    }
}

struct DashboardInfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.bauPilotBlue.opacity(0.10))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundStyle(Color.bauPilotBlue)
            }

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.bauPilotText)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.bauPilotSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.bauPilotStroke.opacity(0.7), lineWidth: 1)
        )
    }
}


struct EintragKarte: View {
    let eintrag: BaustellenEintrag

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bauPilotBlue.opacity(0.11))
                        .frame(width: 46, height: 46)

                    Image(systemName: eintrag.kategorie.symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.bauPilotBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(eintrag.kategorie.localizedName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.bauPilotBlue)

                    Text(eintrag.titel.isEmpty ? "common.untitled".localized("Ohne Titel") : eintrag.titel)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.bauPilotText)
                        .lineLimit(2)
                }

                Spacer()

                Text(eintrag.status.localizedName)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(statusFarbe.opacity(0.14))
                    .foregroundStyle(statusFarbe)
                    .clipShape(Capsule())
            }

            if !eintrag.notiz.isEmpty {
                Text(eintrag.notiz)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
                    .lineLimit(3)
            }

            if !eintrag.bilder.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(eintrag.bilder.enumerated()), id: \.offset) { _, data in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 108, height: 92)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                MiniInfoChip(
                    text: "\("entry.field.priority".localized("Priorität")): \(eintrag.prioritaet.localizedName)",
                    icon: "flag.fill"
                )
                .foregroundStyle(eintrag.prioritaet.farbe)

                Spacer()

                Text(eintrag.datum.formatted(date: .abbreviated, time: .shortened))
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

    private var statusFarbe: Color {
        switch eintrag.status {
        case .open: return .orange
        case .inProgress: return .blue
        case .done: return .green
        }
    }
}

struct NachweisKarte: View {
    let nachweis: NachweisEintrag

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bauPilotBlue.opacity(0.11))
                        .frame(width: 46, height: 46)

                    Image(systemName: nachweis.typ.symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.bauPilotBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(nachweis.typ.localizedName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.bauPilotBlue)

                    Text(nachweis.titel.isEmpty ? "common.untitled".localized("Ohne Titel") : nachweis.titel)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.bauPilotText)
                        .lineLimit(2)
                }

                Spacer()

                Text("proof.title".localized("Nachweis"))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.bauPilotBlue.opacity(0.10))
                    .foregroundStyle(Color.bauPilotBlue)
                    .clipShape(Capsule())
            }

            if !nachweis.notiz.isEmpty {
                Text(nachweis.notiz)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
                    .lineLimit(3)
            }

            if !nachweis.bilder.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(nachweis.bilder.enumerated()), id: \.offset) { _, data in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 108, height: 92)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }

            HStack {
                MiniInfoChip(
                    text: "\(nachweis.bilder.count) \("common.photos".localized("Fotos"))",
                    icon: "photo.fill"
                )

                Spacer()

                Text(nachweis.datum.formatted(date: .abbreviated, time: .shortened))
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
