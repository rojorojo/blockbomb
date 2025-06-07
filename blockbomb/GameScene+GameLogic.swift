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
        guard !isGameOver && !pieceNodes.isEmpty else { 
            if isGameOver {
                print("DEBUG: Skipping game over check - already game over")
            } else if pieceNodes.isEmpty {
                print("DEBUG: Skipping game over check - no pieces available")
            }
            return 
        }
        
        // Debug logging - add indicator if this is happening after revive
        let gameController = self.gameController
        let isAfterRevive = gameController?.score ?? 0 > 0 && gameBoard.getBoardCapacity() > 0.7
        let reviveIndicator = isAfterRevive ? " [POST-REVIVE CHECK]" : ""
        
        print("DEBUG: Starting game over check with \(pieceNodes.count) pieces\(reviveIndicator)")
        print("DEBUG: Current board capacity: \(String(format: "%.1f", gameBoard.getBoardCapacity() * 100))%")
        
        // Print visual board state
        gameBoard.debugPrintBoardState()
        
        // Log the current piece shapes
        let pieceShapeNames = pieceNodes.map { $0.gridPiece.shape.displayName }
        print("DEBUG: Current pieces: \(pieceShapeNames)")
        
        var canPlaceAnyPiece = false
        var detailedResults: [String] = []
        
        // Check if any piece can be placed anywhere (no rotations allowed)
        for (index, piece) in pieceNodes.enumerated() {
            let canPlace = gameBoard.canPlacePieceAnywhere(piece.gridPiece)
            detailedResults.append("\(piece.gridPiece.shape.displayName): \(canPlace ? "CAN" : "CANNOT") place")
            
            if canPlace {
                canPlaceAnyPiece = true
                // Don't break immediately - let's see all results for debugging
            }
        }
        
        print("DEBUG: Piece placement results:")
        detailedResults.forEach { print("  - \($0)") }
        
        if !canPlaceAnyPiece {
            print("DEBUG: GAME OVER TRIGGERED: No pieces can be placed")
            
            // Additional debug: check if board is actually full or nearly full
            let filledCells = Int(gameBoard.getBoardCapacity() * 64) // 8x8 = 64 cells
            print("DEBUG: Board has \(filledCells)/64 cells filled")
            
            handleGameOver()
        } else {
            print("DEBUG: Game continues - at least one piece can be placed")
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
        
        // CRITICAL: Save game state BEFORE triggering game over for revive functionality
        gameController?.saveGameStateForRevive()
        
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
