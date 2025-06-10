import XCTest
import SwiftUI
@testable import blockbomb

class PowerupIntegrationTests: XCTestCase {
    
    var currencyManager: PowerupCurrencyManager!
    var shopManager: PowerupShopManager!
    var reviveHeartManager: ReviveHeartManager!
    
    override func setUp() {
        super.setUp()
        currencyManager = PowerupCurrencyManager.shared
        shopManager = PowerupShopManager.shared
        reviveHeartManager = ReviveHeartManager.shared
        
        // Reset all managers to clean state
        currencyManager.resetPoints()
        reviveHeartManager.resetHearts()
    }
    
    override func tearDown() {
        currencyManager.resetPoints()
        reviveHeartManager.resetHearts()
        super.tearDown()
    }
    
    // MARK: - Integration Flow Tests
    
    func testCompleteAdToHeartFlow() {
        // Given: Player has no hearts or coins
        XCTAssertEqual(currencyManager.currentPoints, 0)
        XCTAssertEqual(reviveHeartManager.heartCount, 0)
        XCTAssertFalse(reviveHeartManager.hasHearts())
        
        // When: Player watches 2 ads (20 points total)
        currencyManager.awardAdPoints() // +10 points
        currencyManager.awardAdPoints() // +10 points
        
        // Then: Player should have enough coins to buy a heart
        XCTAssertEqual(currencyManager.currentPoints, 20)
        XCTAssertTrue(shopManager.canPurchase(.reviveHeart))
        
        // When: Player purchases a revive heart
        let result = shopManager.purchasePowerup(.reviveHeart)
        
        // Then: Purchase should succeed, coins spent, heart added
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(currencyManager.currentPoints, 0)
        XCTAssertEqual(reviveHeartManager.heartCount, 1)
        XCTAssertTrue(reviveHeartManager.hasHearts())
    }
    
    func testInsufficientFundsFlow() {
        // Given: Player has some coins but not enough for a heart
        currencyManager.addPoints(10) // Only 10 points, need 20
        
        // Then: Should not be able to purchase
        XCTAssertFalse(shopManager.canPurchase(.reviveHeart))
        
        // When: Attempting to purchase anyway
        let result = shopManager.purchasePowerup(.reviveHeart)
        
        // Then: Should fail with insufficient funds
        XCTAssertEqual(result, .insufficientFunds)
        XCTAssertEqual(currencyManager.currentPoints, 10) // Points unchanged
        XCTAssertEqual(reviveHeartManager.heartCount, 0) // No hearts added
    }
    
    func testMultipleHeartPurchases() {
        // Given: Player has enough coins for multiple hearts
        currencyManager.addPoints(60) // Enough for 3 hearts
        
        // When: Player purchases 3 hearts
        let result1 = shopManager.purchasePowerup(.reviveHeart)
        let result2 = shopManager.purchasePowerup(.reviveHeart)
        let result3 = shopManager.purchasePowerup(.reviveHeart)
        
        // Then: All purchases should succeed
        XCTAssertTrue(result1.isSuccess)
        XCTAssertTrue(result2.isSuccess)
        XCTAssertTrue(result3.isSuccess)
        
        // And: Correct final state
        XCTAssertEqual(currencyManager.currentPoints, 0)
        XCTAssertEqual(reviveHeartManager.heartCount, 3)
    }
    
    func testAdRewardAccumulation() {
        // Given: Player starts with no coins
        XCTAssertEqual(currencyManager.currentPoints, 0)
        
        // When: Player watches multiple ads over time
        for _ in 1...5 {
            currencyManager.awardAdPoints()
        }
        
        // Then: Points should accumulate correctly
        XCTAssertEqual(currencyManager.currentPoints, 50)
        
        // And: Player can afford multiple hearts
        XCTAssertTrue(shopManager.canPurchase(.reviveHeart))
        
        // When: Purchase one heart
        let result = shopManager.purchasePowerup(.reviveHeart)
        XCTAssertTrue(result.isSuccess)
        
        // Then: Still have coins for another heart
        XCTAssertEqual(currencyManager.currentPoints, 30)
        XCTAssertTrue(shopManager.canPurchase(.reviveHeart))
    }
    
    // MARK: - Game Flow Integration Tests
    
