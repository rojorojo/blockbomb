//
//  PowerupShopSystemTests.swift
//  blockbombTests
//
//  Created by Robert Johnson on 6/10/25.
//

import Testing
import Foundation
@testable import blockbomb

/// Comprehensive test suite for the Powerup Shop system
struct PowerupShopSystemTests {
    
    // MARK: - PowerupShopManager Tests
    
    @Test func testPowerupShopManagerInitialization() async throws {
        let manager = PowerupShopManager.shared
        
        // Verify initialization
        let powerups = manager.getPowerups()
        #expect(powerups.count > 0, "Shop should have powerups available")
        
        // Verify revive heart is available
        let reviveHeart = manager.getPowerup(type: .reviveHeart)
        #expect(reviveHeart != nil, "Revive heart should be available")
        #expect(reviveHeart?.isAvailable == true, "Revive heart should be available for purchase")
        #expect(reviveHeart?.price == 20, "Revive heart should cost 20 points")
    }
    
    @Test func testGetPowerups() async throws {
        let manager = PowerupShopManager.shared
        
        let powerups = manager.getPowerups()
        
        // Should contain all defined powerup types
        let reviveHeart = powerups.first(where: { $0.type == .reviveHeart })
        #expect(reviveHeart != nil, "Powerups should include revive heart")
        
        // Verify powerup structure
        if let reviveHeart = reviveHeart {
            #expect(reviveHeart.displayName == "Revive Heart", "Display name should be correct")
            #expect(reviveHeart.description.contains("Continue playing"), "Description should be meaningful")
            #expect(reviveHeart.price == 20, "Price should be configured correctly")
        }
    }
    
    @Test func testCanPurchase() async throws {
        let manager = PowerupShopManager.shared
        let currencyManager = PowerupCurrencyManager.shared
        
        // Reset to known state
        currencyManager.debugSetPoints(0)
        
        // Test with insufficient funds
        #expect(!manager.canPurchase(.reviveHeart), "Should not be able to purchase with 0 points")
        
        // Test with sufficient funds
        currencyManager.debugSetPoints(50)
        #expect(manager.canPurchase(.reviveHeart), "Should be able to purchase with sufficient points")
        
        // Test with unavailable item
        manager.debugMakeAllUnavailable()
        #expect(!manager.canPurchase(.reviveHeart), "Should not be able to purchase unavailable items")
        
        // Reset availability
        manager.updateAvailability(for: .reviveHeart, available: true)
    }
    
    @Test func testSuccessfulPurchase() async throws {
        let manager = PowerupShopManager.shared
        let currencyManager = PowerupCurrencyManager.shared
        let heartManager = ReviveHeartManager.shared
        
        // Reset to known state
        currencyManager.debugSetPoints(50)
        let initialHearts = heartManager.getHeartCount()
        let initialPoints = currencyManager.getPoints()
        
        // Ensure revive heart is available
        manager.updateAvailability(for: .reviveHeart, available: true)
        
        // Purchase revive heart
        let result = manager.purchasePowerup(.reviveHeart)
        
        #expect(result.isSuccess, "Purchase should succeed")
        #expect(currencyManager.getPoints() == initialPoints - 20, "Points should be deducted")
        #expect(heartManager.getHeartCount() == initialHearts + 1, "Hearts should be added")
    }
    
    @Test func testInsufficientFundsPurchase() async throws {
        let manager = PowerupShopManager.shared
        let currencyManager = PowerupCurrencyManager.shared
        let heartManager = ReviveHeartManager.shared
        
        // Reset to known state with insufficient funds
        currencyManager.debugSetPoints(10) // Less than 20 required
        let initialHearts = heartManager.getHeartCount()
        let initialPoints = currencyManager.getPoints()
        
        // Ensure revive heart is available
        manager.updateAvailability(for: .reviveHeart, available: true)
        
        // Attempt purchase
        let result = manager.purchasePowerup(.reviveHeart)
        
        #expect(!result.isSuccess, "Purchase should fail")
        if case .insufficientFunds = result {
            // This is expected
        } else {
            #expect(false, "Result should be insufficientFunds")
        }
        
        #expect(currencyManager.getPoints() == initialPoints, "Points should not change")
        #expect(heartManager.getHeartCount() == initialHearts, "Hearts should not change")
    }
    
