import SwiftUI
import PhotosUI
import UIKit
import Foundation


struct EintragBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var speechManager: SpeechManager

    @State private var eintrag: BaustellenEintrag
    let onSave: (BaustellenEintrag) -> Void

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var speechBaseText: String = ""
    @State private var limitFehler: LimitFehler?
    @State private var kiHinweis: String?
    @State private var kiLaedt = false
    @State private var zeigePaywall = false
    @State private var fullscreenBild: UIImage?
    @State private var detailsAufgeklappt = false
    @State private var schnellSpeichernNachFoto = true

    init(
        speechManager: SpeechManager,
        eintrag: BaustellenEintrag,
        onSave: @escaping (BaustellenEintrag) -> Void
    ) {
        self.speechManager = speechManager
        self._eintrag = State(initialValue: eintrag)
        self.onSave = onSave
    }

    private var verbleibendeFotoPlaetze: Int {
        max(0, AppLimits.maxFotosProEintrag - eintrag.bilder.count)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("entry.section.photos".localized("Fotos")) {
                    InfoLimitKarte(
                        text: AppConfig.isProUser
                        ? "entry.limit.photos.pro".localized("BauPilot Pro aktiv: Unbegrenzte Fotos pro Eintrag möglich.")
                        : String(format: "entry.limit.photos.free".localized("Kostenlose Version: bis zu %d Fotos pro Eintrag möglich."), AppLimits.maxFotosProEintrag)
                    )

                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: max(1, verbleibendeFotoPlaetze),
                        matching: .images
                    ) {
                        Label("entry.photos.select".localized("Fotos auswählen"), systemImage: "photo.on.rectangle")
                    }
                    .disabled(verbleibendeFotoPlaetze == 0)

                    Toggle(isOn: $schnellSpeichernNachFoto) {
                        Label("entry.quick_save_after_photo".localized("Nach Foto sofort speichern"), systemImage: "bolt.fill")
                    }
                    .font(.footnote)

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
                                                .onTapGesture {
                                                    fullscreenBild = uiImage
                                                }

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

                Section("entry.section.general".localized("Allgemein")) {
                    TextField("entry.field.title".localized("Titel"), text: $eintrag.titel)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("entry.field.note".localized("Notiz"))
                            .font(.subheadline.weight(.semibold))

                        TextEditor(text: $eintrag.notiz)
                            .frame(minHeight: 140)

                        Button {
                            let trimmedNote = eintrag.notiz.trimmingCharacters(in: .whitespacesAndNewlines)

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
                                        kontext: .eintrag
                                    )

                                    await MainActor.run {
                                        eintrag.notiz = verbessert
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

                        if speechManager.isRecording {
                            Button {
                                let finalText = speechManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !finalText.isEmpty {
                                    eintrag.notiz = SpeechTextFormatter.append(existing: speechBaseText, newText: finalText)
                                } else {
                                    eintrag.notiz = speechBaseText
                                }

                                speechManager.stopRecording()
                                speechManager.recognizedText = ""
                                speechBaseText = eintrag.notiz
                            } label: {
                                Label("entry.voice.stop".localized("Stopp"), systemImage: "stop.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        } else {
                            Button {
                                speechBaseText = eintrag.notiz.trimmingCharacters(in: .whitespacesAndNewlines)

                                speechManager.startRecording { text in
                                    let combined = SpeechTextFormatter.append(existing: speechBaseText, newText: text)
                                    if !combined.isEmpty {
                                        eintrag.notiz = combined
                                    }
                                }
                            } label: {
                                Label("entry.voice.start".localized("Spracheingabe starten"), systemImage: "mic.fill")
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

                Section("entry.section.details".localized("Details")) {
                    DisclosureGroup(isExpanded: $detailsAufgeklappt) {
                        Picker("entry.field.category".localized("Kategorie"), selection: $eintrag.kategorie) {
                            ForEach(BaustellenKategorie.allCases) { kategorie in
                                Text(kategorie.localizedName).tag(kategorie)
                            }
                        }

                        Picker("entry.field.status".localized("Status"), selection: $eintrag.status) {
                            ForEach(BaustellenStatus.allCases) { status in
                                Text(status.localizedName).tag(status)
                            }
                        }

                        Picker("entry.field.priority".localized("Priorität"), selection: $eintrag.prioritaet) {
                            ForEach(Prioritaet.allCases) { prioritaet in
                                Text(prioritaet.localizedName).tag(prioritaet)
                            }
                        }

                        DatePicker(
                            "entry.field.date".localized("Datum"),
                            selection: $eintrag.datum,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } label: {
                        Label("entry.details.show".localized("Details anzeigen"), systemImage: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("entry.title".localized("Eintrag"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                speechManager.requestPermissions()
                speechBaseText = eintrag.notiz.trimmingCharacters(in: .whitespacesAndNewlines)
                setzeAutomatischenTitelWennLeer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.cancel".localized("Abbrechen")) {
                        speechManager.stopRecording()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.save".localized("Speichern")) {
                        let finalText = speechManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if speechManager.isRecording, !finalText.isEmpty {
                            eintrag.notiz = SpeechTextFormatter.append(existing: speechBaseText, newText: finalText)
                        } else {
                            eintrag.notiz = SpeechTextFormatter.format(eintrag.notiz)
                        }

                        speechManager.stopRecording()
                        speechManager.recognizedText = ""
                        setzeAutomatischenTitelWennLeer()
                        onSave(eintrag)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onChange(of: photoItems) { _, neueItems in
                Task {
                    guard !neueItems.isEmpty else { return }

                    if eintrag.bilder.count >= AppLimits.maxFotosProEintrag {
                        await MainActor.run {
                            limitFehler = .maxFotosProEintrag
                            photoItems = []
                        }
                        return
                    }

                    for item in neueItems {
                        if eintrag.bilder.count >= AppLimits.maxFotosProEintrag {
                            await MainActor.run {
                                limitFehler = .maxFotosProEintrag
                            }
                            break
                        }

                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                if eintrag.bilder.count < AppLimits.maxFotosProEintrag {
                                    eintrag.bilder.append(data)
                                    if schnellSpeichernNachFoto {
                                        setzeAutomatischenTitelWennLeer()
                                        onSave(eintrag)
                                        dismiss()
                                        return
                                    }
                                } else {
                                    limitFehler = .maxFotosProEintrag
                                }
                            }
                        }
                    }

                    await MainActor.run {
                        photoItems = []
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
            .sheet(item: Binding(
                get: {
                    fullscreenBild.map { EintragFullscreenImageItem(image: $0) }
                },
                set: { newValue in
                    fullscreenBild = newValue?.image
                }
            )) { item in
                ZoomableImageView(image: item.image)
            }
        }
    }

    private func setzeAutomatischenTitelWennLeer() {
        let aktuellerTitel = eintrag.titel.trimmingCharacters(in: .whitespacesAndNewlines)
        if aktuellerTitel.isEmpty {
            eintrag.titel = "\("entry.title.auto".localized("Eintrag")) – \(formatDatum(eintrag.datum))"
        }
    }

    private func formatDatum(_ datum: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: datum)
    }
}

private struct EintragFullscreenImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}
