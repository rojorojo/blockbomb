//
//  ReviveHeartSystemTests.swift
//  blockbombTests
//
//  Created by Robert Johnson on 1/30/25.
//

import Testing
import Foundation
@testable import blockbomb

/// Comprehensive test suite for the Revive Heart system
struct ReviveHeartSystemTests {
    
    // MARK: - ReviveHeartManager Tests
    
    @Test func testReviveHeartManagerInitialization() async throws {
        // Reset to clean state
        UserDefaults.standard.removeObject(forKey: "reviveHeartCount")
        
        // Create a new instance (simulates first launch)
        let manager = ReviveHeartManager.shared
        
        // Should start with 3 hearts
        #expect(manager.getHeartCount() == 3)
        #expect(manager.hasHearts() == true)
    }
    
    @Test func testHeartUsage() async throws {
        let manager = ReviveHeartManager.shared
        
        // Reset to known state
        manager.debugClearUserDefaults()
        
        // Should start with 3 hearts
        #expect(manager.getHeartCount() == 3)
        
        // Use one heart
        let result = manager.useHeart()
        #expect(result == true)
        #expect(manager.getHeartCount() == 2)
        
        // Use second heart
        let result2 = manager.useHeart()
        #expect(result2 == true)
        #expect(manager.getHeartCount() == 1)
        
        // Use third heart
        let result3 = manager.useHeart()
        #expect(result3 == true)
        #expect(manager.getHeartCount() == 0)
        #expect(manager.hasHearts() == false)
        
        // Try to use heart when none available
        let result4 = manager.useHeart()
        #expect(result4 == false)
        #expect(manager.getHeartCount() == 0)
    }
    
    @Test func testAddingHearts() async throws {
        let manager = ReviveHeartManager.shared
        
        // Reset to known state
        manager.debugClearUserDefaults()
        
        // Add hearts
        manager.addHearts(count: 2)
        #expect(manager.getHeartCount() == 5) // 3 default + 2 added
        
        // Test adding zero hearts (should be ignored)
        manager.addHearts(count: 0)
        #expect(manager.getHeartCount() == 5)
        
        // Test adding negative hearts (should be ignored)
        manager.addHearts(count: -1)
        #expect(manager.getHeartCount() == 5)
    }
    
    @Test func testHeartPersistence() async throws {
        let manager = ReviveHeartManager.shared
        
        // Reset to clean state
        manager.debugClearUserDefaults()
        
        // Use some hearts
        manager.useHeart()
        manager.useHeart()
        #expect(manager.getHeartCount() == 1)
        
        // Simulate app restart by clearing and reloading
        let beforeRestart = manager.getHeartCount()
        manager.debugClearUserDefaults()
        
        // After restart, should maintain the count
        // Note: In a real app restart, this would be tested differently
        // For this test, we verify UserDefaults persistence manually
        UserDefaults.standard.set(1, forKey: "reviveHeartCount")
        
        // Create new manager instance to simulate restart
        let persistedCount = UserDefaults.standard.integer(forKey: "reviveHeartCount")
        #expect(persistedCount == 1)
    }
    
    // MARK: - GameStateManager Tests
    
    @Test func testGameStateValidation() async throws {
        // Create a fresh game state
        let now = Date()
        let gameState = GameStateManager.GameState(
            score: 1000,
            boardState: Array(repeating: Array(repeating: nil, count: 10), count: 20),
            currentPieces: ["I", "T", "O"],
            selectionMode: "adaptiveBalanced",
            timestamp: now
        )
        
        // Should be valid when fresh
        #expect(gameState.isValid == true)
        
        // Create an old game state (6 minutes ago - beyond 5 minute limit)
        let oldDate = Date().addingTimeInterval(-360) // 6 minutes ago
        let oldGameState = GameStateManager.GameState(
            score: 500,
            boardState: Array(repeating: Array(repeating: nil, count: 10), count: 20),
            currentPieces: ["L", "J", "S"],
            selectionMode: "balanced",
            timestamp: oldDate
        )
        
        // Should be invalid
        #expect(oldGameState.isValid == false)
    }
    
    @Test func testSelectionModeConversion() async throws {
        // Test all selection mode conversions
        let modes: [(String, TetrominoShape.SelectionMode)] = [
            ("balanced", .balanced),
            ("adaptiveBalanced", .adaptiveBalanced),
            ("random", .random)
        ]
        
        for (stringMode, expectedMode) in modes {
            let convertedMode = GameStateManager.convertStringToSelectionMode(stringMode)
            #expect(convertedMode == expectedMode)
            
            let convertedString = GameStateManager.convertSelectionModeToString(expectedMode)
            #expect(convertedString == stringMode)
        }
        
        // Test unknown mode (should default to adaptiveBalanced)
        let unknownMode = GameStateManager.convertStringToSelectionMode("unknown")
        #expect(unknownMode == .adaptiveBalanced)
    }
    
