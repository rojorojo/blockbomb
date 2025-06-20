import Foundation
import Combine
import SwiftUI
import GameKit

/// Configuration keys for the multiplayer system
enum MultiplayerConfigKey: String, CaseIterable {
    // Match Settings
    case maxMatchDurationMinutes = "MultiplayerConfig.maxMatchDurationMinutes"
    case turnTimeoutSeconds = "MultiplayerConfig.turnTimeoutSeconds"
    case maxConcurrentMatches = "MultiplayerConfig.maxConcurrentMatches"
    case matchmakingTimeout = "MultiplayerConfig.matchmakingTimeout"
    
    // Scoring Configuration
    case winBonusPoints = "MultiplayerConfig.winBonusPoints"
    case resignationPenalty = "MultiplayerConfig.resignationPenalty"
    case scoreThresholdForInstantWin = "MultiplayerConfig.scoreThresholdForInstantWin"
    case tiebreakerScoreMultiplier = "MultiplayerConfig.tiebreakerScoreMultiplier"
    
    // Connection & Network
    case connectionTimeoutSeconds = "MultiplayerConfig.connectionTimeoutSeconds"
    case maxReconnectionAttempts = "MultiplayerConfig.maxReconnectionAttempts"
    case heartbeatIntervalSeconds = "MultiplayerConfig.heartbeatIntervalSeconds"
    case dataCompressionEnabled = "MultiplayerConfig.dataCompressionEnabled"
    
    // Player Preferences
    case allowRandomOpponents = "MultiplayerConfig.allowRandomOpponents"
    case showOpponentScore = "MultiplayerConfig.showOpponentScore"
    case enableChatFeatures = "MultiplayerConfig.enableChatFeatures"
    case autoAcceptRematch = "MultiplayerConfig.autoAcceptRematch"
    
    // Debug & Testing
    case debugModeEnabled = "MultiplayerConfig.debugModeEnabled"
    case simulateNetworkDelay = "MultiplayerConfig.simulateNetworkDelay"
    case forceConnectionLoss = "MultiplayerConfig.forceConnectionLoss"
    case logVerboseNetworking = "MultiplayerConfig.logVerboseNetworking"
    
    // Privacy & Game Center
    case shareStatistics = "MultiplayerConfig.shareStatistics"
    case allowLeaderboards = "MultiplayerConfig.allowLeaderboards"
    case enableAchievements = "MultiplayerConfig.enableAchievements"
    case anonymousMode = "MultiplayerConfig.anonymousMode"
    
    var displayName: String {
        switch self {
        case .maxMatchDurationMinutes: return "Max Match Duration (minutes)"
        case .turnTimeoutSeconds: return "Turn Timeout (seconds)"
        case .maxConcurrentMatches: return "Max Concurrent Matches"
        case .matchmakingTimeout: return "Matchmaking Timeout (seconds)"
        case .winBonusPoints: return "Win Bonus Points"
        case .resignationPenalty: return "Resignation Penalty"
        case .scoreThresholdForInstantWin: return "Instant Win Score Threshold"
        case .tiebreakerScoreMultiplier: return "Tiebreaker Score Multiplier"
        case .connectionTimeoutSeconds: return "Connection Timeout (seconds)"
        case .maxReconnectionAttempts: return "Max Reconnection Attempts"
        case .heartbeatIntervalSeconds: return "Heartbeat Interval (seconds)"
        case .dataCompressionEnabled: return "Data Compression Enabled"
        case .allowRandomOpponents: return "Allow Random Opponents"
        case .showOpponentScore: return "Show Opponent Score"
        case .enableChatFeatures: return "Enable Chat Features"
        case .autoAcceptRematch: return "Auto Accept Rematch"
        case .debugModeEnabled: return "Debug Mode Enabled"
        case .simulateNetworkDelay: return "Simulate Network Delay (ms)"
        case .forceConnectionLoss: return "Force Connection Loss"
        case .logVerboseNetworking: return "Verbose Network Logging"
        case .shareStatistics: return "Share Statistics"
        case .allowLeaderboards: return "Allow Leaderboards"
        case .enableAchievements: return "Enable Achievements"
        case .anonymousMode: return "Anonymous Mode"
        }
    }
    
