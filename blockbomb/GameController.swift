import SwiftUI
import SpriteKit
import Combine

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
}