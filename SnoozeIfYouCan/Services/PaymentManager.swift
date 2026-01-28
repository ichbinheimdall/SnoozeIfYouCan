import Foundation
import StoreKit
import Combine

/// Complete StoreKit 2 integration for snooze payments
/// All payments are donations to Darüşşafaka
///
/// `PaymentManager` handles all in-app purchase operations using Apple's StoreKit 2 framework.
/// It manages product loading, purchase flows, transaction verification, and restoration.
///
/// ## Product Tiers
/// The app uses 5 consumable in-app purchase products corresponding to snooze tiers:
/// - Tier 1: $0.99 (first snooze)
/// - Tier 2: $1.99 (second snooze)
/// - Tier 3: $2.99 (third snooze)
/// - Tier 4: $4.99 (fourth snooze)
/// - Tier 5: $9.99 (fifth snooze)
///
/// ## Usage
/// ```swift
/// // Purchase a snooze
/// let success = await paymentManager.purchaseSnooze(cost: 0.99)
/// if success {
///     // Record donation and allow snooze
/// }
/// ```
///
/// ## Important Notes
/// - All products are **consumable** (can be purchased multiple times)
/// - No subscription or non-consumable products are used
/// - Transactions are automatically finished after verification
/// - Failed transactions are logged but don't prevent app usage
///
/// - Warning: In production, actual charity donation processing would require
///   server-side integration with payment processors. This implementation
///   demonstrates the concept only.
@MainActor
class PaymentManager: ObservableObject {
    static let shared = PaymentManager()
    
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var purchaseInProgress = false
    @Published var lastError: String?
    @Published var isLoading = false
    
    // MARK: - Product Configuration
    
    /// Product IDs configured in App Store Connect
    /// These are consumable products for donation tiers
    enum ProductID: String, CaseIterable {
        case snoozeTier1 = "com.snoozeifyoucan.donation.tier1"  // $0.99
        case snoozeTier2 = "com.snoozeifyoucan.donation.tier2"  // $1.99
        case snoozeTier3 = "com.snoozeifyoucan.donation.tier3"  // $2.99
        case snoozeTier4 = "com.snoozeifyoucan.donation.tier4"  // $4.99
        case snoozeTier5 = "com.snoozeifyoucan.donation.tier5"  // $9.99
        
        var amount: Double {
            switch self {
            case .snoozeTier1: return 0.99
            case .snoozeTier2: return 1.99
            case .snoozeTier3: return 2.99
            case .snoozeTier4: return 4.99
            case .snoozeTier5: return 9.99
            }
        }
        
        /// Find the appropriate tier for a given amount
        static func tier(for amount: Double) -> ProductID {
            if amount <= 0.99 { return .snoozeTier1 }
            if amount <= 1.99 { return .snoozeTier2 }
            if amount <= 2.99 { return .snoozeTier3 }
            if amount <= 4.99 { return .snoozeTier4 }
            return .snoozeTier5
        }
    }
    
    // MARK: - Transaction Listener
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Transaction Handling
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await transaction.finish()
                    print("✅ Transaction completed: \(transaction.productID)")
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            lastError = error.localizedDescription
        }
    }
    
    // MARK: - Purchase
    
    func purchaseSnooze(amount: Double) async -> Bool {
        let tier = ProductID.tier(for: amount)
        
        guard let product = products.first(where: { $0.id == tier.rawValue }) else {
            if products.isEmpty {
                await loadProducts()
                guard let product = products.first(where: { $0.id == tier.rawValue }) else {
                    lastError = "Product not available"
                    return false
                }
                return await purchase(product)
            }
            lastError = "Product not found"
            return false
        }
        
        return await purchase(product)
    }
    
    func purchase(_ product: Product) async -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                // Play success feedback
                HapticsManager.shared.paymentSuccess()
                SoundManager.shared.playPaymentSound()
                
                print("✅ Purchase successful: \(product.displayName)")
                return true
                
            case .userCancelled:
                print("⚠️ User cancelled purchase")
                return false
                
            case .pending:
                print("⏳ Purchase pending approval")
                lastError = "Purchase pending approval"
                return false
                
            @unknown default:
                return false
            }
        } catch StoreKitError.userCancelled {
            print("⚠️ User cancelled")
            return false
        } catch {
            lastError = error.localizedDescription
            print("❌ Purchase failed: \(error)")
            HapticsManager.shared.error()
            return false
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // For testing without real StoreKit (simulator)
    func simulatePurchase(amount: Double) -> Bool {
        #if DEBUG
        print("🧪 Simulated purchase of $\(String(format: "%.2f", amount))")
        HapticsManager.shared.paymentSuccess()
        SoundManager.shared.playPaymentSound()
        return true
        #else
        return false
        #endif
    }
    
    func product(for tier: ProductID) -> Product? {
        products.first { $0.id == tier.rawValue }
    }
    
    func displayPrice(for amount: Double) -> String {
        let tier = ProductID.tier(for: amount)
        if let product = product(for: tier) {
            return product.displayPrice
        }
        return String(format: "$%.2f", tier.amount)
    }
}

// MARK: - Donation tracking for Darüşşafaka
extension PaymentManager {
    struct DonationInfo {
        static let organizationName = "Darüşşafaka"
        static let organizationShortName = "Darüşşafaka"
        static let organizationDescription = """
            Darüşşafaka Cemiyeti, 1863'ten bu yana Türkiye'de \
            yetim ve öksüz çocuklara ücretsiz eğitim veren \
            köklü bir sivil toplum kuruluşudur.
            """
        static let websiteURL = URL(string: "https://www.darussafaka.org")!
    }
    
    func getDonationMessage(for amount: Double) -> String {
        """
        💙 Your $\(String(format: "%.2f", amount)) snooze fee will be donated to \
        \(DonationInfo.organizationName) to support education for children in need.
        """
    }
}