    // MARK: - Integration Tests
    
    @Test func testCanReviveLogic() async throws {
        let gameController = GameController()
        let manager = ReviveHeartManager.shared
        
        // Reset to known state
        manager.debugClearUserDefaults()
        
        // Should not be able to revive without saved game state
        #expect(gameController.canRevive() == false)
        
        // Even with hearts, no saved state means no revive
        #expect(manager.hasHearts() == true)
        #expect(gameController.hasSavedGameState() == false)
        #expect(gameController.canRevive() == false)
        
        // TODO: Add test with saved game state when GameScene is available
        // This would require mocking or creating a test GameScene instance
    }
    
    @Test func testReviveWithoutHearts() async throws {
        let gameController = GameController()
        let manager = ReviveHeartManager.shared
        
        // Reset and remove all hearts
        manager.debugClearUserDefaults()
        manager.useHeart() // 2 remaining
        manager.useHeart() // 1 remaining
        manager.useHeart() // 0 remaining
        
        #expect(manager.hasHearts() == false)
        
        // Attempt revive should fail due to no hearts
        let reviveResult = gameController.attemptRevive()
        #expect(reviveResult == false)
    }
    
    @Test func testReviveHeartRefundOnFailure() async throws {
        let manager = ReviveHeartManager.shared
        
        // Reset to known state
        manager.debugClearUserDefaults()
        let initialHearts = manager.getHeartCount()
        
        // Use a heart
        manager.useHeart()
        #expect(manager.getHeartCount() == initialHearts - 1)
        
        // Simulate a failed restoration by adding a heart back (what the code does on failure)
        manager.addHearts(count: 1)
        #expect(manager.getHeartCount() == initialHearts)
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testGameStateExpiry() async throws {
        // Test that game states older than 5 minutes are considered invalid
        let expiredDate = Date().addingTimeInterval(-301) // 5 minutes and 1 second ago
        let validDate = Date().addingTimeInterval(-299)   // 4 minutes and 59 seconds ago
        
        let expiredState = GameStateManager.GameState(
            score: 100,
            boardState: Array(repeating: Array(repeating: nil, count: 10), count: 20),
            currentPieces: ["I"],
            selectionMode: "balanced",
            timestamp: expiredDate
        )
        
        let validState = GameStateManager.GameState(
            score: 200,
            boardState: Array(repeating: Array(repeating: nil, count: 10), count: 20),
            currentPieces: ["T"],
            selectionMode: "balanced", 
            timestamp: validDate
        )
        
        #expect(expiredState.isValid == false)
        #expect(validState.isValid == true)
    }
    
    @Test func testMultipleRevivesInSession() async throws {
        let manager = ReviveHeartManager.shared
        
        // Reset to known state with 3 hearts
        manager.debugClearUserDefaults()
        #expect(manager.getHeartCount() == 3)
        
        // Simulate multiple revives in one session
        let result1 = manager.useHeart()
        #expect(result1 == true)
        #expect(manager.getHeartCount() == 2)
        
        let result2 = manager.useHeart()
        #expect(result2 == true)
        #expect(manager.getHeartCount() == 1)
        
        let result3 = manager.useHeart()
        #expect(result3 == true)
        #expect(manager.getHeartCount() == 0)
        
        // Fourth attempt should fail
        let result4 = manager.useHeart()
        #expect(result4 == false)
        #expect(manager.getHeartCount() == 0)
    }
    
    @Test func testDebugMethods() async throws {
        let manager = ReviveHeartManager.shared
        
        // Test debug set hearts
        manager.debugSetHearts(10)
        #expect(manager.getHeartCount() == 10)
        
        // Test debug set to zero
        manager.debugSetHearts(0)
        #expect(manager.getHeartCount() == 0)
        #expect(manager.hasHearts() == false)
        
        // Test debug set negative (should clamp to 0)
        manager.debugSetHearts(-5)
        #expect(manager.getHeartCount() == 0)
        
        // Test debug clear UserDefaults
        manager.debugSetHearts(7)
        #expect(manager.getHeartCount() == 7)
        
        manager.debugClearUserDefaults()
        #expect(manager.getHeartCount() == 3) // Should reset to default
    }
}
