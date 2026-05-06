import SwiftUI
import Foundation

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
                Section("site.general".localized("Allgemein")) {
                    TextField("site.field.name".localized("Baustellenname"), text: $baustelle.name)
                    TextField("site.field.location".localized("Ort"), text: $baustelle.ort)
                    TextField("site.field.customer".localized("Kunde"), text: $baustelle.kunde)
                }

                Section("site.note".localized("Notiz")) {
                    TextEditor(text: $baustelle.notiz)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle("site.title".localized("Baustelle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.cancel".localized("Abbrechen")) { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.save".localized("Speichern")) {
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
