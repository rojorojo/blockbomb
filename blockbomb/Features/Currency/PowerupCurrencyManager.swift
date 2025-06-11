import Foundation
import Combine

/// Manages the powerup currency system including persistence and point tracking
class PowerupCurrencyManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PowerupCurrencyManager()
    
    // MARK: - Published Properties
    @Published var points: Int = 0 {
        didSet {
            savePoints()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current points balance (computed property for UI binding)
    var currentPoints: Int {
        return points
    }
    
    // MARK: - Constants
    private let userDefaultsKey = "powerupCurrencyPoints"
    
    // MARK: - Configuration Integration
    private let rewardConfig = RewardConfig.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Default point balance from configuration
    private var defaultPointBalance: Int {
        return rewardConfig.defaultPointBalance
    }
    
    /// Points per ad from configuration
    private var pointsPerAd: Int {
        return rewardConfig.pointsPerAd
    }
    
    // MARK: - Initialization
    private init() {
        loadPoints()
        setupConfigurationObservers()
    }
    
    // MARK: - Public Methods
    
    /// Get the current number of points
    /// - Returns: The current point balance
    func getPoints() -> Int {
        return points
    }
    
    /// Check if the player has enough points for a purchase
    /// - Parameter amount: The amount of points needed
    /// - Returns: True if player has enough points, false otherwise
    func hasEnoughPoints(_ amount: Int) -> Bool {
        return points >= amount
    }
    
    /// Add points to the player's balance (typically from watching ads)
    /// - Parameter amount: Number of points to add
    func addPoints(_ amount: Int) {
        guard amount > 0 else {
            print("PowerupCurrencyManager: Cannot add negative or zero points")
            return
        }
        
        points += amount
        print("PowerupCurrencyManager: Added \(amount) points. Total: \(points)")
    }
    
    /// Spend points from the player's balance
    /// - Parameter amount: Number of points to spend
    /// - Returns: True if the transaction was successful, false if insufficient funds
    @discardableResult
    func spendPoints(_ amount: Int) -> Bool {
        guard amount > 0 else {
            print("PowerupCurrencyManager: Cannot spend negative or zero points")
            return false
        }
        
        guard hasEnoughPoints(amount) else {
            print("PowerupCurrencyManager: Cannot spend \(amount) points - insufficient funds. Current balance: \(points)")
            return false
        }
        
        points -= amount
        print("PowerupCurrencyManager: Spent \(amount) points. Remaining: \(points)")
        return true
    }
    
    /// Award points for watching an ad
    func awardAdPoints() {
        addPoints(pointsPerAd)
        print("PowerupCurrencyManager: Awarded \(pointsPerAd) points for watching ad")
    }
    
    /// Reset points to default balance (useful for testing or game reset)
    func resetPoints() {
        points = defaultPointBalance
        print("PowerupCurrencyManager: Reset points to default balance: \(defaultPointBalance)")
    }
    
    // MARK: - Configuration
    
    /// Get the number of points awarded per ad (for display purposes)
    /// - Returns: Points per ad value
    func getPointsPerAd() -> Int {
        return pointsPerAd
    }
    
    // MARK: - Private Methods
    
    /// Setup observers for configuration changes
    private func setupConfigurationObservers() {
        NotificationCenter.default.publisher(for: .rewardConfigCurrencyChanged)
            .sink { [weak self] notification in
                if let key = notification.userInfo?["key"] as? String,
                   let value = notification.userInfo?["value"] as? Int {
                    self?.handleConfigurationChange(key: key, value: value)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handle configuration changes
    private func handleConfigurationChange(key: String, value: Int) {
        switch key {
        case RewardConfigKey.pointsPerAd.rawValue:
            print("PowerupCurrencyManager: Points per ad updated to \(value)")
        case RewardConfigKey.defaultPointBalance.rawValue:
            print("PowerupCurrencyManager: Default point balance updated to \(value)")
        default:
            break
        }
    }
    
    /// Load point balance from UserDefaults
    private func loadPoints() {
        if UserDefaults.standard.object(forKey: userDefaultsKey) != nil {
            // Point balance exists in UserDefaults
            points = UserDefaults.standard.integer(forKey: userDefaultsKey)
            print("PowerupCurrencyManager: Loaded point balance from UserDefaults: \(points)")
        } else {
            // First launch - initialize with default balance
            points = defaultPointBalance
            savePoints()
            print("PowerupCurrencyManager: First launch - initialized with \(defaultPointBalance) points")
        }
    }
    
    /// Save point balance to UserDefaults
    private func savePoints() {
        UserDefaults.standard.set(points, forKey: userDefaultsKey)
        print("PowerupCurrencyManager: Saved point balance to UserDefaults: \(points)")
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension PowerupCurrencyManager {
    /// Debug method to set a specific point balance (only available in debug builds)
    func debugSetPoints(_ amount: Int) {
        points = max(0, amount) // Ensure non-negative
        print("PowerupCurrencyManager: Debug set points to: \(points)")
    }
    
    /// Debug method to add points without validation (only available in debug builds)
    func debugAddPoints(_ amount: Int) {
        points += amount
        print("PowerupCurrencyManager: Debug added \(amount) points. Total: \(points)")
    }
    
    /// Debug method to simulate watching multiple ads
    func debugSimulateAds(_ adCount: Int) {
        let totalPoints = adCount * pointsPerAd
        addPoints(totalPoints)
        print("PowerupCurrencyManager: Debug simulated watching \(adCount) ads, earned \(totalPoints) points")
    }
    
    /// Debug method to clear UserDefaults (only available in debug builds)
    func debugClearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        loadPoints() // Reload from defaults
        print("PowerupCurrencyManager: Debug cleared UserDefaults and reloaded")
    }
}
#endif