    var description: String {
        switch self {
        case .maxMatchDurationMinutes: return "Maximum duration for a multiplayer match"
        case .turnTimeoutSeconds: return "Time limit for each player turn"
        case .maxConcurrentMatches: return "Maximum number of active matches at once"
        case .matchmakingTimeout: return "How long to wait for matchmaking"
        case .winBonusPoints: return "Bonus points awarded for winning a match"
        case .resignationPenalty: return "Points deducted for resigning from a match"
        case .scoreThresholdForInstantWin: return "Score difference for instant win condition"
        case .tiebreakerScoreMultiplier: return "Multiplier used in tiebreaker calculations"
        case .connectionTimeoutSeconds: return "Network connection timeout threshold"
        case .maxReconnectionAttempts: return "Maximum reconnection attempts on disconnect"
        case .heartbeatIntervalSeconds: return "Interval for connection health checks"
        case .dataCompressionEnabled: return "Enable data compression for network efficiency"
        case .allowRandomOpponents: return "Allow matchmaking with random players"
        case .showOpponentScore: return "Display opponent's score during gameplay"
        case .enableChatFeatures: return "Enable in-game chat functionality"
        case .autoAcceptRematch: return "Automatically accept rematch requests"
        case .debugModeEnabled: return "Enable debug features for multiplayer testing"
        case .simulateNetworkDelay: return "Artificial network delay for testing (milliseconds)"
        case .forceConnectionLoss: return "Force connection loss for testing scenarios"
        case .logVerboseNetworking: return "Enable detailed network operation logging"
        case .shareStatistics: return "Share multiplayer statistics with Game Center"
        case .allowLeaderboards: return "Participate in Game Center leaderboards"
        case .enableAchievements: return "Enable Game Center achievements"
        case .anonymousMode: return "Play anonymously without sharing player info"
        }
    }
    
    var category: MultiplayerConfigCategory {
        switch self {
        case .maxMatchDurationMinutes, .turnTimeoutSeconds, .maxConcurrentMatches, .matchmakingTimeout:
            return .matchSettings
        case .winBonusPoints, .resignationPenalty, .scoreThresholdForInstantWin, .tiebreakerScoreMultiplier:
            return .scoring
        case .connectionTimeoutSeconds, .maxReconnectionAttempts, .heartbeatIntervalSeconds, .dataCompressionEnabled:
            return .networking
        case .allowRandomOpponents, .showOpponentScore, .enableChatFeatures, .autoAcceptRematch:
            return .playerPreferences
        case .debugModeEnabled, .simulateNetworkDelay, .forceConnectionLoss, .logVerboseNetworking:
            return .debug
        case .shareStatistics, .allowLeaderboards, .enableAchievements, .anonymousMode:
            return .privacy
        }
    }
    
    var isBoolean: Bool {
        switch self {
        case .dataCompressionEnabled, .allowRandomOpponents, .showOpponentScore, .enableChatFeatures,
             .autoAcceptRematch, .debugModeEnabled, .forceConnectionLoss, .logVerboseNetworking,
             .shareStatistics, .allowLeaderboards, .enableAchievements, .anonymousMode:
            return true
        default:
            return false
        }
    }
}

/// Configuration categories for organization
enum MultiplayerConfigCategory: String, CaseIterable {
    case matchSettings = "Match Settings"
    case scoring = "Scoring"
    case networking = "Networking"
    case playerPreferences = "Player Preferences"
    case debug = "Debug & Testing"
    case privacy = "Privacy & Game Center"
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .matchSettings: return Color.blue
        case .scoring: return BlockColors.amber
        case .networking: return Color.green
        case .playerPreferences: return Color.purple
        case .debug: return Color.red
        case .privacy: return Color.orange
        }
    }
    
    var systemImage: String {
        switch self {
        case .matchSettings: return "gamecontroller"
        case .scoring: return "chart.bar"
        case .networking: return "network"
        case .playerPreferences: return "person.2"
        case .debug: return "ladybug"
        case .privacy: return "lock.shield"
        }
    }
}

/// Configuration value with validation and default fallback
struct MultiplayerConfigValue {
    let key: MultiplayerConfigKey
    let value: Int
    let isDefault: Bool
    
    var isValid: Bool {
        return value >= minValueForKey(key) && value <= maxValueForKey(key)
    }
    
    var boolValue: Bool {
        return value != 0
    }
    
