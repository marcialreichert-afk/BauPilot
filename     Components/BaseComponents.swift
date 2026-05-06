import SwiftUI


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


struct InfoLimitKarte: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.bauPilotBlue)
                .padding(.top, 1)

            Text(text)
                .font(.footnote)
                .foregroundStyle(Color.bauPilotSecondaryText)

            Spacer()
        }
        .padding(12)
        .background(Color.bauPilotCard)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
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


struct LeererBereichKarte: View {
    let icon: String
    let titel: String
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(Color.bauPilotSecondaryText)

            Text(titel)
                .font(.headline)
                .foregroundStyle(Color.bauPilotText)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.bauPilotSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.bauPilotCard)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.bauPilotStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct MiniInfoChip: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.bauPilotBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.bauPilotBlue.opacity(0.10))
        .clipShape(Capsule())
    }
}


struct BaustellenKarte: View {
    let baustelle: Baustelle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(baustelle.name.isEmpty ? "common.unnamed".localized("Ohne Namen") : baustelle.name)
                    .font(.headline)
                    .foregroundStyle(Color.bauPilotText)

                Spacer()

                Text("\(baustelle.eintraege.count) \("home.site.entries".localized("Einträge"))")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.bauPilotBlue.opacity(0.10))
                    .foregroundStyle(Color.bauPilotBlue)
                    .clipShape(Capsule())
            }

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

            HStack(spacing: 8) {
                MiniInfoChip(text: "\(baustelle.nachweise.count) \("home.site.proofs".localized("Nachweise"))", icon: "doc.text")
                MiniInfoChip(text: "\(baustelle.aufmasse.count) \("home.site.materials.short".localized("Aufmaß"))", icon: "shippingbox")
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
            Text(baustelle.name.isEmpty ? "common.unnamed".localized("Ohne Namen") : baustelle.name)
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

            HStack(spacing: 8) {
                MiniInfoChip(text: "\(baustelle.eintraege.count) \("home.site.entries".localized("Einträge"))", icon: "list.bullet.rectangle")
                MiniInfoChip(text: "\(baustelle.nachweise.count) \("home.site.proofs".localized("Nachweise"))", icon: "doc.text")
                MiniInfoChip(text: "\(baustelle.aufmasse.count) \("home.site.materials.short".localized("Aufmaß"))", icon: "shippingbox")
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
                Label(eintrag.kategorie.localizedName, systemImage: eintrag.kategorie.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bauPilotBlue)

                Spacer()

                Text(eintrag.status.localizedName)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusFarbe.opacity(0.14))
                    .foregroundStyle(statusFarbe)
                    .clipShape(Capsule())
            }

            Text(eintrag.titel.isEmpty ? "common.untitled".localized("Ohne Titel") : eintrag.titel)
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
                Text("\("entry.field.priority".localized("Priorität")): \(eintrag.prioritaet.localizedName)")
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(nachweis.typ.localizedName, systemImage: nachweis.typ.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bauPilotBlue)

                Spacer()
            }

            Text(nachweis.titel.isEmpty ? "common.untitled".localized("Ohne Titel") : nachweis.titel)
                .font(.headline)
                .foregroundStyle(Color.bauPilotText)

            if !nachweis.notiz.isEmpty {
                Text(nachweis.notiz)
                    .font(.subheadline)
                    .foregroundStyle(Color.bauPilotSecondaryText)
                    .lineLimit(3)
            }

            if !nachweis.bilder.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(nachweis.bilder.enumerated()), id: \.offset) { _, data in
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

            Text(nachweis.datum.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(Color.bauPilotSecondaryText)
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
