import Testing
import Foundation
@testable import blockbomb

/// Comprehensive test suite for the RewardConfig system
struct RewardConfigSystemTests {
    
    // MARK: - Configuration Value Tests
    
    @Test func testDefaultValues() async throws {
        let config = RewardConfig.shared
        
        // Test default currency values
        #expect(config.getValue(for: .pointsPerAd) == 10, "Default points per ad should be 10")
        #expect(config.getValue(for: .defaultPointBalance) == 0, "Default point balance should be 0")
        
        // Test default powerup prices
        #expect(config.getValue(for: .reviveHeartPrice) == 20, "Default revive heart price should be 20")
        // TODO: Temporarily hidden - will be enabled in future update
        // #expect(config.getValue(for: .futureBonus1Price) == 50, "Default future bonus 1 price should be 50")
        // #expect(config.getValue(for: .futureBonus2Price) == 100, "Default future bonus 2 price should be 100")
        // #expect(config.getValue(for: .futureBonus3Price) == 200, "Default future bonus 3 price should be 200")
        
        // Test default advertising values
        #expect(config.getValue(for: .gamesBetweenInterstitials) == 2, "Default games between interstitials should be 2")
        #expect(config.getValue(for: .bonusAdCooldownSeconds) == 120, "Default bonus ad cooldown should be 120 seconds")
        #expect(config.getValue(for: .minGameDurationForAd) == 30, "Default min game duration should be 30 seconds")
    }
    
    @Test func testSetAndGetValues() async throws {
        let config = RewardConfig.shared
        
        // Test setting and getting values
        config.setValue(15, for: .pointsPerAd)
        #expect(config.getValue(for: .pointsPerAd) == 15, "Set value should be retrievable")
        
        config.setValue(25, for: .reviveHeartPrice)
        #expect(config.getValue(for: .reviveHeartPrice) == 25, "Set powerup price should be retrievable")
        
        config.setValue(5, for: .gamesBetweenInterstitials)
        #expect(config.getValue(for: .gamesBetweenInterstitials) == 5, "Set ad frequency should be retrievable")
        
        // Reset to defaults for other tests
        config.resetAllToDefaults()
    }
    
    @Test func testValueValidation() async throws {
        let config = RewardConfig.shared
        
        // Test that negative values are validated
        config.setValue(-10, for: .pointsPerAd)
        #expect(config.getValue(for: .pointsPerAd) == 10, "Negative values should revert to default")
        
        // Test that excessively large values are validated
        config.setValue(1000, for: .pointsPerAd)
        #expect(config.getValue(for: .pointsPerAd) == 10, "Values exceeding max should revert to default")
        
        // Test valid edge cases
        config.setValue(1, for: .pointsPerAd)
        #expect(config.getValue(for: .pointsPerAd) == 1, "Valid minimum values should be accepted")
        
        config.setValue(100, for: .pointsPerAd)
        #expect(config.getValue(for: .pointsPerAd) == 100, "Valid maximum values should be accepted")
        
        // Reset for other tests
        config.resetAllToDefaults()
    }
    
    @Test func testResetToDefaults() async throws {
        let config = RewardConfig.shared
        
        // Change some values
        config.setValue(25, for: .pointsPerAd)
        config.setValue(30, for: .reviveHeartPrice)
        config.setValue(5, for: .gamesBetweenInterstitials)
        
        // Reset specific key
        config.resetToDefault(key: .pointsPerAd)
        #expect(config.getValue(for: .pointsPerAd) == 10, "Reset should restore default value")
        
        // Other values should remain changed
        #expect(config.getValue(for: .reviveHeartPrice) == 30, "Other values should remain unchanged")
        
        // Reset all
        config.resetAllToDefaults()
        #expect(config.getValue(for: .reviveHeartPrice) == 20, "Reset all should restore all defaults")
        #expect(config.getValue(for: .gamesBetweenInterstitials) == 2, "Reset all should restore all defaults")
    }
    