    @Test func testUnavailableItemPurchase() async throws {
        let manager = PowerupShopManager.shared
        let currencyManager = PowerupCurrencyManager.shared
        let heartManager = ReviveHeartManager.shared
        
        // Reset to known state
        currencyManager.debugSetPoints(50)
        let initialHearts = heartManager.getHeartCount()
        let initialPoints = currencyManager.getPoints()
        
        // Make revive heart unavailable
        manager.updateAvailability(for: .reviveHeart, available: false)
        
        // Attempt purchase
        let result = manager.purchasePowerup(.reviveHeart)
        
        #expect(!result.isSuccess, "Purchase should fail")
        if case .itemNotAvailable = result {
            // This is expected
        } else {
            #expect(false, "Result should be itemNotAvailable")
        }
        
        #expect(currencyManager.getPoints() == initialPoints, "Points should not change")
        #expect(heartManager.getHeartCount() == initialHearts, "Hearts should not change")
        
        // Reset availability for other tests
        manager.updateAvailability(for: .reviveHeart, available: true)
    }
    
    @Test func testGetPrice() async throws {
        let manager = PowerupShopManager.shared
        
        // Test getting price for available powerup
        let reviveHeartPrice = manager.getPrice(for: .reviveHeart)
        #expect(reviveHeartPrice == 20, "Revive heart price should be 20")
        
        // Test updating price
        manager.updatePrice(for: .reviveHeart, price: 25)
        let updatedPrice = manager.getPrice(for: .reviveHeart)
        #expect(updatedPrice == 25, "Updated price should be reflected")
        
        // Reset price
        manager.updatePrice(for: .reviveHeart, price: 20)
    }
    
    @Test func testIsAvailable() async throws {
        let manager = PowerupShopManager.shared
        
        // Test default availability
        #expect(manager.isAvailable(.reviveHeart), "Revive heart should be available by default")
        // TODO: Temporarily hidden - will be enabled in future update
        // #expect(!manager.isAvailable(.futureBonus1), "Future bonuses should not be available by default")
        
        // TODO: Temporarily hidden - will be enabled in future update  
        // Test updating availability
        // manager.updateAvailability(for: .futureBonus1, available: true)
        // #expect(manager.isAvailable(.futureBonus1), "Future bonus should be available after update")
        
        // manager.updateAvailability(for: .futureBonus1, available: false)
        // #expect(!manager.isAvailable(.futureBonus1), "Future bonus should be unavailable after update")
    }
    
    @Test func testUpdatePriceAndAvailability() async throws {
        let manager = PowerupShopManager.shared
        
        // Test updating price with validation
        manager.updatePrice(for: .reviveHeart, price: 30)
        #expect(manager.getPrice(for: .reviveHeart) == 30, "Price should be updated")
        
        // Test negative price (should be rejected)
        manager.updatePrice(for: .reviveHeart, price: -5)
        #expect(manager.getPrice(for: .reviveHeart) == 30, "Negative price should be rejected")
        
        // Test availability updates
        manager.updateAvailability(for: .reviveHeart, available: false)
        #expect(!manager.isAvailable(.reviveHeart), "Availability should be updated")
        
        // Reset to defaults
        manager.updatePrice(for: .reviveHeart, price: 20)
        manager.updateAvailability(for: .reviveHeart, available: true)
    }
    
