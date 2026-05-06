import SwiftUI
import PhotosUI
import UIKit
import Foundation

struct NachweisBearbeitenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nachweis: NachweisEintrag
    let onSave: (NachweisEintrag) -> Void

    @State private var photoItem: PhotosPickerItem?
    @State private var kiHinweis: String?
    @State private var kiLaedt = false
    @State private var zeigePaywall = false
    @State private var fullscreenBild: UIImage?
    @State private var detailsAufgeklappt = false
    @State private var schnellSpeichernNachFoto = true
    @State private var zeigeUnterschrift = false
    @State private var proHinweis: String?

    init(nachweis: NachweisEintrag, onSave: @escaping (NachweisEintrag) -> Void) {
        self._nachweis = State(initialValue: nachweis)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("proof.title".localized("Nachweis")) {
                    Picker("proof.field.type".localized("Typ"), selection: $nachweis.typ) {
                        ForEach(NachweisTyp.allCases) { typ in
                            Text(typ.localizedName).tag(typ)
                        }
                    }

                    TextField("proof.field.title".localized("Titel"), text: $nachweis.titel)

                    DisclosureGroup(
                        isExpanded: $detailsAufgeklappt,
                        content: {
                            DatePicker(
                                "proof.field.date".localized("Datum"),
                                selection: $nachweis.datum,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        },
                        label: {
                            Label("proof.details.show".localized("Details"), systemImage: "slider.horizontal.3")
                        }
                    )
                }

                Section("proof.section.photo".localized("Foto")) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("proof.photo.add".localized("Foto hinzufügen"), systemImage: "camera.fill")
                    }
                    Toggle(isOn: $schnellSpeichernNachFoto) {
                        Label("proof.quick_save_after_photo".localized("Nach Foto sofort speichern"), systemImage: "bolt.fill")
                    }
                    .font(.footnote)

                    Button {
                        guard AppConfig.isProUser else {
                            zeigePaywall = true
                            return
                        }
                        zeigeUnterschrift = true
                    } label: {
                        Label("proof.signature.add".localized("Unterschrift hinzufügen – Pro"), systemImage: "signature")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.bauPilotBlue)

                    if nachweis.bilder.isEmpty {
                        Label(
                            "proof.photo.recommended".localized("Foto empfohlen: So ist der Nachweis später im Bericht eindeutig belegbar."),
                            systemImage: "info.circle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                    ForEach(Array(nachweis.bilder.enumerated()), id: \.offset) { index, data in
                        if let uiImage = UIImage(data: data) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .onTapGesture {
                                        fullscreenBild = uiImage
                                    }

                                Button {
                                    nachweis.bilder.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white, .red)
                                }
                                .padding(8)
                            }
                        }
                    }
                }

                Section("proof.field.note".localized("Notiz")) {
                    TextEditor(text: $nachweis.notiz)
                        .frame(minHeight: 120)

                    Button {
                        let trimmedNote = nachweis.notiz.trimmingCharacters(in: .whitespacesAndNewlines)

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
                                    kontext: .nachweis
                                )

                                await MainActor.run {
                                    nachweis.notiz = verbessert
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

                    Button {
                        guard AppConfig.isProUser else {
                            zeigePaywall = true
                            return
                        }
                        kopiereNachweisDaten()
                        proHinweis = "proof.copy.success".localized("Nachweisdaten wurden kopiert.")
                    } label: {
                        Label("proof.copy.button".localized("Nachweis kopieren – Pro"), systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle("proof.title".localized("Nachweis"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.cancel".localized("Abbrechen")) { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.save".localized("Speichern")) {
                        setzeAutomatischenTitelWennLeer()
                        nachweis.notiz = SpeechTextFormatter.format(nachweis.notiz)
                        onSave(nachweis)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                setzeAutomatischenTitelWennLeer()
            }
            .onChange(of: nachweis.typ) { _, _ in
                setzeAutomatischenTitelWennLeer(force: true)
                if nachweis.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    nachweis.notiz = notizVorlageFuerTyp(nachweis.typ)
                }
            }
            .onChange(of: photoItem) { _, neuesItem in
                Task {
                    guard let item = neuesItem else { return }
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let jpegData = image.jpegData(compressionQuality: 0.85) {
                        await MainActor.run {
                            if !AppConfig.isProUser && nachweis.bilder.count >= 1 {
                                photoItem = nil
                                zeigePaywall = true
                                return
                            }

                            nachweis.bilder.append(jpegData)
                            photoItem = nil
                            if schnellSpeichernNachFoto {
                                // 🔥 Ultra Fast Flow: Foto → speichern → fertig
                                setzeAutomatischenTitelWennLeer()
                                nachweis.notiz = SpeechTextFormatter.format(nachweis.notiz)
                                onSave(nachweis)
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .alert("ki.text.title".localized("KI Text"), isPresented: Binding(
            get: { kiHinweis != nil },
            set: { if !$0 { kiHinweis = nil } }
        )) {
            Button("nav.ok".localized("OK"), role: .cancel) { kiHinweis = nil }
        } message: {
            Text(kiHinweis ?? "")
        }
        .alert("proof.pro.title".localized("BauPilot Pro"), isPresented: Binding(
            get: { proHinweis != nil },
            set: { if !$0 { proHinweis = nil } }
        )) {
            Button("nav.ok".localized("OK"), role: .cancel) { proHinweis = nil }
        } message: {
            Text(proHinweis ?? "")
        }
        .sheet(isPresented: $zeigePaywall) {
            PaywallView()
        }
        .sheet(isPresented: $zeigeUnterschrift) {
            UnterschriftSheet { unterschriftBild in
                guard let data = unterschriftBild.jpegData(compressionQuality: 0.9) else { return }
                nachweis.bilder.append(data)
                setzeAutomatischenTitelWennLeer()
                nachweis.notiz = SpeechTextFormatter.format(nachweis.notiz)
                onSave(nachweis)
            }
        }
        .sheet(item: Binding(
            get: {
                fullscreenBild.map { FullscreenImageItem(image: $0) }
            },
            set: { newValue in
                fullscreenBild = newValue?.image
            }
        )) { item in
            ZoomableImageView(image: item.image)
        }
    }

    private func setzeAutomatischenTitelWennLeer(force: Bool = false) {
        let aktuellerTitel = nachweis.titel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard force || aktuellerTitel.isEmpty || aktuellerTitel.hasPrefix(nachweisAutoTitelPrefix) else { return }

        nachweis.titel = automatischerTitel
    }

    private var automatischerTitel: String {
        "\(nachweisAutoTitelPrefix) – \(formatDatum(nachweis.datum))"
    }

    private var nachweisAutoTitelPrefix: String {
        nachweis.typ.localizedName
    }

    private func formatDatum(_ datum: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: datum)
    }

    private func notizVorlageFuerTyp(_ typ: NachweisTyp) -> String {
        switch typ {
        case .pressureTest:
            return "proof.template.pressure_test".localized("Druckprüfung durchgeführt. Anlage geprüft, keine sichtbaren Undichtigkeiten festgestellt.")
        case .filling:
            return "proof.template.filling".localized("Anlage befüllt und kontrolliert. Werte wurden vor Ort geprüft.")
        case .commissioning:
            return "proof.template.commissioning".localized("Inbetriebnahme durchgeführt. Funktion wurde geprüft.")
        case .inspectionReport:
            return "proof.template.inspection_report".localized("Prüfprotokoll erstellt. Relevante Werte und Beobachtungen wurden dokumentiert.")
        case .acceptance:
            return "proof.template.acceptance".localized("Abnahme vor Ort dokumentiert. Zustand wurde geprüft und festgehalten.")
        case .other:
            return ""
        }
    }

    private func kopiereNachweisDaten() {
        let text = """
        \("proof.field.type".localized("Typ")): \(nachweis.typ.localizedName)
        \("proof.field.title".localized("Titel")): \(nachweis.titel)
        \("proof.field.date".localized("Datum")): \(formatDatum(nachweis.datum))
        \("proof.field.note".localized("Notiz")):
        \(nachweis.notiz)
        """

        UIPasteboard.general.string = text
    }
}

private struct FullscreenImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct UnterschriftSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var canvas = SignatureCanvasView()

    let onSave: (UIImage) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("proof.signature.info".localized("Bitte unterschreiben Sie im Feld unten."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SignatureCanvasRepresentable(canvasView: canvas)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 260)
                    .padding(.bottom, 8)

                Button(role: .destructive) {
                    canvas.clear()
                } label: {
                    Label("proof.signature.clear".localized("Unterschrift löschen"), systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("proof.signature.title".localized("Unterschrift"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.cancel".localized("Abbrechen")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.save".localized("Speichern")) {
                        let image = canvas.renderedImage()
                        onSave(image)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

private struct SignatureCanvasRepresentable: UIViewRepresentable {
    let canvasView: SignatureCanvasView

    func makeUIView(context: Context) -> SignatureCanvasView {
        canvasView
    }

    func updateUIView(_ uiView: SignatureCanvasView, context: Context) {}
}

private final class SignatureCanvasView: UIView {
    private var lines: [[CGPoint]] = []
    private var currentLine: [CGPoint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        isMultipleTouchEnabled = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentLine = [point]
        lines.append(currentLine)
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentLine.append(point)
        if !lines.isEmpty {
            lines[lines.count - 1] = currentLine
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        UIColor.black.setStroke()
        let path = UIBezierPath()
        path.lineWidth = 3
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        for line in lines {
            guard let first = line.first else { continue }
            path.move(to: first)
            for point in line.dropFirst() {
                path.addLine(to: point)
            }
        }

        path.stroke()
    }

    func clear() {
        lines.removeAll()
        currentLine.removeAll()
        setNeedsDisplay()
    }

    func renderedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}
