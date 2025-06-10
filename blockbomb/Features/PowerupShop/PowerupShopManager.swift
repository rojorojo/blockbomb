import Foundation

/// Enum defining all available powerup types in the shop
enum PowerupType: String, CaseIterable {
    case reviveHeart = "revive_heart"
    case futureBonus1 = "future_bonus_1"
    case futureBonus2 = "future_bonus_2"
    case futureBonus3 = "future_bonus_3"
    
    /// Display name for the powerup
    var displayName: String {
        switch self {
        case .reviveHeart:
            return "Revive Heart"
        case .futureBonus1:
            return "Future Bonus 1"
        case .futureBonus2:
            return "Future Bonus 2"
        case .futureBonus3:
            return "Future Bonus 3"
        }
    }
    
    /// Description of what the powerup does
    var description: String {
        switch self {
        case .reviveHeart:
            return "Continue playing when you run out of moves"
        case .futureBonus1:
            return "Coming soon - Special bonus powerup"
        case .futureBonus2:
            return "Coming soon - Advanced powerup"
        case .futureBonus3:
            return "Coming soon - Premium powerup"
        }
    }
}

/// Structure representing a powerup item in the shop
struct PowerupItem {
    let type: PowerupType
    let price: Int
    let isAvailable: Bool
    
    var displayName: String {
        return type.displayName
    }
    
    var description: String {
        return type.description
    }
}

/// Result of a powerup purchase attempt
enum PurchaseResult {
    case success
    case insufficientFunds
    case itemNotAvailable
    case purchaseError(String)
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .insufficientFunds:
            return "Not enough points to purchase this item"
        case .itemNotAvailable:
            return "This item is not currently available"
        case .purchaseError(let message):
            return message
        }
    }
}

