import Foundation
import StoreKit
import Combine


@MainActor
final class StoreKitManager: ObservableObject {
    
    static let shared = StoreKitManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = AppConfig.isProUser
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let productIds = ["baupilot_pro_v2"]
    private var updatesTask: Task<Void, Never>?
    
    private init() {
        updatesTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedStatus()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIds)
            print("StoreKit angefragte Product IDs:", productIds)
            print("StoreKit geladene Produkte:", products.map { $0.id })
        } catch {
            errorMessage = "store.error.products_load_failed".localized("Produkte konnten nicht geladen werden.")
            print("StoreKit Produktfehler:", error)
        }
    }
    
    func purchasePro() async {
        if products.isEmpty {
            await loadProducts()
        }

        if products.isEmpty {
            print("StoreKit keine Produkte geladen. Erwartete Product IDs:", productIds)
            errorMessage = "store.error.products_empty".localized("Abonnement konnte nicht geladen werden. Bitte später erneut versuchen.")
            return
        }
        
        guard let product = products.first(where: { $0.id == "baupilot_pro_v2" }) else {
            print("StoreKit Pro nicht verfügbar. Geladene Produkte:", products.map { $0.id })
            print("StoreKit erwartete Product ID: baupilot_pro_v2")
            errorMessage = "store.error.pro_unavailable".localized("BauPilot Pro ist aktuell nicht verfügbar.")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedStatus()
                await registerProOnServer()
                
            case .userCancelled:
                break
                
            case .pending:
                errorMessage = "store.error.purchase_pending".localized("Der Kauf wartet noch auf Bestätigung.")
                
            @unknown default:
                errorMessage = "store.error.unknown_purchase_status".localized("Unbekannter Kaufstatus.")
            }
        } catch {
            errorMessage = "store.error.purchase_failed".localized("Kauf konnte nicht abgeschlossen werden.")
            print("StoreKit Kauffehler:", error)
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
            if isPro {
                await registerProOnServer()
            }
        } catch {
            errorMessage = "store.error.restore_failed".localized("Käufe konnten nicht wiederhergestellt werden.")
            print("StoreKit Restore-Fehler:", error)
        }
    }
    
    func updatePurchasedStatus() async {
        var hasPro = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if productIds.contains(transaction.productID), transaction.revocationDate == nil {
                    hasPro = true
                    break
                }
            } catch {
                continue
            }
        }
        
        isPro = hasPro
        AppConfig.setPro(hasPro)
    }
    
    private func registerProOnServer() async {
        guard let url = URL(string: "https://baupilot-ki-api.vercel.app/api/register-pro") else {
            errorMessage = "store.error.invalid_server_url".localized("Server-Adresse ist ungültig.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(DeviceIDManager.shared.deviceID, forHTTPHeaderField: "X-BauPilot-Device-ID")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "store.error.pro_server_activation_failed".localized("Pro konnte auf dem Server nicht aktiviert werden.")
                return
            }
        } catch {
            errorMessage = "store.error.server_unreachable".localized("Server konnte nicht erreicht werden.")
            print("Pro-Registrierung Fehler:", error)
        }
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    guard let self else { return }
                    let transaction = try await self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePurchasedStatus()
                    await self.registerProOnServer()
                } catch {
                    print("StoreKit Transaktionsfehler:", error)
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreKitError.notVerified
        }
    }
}

enum StoreKitError: Error {
    case notVerified
}