    @Test func testGetPowerupByType() async throws {
        let manager = PowerupShopManager.shared
        
        // Test getting existing powerup
        let reviveHeart = manager.getPowerup(type: .reviveHeart)
        #expect(reviveHeart != nil, "Should find revive heart powerup")
        #expect(reviveHeart?.type == .reviveHeart, "Should return correct powerup type")
        
        // Make item unavailable and test again
        manager.updateAvailability(for: .reviveHeart, available: false)
        let unavailableHeart = manager.getPowerup(type: .reviveHeart)
        #expect(unavailableHeart?.isAvailable == false, "Should reflect availability status")
        
        // Reset availability
        manager.updateAvailability(for: .reviveHeart, available: true)
    }
    
    // MARK: - PowerupType Tests
    
    @Test func testPowerupTypeProperties() async throws {
        // Test revive heart properties
        #expect(PowerupType.reviveHeart.displayName == "Revive Heart", "Display name should be correct")
        #expect(PowerupType.reviveHeart.description.contains("Continue"), "Description should be meaningful")
        #expect(PowerupType.reviveHeart.rawValue == "revive_heart", "Raw value should be correct")
        
        // TODO: Temporarily hidden - will be enabled in future update
        // Test future bonus properties
        // #expect(PowerupType.futureBonus1.displayName == "Future Bonus 1", "Display name should be correct")
        // #expect(PowerupType.futureBonus1.description.contains("Coming soon"), "Description should indicate coming soon")
    }
    
    @Test func testPowerupTypeAllCases() async throws {
        let allTypes = PowerupType.allCases
        #expect(allTypes.contains(.reviveHeart), "All cases should include revive heart")
        // TODO: Temporarily hidden - will be enabled in future update
        // #expect(allTypes.contains(.futureBonus1), "All cases should include future bonus 1")
        // #expect(allTypes.contains(.futureBonus2), "All cases should include future bonus 2")
        // #expect(allTypes.contains(.futureBonus3), "All cases should include future bonus 3")
    }
    
    // MARK: - PurchaseResult Tests
    
    @Test func testPurchaseResultProperties() async throws {
        // Test success result
        let success = PurchaseResult.success
        #expect(success.isSuccess, "Success result should be success")
        #expect(success.errorMessage == nil, "Success result should have no error message")
        
        // Test insufficient funds result
        let insufficientFunds = PurchaseResult.insufficientFunds
        #expect(!insufficientFunds.isSuccess, "Insufficient funds result should not be success")
        #expect(insufficientFunds.errorMessage != nil, "Insufficient funds result should have error message")
        
        // Test item not available result
        let notAvailable = PurchaseResult.itemNotAvailable
        #expect(!notAvailable.isSuccess, "Not available result should not be success")
        #expect(notAvailable.errorMessage != nil, "Not available result should have error message")
        
        // Test purchase error result
        let purchaseError = PurchaseResult.purchaseError("Test error")
        #expect(!purchaseError.isSuccess, "Purchase error result should not be success")
        #expect(purchaseError.errorMessage == "Test error", "Purchase error should have custom message")
    }
    
    // MARK: - Debug Method Tests
    
    @Test func testDebugResetPrices() async throws {
        let manager = PowerupShopManager.shared
        
        // Change prices
        manager.updatePrice(for: .reviveHeart, price: 100)
        // TODO: Temporarily hidden - will be enabled in future update
        // manager.updatePrice(for: .futureBonus1, price: 200)
        
        // Reset prices
        manager.debugResetPrices()
        
        // Verify reset
        #expect(manager.getPrice(for: .reviveHeart) == 20, "Revive heart price should be reset to 20")
        // TODO: Temporarily hidden - will be enabled in future update
        // #expect(manager.getPrice(for: .futureBonus1) == 50, "Future bonus 1 price should be reset to 50")
    }
    
    @Test func testDebugMakeAllAvailable() async throws {
        let manager = PowerupShopManager.shared
        
        // Make all unavailable first
        manager.debugMakeAllUnavailable()
        
        // Make all available
        manager.debugMakeAllAvailable()
        
        // Verify all are available
        for type in PowerupType.allCases {
            #expect(manager.isAvailable(type), "\(type.displayName) should be available")
        }
    }
    
