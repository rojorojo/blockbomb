import SwiftUI
import SpriteKit
import Combine
// Add ReviveHeart import for Phase 1 game state preservation
import Foundation

class GameController: ObservableObject, PostReviveTracker {
    // Published properties that SwiftUI will observe
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var finalScore: Int = 0
    @Published var highScore: Int = 0
    @Published var isNewHighScore: Bool = false
    @Published var showHighScoreAnimation: Bool = false // Flag for real-time high score animation
    
    // Rarity system configuration
    @Published var selectionMode: TetrominoShape.SelectionMode = .strategicWeighted

    // Internal reference to game scene
    private(set) var gameScene: GameScene?
    
    // Ad timing integration
    private let adTimingManager = AdTimingManager.shared
    
    // Game state manager for revive heart functionality
    private var savedGameState: GameStateManager.GameState?
    
    // Post-revive block prioritization tracking
    private var postRevivePiecesRemaining: Int = 0
    private let postRevivePriorityPieces: Int = 18
    
    // Init with default values
    init() {
        // Load saved high score from UserDefaults
        highScore = UserDefaults.standard.integer(forKey: "highScore")
        print("GameController: Initialized with high score: \(highScore)")
        
        // Debug: Check if player has played before
        let hasPlayedBefore = UserDefaults.standard.object(forKey: "highScore") != nil
        print("GameController: Has played before: \(hasPlayedBefore)")
    }
    
    // Associate a game scene with this controller
    func setGameScene(_ scene: GameScene) {
        gameScene = scene
        
        // Start initial logging session
        GameplayDataLogger.shared.startSession()
        
        // Establish bidirectional connection
        scene.gameController = self
        
        // Configure scene callbacks
        scene.scoreUpdateHandler = { [weak self] newScore in
            DispatchQueue.main.async {
                self?.updateScore(newScore) 
            }
        }
        
        scene.gameOverHandler = { [weak self] finalScore in
            DispatchQueue.main.async {
                self?.finalScore = finalScore

                // Check if this is a new high score
                let currentHighScore = self?.highScore ?? 0
                
                // Check if this is the first game ever played (no previous high score set)
                let hasPlayedBefore = UserDefaults.standard.object(forKey: "highScore") != nil
                
                // Only trigger new high score experience if:
                // 1. Final score is greater than current high score AND
                // 2. Player has played before (not their first game)
                let isNewHighScore = finalScore > currentHighScore && hasPlayedBefore
                self?.isNewHighScore = isNewHighScore
                
                print("GameController: Game Over - Final Score: \(finalScore), Previous High Score: \(currentHighScore), Has Played Before: \(hasPlayedBefore), Is New High Score: \(isNewHighScore)")
                
                // Always update high score if final score is higher (even on first game)
                if finalScore > currentHighScore {
                    self?.highScore = finalScore
                    UserDefaults.standard.set(finalScore, forKey: "highScore")
                }
                
                // Only play new high score celebration if it's not the first game
                if isNewHighScore {
                    print("GameController: NEW HIGH SCORE! Playing audio and haptic feedback")
                    // Play new high score sound
                    AudioManager.shared.playNewHighScoreSound()
                    AudioManager.shared.triggerHapticFeedback(for: .newHighScore)
                } else {
                    print("GameController: Regular game over - playing standard audio")
                    // Play regular game over sound
                    AudioManager.shared.playGameOverSound()
                    AudioManager.shared.triggerHapticFeedback(for: .gameOver)
                }
                
                self?.isGameOver = true
                
                // End the logging session
                GameplayDataLogger.shared.endSession()
                
                // Notify ad timing manager about game end for potential interstitial
                self?.adTimingManager.onGameEnd(gameController: self ?? GameController())
            }
        }
        
        // Disable native SpriteKit UI since we're using SwiftUI
        scene.shouldDisplayScore = false
        scene.shouldDisplayGameOver = false
    }

