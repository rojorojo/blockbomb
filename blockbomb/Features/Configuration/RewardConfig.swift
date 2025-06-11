import Foundation
import Combine
import SwiftUI

/// Configuration keys for the reward system
enum RewardConfigKey: String, CaseIterable {
    // Currency Configuration
    case pointsPerAd = "RewardConfig.pointsPerAd"
    case defaultPointBalance = "RewardConfig.defaultPointBalance"
    
    // Powerup Pricing Configuration
    case reviveHeartPrice = "RewardConfig.reviveHeartPrice"
    case futureBonus1Price = "RewardConfig.futureBonus1Price"
    case futureBonus2Price = "RewardConfig.futureBonus2Price"
    case futureBonus3Price = "RewardConfig.futureBonus3Price"
    
    // Ad Frequency Configuration
    case gamesBetweenInterstitials = "RewardConfig.gamesBetweenInterstitials"
    case bonusAdCooldownSeconds = "RewardConfig.bonusAdCooldownSeconds"
    case minGameDurationForAd = "RewardConfig.minGameDurationForAd"
    
    // Reward Economy Tuning
    case adWatchBonusMultiplier = "RewardConfig.adWatchBonusMultiplier"
    case firstTimePlayerBonus = "RewardConfig.firstTimePlayerBonus"
    case dailyBonusPoints = "RewardConfig.dailyBonusPoints"
    
    var displayName: String {
        switch self {
        case .pointsPerAd: return "Points Per Ad"
        case .defaultPointBalance: return "Default Point Balance"
        case .reviveHeartPrice: return "Revive Heart Price"
        case .futureBonus1Price: return "Future Bonus 1 Price"
        case .futureBonus2Price: return "Future Bonus 2 Price"
        case .futureBonus3Price: return "Future Bonus 3 Price"
        case .gamesBetweenInterstitials: return "Games Between Interstitials"
        case .bonusAdCooldownSeconds: return "Bonus Ad Cooldown (seconds)"
        case .minGameDurationForAd: return "Min Game Duration for Ad"
        case .adWatchBonusMultiplier: return "Ad Watch Bonus Multiplier"
        case .firstTimePlayerBonus: return "First Time Player Bonus"
        case .dailyBonusPoints: return "Daily Bonus Points"
        }
    }
    
    var description: String {
        switch self {
        case .pointsPerAd: return "Points awarded for watching a rewarded ad"
        case .defaultPointBalance: return "Starting point balance for new players"
        case .reviveHeartPrice: return "Cost in points to purchase a revive heart"
        case .futureBonus1Price: return "Cost for future bonus powerup 1"
        case .futureBonus2Price: return "Cost for future bonus powerup 2"
        case .futureBonus3Price: return "Cost for future bonus powerup 3"
        case .gamesBetweenInterstitials: return "Number of games before showing interstitial ads"
        case .bonusAdCooldownSeconds: return "Cooldown time between bonus ad opportunities"
        case .minGameDurationForAd: return "Minimum game duration before showing ads"
        case .adWatchBonusMultiplier: return "Multiplier for bonus rewards from ads"
        case .firstTimePlayerBonus: return "Bonus points for first-time players"
        case .dailyBonusPoints: return "Daily login bonus points"
        }
    }
    
    var category: RewardConfigCategory {
        switch self {
        case .pointsPerAd, .defaultPointBalance, .adWatchBonusMultiplier, .firstTimePlayerBonus, .dailyBonusPoints:
            return .currency
        case .reviveHeartPrice, .futureBonus1Price, .futureBonus2Price, .futureBonus3Price:
            return .powerups
        case .gamesBetweenInterstitials, .bonusAdCooldownSeconds, .minGameDurationForAd:
            return .advertising
        }
    }
}

/// Configuration categories for organization
enum RewardConfigCategory: String, CaseIterable {
    case currency = "Currency"
    case powerups = "Powerups"
    case advertising = "Advertising"
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .currency: return BlockColors.amber
        case .powerups: return BlockColors.violet
        case .advertising: return BlockColors.cyan
        }
    }
}