    private func minValueForKey(_ key: MultiplayerConfigKey) -> Int {
        switch key {
        case .maxMatchDurationMinutes: return 5
        case .turnTimeoutSeconds: return 30
        case .maxConcurrentMatches: return 1
        case .matchmakingTimeout: return 10
        case .winBonusPoints: return 0
        case .resignationPenalty: return 0
        case .scoreThresholdForInstantWin: return 1000
        case .tiebreakerScoreMultiplier: return 1
        case .connectionTimeoutSeconds: return 5
        case .maxReconnectionAttempts: return 0
        case .heartbeatIntervalSeconds: return 5
        case .simulateNetworkDelay: return 0
        default: return 0
        }
    }
    
    private func maxValueForKey(_ key: MultiplayerConfigKey) -> Int {
        switch key {
        case .maxMatchDurationMinutes: return 60
        case .turnTimeoutSeconds: return 300
        case .maxConcurrentMatches: return 10
        case .matchmakingTimeout: return 120
        case .winBonusPoints: return 1000
        case .resignationPenalty: return 500
        case .scoreThresholdForInstantWin: return 10000
        case .tiebreakerScoreMultiplier: return 5
        case .connectionTimeoutSeconds: return 60
        case .maxReconnectionAttempts: return 10
        case .heartbeatIntervalSeconds: return 60
        case .simulateNetworkDelay: return 5000
        default: return 1
        }
    }
}

/// JSON configuration structure for server-side config
struct MultiplayerConfigJSON: Codable {
    let version: String
    let timestamp: Date
    let configurations: [String: Int]
    let metadata: ConfigMetadata?
    
    struct ConfigMetadata: Codable {
        let description: String?
        let author: String?
        let environment: String? // "production", "staging", "development"
        let targetVersion: String?
    }
    
    static let currentVersion = "1.0"
}

/// Main configuration manager for the multiplayer system
class MultiplayerConfig: ObservableObject {
    
    // MARK: - Singleton
    static let shared = MultiplayerConfig()
    
    // MARK: - Published Properties
    @Published var configValues: [MultiplayerConfigKey: MultiplayerConfigValue] = [:]
    @Published var isLoading = false
    @Published var lastUpdateTimestamp: Date?
    @Published var gameCenterAvailable = false
    @Published var debugModeActive = false
    
    // MARK: - Private Properties
    private let userDefaultsPrefix = "MultiplayerConfig."
    private let configFileName = "multiplayer_config.json"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Default Values
    private let defaultValues: [MultiplayerConfigKey: Int] = [
        // Match Settings
        .maxMatchDurationMinutes: 30,
        .turnTimeoutSeconds: 120,
        .maxConcurrentMatches: 3,
        .matchmakingTimeout: 30,
        
        // Scoring Configuration
        .winBonusPoints: 100,
        .resignationPenalty: 50,
        .scoreThresholdForInstantWin: 5000,
        .tiebreakerScoreMultiplier: 2,
        
        // Connection & Network
        .connectionTimeoutSeconds: 15,
        .maxReconnectionAttempts: 3,
        .heartbeatIntervalSeconds: 30,
        .dataCompressionEnabled: 1, // true
        
        // Player Preferences
        .allowRandomOpponents: 1, // true
        .showOpponentScore: 1, // true
        .enableChatFeatures: 0, // false (future feature)
        .autoAcceptRematch: 0, // false
        
        // Debug & Testing
        .debugModeEnabled: 0, // false
        .simulateNetworkDelay: 0,
        .forceConnectionLoss: 0, // false
        .logVerboseNetworking: 0, // false
        
        // Privacy & Game Center
        .shareStatistics: 1, // true
        .allowLeaderboards: 1, // true
        .enableAchievements: 1, // true
        .anonymousMode: 0 // false
    ]
    