    @Test func testDebugMakeAllUnavailable() async throws {
        let manager = PowerupShopManager.shared
        
        // Make all available first
        manager.debugMakeAllAvailable()
        
        // Make all unavailable
        manager.debugMakeAllUnavailable()
        
        // Verify all are unavailable
        for type in PowerupType.allCases {
            #expect(!manager.isAvailable(type), "\(type.displayName) should be unavailable")
        }
        
        // Reset for other tests
        manager.updateAvailability(for: .reviveHeart, available: true)
    }
    
    @Test func testDebugTestPurchase() async throws {
        let manager = PowerupShopManager.shared
        let heartManager = ReviveHeartManager.shared
        
        // Set up for testing
        manager.updateAvailability(for: .reviveHeart, available: true)
        let initialHearts = heartManager.getHeartCount()
        
        // Test debug purchase (should not spend points)
        let result = manager.debugTestPurchase(.reviveHeart)
        
        #expect(result.isSuccess, "Debug purchase should succeed")
        #expect(heartManager.getHeartCount() == initialHearts + 1, "Hearts should be added")
    }
    
    // MARK: - Integration Tests
    
    @Test func testCompleteReviveHeartPurchaseFlow() async throws {
        let shopManager = PowerupShopManager.shared
        let currencyManager = PowerupCurrencyManager.shared
        let heartManager = ReviveHeartManager.shared
        
        // Reset to clean state
        currencyManager.debugSetPoints(0)
        let initialHearts = heartManager.getHeartCount()
        
        // Player watches 2 ads to earn enough for revive heart
        currencyManager.awardAdPoints() // 10 points
        currencyManager.awardAdPoints() // 20 points total
        
        // Check if purchase is possible
        #expect(shopManager.canPurchase(.reviveHeart), "Should be able to purchase after earning enough points")
        
        // Make purchase
        let result = shopManager.purchasePowerup(.reviveHeart)
        
        // Verify successful transaction
        #expect(result.isSuccess, "Purchase should succeed")
        #expect(currencyManager.getPoints() == 0, "Points should be spent")
        #expect(heartManager.getHeartCount() == initialHearts + 1, "Hearts should be added")
    }
    
    @Test func testMultiplePurchases() async throws {
        let shopManager = PowerupShopManager.shared
        let currencyManager = PowerupCurrencyManager.shared
        let heartManager = ReviveHeartManager.shared
        
        // Reset to clean state
        currencyManager.debugSetPoints(100) // Enough for 5 revive hearts
        let initialHearts = heartManager.getHeartCount()
        
        // Purchase multiple revive hearts
        for i in 1...3 {
            let result = shopManager.purchasePowerup(.reviveHeart)
            #expect(result.isSuccess, "Purchase \(i) should succeed")
        }
        
        // Verify final state
        #expect(currencyManager.getPoints() == 40, "Should have 40 points remaining (100 - 60)")
        #expect(heartManager.getHeartCount() == initialHearts + 3, "Should have 3 additional hearts")
    }
    
    @Test func testShopConfigurationPersistence() async throws {
        let manager = PowerupShopManager.shared
        
        // Change configuration
        manager.updatePrice(for: .reviveHeart, price: 25)
        // TODO: Temporarily hidden - will be enabled in future update
        // manager.updateAvailability(for: .futureBonus1, available: true)
        
        // Verify changes are reflected in shop
        let powerups = manager.getPowerups()
        let reviveHeart = powerups.first(where: { $0.type == .reviveHeart })
        // TODO: Temporarily hidden - will be enabled in future update
        // let futureBonus = powerups.first(where: { $0.type == .futureBonus1 })
        
        #expect(reviveHeart?.price == 25, "Price change should be reflected")
        // TODO: Temporarily hidden - will be enabled in future update
        // #expect(futureBonus?.isAvailable == true, "Availability change should be reflected")
        
        // Reset for cleanup
        manager.debugResetPrices()
        // TODO: Temporarily hidden - will be enabled in future update
        // manager.updateAvailability(for: .futureBonus1, available: false)
    }
}