/// Configuration value with validation and default fallback
struct RewardConfigValue {
    let key: RewardConfigKey
    let value: Int
    let isDefault: Bool
    
    var isValid: Bool {
        return value >= 0 && value <= maxValueForKey(key)
    }
    
    private func maxValueForKey(_ key: RewardConfigKey) -> Int {
        switch key {
        case .pointsPerAd: return 100
        case .defaultPointBalance: return 1000
        case .reviveHeartPrice, .futureBonus1Price, .futureBonus2Price, .futureBonus3Price: return 500
        case .gamesBetweenInterstitials: return 20
        case .bonusAdCooldownSeconds: return 3600 // 1 hour max
        case .minGameDurationForAd: return 300 // 5 minutes max
        case .adWatchBonusMultiplier: return 10
        case .firstTimePlayerBonus: return 200
        case .dailyBonusPoints: return 100
        }
    }
}

/// JSON configuration structure for server-side config
struct RewardConfigJSON: Codable {
    let version: String
    let timestamp: Date
    let configurations: [String: Int]
    let metadata: ConfigMetadata?
    
    struct ConfigMetadata: Codable {
        let description: String?
        let author: String?
        let environment: String? // "production", "staging", "development"
    }
    
    static let currentVersion = "1.0"
}

/// Main configuration manager for the reward economy system
class RewardConfig: ObservableObject {
    
    // MARK: - Singleton
    static let shared = RewardConfig()
    
    // MARK: - Published Properties
    @Published var configValues: [RewardConfigKey: RewardConfigValue] = [:]
    @Published var isLoading = false
    @Published var lastUpdateTimestamp: Date?
    
    // MARK: - Private Properties
    private let userDefaultsPrefix = "RewardConfig."
    private let configFileName = "reward_config.json"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Default Values
    private let defaultValues: [RewardConfigKey: Int] = [
        .pointsPerAd: 10,
        .defaultPointBalance: 0,
        .reviveHeartPrice: 20,
        .futureBonus1Price: 50,
        .futureBonus2Price: 100,
        .futureBonus3Price: 200,
        .gamesBetweenInterstitials: 2,
        .bonusAdCooldownSeconds: 120,
        .minGameDurationForAd: 30,
        .adWatchBonusMultiplier: 1,
        .firstTimePlayerBonus: 50,
        .dailyBonusPoints: 10
    ]
    
    // MARK: - Initialization
    private init() {
        loadConfiguration()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Get configuration value for a specific key
    func getValue(for key: RewardConfigKey) -> Int {
        return configValues[key]?.value ?? getDefaultValue(for: key)
    }
    
    /// Set configuration value for a specific key
    func setValue(_ value: Int, for key: RewardConfigKey) {
        let validatedValue = validateValue(value, for: key)
        let configValue = RewardConfigValue(key: key, value: validatedValue, isDefault: false)
        
        configValues[key] = configValue
        saveToUserDefaults(key: key, value: validatedValue)
        
        print("RewardConfig: Set \(key.displayName) to \(validatedValue)")
        
        // Notify dependent systems
        notifySystemsOfChange(key: key, value: validatedValue)
    }
    
    /// Reset a specific key to its default value
    func resetToDefault(key: RewardConfigKey) {
        let defaultValue = getDefaultValue(for: key)
        setValue(defaultValue, for: key)
        
        // Remove from UserDefaults to indicate it's using default
        UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key.rawValue)
        
        // Update config value to indicate it's using default
        configValues[key] = RewardConfigValue(key: key, value: defaultValue, isDefault: true)
        
        print("RewardConfig: Reset \(key.displayName) to default value: \(defaultValue)")
    }
    
    /// Reset all configuration to default values
    func resetAllToDefaults() {
        for key in RewardConfigKey.allCases {
            resetToDefault(key: key)
        }
        
        print("RewardConfig: Reset all values to defaults")
    }
    