    // MARK: - Initialization
    private init() {
        loadConfiguration()
        setupObservers()
        checkGameCenterAvailability()
        
        #if DEBUG
        debugModeActive = true
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Get multiplayer configuration with all current settings
    func getMultiplayerConfig() -> MultiplayerConfiguration {
        return MultiplayerConfiguration(
            maxMatchDuration: TimeInterval(getValue(for: .maxMatchDurationMinutes) * 60),
            turnTimeout: TimeInterval(getValue(for: .turnTimeoutSeconds)),
            maxConcurrentMatches: getValue(for: .maxConcurrentMatches),
            matchmakingTimeout: TimeInterval(getValue(for: .matchmakingTimeout)),
            winBonus: getValue(for: .winBonusPoints),
            resignationPenalty: getValue(for: .resignationPenalty),
            instantWinThreshold: getValue(for: .scoreThresholdForInstantWin),
            connectionTimeout: TimeInterval(getValue(for: .connectionTimeoutSeconds)),
            maxReconnectionAttempts: getValue(for: .maxReconnectionAttempts),
            heartbeatInterval: TimeInterval(getValue(for: .heartbeatIntervalSeconds)),
            dataCompressionEnabled: getBoolValue(for: .dataCompressionEnabled),
            allowRandomOpponents: getBoolValue(for: .allowRandomOpponents),
            showOpponentScore: getBoolValue(for: .showOpponentScore),
            enableChatFeatures: getBoolValue(for: .enableChatFeatures),
            autoAcceptRematch: getBoolValue(for: .autoAcceptRematch),
            shareStatistics: getBoolValue(for: .shareStatistics),
            allowLeaderboards: getBoolValue(for: .allowLeaderboards),
            enableAchievements: getBoolValue(for: .enableAchievements),
            anonymousMode: getBoolValue(for: .anonymousMode)
        )
    }
    
    /// Get configuration value for a specific key
    func getValue(for key: MultiplayerConfigKey) -> Int {
        return configValues[key]?.value ?? getDefaultValue(for: key)
    }
    
    /// Get boolean value for configuration keys that represent boolean settings
    func getBoolValue(for key: MultiplayerConfigKey) -> Bool {
        return getValue(for: key) != 0
    }
    
    /// Update settings with new configuration
    func updateSettings(_ newConfig: [MultiplayerConfigKey: Int]) {
        for (key, value) in newConfig {
            setValue(value, for: key)
        }
        
        print("MultiplayerConfig: Updated \(newConfig.count) settings")
        
        // Apply immediate effects for certain settings
        applyImmediateSettingsEffects()
    }
    
    /// Set configuration value for a specific key
    func setValue(_ value: Int, for key: MultiplayerConfigKey) {
        let validatedValue = validateValue(value, for: key)
        let configValue = MultiplayerConfigValue(key: key, value: validatedValue, isDefault: false)
        
        configValues[key] = configValue
        saveToUserDefaults(key: key, value: validatedValue)
        
        print("MultiplayerConfig: Set \(key.displayName) to \(validatedValue)")
        
        // Handle special settings that need immediate action
        handleSpecialSettings(key: key, value: validatedValue)
        
        // Notify dependent systems
        notifySystemsOfChange(key: key, value: validatedValue)
    }
    
    /// Enable debug multiplayer mode with testing configurations
    func debugMultiplayer(scenario: MultiplayerDebugScenario) {
        guard debugModeActive else {
            print("MultiplayerConfig: Debug mode not available in production")
            return
        }
        
        print("MultiplayerConfig: Applying debug scenario: \(scenario)")
        
        switch scenario {
        case .fastMatches:
            setValue(1, for: .maxMatchDurationMinutes)
            setValue(10, for: .turnTimeoutSeconds)
            setValue(5, for: .matchmakingTimeout)
            
        case .connectionTesting:
            setValue(1000, for: .simulateNetworkDelay)
            setValue(1, for: .logVerboseNetworking)
            setValue(1, for: .maxReconnectionAttempts)
            
        case .scoringTesting:
            setValue(10, for: .winBonusPoints)
            setValue(5, for: .resignationPenalty)
            setValue(100, for: .scoreThresholdForInstantWin)
            
        case .privacyTesting:
            setValue(1, for: .anonymousMode)
            setValue(0, for: .shareStatistics)
            setValue(0, for: .allowLeaderboards)
            
        case .highPerformance:
            setValue(0, for: .dataCompressionEnabled)
            setValue(60, for: .heartbeatIntervalSeconds)
            setValue(0, for: .logVerboseNetworking)
            
        case .resetToDefaults:
            resetAllToDefaults()
        }
        
        // Save debug settings immediately
        saveConfiguration()
    }
    
    /// Reset a specific key to its default value
    func resetToDefault(key: MultiplayerConfigKey) {
        let defaultValue = getDefaultValue(for: key)
        setValue(defaultValue, for: key)
        
        // Remove from UserDefaults to indicate it's using default
        UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key.rawValue)
        
        // Update config value to indicate it's using default
        configValues[key] = MultiplayerConfigValue(key: key, value: defaultValue, isDefault: true)
        
        print("MultiplayerConfig: Reset \(key.displayName) to default value: \(defaultValue)")
    }
    