    // New method to update score
    func updateScore(_ newScore: Int) {
        let previousScore = score
        score = newScore
        
        // Check if we've crossed the high score threshold during gameplay
        // This triggers the real-time high score animation
        let hasPlayedBefore = UserDefaults.standard.object(forKey: "highScore") != nil
        
        // Debug logging for high score animation trigger
        print("GameController: updateScore called - Previous: \(previousScore), New: \(newScore), High Score: \(highScore), Has Played Before: \(hasPlayedBefore), Animation Showing: \(showHighScoreAnimation)")
        
        // Only trigger animation if:
        // 1. Player has played before (not first game)
        // 2. Previous score was below high score
        // 3. New score is above high score
        // 4. Animation is not already showing
        if hasPlayedBefore && 
           previousScore < highScore && 
           newScore > highScore && 
           !showHighScoreAnimation {
            
            print("GameController: Real-time high score reached! Score: \(newScore), Previous High Score: \(highScore)")
            
            // Play the new high score during gameplay audio
            AudioManager.shared.playNewHighScorePlayingSound()
            
            // Trigger the high score animation
            withAnimation(.easeInOut(duration: 0.3)) {
                showHighScoreAnimation = true
            }
        }
        
        // Note: High score is only updated at game over to ensure proper new high score celebration at end
    }
    
    // Game control methods
    func restartGame() {
        // Start a new logging session
        GameplayDataLogger.shared.startSession()
        
        withAnimation {
            isGameOver = false
            isNewHighScore = false // Reset new high score flag
            showHighScoreAnimation = false // Reset high score animation flag
        }
        
        // Clear any saved game state when starting fresh
        clearSavedGameState()
        
        // Reset post-revive tracking for new game
        resetPostReviveTracking()
        
        if let gameScene = gameScene {
            gameScene.resetGame()
            score = 0 // Reset displayed score in SwiftUI
        } else {
            print("Error: Cannot restart game - gameScene is nil")
        }
    }
    
    // Any other game-related methods can go here
    func pauseGame() {
        gameScene?.isPaused = true
    }
    
    func resumeGame() {
        gameScene?.isPaused = false
    }
    
    // MARK: - Game State Preservation Methods
    
    /// Save the current game state for potential revive
    /// Should be called just before game over is triggered
    func saveGameStateForRevive() {
        guard let gameScene = gameScene else {
            print("GameController: Cannot save game state - gameScene is nil")
            return
        }
        
        // Use GameStateManager to capture current state
        savedGameState = GameStateManager.captureGameState(from: self, gameScene: gameScene)
        
        print("GameController: Game state saved for revive using GameStateManager - Score: \(score)")
    }
    
    /// Restore the previously saved game state
    /// Returns true if restoration was successful
    @discardableResult
    func restoreGameStateFromRevive() -> Bool {
        guard let gameScene = gameScene,
              let gameState = savedGameState else {
            print("GameController: Cannot restore game state - gameScene is nil or no saved state")
            return false
        }
        
        // Use GameStateManager to restore the saved state
        let success = GameStateManager.restoreGameState(gameState, to: self, gameScene: gameScene)
        
        if success {
            // Reset game over state
            isGameOver = false
            
            // Clear the saved state after successful restoration
            savedGameState = nil
            
            print("GameController: Game state successfully restored using GameStateManager")
        } else {
            print("GameController: Failed to restore game state using GameStateManager")
        }
        
        return success
    }
    
    /// Check if there's a saved game state available for revive
    /// - Returns: True if a saved state exists and can be restored
    func hasSavedGameState() -> Bool {
        return savedGameState != nil && savedGameState!.isValid
    }
    
    /// Clear the saved game state (called after successful revive or when no longer needed)
    func clearSavedGameState() {
        savedGameState = nil
        print("GameController: Cleared saved game state")
    }
    
    // MARK: - Post-Revive Block Prioritization System
    
    /// Check if we're currently in post-revive priority mode
    /// - Returns: True if we should prioritize placeable blocks
    func isInPostReviveMode() -> Bool {
        return postRevivePiecesRemaining > 0
    }
    
