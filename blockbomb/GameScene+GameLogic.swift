import SpriteKit

// Extension containing game logic functionality
extension GameScene {
    // MARK: - Game Logic
    
    func calculatePoints(forLines lines: Int) -> Int {
        switch lines {
        case 1: return 100
        case 2: return 300
        case 3: return 500
        case 4: return 800
        case 5...: return 1000 + (lines - 5) * 200  // Higher bonus for more lines
        default: return 0
        }
    }
    
    /// Check if any of the current pieces can be placed on the board
    func checkForGameOver() {
        guard !isGameOver && !pieceNodes.isEmpty else { return }
        
        // Debug logging
        print("Checking for game over with \(pieceNodes.count) pieces")
        
        var canPlaceAnyPiece = false
        // Check if any piece can be placed anywhere (no rotations allowed)
        for piece in pieceNodes {
            if gameBoard.canPlacePieceAnywhere(piece.gridPiece) {
                canPlaceAnyPiece = true
                print("Piece \(piece.gridPiece.shape) can be placed")
                break // At least one piece can be placed, game continues
            } else {
                print("Piece \(piece.gridPiece.shape) cannot be placed anywhere")
            }
        }
        
        if !canPlaceAnyPiece {
            print("GAME OVER: No pieces can be placed")
            handleGameOver()
        }
    }
    
    /// Check if a specific piece can be placed anywhere on the board
    func canPlacePieceAnywhere(_ piece: GridPiece) -> Bool {
        // Delegate to the GameBoard implementation
        return gameBoard.canPlacePieceAnywhere(piece)
    }
    
    // Add a forced check that runs after each piece placement
    func checkGameStateAfterPlacement() {
        // Give a moment for animations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkForGameOver()
        }
    }
    
    /// Handle the game over state
    func handleGameOver() {
        isGameOver = true
        
        // Stop all piece animations
        pieceNodes.forEach { $0.removeAllActions() }
        
        // Show game over effect in SpriteKit if enabled
        showGameOverEffect()
        
        // Call the SwiftUI handler to show game over screen
        gameOverHandler?(score)
    }
    
    /// Reset the game to starting state
    func resetGame() {
        isGameOver = false
        
        // Remove game over visuals
        self.children.filter { $0.zPosition >= 500 }.forEach { $0.removeFromParent() }
        
        // Reset the game board
        gameBoard.resetBoard()
        
        // Reset score
        score = 0
        updateScoreLabel()
        
        // Set up new pieces
        setupDraggablePieces()
    }
    
    // Helper method to get safe area insets
    func getSafeAreaInsets(for view: SKView) -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0) // Default values for older iOS
        }
    }
}