    /// Reset all configuration to default values
    func resetAllToDefaults() {
        for key in MultiplayerConfigKey.allCases {
            resetToDefault(key: key)
        }
        
        print("MultiplayerConfig: Reset all values to defaults")
    }
    
    /// Export current configuration as JSON
    func exportConfiguration() -> Data? {
        let configurations = Dictionary(uniqueKeysWithValues: 
            configValues.map { (key, configValue) in
                (key.rawValue, configValue.value)
            }
        )
        
        let configJSON = MultiplayerConfigJSON(
            version: MultiplayerConfigJSON.currentVersion,
            timestamp: Date(),
            configurations: configurations,
            metadata: MultiplayerConfigJSON.ConfigMetadata(
                description: "Block Puzzle Game Multiplayer Configuration",
                author: "MultiplayerConfig System",
                environment: debugModeActive ? "development" : "production",
                targetVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            )
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(configJSON)
        } catch {
            print("MultiplayerConfig: Failed to export configuration: \(error)")
            return nil
        }
    }
    
    /// Import configuration from JSON data
    func importConfiguration(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let configJSON = try decoder.decode(MultiplayerConfigJSON.self, from: data)
            
            // Validate version compatibility
            guard configJSON.version == MultiplayerConfigJSON.currentVersion else {
                print("MultiplayerConfig: Version mismatch - expected \(MultiplayerConfigJSON.currentVersion), got \(configJSON.version)")
                return false
            }
            
            // Apply configurations
            var updatedCount = 0
            for (keyString, value) in configJSON.configurations {
                if let key = MultiplayerConfigKey(rawValue: keyString) {
                    setValue(value, for: key)
                    updatedCount += 1
                }
            }
            
            lastUpdateTimestamp = configJSON.timestamp
            
            print("MultiplayerConfig: Successfully imported \(updatedCount) configuration values")
            return true
            
        } catch {
            print("MultiplayerConfig: Failed to import configuration: \(error)")
            return false
        }
    }
    
    // MARK: - Accessibility Support
    
    /// Get accessibility description for a configuration key
    func getAccessibilityDescription(for key: MultiplayerConfigKey) -> String {
        let currentValue = getValue(for: key)
        let valueDescription = key.isBoolean ? (currentValue != 0 ? "enabled" : "disabled") : "\(currentValue)"
        
        return "\(key.displayName): \(valueDescription). \(key.description)"
    }
    
    /// Announce configuration change for accessibility
    func announceConfigurationChange(key: MultiplayerConfigKey, newValue: Int) {
        let announcement = "Multiplayer setting updated: \(getAccessibilityDescription(for: key))"
        
        // Use iOS accessibility announcement
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        isLoading = true
        
        // Load from UserDefaults first
        for key in MultiplayerConfigKey.allCases {
            let userDefaultsKey = userDefaultsPrefix + key.rawValue
            let storedValue = UserDefaults.standard.object(forKey: userDefaultsKey) as? Int
            
            let value = storedValue ?? getDefaultValue(for: key)
            let isDefault = storedValue == nil
            
            configValues[key] = MultiplayerConfigValue(key: key, value: value, isDefault: isDefault)
        }
        
        // Try to load from JSON file if available
        loadFromJSONFile()
        
        isLoading = false
        lastUpdateTimestamp = Date()
        
        print("MultiplayerConfig: Configuration loaded with \(configValues.count) values")
    }
    
    private func loadFromJSONFile() {
        guard let url = Bundle.main.url(forResource: configFileName.replacingOccurrences(of: ".json", with: ""), 
                                       withExtension: "json") else {
            print("MultiplayerConfig: No JSON configuration file found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            _ = importConfiguration(from: data)
        } catch {
            print("MultiplayerConfig: Failed to load JSON configuration: \(error)")
        }
    }
    
    private func setupObservers() {
        // Observe Game Center authentication state
        NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)
            .sink { [weak self] _ in
                self?.checkGameCenterAvailability()
            }
            .store(in: &cancellables)
    }
    
    private func checkGameCenterAvailability() {
        gameCenterAvailable = GKLocalPlayer.local.isAuthenticated
        
        // Automatically disable Game Center features if not available
        if !gameCenterAvailable {
            setValue(0, for: .shareStatistics)
            setValue(0, for: .allowLeaderboards)
            setValue(0, for: .enableAchievements)
        }
    }
    
    private func getDefaultValue(for key: MultiplayerConfigKey) -> Int {
        return defaultValues[key] ?? 0
    }
    
    private func validateValue(_ value: Int, for key: MultiplayerConfigKey) -> Int {
        let configValue = MultiplayerConfigValue(key: key, value: value, isDefault: false)
        
        if configValue.isValid {
            return value
        } else {
            let defaultValue = getDefaultValue(for: key)
            print("MultiplayerConfig: Invalid value \(value) for \(key.displayName), using default: \(defaultValue)")
            return defaultValue
        }
    }
    
    private func saveToUserDefaults(key: MultiplayerConfigKey, value: Int) {
        let userDefaultsKey = userDefaultsPrefix + key.rawValue
        UserDefaults.standard.set(value, forKey: userDefaultsKey)
    }
    
    private func saveConfiguration() {
        // Save all current values to UserDefaults
        for (key, configValue) in configValues {
            if !configValue.isDefault {
                saveToUserDefaults(key: key, value: configValue.value)
            }
        }
        
        lastUpdateTimestamp = Date()
        print("MultiplayerConfig: Configuration saved")
    }
    
    private func handleSpecialSettings(key: MultiplayerConfigKey, value: Int) {
        switch key {
        case .debugModeEnabled:
            debugModeActive = value != 0
            
        case .anonymousMode:
            if value != 0 {
                // When anonymous mode is enabled, disable sharing features
                setValue(0, for: .shareStatistics)
                setValue(0, for: .allowLeaderboards)
            }
            
        default:
            break
        }
        
        // Always check Game Center availability when privacy settings change
        if key == .shareStatistics || key == .allowLeaderboards || key == .enableAchievements {
            checkGameCenterAvailability()
        }
    }
    
    private func applyImmediateSettingsEffects() {
        // Apply settings that need immediate effect
        if getBoolValue(for: .debugModeEnabled) && debugModeActive {
            print("MultiplayerConfig: Debug mode activated with enhanced logging")
        }
        
        // Update networking configurations
        NotificationCenter.default.post(
            name: .multiplayerConfigurationChanged, 
            object: self, 
            userInfo: ["config": getMultiplayerConfig()]
        )
    }
    
    private func notifySystemsOfChange(key: MultiplayerConfigKey, value: Int) {
        // Announce for accessibility
        announceConfigurationChange(key: key, newValue: value)
        
        // Post notification for dependent systems
        NotificationCenter.default.post(
            name: .multiplayerSettingChanged,
            object: self,
            userInfo: [
                "key": key,
                "value": value,
                "config": getMultiplayerConfig()
            ]
        )
    }
}