/// Manages the powerup shop system including pricing, availability, and purchase transactions
class PowerupShopManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PowerupShopManager()
    
    // MARK: - Published Properties
    @Published var availablePowerups: [PowerupItem] = []
    
    // MARK: - Private Properties
    private let currencyManager = PowerupCurrencyManager.shared
    private let reviveHeartManager = ReviveHeartManager.shared
    
    // MARK: - Configuration
    private var powerupPricing: [PowerupType: Int] = [
        .reviveHeart: 20,
        .futureBonus1: 50,
        .futureBonus2: 100,
        .futureBonus3: 200
    ]
    
    private var powerupAvailability: [PowerupType: Bool] = [
        .reviveHeart: true,
        .futureBonus1: false, // Coming soon
        .futureBonus2: false, // Coming soon
        .futureBonus3: false  // Coming soon
    ]
    
    // MARK: - Initialization
    private init() {
        updateAvailablePowerups()
    }
    
    // MARK: - Public Methods
    
    /// Get all available powerups in the shop
    /// - Returns: Array of PowerupItem representing available powerups
    func getPowerups() -> [PowerupItem] {
        return availablePowerups
    }
    
    /// Check if a specific powerup can be purchased
    /// - Parameter type: The powerup type to check
    /// - Returns: True if the powerup can be purchased, false otherwise
    func canPurchase(_ type: PowerupType) -> Bool {
        guard let item = availablePowerups.first(where: { $0.type == type }) else {
            return false
        }
        
        return item.isAvailable && currencyManager.hasEnoughPoints(item.price)
    }
    
    /// Attempt to purchase a powerup
    /// - Parameter type: The powerup type to purchase
    /// - Returns: PurchaseResult indicating success or failure reason
    func purchasePowerup(_ type: PowerupType) -> PurchaseResult {
        print("PowerupShopManager: Attempting to purchase \(type.displayName)")
        
        // Find the powerup item
        guard let item = availablePowerups.first(where: { $0.type == type }) else {
            print("PowerupShopManager: Powerup \(type.displayName) not found in available items")
            return .itemNotAvailable
        }
        
        // Check if item is available
        guard item.isAvailable else {
            print("PowerupShopManager: Powerup \(type.displayName) is not currently available")
            return .itemNotAvailable
        }
        
        // Check if player has enough points
        guard currencyManager.hasEnoughPoints(item.price) else {
            print("PowerupShopManager: Insufficient funds for \(type.displayName). Required: \(item.price), Available: \(currencyManager.getPoints())")
            return .insufficientFunds
        }
        
        // Attempt to spend the points
        guard currencyManager.spendPoints(item.price) else {
            print("PowerupShopManager: Failed to spend points for \(type.displayName)")
            return .purchaseError("Failed to process payment")
        }
        
        // Process the specific powerup purchase
        let deliveryResult = deliverPowerup(type)
        
        if deliveryResult.isSuccess {
            print("PowerupShopManager: Successfully purchased \(type.displayName) for \(item.price) points")
            return .success
        } else {
            // Refund the points if delivery failed
            currencyManager.addPoints(item.price)
            print("PowerupShopManager: Purchase failed, refunded \(item.price) points")
            return deliveryResult
        }
    }
    
    /// Get the price of a specific powerup
    /// - Parameter type: The powerup type
    /// - Returns: The price in points, or nil if not available
    func getPrice(for type: PowerupType) -> Int? {
        return powerupPricing[type]
    }
    
    /// Check if a powerup type is available for purchase
    /// - Parameter type: The powerup type
    /// - Returns: True if available, false otherwise
    func isAvailable(_ type: PowerupType) -> Bool {
        return powerupAvailability[type] ?? false
    }
    
    /// Get powerup by type
    /// - Parameter type: The powerup type
    /// - Returns: PowerupItem if found, nil otherwise
    func getPowerup(type: PowerupType) -> PowerupItem? {
        return availablePowerups.first(where: { $0.type == type })
    }
    
    // MARK: - Configuration Methods
    
    /// Update the price of a powerup (useful for configuration/balancing)
    /// - Parameters:
    ///   - type: The powerup type
    ///   - price: The new price in points
    func updatePrice(for type: PowerupType, price: Int) {
        guard price >= 0 else {
            print("PowerupShopManager: Cannot set negative price for \(type.displayName)")
            return
        }
        
        powerupPricing[type] = price
        updateAvailablePowerups()
        print("PowerupShopManager: Updated price for \(type.displayName) to \(price) points")
    }
    
    /// Update the availability of a powerup
    /// - Parameters:
    ///   - type: The powerup type
    ///   - available: Whether the powerup should be available
    func updateAvailability(for type: PowerupType, available: Bool) {
        powerupAvailability[type] = available
        updateAvailablePowerups()
        print("PowerupShopManager: Updated availability for \(type.displayName) to \(available)")
    }
    
    // MARK: - Private Methods
    
    /// Update the available powerups array based on current pricing and availability
    private func updateAvailablePowerups() {
        availablePowerups = PowerupType.allCases.compactMap { type in
            guard let price = powerupPricing[type] else { return nil }
            let isAvailable = powerupAvailability[type] ?? false
            
            return PowerupItem(
                type: type,
                price: price,
                isAvailable: isAvailable
            )
        }
        
        print("PowerupShopManager: Updated available powerups. Count: \(availablePowerups.count)")
    }
    
    /// Deliver the purchased powerup to the player
    /// - Parameter type: The powerup type to deliver
    /// - Returns: PurchaseResult indicating delivery success or failure
    private func deliverPowerup(_ type: PowerupType) -> PurchaseResult {
        switch type {
        case .reviveHeart:
            return deliverReviveHeart()
        case .futureBonus1, .futureBonus2, .futureBonus3:
            // Future powerups not yet implemented
            return .purchaseError("This powerup is not yet implemented")
        }
    }
    
    /// Deliver a revive heart to the player
    /// - Returns: PurchaseResult indicating delivery success or failure
    private func deliverReviveHeart() -> PurchaseResult {
        reviveHeartManager.addHearts(count: 1)
        print("PowerupShopManager: Delivered 1 revive heart to player")
        return .success
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension PowerupShopManager {
    /// Debug method to reset all prices to default values
    func debugResetPrices() {
        powerupPricing = [
            .reviveHeart: 20,
            .futureBonus1: 50,
            .futureBonus2: 100,
            .futureBonus3: 200
        ]
        updateAvailablePowerups()
        print("PowerupShopManager: Debug reset all prices to defaults")
    }
    
    /// Debug method to make all powerups available
    func debugMakeAllAvailable() {
        for type in PowerupType.allCases {
            powerupAvailability[type] = true
        }
        updateAvailablePowerups()
        print("PowerupShopManager: Debug made all powerups available")
    }
    
    /// Debug method to make all powerups unavailable
    func debugMakeAllUnavailable() {
        for type in PowerupType.allCases {
            powerupAvailability[type] = false
        }
        updateAvailablePowerups()
        print("PowerupShopManager: Debug made all powerups unavailable")
    }
    
    /// Debug method to set a specific price for testing
    func debugSetPrice(for type: PowerupType, price: Int) {
        updatePrice(for: type, price: price)
        print("PowerupShopManager: Debug set price for \(type.displayName) to \(price)")
    }
    
    /// Debug method to test a purchase without spending points
    func debugTestPurchase(_ type: PowerupType) -> PurchaseResult {
        print("PowerupShopManager: Debug testing purchase of \(type.displayName)")
        
        guard let item = availablePowerups.first(where: { $0.type == type }) else {
            return .itemNotAvailable
        }
        
        guard item.isAvailable else {
            return .itemNotAvailable
        }
        
        // Simulate delivery without spending points
        return deliverPowerup(type)
    }
}
#endif
