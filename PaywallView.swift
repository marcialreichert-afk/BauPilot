import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var store = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                
                // 🔥 Icon + Titel
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.bauPilotBlue)
                    
                    Text("paywall.title".localized("BauPilot Pro"))
                        .font(.largeTitle.bold())
                    
                    Text("paywall.subtitle".localized("Baustellendoku schneller fertig"))
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("paywall.description".localized("Nutze KI, um aus kurzen Notizen professionelle Baustellentexte zu erstellen."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                
                // 📋 Vorteile
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "wand.and.stars", text: "paywall.feature.notes_to_reports".localized("Kurze Notizen in saubere Berichte umwandeln"))
                    FeatureRow(icon: "clock.badge.checkmark", text: "paywall.feature.less_work".localized("Weniger Schreibarbeit nach Feierabend"))
                    FeatureRow(icon: "doc.text", text: "paywall.feature.professional_texts".localized("Professionelle Texte für Einträge, Nachweise und Aufmaß"))
                    FeatureRow(icon: "infinity", text: "paywall.feature.unlimited".localized("Pro-Funktionen ohne Free-Limits nutzen"))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // ℹ️ Pflichtinfos vor dem Kauf
                VStack(spacing: 8) {
                    Text("paywall.legal.notice".localized("Das Abo verlängert sich automatisch und kann jederzeit in den Apple-ID Einstellungen gekündigt werden."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Link("paywall.privacy".localized("Datenschutzerklärung"), destination: URL(string: "https://melodious-product-ef4.notion.site/Datenschutzerkl-rung-BauPilot-68281294508b4de095e421ebe803530c")!)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Link("paywall.terms".localized("Nutzungsbedingungen (EULA)"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .font(.caption.weight(.semibold))
                }
                .padding(.top, 4)

                // 💰 Apple-konformer Abo-Bereich
                SubscriptionStoreView(productIDs: store.products.map(\.id))
                    .subscriptionStorePolicyDestination(
                        url: URL(string: "https://melodious-product-ef4.notion.site/Datenschutzerkl-rung-BauPilot-68281294508b4de095e421ebe803530c")!,
                        for: .privacyPolicy
                    )
                    .subscriptionStorePolicyDestination(
                        url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
                        for: .termsOfService
                    )
                    .subscriptionStoreButtonLabel(.multiline)
                    .subscriptionStoreControlStyle(.buttons)
                    .frame(minHeight: 160, maxHeight: 220)
                
                }
                .padding()
            }
            .onChange(of: store.isPro) { isPro in
                if isPro {
                    dismiss()
                }
            }
            .navigationTitle("paywall.navigation.title".localized("Pro freischalten"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("paywall.close".localized("Nicht jetzt")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 🔧 Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.bauPilotBlue)
            
            Text(text)
                .font(.subheadline.weight(.medium))
            
            Spacer()
        }
    }
}