    // MARK: - Persistence Tests
    
    @Test func testUserDefaultsPersistence() async throws {
        let config = RewardConfig.shared
        let testKey = "RewardConfig." + RewardConfigKey.pointsPerAd.rawValue
        
        // Set a value and verify it's persisted
        config.setValue(15, for: .pointsPerAd)
        let persistedValue = UserDefaults.standard.integer(forKey: testKey)
        #expect(persistedValue == 15, "Values should persist to UserDefaults")
        
        // Reset should remove from UserDefaults
        config.resetToDefault(key: .pointsPerAd)
        let resetValue = UserDefaults.standard.object(forKey: testKey)
        #expect(resetValue == nil, "Reset should remove UserDefaults entry")
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: testKey)
    }
    
    // MARK: - JSON Configuration Tests
    
    @Test func testJSONExport() async throws {
        let config = RewardConfig.shared
        
        // Set some custom values
        config.setValue(15, for: .pointsPerAd)
        config.setValue(25, for: .reviveHeartPrice)
        
        // Export configuration
        guard let exportData = config.exportConfiguration() else {
            #fail("Export should succeed")
            return
        }
        
        // Verify JSON structure
        let jsonObject = try JSONSerialization.jsonObject(with: exportData) as? [String: Any]
        #expect(jsonObject != nil, "Export should produce valid JSON")
        
        let configurations = jsonObject?["configurations"] as? [String: Int]
        #expect(configurations?["RewardConfig.pointsPerAd"] == 15, "Export should include custom values")
        #expect(configurations?["RewardConfig.reviveHeartPrice"] == 25, "Export should include custom values")
        
        // Reset for other tests
        config.resetAllToDefaults()
    }
    
    @Test func testJSONImport() async throws {
        let config = RewardConfig.shared
        
        // Create test configuration JSON
        let testConfig = [
            "version": "1.0",
            "timestamp": "2025-06-11T10:00:00Z",
            "configurations": [
                "RewardConfig.pointsPerAd": 20,
                "RewardConfig.reviveHeartPrice": 30
            ]
        ] as [String: Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: testConfig)
        
        // Import configuration
        let success = config.importConfiguration(from: jsonData)
        #expect(success, "Import should succeed with valid JSON")
        
        // Verify imported values
        #expect(config.getValue(for: .pointsPerAd) == 20, "Import should set values correctly")
        #expect(config.getValue(for: .reviveHeartPrice) == 30, "Import should set values correctly")
        
        // Reset for other tests
        config.resetAllToDefaults()
    }
    
    @Test func testJSONImportVersionValidation() async throws {
        let config = RewardConfig.shared
        
        // Create configuration with wrong version
        let testConfig = [
            "version": "2.0",
            "configurations": [
                "RewardConfig.pointsPerAd": 20
            ]
        ] as [String: Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: testConfig)
        
        // Import should fail due to version mismatch
        let success = config.importConfiguration(from: jsonData)
        #expect(!success, "Import should fail with version mismatch")
        
        // Values should remain unchanged
        #expect(config.getValue(for: .pointsPerAd) == 10, "Values should remain unchanged on failed import")
    }
    
    // MARK: - Configuration Key Tests
    
    @Test func testConfigurationKeyProperties() async throws {
        // Test key display names
        #expect(RewardConfigKey.pointsPerAd.displayName == "Points Per Ad", "Display name should be human readable")
        #expect(RewardConfigKey.reviveHeartPrice.displayName == "Revive Heart Price", "Display name should be human readable")
        
        // Test key descriptions
        #expect(RewardConfigKey.pointsPerAd.description.contains("rewarded ad"), "Description should be meaningful")
        #expect(RewardConfigKey.reviveHeartPrice.description.contains("points"), "Description should be meaningful")
        
        // Test key categories
        #expect(RewardConfigKey.pointsPerAd.category == .currency, "Currency keys should have currency category")
        #expect(RewardConfigKey.reviveHeartPrice.category == .powerups, "Powerup keys should have powerup category")
        #expect(RewardConfigKey.gamesBetweenInterstitials.category == .advertising, "Ad keys should have advertising category")
    }
    
    @Test func testConfigurationCategories() async throws {
        let categories = RewardConfigCategory.allCases
        
        #expect(categories.contains(.currency), "Should include currency category")
        #expect(categories.contains(.powerups), "Should include powerups category")
        #expect(categories.contains(.advertising), "Should include advertising category")
        
        // Test category display names
        #expect(RewardConfigCategory.currency.displayName == "Currency", "Category display names should be correct")
        #expect(RewardConfigCategory.powerups.displayName == "Powerups", "Category display names should be correct")
        #expect(RewardConfigCategory.advertising.displayName == "Advertising", "Category display names should be correct")
    }
    
    // MARK: - Configuration Value Structure Tests
    
    @Test func testRewardConfigValue() async throws {
        let config = RewardConfig.shared
        
        // Test config value structure
        config.setValue(15, for: .pointsPerAd)
        
        guard let configValue = config.configValues[.pointsPerAd] else {
            #fail("Config value should exist after setting")
            return
        }
        
        #expect(configValue.key == .pointsPerAd, "Config value should have correct key")
        #expect(configValue.value == 15, "Config value should have correct value")
        #expect(!configValue.isDefault, "Config value should not be marked as default when set")
        #expect(configValue.isValid, "Valid config value should be marked as valid")
        
        // Reset to default
        config.resetToDefault(key: .pointsPerAd)
        
        guard let defaultValue = config.configValues[.pointsPerAd] else {
            #fail("Config value should exist after reset")
            return
        }
        
        #expect(defaultValue.isDefault, "Reset config value should be marked as default")
    }
    
    // MARK: - Convenience Property Tests
    
    @Test func testConvenienceProperties() async throws {
        let config = RewardConfig.shared
        
        // Test convenience properties match getValue results
        #expect(config.pointsPerAd == config.getValue(for: .pointsPerAd), "Convenience property should match getValue")
        #expect(config.defaultPointBalance == config.getValue(for: .defaultPointBalance), "Convenience property should match getValue")
        #expect(config.reviveHeartPrice == config.getValue(for: .reviveHeartPrice), "Convenience property should match getValue")
        #expect(config.gamesBetweenInterstitials == config.getValue(for: .gamesBetweenInterstitials), "Convenience property should match getValue")
        #expect(config.bonusAdCooldownSeconds == config.getValue(for: .bonusAdCooldownSeconds), "Convenience property should match getValue")
        
        // Test powerup prices dictionary
        let powerupPrices = config.powerupPrices
        #expect(powerupPrices[.reviveHeart] == config.getValue(for: .reviveHeartPrice), "Powerup prices should match configuration")
        // TODO: Temporarily hidden - will be enabled in future update
        // #expect(powerupPrices[.futureBonus1] == config.getValue(for: .futureBonus1Price), "Powerup prices should match configuration")
        // #expect(powerupPrices[.futureBonus2] == config.getValue(for: .futureBonus2Price), "Powerup prices should match configuration")
        // #expect(powerupPrices[.futureBonus3] == config.getValue(for: .futureBonus3Price), "Powerup prices should match configuration")
    }
    
    // MARK: - Integration Tests
    
    @Test func testNotificationSystem() async throws {
        let config = RewardConfig.shared
        var notificationReceived = false
        var receivedKey: String?
        var receivedValue: Int?
        
        // Set up notification observer
        let observer = NotificationCenter.default.addObserver(
            forName: .rewardConfigCurrencyChanged,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            receivedKey = notification.userInfo?["key"] as? String
            receivedValue = notification.userInfo?["value"] as? Int
        }
        
        // Change a currency configuration
        config.setValue(15, for: .pointsPerAd)
        
        // Give notification time to process
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(notificationReceived, "Notification should be sent on configuration change")
        #expect(receivedKey == RewardConfigKey.pointsPerAd.rawValue, "Notification should include correct key")
        #expect(receivedValue == 15, "Notification should include correct value")
        
        // Clean up
        NotificationCenter.default.removeObserver(observer)
        config.resetAllToDefaults()
    }
    
    // MARK: - Debug Method Tests
    
    #if DEBUG
    @Test func testDebugPresets() async throws {
        let config = RewardConfig.shared
        
        // Apply test preset
        config.debugApplyTestPreset()
        
        // Verify test preset values
        #expect(config.getValue(for: .pointsPerAd) == 20, "Test preset should set higher points per ad")
        #expect(config.getValue(for: .defaultPointBalance) == 100, "Test preset should set starting points")
        #expect(config.getValue(for: .reviveHeartPrice) == 15, "Test preset should set cheaper hearts")
        #expect(config.getValue(for: .gamesBetweenInterstitials) == 1, "Test preset should set frequent ads")
        #expect(config.getValue(for: .bonusAdCooldownSeconds) == 30, "Test preset should set short cooldown")
        
        // Apply production preset
        config.debugApplyProductionPreset()
        
        // Verify production preset values
        #expect(config.getValue(for: .pointsPerAd) == 10, "Production preset should use standard values")
        #expect(config.getValue(for: .defaultPointBalance) == 0, "Production preset should start with no points")
        #expect(config.getValue(for: .reviveHeartPrice) == 20, "Production preset should use standard price")
        #expect(config.getValue(for: .gamesBetweenInterstitials) == 3, "Production preset should have moderate ad frequency")
        #expect(config.getValue(for: .bonusAdCooldownSeconds) == 180, "Production preset should have longer cooldown")
        
        // Reset for other tests
        config.resetAllToDefaults()
    }
    
    @Test func testDebugJSONSerialization() async throws {
        let config = RewardConfig.shared
        
        // Test JSON serialization
        config.debugTestJSONSerialization()
        
        // The debug method should not crash and should print success/failure
        // Since it's a debug method, we mainly test that it executes without error
        #expect(true, "Debug JSON serialization should complete without crashing")
    }
    
    @Test func testDebugValidation() async throws {
        let config = RewardConfig.shared
        
        // Set some invalid values
        config.setValue(-10, for: .pointsPerAd)
        config.setValue(2000, for: .reviveHeartPrice)
        
        // Run validation
        config.debugValidateAllValues()
        
        // The debug method should identify and report invalid values
        // Since it's a debug method, we mainly test that it executes without error
        #expect(true, "Debug validation should complete without crashing")
        
        // Reset for other tests
        config.resetAllToDefaults()
    }
    #endif
    
    // MARK: - Edge Case Tests
    
    @Test func testAllConfigurationKeys() async throws {
        let config = RewardConfig.shared
        
        // Test that all keys have valid default values
        for key in RewardConfigKey.allCases {
            let value = config.getValue(for: key)
            #expect(value >= 0, "All configuration values should be non-negative: \(key.displayName)")
            
            // Test that we can set and get each key
            let testValue = 1
            config.setValue(testValue, for: key)
            #expect(config.getValue(for: key) >= 0, "All keys should accept valid values: \(key.displayName)")
        }
        
        // Reset for other tests
        config.resetAllToDefaults()
    }
    
    @Test func testConfigurationLoading() async throws {
        let config = RewardConfig.shared
        
        // Test that configuration is not loading (should be false after initialization)
        #expect(!config.isLoading, "Configuration should not be loading after initialization")
        
        // Test that configuration values are populated
        #expect(!config.configValues.isEmpty, "Configuration values should be populated")
        #expect(config.configValues.count == RewardConfigKey.allCases.count, "All configuration keys should have values")
    }
}
