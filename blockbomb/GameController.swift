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
    
    // MARK: - Game State Preservation for Revive Hearts
    private var savedGameState: SavedGameState?
    
    // MARK: - Saved Game State Structure
    private struct SavedGameState {
        let score: Int
        let boardState: [[GridCell?]]  // Grid state before game over
        let currentPieces: [TetrominoShape]  // Current pieces available
        let selectionMode: TetrominoShape.SelectionMode
        let timestamp: Date
    }
    
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
    
    // MARK: - Game State Preservation Methods
    
    /// Save the current game state for potential revive
    /// Should be called just before game over is triggered
    func saveGameStateForRevive() {
        guard let gameScene = gameScene else {
            print("GameController: Cannot save game state - gameScene is nil")
            return
        }
        
        // Capture current game state
        savedGameState = SavedGameState(
            score: score,
            boardState: captureBoardState(from: gameScene),
            currentPieces: getCurrentPieceShapes(from: gameScene),
            selectionMode: selectionMode,
            timestamp: Date()
        )
        
        print("GameController: Game state saved for revive - Score: \(score)")
    }
    
    /// Restore the previously saved game state
    /// Returns true if restoration was successful
    @discardableResult
    func restoreGameStateFromRevive() -> Bool {
        guard let savedState = savedGameState,
              let gameScene = gameScene else {
            print("GameController: Cannot restore game state - no saved state or gameScene is nil")
            return false
        }
        
        // Check if saved state is not too old (optional safety measure)
        let timeElapsed = Date().timeIntervalSince(savedState.timestamp)
        if timeElapsed > 300 { // 5 minutes max
            print("GameController: Saved game state is too old, cannot restore")
            savedGameState = nil
            return false
        }
        
        // Restore game state
        withAnimation {
            isGameOver = false
            isNewHighScore = false
        }
        
        // Restore score
        score = savedState.score
        
        // Restore board state
        restoreBoardState(savedState.boardState, to: gameScene)
        
        // Restore pieces
        restoreCurrentPieces(savedState.currentPieces, to: gameScene)
        
        // Restore selection mode
        selectionMode = savedState.selectionMode
        
        print("GameController: Game state restored from revive - Score: \(score)")
        
        // Clear the saved state after successful restoration
        savedGameState = nil
        
        return true
    }
    
    /// Check if there's a saved game state available for revival
    func hasSavedGameState() -> Bool {
        return savedGameState != nil
    }
    
    /// Clear any saved game state (call when starting a new game normally)
    func clearSavedGameState() {
        savedGameState = nil
        print("GameController: Saved game state cleared")
    }
    
    // MARK: - Private Helper Methods for Game State Capture/Restore
    
    private func captureBoardState(from gameScene: GameScene) -> [[GridCell?]] {
        // Create a simplified representation of the game board
        // This is a placeholder - we'll need to implement proper board state capture
        // based on the actual GameBoard structure
        var boardState: [[GridCell?]] = []
        
        // Initialize empty board state for now
        // In a real implementation, we'd capture the actual filled cells from gameScene.gameBoard
        for row in 0..<8 {
            var rowState: [GridCell?] = []
            for col in 0..<8 {
                // TODO: Capture actual cell state from gameScene.gameBoard.grid[row][col]
                // For now, storing nil (empty) - this needs to be connected to actual board state
                rowState.append(nil)
            }
            boardState.append(rowState)
        }
        
        print("GameController: Board state captured (placeholder implementation)")
        return boardState
    }
    
    private func getCurrentPieceShapes(from gameScene: GameScene) -> [TetrominoShape] {
        // Capture the current pieces available to the player
        var pieceShapes: [TetrominoShape] = []
        
        // Get shapes from current piece nodes
        for pieceNode in gameScene.pieceNodes {
            pieceShapes.append(pieceNode.gridPiece.shape)
        }
        
        print("GameController: Captured \(pieceShapes.count) piece shapes")
        return pieceShapes
    }
    
    private func restoreBoardState(_ boardState: [[GridCell?]], to gameScene: GameScene) {
        // Restore the board state to the game scene
        // This is a placeholder - we'll need to implement proper board state restoration
        
        // Reset the board first
        gameScene.gameBoard.resetBoard()
        
        // TODO: Restore actual filled cells to gameScene.gameBoard.grid
        // This will require accessing the actual grid structure and placing blocks
        
        print("GameController: Board state restored (placeholder implementation)")
    }
    
    private func restoreCurrentPieces(_ pieceShapes: [TetrominoShape], to gameScene: GameScene) {
        // Restore the specific pieces that were available when game over occurred
        // This requires modifying the piece setup to use specific shapes instead of random selection
        
        // For now, we'll use the normal piece setup
        // TODO: Implement specific piece restoration in GameScene
        gameScene.setupDraggablePieces()
        
        print("GameController: Pieces restored (placeholder implementation)")
    }
}