    func testGameOverViewButtonLogic() {
        // Test case 1: No hearts, no coins - should show "Watch Ad" button
        currencyManager.resetPoints()
        reviveHeartManager.resetHearts()
        
        XCTAssertFalse(reviveHeartManager.hasHearts())
        XCTAssertFalse(shopManager.canPurchase(.reviveHeart))
        // This would correspond to showing the "Watch Ad for Coins" button
        
        // Test case 2: No hearts, enough coins - should show "Buy Heart" button
        currencyManager.addPoints(20)
        
        XCTAssertFalse(reviveHeartManager.hasHearts())
        XCTAssertTrue(shopManager.canPurchase(.reviveHeart))
        // This would correspond to showing the "Buy Heart" button
        
        // Test case 3: Has hearts - should show "Revive" button
        let purchaseResult = shopManager.purchasePowerup(.reviveHeart)
        XCTAssertTrue(purchaseResult.isSuccess)
        XCTAssertTrue(reviveHeartManager.hasHearts())
        // This would correspond to showing the "Revive" button
    }
    
    func testCurrencyPersistenceAfterPurchase() {
        // Given: Player earns some coins
        currencyManager.addPoints(50)
        let initialPoints = currencyManager.currentPoints
        
        // When: Player makes a purchase
        let result = shopManager.purchasePowerup(.reviveHeart)
        XCTAssertTrue(result.isSuccess)
        
        // Then: Points should be correctly updated and persisted
        let expectedPoints = initialPoints - shopManager.getPrice(for: .reviveHeart)
        XCTAssertEqual(currencyManager.currentPoints, expectedPoints)
        
        // And: Creating new instance should load correct points
        let newManager = PowerupCurrencyManager()
        XCTAssertEqual(newManager.currentPoints, expectedPoints)
    }
    
    // MARK: - Error Handling Tests
    
    func testPurchaseWithZeroCoins() {
        // Given: Player has exactly zero coins
        currencyManager.resetPoints()
        XCTAssertEqual(currencyManager.currentPoints, 0)
        
        // When: Attempting to purchase
        let result = shopManager.purchasePowerup(.reviveHeart)
        
        // Then: Should fail gracefully
        XCTAssertEqual(result, .insufficientFunds)
        XCTAssertEqual(currencyManager.currentPoints, 0)
        XCTAssertEqual(reviveHeartManager.heartCount, 0)
    }
    
    func testFutureItemsPurchase() {
        // Given: Player has enough coins
        currencyManager.addPoints(100)
        
        // When: Attempting to purchase future items
        let result1 = shopManager.purchasePowerup(.futureBonus1)
        let result2 = shopManager.purchasePowerup(.futureBonus2)
        let result3 = shopManager.purchasePowerup(.futureBonus3)
        
        // Then: Should fail as items are not available yet
        XCTAssertEqual(result1, .itemNotAvailable)
        XCTAssertEqual(result2, .itemNotAvailable)
        XCTAssertEqual(result3, .itemNotAvailable)
        
        // And: Coins should remain unchanged
        XCTAssertEqual(currencyManager.currentPoints, 100)
    }
    
    // MARK: - Edge Case Tests
    
    func testConcurrentPurchases() {
        // Given: Player has exactly enough for one heart
        currencyManager.addPoints(20)
        
        // When: Attempting rapid consecutive purchases
        let result1 = shopManager.purchasePowerup(.reviveHeart)
        let result2 = shopManager.purchasePowerup(.reviveHeart)
        
        // Then: First should succeed, second should fail
        XCTAssertTrue(result1.isSuccess)
        XCTAssertEqual(result2, .insufficientFunds)
        
        // And: Correct final state
        XCTAssertEqual(currencyManager.currentPoints, 0)
        XCTAssertEqual(reviveHeartManager.heartCount, 1)
    }
    
    func testMaxCoinsBeforePurchase() {
        // Given: Player accumulates many coins
        currencyManager.addPoints(1000)
        
        // When: Making a purchase
        let result = shopManager.purchasePowerup(.reviveHeart)
        
        // Then: Should work normally
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(currencyManager.currentPoints, 980)
        XCTAssertEqual(reviveHeartManager.heartCount, 1)
    }
    
    // MARK: - Performance Tests
    
    func testMultipleAdRewardsPerformance() {
        measure {
            for _ in 1...100 {
                currencyManager.awardAdPoints()
            }
        }
        
        // Verify final state
        XCTAssertEqual(currencyManager.currentPoints, 1000)
    }
    
    func testMultiplePurchasesPerformance() {
        // Given: Enough coins for many purchases
        currencyManager.addPoints(2000)
        
        measure {
            for _ in 1...10 {
                _ = shopManager.purchasePowerup(.reviveHeart)
            }
        }
        
        // Verify final state
        XCTAssertEqual(currencyManager.currentPoints, 1800) // 2000 - (10 * 20)
        XCTAssertEqual(reviveHeartManager.heartCount, 10)
    }
}