    /// Export current configuration as JSON
    func exportConfiguration() -> Data? {
        let configurations = Dictionary(uniqueKeysWithValues: 
            configValues.map { (key, configValue) in
                (key.rawValue, configValue.value)
            }
        )
        
        let configJSON = RewardConfigJSON(
            version: RewardConfigJSON.currentVersion,
            timestamp: Date(),
            configurations: configurations,
            metadata: RewardConfigJSON.ConfigMetadata(
                description: "Block Puzzle Game Reward Configuration",
                author: "RewardConfig System",
                environment: "development"
            )
        )
        
        do {
            return try JSONEncoder().encode(configJSON)
        } catch {
            print("RewardConfig: Failed to export configuration: \(error)")
            return nil
        }
    }
    
    /// Import configuration from JSON data
    func importConfiguration(from data: Data) -> Bool {
        do {
            let configJSON = try JSONDecoder().decode(RewardConfigJSON.self, from: data)
            
            // Validate version compatibility
            guard configJSON.version == RewardConfigJSON.currentVersion else {
                print("RewardConfig: Version mismatch - expected \(RewardConfigJSON.currentVersion), got \(configJSON.version)")
                return false
            }
            
            // Apply configurations
            for (keyString, value) in configJSON.configurations {
                if let key = RewardConfigKey(rawValue: keyString) {
                    setValue(value, for: key)
                } else {
                    print("RewardConfig: Unknown configuration key: \(keyString)")
                }
            }
            
            lastUpdateTimestamp = configJSON.timestamp
            print("RewardConfig: Successfully imported configuration with \(configJSON.configurations.count) values")
            return true
            
        } catch {
            print("RewardConfig: Failed to import configuration: \(error)")
            return false
        }
    }
    
