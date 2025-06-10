//
//  PowerupCurrencySystemTests.swift
//  blockbombTests
//
//  Created by Robert Johnson on 6/10/25.
//

import Testing
import Foundation
@testable import blockbomb

/// Comprehensive test suite for the Powerup Currency system
struct PowerupCurrencySystemTests {
    
    // MARK: - PowerupCurrencyManager Tests
    
    @Test func testPowerupCurrencyManagerInitialization() async throws {
        // Reset to clean state
        UserDefaults.standard.removeObject(forKey: "powerupCurrencyPoints")
        
        // Create a new instance (simulates first launch)
        let manager = PowerupCurrencyManager.shared
        
        // Verify default initialization
        #expect(manager.getPoints() == 0, "Manager should initialize with 0 points on first launch")
        #expect(!manager.hasEnoughPoints(1), "Manager should not have enough points for any purchase on first launch")
    }
    
    @Test func testPointsPersistence() async throws {
        let testKey = "powerupCurrencyPoints"
        
        // Clean state
        UserDefaults.standard.removeObject(forKey: testKey)
        
        // Set test points
        let testPoints = 150
        UserDefaults.standard.set(testPoints, forKey: testKey)
        
        // Create manager instance and verify it loads persisted data
        let manager = PowerupCurrencyManager.shared
        #expect(manager.getPoints() == testPoints, "Manager should load persisted points from UserDefaults")
    }
    
    @Test func testAddPoints() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to known state
        manager.debugSetPoints(0)
        
        // Test adding valid points
        manager.addPoints(50)
        #expect(manager.getPoints() == 50, "Adding 50 points should result in 50 total points")
        
        // Test adding more points (cumulative)
        manager.addPoints(25)
        #expect(manager.getPoints() == 75, "Adding 25 more points should result in 75 total points")
        
        // Test adding zero points (should not change balance)
        let beforeZero = manager.getPoints()
        manager.addPoints(0)
        #expect(manager.getPoints() == beforeZero, "Adding 0 points should not change balance")
        