    /// Get the number of priority pieces remaining after revive
    /// - Returns: Number of pieces remaining with prioritized blocks
    func getPostRevivePiecesRemaining() -> Int {
        return postRevivePiecesRemaining
    }
    
    /// Called when a new set of pieces is generated to decrement post-revive counter
    func onPiecesGenerated() {
        if postRevivePiecesRemaining > 0 {
            // Decrement by 3 since we just generated 3 pieces
            let piecesToDecrement = min(3, postRevivePiecesRemaining)
            postRevivePiecesRemaining -= piecesToDecrement
            print("GameController: Post-revive pieces generated. \(piecesToDecrement) pieces counted. Pieces remaining: \(postRevivePiecesRemaining)")
            
            if postRevivePiecesRemaining == 0 {
                print("GameController: Post-revive priority mode ended")
            }
        }
    }
    
    /// Start post-revive priority mode (called after successful revive)
    private func startPostRevivePriorityMode() {
        postRevivePiecesRemaining = postRevivePriorityPieces
        print("GameController: Started post-revive priority mode for \(postRevivePriorityPieces) pieces")
    }
    
    /// Reset post-revive tracking (called on new game)
    func resetPostReviveTracking() {
        postRevivePiecesRemaining = 0
        print("GameController: Reset post-revive tracking")
    }
    
    // MARK: - Revive Heart Integration
    
    /// Attempt to revive the game by using a heart and restoring the saved game state
    /// - Returns: True if revive was successful, false if no hearts available or restoration failed
    func attemptRevive() -> Bool {
        // Check if player has hearts available
        guard ReviveHeartManager.shared.hasHearts() else {
            print("GameController: Cannot revive - no hearts available")
            return false
        }
        
        // Check if we have a saved game state to restore
        guard hasSavedGameState() else {
            print("GameController: Cannot revive - no saved game state available")
            return false
        }
        
        // Use a heart (this will decrement the count and save to UserDefaults)
        guard ReviveHeartManager.shared.useHeart() else {
            print("GameController: Failed to use heart for revive")
            return false
        }
        
        // Attempt to restore the game state
        let restorationSuccess = restoreGameStateFromRevive()
        
        if restorationSuccess {
            // Start post-revive priority mode for next 4 rounds
            startPostRevivePriorityMode()
            
            // Audio and haptic feedback will be played during the animation
            print("GameController: Revive successful! Hearts remaining: \(ReviveHeartManager.shared.getHeartCount())")
            return true
        } else {
            // Restoration failed - we should give the heart back
            ReviveHeartManager.shared.addHearts(count: 1)
            print("GameController: Revive failed - game state restoration unsuccessful. Heart refunded.")
            return false
        }
    }
    
    /// Check if revive is possible (has hearts and saved state)
    /// - Returns: True if revive can be attempted
    func canRevive() -> Bool {
        return ReviveHeartManager.shared.hasHearts() && hasSavedGameState()
    }
    
    // MARK: - Debug Methods for Testing
    #if DEBUG
    /// Debug method to test new high score functionality
    func debugTestNewHighScore(withScore testScore: Int) {
        print("GameController: DEBUG - Testing new high score with score: \(testScore)")
        
        // Save current values
        let originalScore = score
        let originalHighScore = highScore
        
        // Simulate game over with test score
        finalScore = testScore
        
        // Check if this would be a new high score using the same logic as production
        let currentHighScore = highScore
        let hasPlayedBefore = UserDefaults.standard.object(forKey: "highScore") != nil
        let isNewHighScore = testScore > currentHighScore && hasPlayedBefore
        self.isNewHighScore = isNewHighScore
        
        print("GameController: DEBUG - Test Results:")
        print("  - Test Score: \(testScore)")
        print("  - Current High Score: \(currentHighScore)")
        print("  - Has Played Before: \(hasPlayedBefore)")
        print("  - Would be New High Score: \(isNewHighScore)")
        
        // Always update high score if test score is higher
        if testScore > currentHighScore {
            self.highScore = testScore
            UserDefaults.standard.set(testScore, forKey: "highScore")
        }
        
        // Only play celebration if it's not the first game
        if isNewHighScore {
            print("GameController: DEBUG - Playing new high score sound and haptics")
            AudioManager.shared.playNewHighScoreSound()
            AudioManager.shared.triggerHapticFeedback(for: .newHighScore)
        } else {
            print("GameController: DEBUG - Playing regular game over sound")
            AudioManager.shared.playGameOverSound()
            AudioManager.shared.triggerHapticFeedback(for: .gameOver)
        }
        
        // Set game over to show the screen
        isGameOver = true
    }
    