// MARK: - Supporting Types

/// Debug scenarios for multiplayer testing
enum MultiplayerDebugScenario: String, CaseIterable {
    case fastMatches = "Fast Matches"
    case connectionTesting = "Connection Testing"
    case scoringTesting = "Scoring Testing"
    case privacyTesting = "Privacy Testing"
    case highPerformance = "High Performance"
    case resetToDefaults = "Reset to Defaults"
    
    var description: String {
        switch self {
        case .fastMatches: return "Quick matches for rapid testing"
        case .connectionTesting: return "Simulate network issues and delays"
        case .scoringTesting: return "Lower thresholds for scoring system testing"
        case .privacyTesting: return "Enable privacy modes and disable sharing"
        case .highPerformance: return "Optimize for performance over features"
        case .resetToDefaults: return "Reset all settings to default values"
        }
    }
}

/// Complete multiplayer configuration structure
struct MultiplayerConfiguration {
    let maxMatchDuration: TimeInterval
    let turnTimeout: TimeInterval
    let maxConcurrentMatches: Int
    let matchmakingTimeout: TimeInterval
    let winBonus: Int
    let resignationPenalty: Int
    let instantWinThreshold: Int
    let connectionTimeout: TimeInterval
    let maxReconnectionAttempts: Int
    let heartbeatInterval: TimeInterval
    let dataCompressionEnabled: Bool
    let allowRandomOpponents: Bool
    let showOpponentScore: Bool
    let enableChatFeatures: Bool
    let autoAcceptRematch: Bool
    let shareStatistics: Bool
    let allowLeaderboards: Bool
    let enableAchievements: Bool
    let anonymousMode: Bool
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let multiplayerConfigurationChanged = Notification.Name("multiplayerConfigurationChanged")
    static let multiplayerSettingChanged = Notification.Name("multiplayerSettingChanged")
}