        // Test adding negative points (should not change balance)
        let beforeNegative = manager.getPoints()
        manager.addPoints(-10)
        #expect(manager.getPoints() == beforeNegative, "Adding negative points should not change balance")
    }
    
    @Test func testSpendPoints() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to known state with sufficient points
        manager.debugSetPoints(100)
        
        // Test successful spending
        let spendResult = manager.spendPoints(30)
        #expect(spendResult == true, "Spending 30 points from 100 should succeed")
        #expect(manager.getPoints() == 70, "After spending 30 points, balance should be 70")
        
        // Test spending more points
        let spendResult2 = manager.spendPoints(20)
        #expect(spendResult2 == true, "Spending 20 more points should succeed")
        #expect(manager.getPoints() == 50, "After spending 20 more points, balance should be 50")
        
        // Test insufficient funds
        let insufficientResult = manager.spendPoints(60)
        #expect(insufficientResult == false, "Spending 60 points when only 50 available should fail")
        #expect(manager.getPoints() == 50, "Failed spending should not change balance")
        
        // Test spending zero points
        let zeroResult = manager.spendPoints(0)
        #expect(zeroResult == false, "Spending 0 points should fail")
        
        // Test spending negative points
        let negativeResult = manager.spendPoints(-10)
        #expect(negativeResult == false, "Spending negative points should fail")
    }
    
    @Test func testHasEnoughPoints() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to known state
        manager.debugSetPoints(50)
        
        // Test various point checks
        #expect(manager.hasEnoughPoints(25) == true, "Should have enough points for 25 when balance is 50")
        #expect(manager.hasEnoughPoints(50) == true, "Should have enough points for exact balance (50)")
        #expect(manager.hasEnoughPoints(51) == false, "Should not have enough points for 51 when balance is 50")
        #expect(manager.hasEnoughPoints(0) == true, "Should always have enough points for 0")
        #expect(manager.hasEnoughPoints(-5) == true, "Should have enough points for negative amounts")
    }
    
    @Test func testAwardAdPoints() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to known state
        manager.debugSetPoints(0)
        
        // Test single ad reward
        manager.awardAdPoints()
        #expect(manager.getPoints() == 10, "Watching one ad should award 10 points")
        
        // Test multiple ad rewards
        manager.awardAdPoints()
        manager.awardAdPoints()
        #expect(manager.getPoints() == 30, "Watching three ads total should award 30 points")
    }
    
    @Test func testGetPointsPerAd() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Test points per ad configuration
        #expect(manager.getPointsPerAd() == 10, "Points per ad should be 10")
    }
    
    @Test func testResetPoints() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Set some points first
        manager.debugSetPoints(250)
        #expect(manager.getPoints() == 250, "Points should be set to 250")
        
        // Reset points
        manager.resetPoints()
        #expect(manager.getPoints() == 0, "Reset should set points to 0")
    }
    
    @Test func testUserDefaultsPersistence() async throws {
        let manager = PowerupCurrencyManager.shared
        let testKey = "powerupCurrencyPoints"
        
        // Set points and verify UserDefaults is updated
        manager.debugSetPoints(75)
        
        let savedValue = UserDefaults.standard.integer(forKey: testKey)
        #expect(savedValue == 75, "Points should be persisted to UserDefaults")
        
        // Modify points and verify persistence
        manager.addPoints(25)
        let updatedValue = UserDefaults.standard.integer(forKey: testKey)
        #expect(updatedValue == 100, "Updated points should be persisted to UserDefaults")
    }
    
    // MARK: - Debug Method Tests
    
    @Test func testDebugSetPoints() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Test setting various point values
        manager.debugSetPoints(500)
        #expect(manager.getPoints() == 500, "Debug set should work for positive values")
        
        manager.debugSetPoints(0)
        #expect(manager.getPoints() == 0, "Debug set should work for zero")
        
        // Test that negative values are clamped to 0
        manager.debugSetPoints(-50)
        #expect(manager.getPoints() == 0, "Debug set should clamp negative values to 0")
    }
    
    @Test func testDebugAddPoints() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to known state
        manager.debugSetPoints(10)
        
        // Test debug add (should work even with negative values)
        manager.debugAddPoints(15)
        #expect(manager.getPoints() == 25, "Debug add should work for positive values")
        
        manager.debugAddPoints(-5)
        #expect(manager.getPoints() == 20, "Debug add should work for negative values")
    }
    
    @Test func testDebugSimulateAds() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to known state
        manager.debugSetPoints(0)
        
        // Test simulating multiple ads
        manager.debugSimulateAds(3)
        #expect(manager.getPoints() == 30, "Simulating 3 ads should add 30 points (3 × 10)")
        
        // Test simulating one ad
        manager.debugSimulateAds(1)
        #expect(manager.getPoints() == 40, "Simulating 1 more ad should add 10 points for total of 40")
        
        // Test simulating zero ads
        let beforeZero = manager.getPoints()
        manager.debugSimulateAds(0)
        #expect(manager.getPoints() == beforeZero, "Simulating 0 ads should not change points")
    }
    
    @Test func testDebugClearUserDefaults() async throws {
        let manager = PowerupCurrencyManager.shared
        let testKey = "powerupCurrencyPoints"
        
        // Set some points first
        manager.debugSetPoints(150)
        #expect(UserDefaults.standard.integer(forKey: testKey) == 150, "UserDefaults should contain the set value")
        
        // Clear UserDefaults
        manager.debugClearUserDefaults()
        #expect(manager.getPoints() == 0, "After clearing UserDefaults, points should reset to default (0)")
        #expect(UserDefaults.standard.object(forKey: testKey) == nil, "UserDefaults should no longer contain the key")
    }
    
    // MARK: - Integration and Edge Case Tests
    
    @Test func testConcurrentPointOperations() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to known state
        manager.debugSetPoints(100)
        
        // Simulate concurrent operations (add and spend)
        manager.addPoints(50)
        let spendResult = manager.spendPoints(30)
        manager.addPoints(20)
        
        #expect(spendResult == true, "Spending should succeed")
        #expect(manager.getPoints() == 140, "Final balance should be 100 + 50 - 30 + 20 = 140")
    }
    
    @Test func testReviveHeartPurchaseScenario() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Reset to simulate new player
        manager.debugSetPoints(0)
        
        // Player watches 2 ads (enough for 1 revive heart at 20 points)
        manager.awardAdPoints() // 10 points
        manager.awardAdPoints() // 20 points total
        
        #expect(manager.hasEnoughPoints(20) == true, "Should have enough points for revive heart")
        
        // Purchase revive heart (20 points)
        let purchaseResult = manager.spendPoints(20)
        #expect(purchaseResult == true, "Purchase should succeed")
        #expect(manager.getPoints() == 0, "Balance should be 0 after purchase")
        
        // Try to purchase another without enough points
        let failedPurchase = manager.spendPoints(20)
        #expect(failedPurchase == false, "Second purchase should fail due to insufficient funds")
    }
    
    @Test func testLargePointValues() async throws {
        let manager = PowerupCurrencyManager.shared
        
        // Test with large values
        manager.debugSetPoints(999999)
        #expect(manager.getPoints() == 999999, "Should handle large point values")
        
        manager.addPoints(1)
        #expect(manager.getPoints() == 1000000, "Should handle addition to large values")
        
        let spendResult = manager.spendPoints(500000)
        #expect(spendResult == true, "Should handle spending large amounts")
        #expect(manager.getPoints() == 500000, "Should have correct balance after large spending")
    }
}
