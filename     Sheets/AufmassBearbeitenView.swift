import SwiftUI
import PhotosUI
import UIKit
import Foundation

struct AufmassBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var aufmass: AufmassMaterialEintrag
    let onSave: (AufmassMaterialEintrag) -> Void

    @State private var photoItem: PhotosPickerItem?
    @State private var limitFehler: LimitFehler?
    @State private var kiHinweis: String?
    @State private var kiLaedt = false
    @State private var kiAufmassText = ""
    @State private var kiAufmassLaedt = false
    @State private var zeigePaywall = false
    @State private var ocrVorschlaege: [OCRAufmassVorschlag] = []
    @State private var ocrFehlerText: String?
    @State private var zeigeBildFullscreen = false

    init(aufmass: AufmassMaterialEintrag, onSave: @escaping (AufmassMaterialEintrag) -> Void) {
        self._aufmass = State(initialValue: aufmass)
        self.onSave = onSave
    }

    var body: some View {
        let unsichereAnzahl = ocrVorschlaege.count { $0.istUnsicher }
        NavigationStack {
            Form {
                Section("material.title".localized("Aufmaß / Material")) {
                    TextField("material.field.title".localized("Titel"), text: $aufmass.titel)
                    DatePicker(
                        "material.field.date".localized("Datum"),
                        selection: $aufmass.datum,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("material.positions.title".localized("Positionen")) {
                    if aufmass.positionen.isEmpty {
                        Text("material.positions.empty".localized("Noch keine Positionen vorhanden."))
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        TextField(
                            "material.ki.position.placeholder".localized("z. B. 12 m DN20 Rohr verlegt"),
                            text: $kiAufmassText,
                            axis: .vertical
                        )
                        .lineLimit(1...3)

                        Button {
                            let trimmedText = kiAufmassText.trimmingCharacters(in: .whitespacesAndNewlines)

                            guard AppConfig.isProUser else {
                                zeigePaywall = true
                                return
                            }

                            guard KIUsageManager.shared.canUseKIText else {
                                kiHinweis = "ki.text.limit_reached".localized("Monatliches KI-Limit erreicht. Dein Kontingent wird im nächsten Monat zurückgesetzt.")
                                return
                            }

                            guard !trimmedText.isEmpty else {
                                kiHinweis = "material.ki.position.empty".localized("Bitte gib zuerst eine Aufmaß-Position ein.")
                                return
                            }

                            kiAufmassLaedt = true

                            Task {
                                do {
                                    let result = try await KITextService.shared.parseAufmassPosition(trimmedText)

                                    await MainActor.run {
                                        aufmass.positionen.append(
                                            AufmassPosition(
                                                bezeichnung: result.bezeichnung,
                                                menge: result.menge,
                                                einheit: result.einheit,
                                                bereich: "",
                                                notiz: ""
                                            )
                                        )
                                        KIUsageManager.shared.registerKITextAction()
                                        kiAufmassText = ""
                                        kiAufmassLaedt = false
                                        kiHinweis = "material.ki.position.success".localized("KI-Aufmaßposition wurde hinzugefügt.")
                                    }
                                } catch {
                                    await MainActor.run {
                                        kiAufmassLaedt = false
                                        kiHinweis = error.localizedDescription
                                    }
                                }
                            }
                        } label: {
                            Label(
                                kiAufmassLaedt
                                ? "material.ki.position.loading".localized("KI erstellt Position …")
                                : (AppConfig.isProUser
                                   ? "material.ki.position.button.pro".localized("✨ Position mit KI erstellen")
                                   : "material.ki.position.button.free".localized("✨ Position mit KI erstellen – Pro")),
                                systemImage: "sparkles"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.bauPilotBlue)
                        .disabled(kiAufmassLaedt)
                    }
                    .padding(.vertical, 4)

                    ForEach($aufmass.positionen) { $position in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("material.field.description".localized("Bezeichnung"), text: $position.bezeichnung)

                            HStack {
                                TextField("material.field.quantity".localized("Menge"), text: $position.menge)
                                    .keyboardType(.decimalPad)

                                TextField("material.field.unit".localized("Einheit"), text: $position.einheit)
                            }

                            TextField("material.field.area".localized("Bereich / Raum"), text: $position.bereich)
                            TextField("material.field.note".localized("Notiz"), text: $position.notiz)
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete { indexSet in
                        aufmass.positionen.remove(atOffsets: indexSet)
                    }

                    Button {
                        aufmass.positionen.append(AufmassPosition())
                    } label: {
                        Label("material.position.add".localized("Position hinzufügen"), systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.bauPilotBlue)
                }

                Section("material.field.note".localized("Notiz")) {
                    TextEditor(text: $aufmass.notiz)
                        .frame(minHeight: 100)

                    Button {
                        let trimmedNote = aufmass.notiz.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard AppConfig.isProUser else {
                            zeigePaywall = true
                            return
                        }

                        guard KIUsageManager.shared.canUseKIText else {
                            kiHinweis = "ki.text.limit_reached".localized("Monatliches KI-Limit erreicht. Dein Kontingent wird im nächsten Monat zurückgesetzt.")
                            return
                        }

                        guard !trimmedNote.isEmpty else {
                            kiHinweis = "ki.text.empty_note".localized("Bitte gib zuerst eine Notiz ein.")
                            return
                        }

                        kiLaedt = true

                        Task {
                            do {
                                let verbessert = try await KITextService.shared.verbessereNotiz(
                                    trimmedNote,
                                    kontext: .aufmass
                                )

                                await MainActor.run {
                                    aufmass.notiz = verbessert
                                    KIUsageManager.shared.registerKITextAction()
                                    kiLaedt = false
                                    kiHinweis = "ki.text.success".localized("KI-Text wurde angewendet.")
                                }
                            } catch {
                                await MainActor.run {
                                    kiLaedt = false
                                    kiHinweis = error.localizedDescription
                                }
                            }
                        }
                    } label: {
                        Label(
                            kiLaedt
                            ? "ki.text.button.loading".localized("KI arbeitet …")
                            : (AppConfig.isProUser
                               ? "ki.text.button.pro".localized("✨ Mit KI verbessern")
                               : "ki.text.button.free".localized("✨ Mit KI verbessern – Pro")),
                            systemImage: "sparkles"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.bauPilotBlue)
                    .disabled(kiLaedt)
                }

                Section("material.section.photo".localized("Foto vom Blatt")) {
                    InfoLimitKarte(
                        text: AppConfig.isProUser
                            ? "material.limit.photo.pro".localized("BauPilot Pro aktiv: Unbegrenzte Fotos für Aufmaß / Material möglich.")
                            : String(format: "material.limit.free".localized("Kostenlose Version: maximal %d Foto pro Aufmaß / Material möglich."), AppLimits.maxFotosProAufmass)
                    )

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("material.photo.add".localized("Foto hinzufügen"), systemImage: "camera.fill")
                    }
                    .disabled(aufmass.bild != nil)

                    if let data = aufmass.bild, let uiImage = UIImage(data: data) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .onTapGesture {
                                    zeigeBildFullscreen = true
                                }

                            Button {
                                aufmass.bild = nil
                                ocrVorschlaege.removeAll()
                                ocrFehlerText = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, .red)
                            }
                            .padding(8)
                        }

                        Button {
                            AufmassOCRService.erkennePositionen(aus: uiImage) { result in
                                switch result {
                                case .success(let vorschlaege):
                                    ocrVorschlaege = vorschlaege
                                    ocrFehlerText = nil
                                case .failure(let error):
                                    ocrFehlerText = error.localizedDescription
                                }
                            }
                        } label: {
                            Label("material.ocr.start".localized("Positionen aus Foto erkennen"), systemImage: "text.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.bauPilotBlue)
                    }

                    if let ocrFehlerText {
                        Text(ocrFehlerText)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if !ocrVorschlaege.isEmpty {
                    Section("material.ocr.results".localized("Erkannte Positionen")) {
                        if unsichereAnzahl > 0 {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(
                                        unsichereAnzahl == 1
                                        ? "material.ocr.warning.single".localized("1 Position sollte geprüft werden.")
                                        : String(format: "material.ocr.warning.multiple".localized("%d Positionen sollten geprüft werden."), unsichereAnzahl)
                                    )
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text("material.ocr.warning.info".localized("Unsichere OCR-Zeilen sind gelb markiert. Speichern bleibt trotzdem möglich."))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }


                        ForEach(Array(ocrVorschlaege.indices), id: \.self) { index in
                            VStack(alignment: .leading, spacing: 6) {
                                OCRVorschlagRow(vorschlag: $ocrVorschlaege[index])

                                if ocrVorschlaege[index].istUnsicher {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.yellow)
                                            .padding(.top, 1)

                                        Text(ocrVorschlaege[index].warnhinweis ?? "material.ocr.warning.default".localized("Diese Position sollte geprüft werden."))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.bottom, 4)
                                }
                            }
                            .padding(.vertical, ocrVorschlaege[index].istUnsicher ? 6 : 0)
                        }

                        Button {
                            let neuePositionen = ocrVorschlaege.map { vorschlag in
                                AufmassPosition(
                                    bezeichnung: vorschlag.bezeichnung,
                                    menge: vorschlag.menge,
                                    einheit: vorschlag.einheit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Stk" : vorschlag.einheit,
                                    bereich: vorschlag.bereich,
                                    notiz: ""
                                )
                            }

                            aufmass.positionen.append(contentsOf: neuePositionen)
                            ocrVorschlaege.removeAll()
                        } label: {
                            Label("material.ocr.apply".localized("Alle übernehmen"), systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
            .navigationTitle("material.title".localized("Aufmaß / Material"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.cancel".localized("Abbrechen")) { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.save".localized("Speichern")) {
                        aufmass.notiz = SpeechTextFormatter.format(aufmass.notiz)

                        if aufmass.titel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           let erste = aufmass.positionen.first?.bezeichnung,
                           !erste.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            aufmass.titel = erste
                        }

                        if !ocrVorschlaege.isEmpty {
                            let neuePositionen = ocrVorschlaege.map { vorschlag in
                                AufmassPosition(
                                    bezeichnung: vorschlag.bezeichnung,
                                    menge: vorschlag.menge,
                                    einheit: vorschlag.einheit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Stk" : vorschlag.einheit,
                                    bereich: vorschlag.bereich,
                                    notiz: ""
                                )
                            }

                            aufmass.positionen.append(contentsOf: neuePositionen)
                            ocrVorschlaege.removeAll()
                        }

                        onSave(aufmass)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onChange(of: photoItem) { _, neuesItem in
                Task {
                    guard let item = neuesItem else { return }

                    if aufmass.bild != nil {
                        await MainActor.run {
                            limitFehler = .maxFotosProAufmass
                            photoItem = nil
                        }
                        return
                    }

                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let jpegData = image.jpegData(compressionQuality: 0.85) {
                        await MainActor.run {
                            if aufmass.bild == nil {
                                aufmass.bild = jpegData
                            } else {
                                limitFehler = .maxFotosProAufmass
                            }
                            photoItem = nil
                        }
                    }
                }
            }
            .alert("common.notice".localized("Hinweis"), isPresented: Binding(
                get: { limitFehler != nil },
                set: { if !$0 { limitFehler = nil } }
            )) {
                Button("nav.ok".localized("OK"), role: .cancel) { limitFehler = nil }
            } message: {
                Text(limitFehler?.errorDescription ?? "")
            }
            .alert("ki.text.title".localized("KI Text"), isPresented: Binding(
                get: { kiHinweis != nil },
                set: { if !$0 { kiHinweis = nil } }
            )) {
                Button("nav.ok".localized("OK"), role: .cancel) { kiHinweis = nil }
            } message: {
                Text(kiHinweis ?? "")
            }
            .sheet(isPresented: $zeigePaywall) {
                PaywallView()
            }
            .sheet(isPresented: $zeigeBildFullscreen) {
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let data = aufmass.bild,
                       let image = UIImage(data: data) {
                        ZoomableImageView(image: image)
                    }
                }
            }
        }
    }
}
