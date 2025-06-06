import SwiftUI
import SpriteKit
import Combine
// Add ReviveHeart import for Phase 1 game state preservation
import Foundation

class GameController: ObservableObject {
    // Published properties that SwiftUI will observe
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var finalScore: Int = 0
    @Published var highScore: Int = 0
    @Published var isNewHighScore: Bool = false
    
    // Rarity system configuration
    @Published var selectionMode: TetrominoShape.SelectionMode = .adaptiveBalanced

    // Internal reference to game scene
    private(set) var gameScene: GameScene?
    
    // Game state manager for revive heart functionality
    private var savedGameState: GameStateManager.GameState?
    
    // Init with default values
    init() {
        // Load saved high score from UserDefaults
        highScore = UserDefaults.standard.integer(forKey: "highScore")
    }
    
    // Associate a game scene with this controller
    func setGameScene(_ scene: GameScene) {
        gameScene = scene
        
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
                let isNewHighScore = finalScore > (self?.highScore ?? 0)
                self?.isNewHighScore = isNewHighScore
                
                // Update high score if needed before showing game over
                if isNewHighScore {
                    self?.highScore = finalScore
                    UserDefaults.standard.set(finalScore, forKey: "highScore")
                    // Play new high score sound
                    AudioManager.shared.playNewHighScoreSound()
                    AudioManager.shared.triggerHapticFeedback(for: .newHighScore)
                } else {
                    // Play regular game over sound
                    AudioManager.shared.playGameOverSound()
                    AudioManager.shared.triggerHapticFeedback(for: .gameOver)
                }
                
                self?.isGameOver = true
            }
        }
        
        // Disable native SpriteKit UI since we're using SwiftUI
        scene.shouldDisplayScore = false
        scene.shouldDisplayGameOver = false
    }

    // New method to update score and check for high score
    func updateScore(_ newScore: Int) {
        score = newScore
        
        // Check if this is a new high score
        if score > highScore {
            highScore = score
            // Save high score to UserDefaults
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
    }
    
    // Game control methods
    func restartGame() {
        withAnimation {
            isGameOver = false
            isNewHighScore = false // Reset new high score flag
        }
        
        // Clear any saved game state when starting fresh
        clearSavedGameState()
        
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
            // Play revive success audio
            AudioManager.shared.playReviveSound()
            AudioManager.shared.triggerHapticFeedback(for: .revive)
            
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
}