    /// Debug method to reset high score for testing
    func debugResetHighScore() {
        highScore = 0
        UserDefaults.standard.removeObject(forKey: "highScore") // Remove the key entirely to simulate first-time player
        print("GameController: DEBUG - Reset high score to 0 and cleared first-time player state")
    }
    
    /// Debug method to set a test high score for animation testing
    func debugSetTestHighScore() {
        highScore = 500
        UserDefaults.standard.set(500, forKey: "highScore")
        print("GameController: DEBUG - Set test high score to 500")
    }
    
    /// Debug method to force trigger high score animation
    func debugTestHighScoreAnimation() {
        print("GameController: DEBUG - Force triggering high score animation")
        withAnimation(.easeInOut(duration: 0.3)) {
            showHighScoreAnimation = true
        }
    }
    
    /// Debug method to simulate real-time high score crossing
    func debugSimulateHighScoreCrossing() {
        print("GameController: DEBUG - Simulating real-time high score crossing")
        
        // Set up a test scenario where we have a high score of 500
        let testHighScore = 500
        highScore = testHighScore
        UserDefaults.standard.set(testHighScore, forKey: "highScore")
        
        // Set current score just below high score
        score = testHighScore - 10
        
        print("GameController: DEBUG - Setup complete:")
        print("  - High Score: \(highScore)")
        print("  - Current Score: \(score)")
        print("  - Has Played Before: \(UserDefaults.standard.object(forKey: "highScore") != nil)")
        
        // Now simulate a score update that crosses the high score
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("GameController: DEBUG - Simulating score update that crosses high score")
            self.updateScore(testHighScore + 50) // Cross the high score threshold
        }
    }
    
    /// Debug method to simulate first-time player completing their first game
    func debugSimulateFirstGame(withScore testScore: Int) {
        print("GameController: DEBUG - Simulating first-time player with score: \(testScore)")
        
        // Ensure we're in first-time player state
        UserDefaults.standard.removeObject(forKey: "highScore")
        highScore = 0
        
        // Simulate the game over experience
        finalScore = testScore
        
        // This should NOT trigger new high score celebration
        let currentHighScore = highScore
        let hasPlayedBefore = UserDefaults.standard.object(forKey: "highScore") != nil
        let isNewHighScore = testScore > currentHighScore && hasPlayedBefore
        self.isNewHighScore = isNewHighScore
        
        print("GameController: DEBUG - First Game Results:")
        print("  - Test Score: \(testScore)")
        print("  - Current High Score: \(currentHighScore)")
        print("  - Has Played Before: \(hasPlayedBefore)")
        print("  - Should Show New High Score: \(isNewHighScore)")
        
        // Update high score (but no celebration)
        if testScore > currentHighScore {
            self.highScore = testScore
            UserDefaults.standard.set(testScore, forKey: "highScore")
            print("GameController: DEBUG - Set initial high score to \(testScore)")
        }
        
        // Should play regular game over sound, not celebration
        print("GameController: DEBUG - Playing regular game over sound (first game)")
        AudioManager.shared.playGameOverSound()
        AudioManager.shared.triggerHapticFeedback(for: .gameOver)
        
        isGameOver = true
    }
    #endif
}