    /// Load configuration from local JSON file if available
    func loadFromFile() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("RewardConfig: Could not access documents directory")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(configFileName)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            print("RewardConfig: No local configuration file found")
            return
        }
        
        if importConfiguration(from: data) {
            print("RewardConfig: Loaded configuration from local file")
        }
    }
    
    /// Save configuration to local JSON file
    func saveToFile() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = exportConfiguration() else {
            print("RewardConfig: Failed to prepare configuration for saving")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(configFileName)
        
        do {
            try data.write(to: fileURL)
            print("RewardConfig: Saved configuration to local file")
        } catch {
            print("RewardConfig: Failed to save configuration to file: \(error)")
        }
    }
    
    // MARK: - Convenience Methods for System Integration
    
    /// Get points per ad for currency system
    var pointsPerAd: Int {
        return getValue(for: .pointsPerAd)
    }
    
    /// Get default point balance for new users
    var defaultPointBalance: Int {
        return getValue(for: .defaultPointBalance)
    }
    
    /// Get revive heart price for shop system
    var reviveHeartPrice: Int {
        return getValue(for: .reviveHeartPrice)
    }
    
    /// Get games between interstitials for ad timing
    var gamesBetweenInterstitials: Int {
        return getValue(for: .gamesBetweenInterstitials)
    }
    
    /// Get bonus ad cooldown for ad timing
    var bonusAdCooldownSeconds: Int {
        return getValue(for: .bonusAdCooldownSeconds)
    }
    
    /// Get all powerup prices as dictionary
    var powerupPrices: [PowerupType: Int] {
        return [
            .reviveHeart: getValue(for: .reviveHeartPrice),
            .futureBonus1: getValue(for: .futureBonus1Price),
            .futureBonus2: getValue(for: .futureBonus2Price),
            .futureBonus3: getValue(for: .futureBonus3Price)
        ]
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        isLoading = true
        
        // Load from UserDefaults first
        for key in RewardConfigKey.allCases {
            let userDefaultsKey = userDefaultsPrefix + key.rawValue
            
            if UserDefaults.standard.object(forKey: userDefaultsKey) != nil {
                let value = UserDefaults.standard.integer(forKey: userDefaultsKey)
                configValues[key] = RewardConfigValue(key: key, value: value, isDefault: false)
            } else {
                let defaultValue = getDefaultValue(for: key)
                configValues[key] = RewardConfigValue(key: key, value: defaultValue, isDefault: true)
            }
        }
        
        // Try to load from file (this may override UserDefaults values)
        loadFromFile()
        
        isLoading = false
        print("RewardConfig: Configuration loaded successfully")
    }
    
    private func setupObservers() {
        // Save configuration to file when values change
        $configValues
            .dropFirst() // Skip initial load
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveToFile()
            }
            .store(in: &cancellables)
    }
    
    private func getDefaultValue(for key: RewardConfigKey) -> Int {
        return defaultValues[key] ?? 0
    }
    
    private func validateValue(_ value: Int, for key: RewardConfigKey) -> Int {
        let configValue = RewardConfigValue(key: key, value: value, isDefault: false)
        return configValue.isValid ? value : getDefaultValue(for: key)
    }
    
    private func saveToUserDefaults(key: RewardConfigKey, value: Int) {
        UserDefaults.standard.set(value, forKey: userDefaultsPrefix + key.rawValue)
    }
    
    private func notifySystemsOfChange(key: RewardConfigKey, value: Int) {
        // Notify relevant systems of configuration changes
        switch key.category {
        case .currency:
            NotificationCenter.default.post(name: .rewardConfigCurrencyChanged, object: nil, userInfo: [
                "key": key.rawValue,
                "value": value
            ])
        case .powerups:
            NotificationCenter.default.post(name: .rewardConfigPowerupsChanged, object: nil, userInfo: [
                "key": key.rawValue,
                "value": value
            ])
        case .advertising:
            NotificationCenter.default.post(name: .rewardConfigAdvertisingChanged, object: nil, userInfo: [
                "key": key.rawValue,
                "value": value
            ])
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension RewardConfig {
    /// Debug method to simulate server-side configuration update
    func debugSimulateServerUpdate() {
        print("RewardConfig: Simulating server-side configuration update...")
        
        // Simulate some configuration changes
        setValue(15, for: .pointsPerAd) // Increase points per ad
        setValue(25, for: .reviveHeartPrice) // Increase heart price
        setValue(3, for: .gamesBetweenInterstitials) // More games between ads
        
        print("RewardConfig: Server simulation complete")
    }
    
    /// Debug method to test JSON import/export
    func debugTestJSONSerialization() {
        print("RewardConfig: Testing JSON serialization...")
        
        guard let exportedData = exportConfiguration() else {
            print("RewardConfig: Export failed")
            return
        }
        
        let success = importConfiguration(from: exportedData)
        print("RewardConfig: JSON test \(success ? "passed" : "failed")")
    }
    
    /// Debug method to validate all current values
    func debugValidateAllValues() {
        print("RewardConfig: Validating all configuration values...")
        
        var invalidCount = 0
        for (key, configValue) in configValues {
            if !configValue.isValid {
                print("RewardConfig: Invalid value for \(key.displayName): \(configValue.value)")
                invalidCount += 1
            }
        }
        
        print("RewardConfig: Validation complete - \(invalidCount) invalid values found")
    }
    
    /// Debug method to create test configuration preset
    func debugApplyTestPreset() {
        print("RewardConfig: Applying test configuration preset...")
        
        setValue(20, for: .pointsPerAd) // Higher reward for testing
        setValue(100, for: .defaultPointBalance) // Start with points
        setValue(15, for: .reviveHeartPrice) // Cheaper for testing
        setValue(1, for: .gamesBetweenInterstitials) // Frequent ads for testing
        setValue(30, for: .bonusAdCooldownSeconds) // Short cooldown for testing
        
        print("RewardConfig: Test preset applied")
    }
    
    /// Debug method to create production-like preset
    func debugApplyProductionPreset() {
        print("RewardConfig: Applying production configuration preset...")
        
        setValue(10, for: .pointsPerAd)
        setValue(0, for: .defaultPointBalance)
        setValue(20, for: .reviveHeartPrice)
        setValue(3, for: .gamesBetweenInterstitials)
        setValue(180, for: .bonusAdCooldownSeconds) // 3 minutes
        
        print("RewardConfig: Production preset applied")
    }
}
#endif

// MARK: - Notification Names

extension Notification.Name {
    static let rewardConfigCurrencyChanged = Notification.Name("RewardConfig.CurrencyChanged")
    static let rewardConfigPowerupsChanged = Notification.Name("RewardConfig.PowerupsChanged")
    static let rewardConfigAdvertisingChanged = Notification.Name("RewardConfig.AdvertisingChanged")
}
