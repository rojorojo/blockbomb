import Foundation
import SpriteKit

/// Manages saving and restoring game state for the Revive Heart feature
class GameStateManager {
    
    // MARK: - Game State Structure
    
    /// Complete game state that can be saved and restored
    struct GameState: Codable {
        let score: Int
        let boardState: [[String?]]  // Grid state (color names for filled cells)
        let currentPieces: [String]  // TetrominoShape display names
        let selectionMode: String    // Selection mode as string
        let timestamp: Date
        
        /// Maximum age for a saved state (5 minutes)
        static let maxAge: TimeInterval = 300
        
        /// Check if this saved state is still valid
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) <= GameState.maxAge
        }
    }
    
    // MARK: - State Capture Methods
    
    /// Capture the current game state from GameController and GameScene
    /// - Parameters:
    ///   - gameController: The game controller containing score and settings
    ///   - gameScene: The game scene containing board and piece state
    /// - Returns: GameState object representing current state
    static func captureGameState(from gameController: GameController, gameScene: GameScene) -> GameState {
        let boardState = captureBoardState(from: gameScene.gameBoard)
        let currentPieces = capturePieceShapes(from: gameScene.pieceNodes)
        let selectionModeString = convertSelectionModeToString(gameController.selectionMode)
        
        let gameState = GameState(
            score: gameController.score,
            boardState: boardState,
            currentPieces: currentPieces,
            selectionMode: selectionModeString,
            timestamp: Date()
        )
        
        print("GameStateManager: Captured game state - Score: \(gameState.score), Pieces: \(gameState.currentPieces.count)")
        return gameState
    }
    
    /// Capture the current board state as a 2D array of color names
    private static func captureBoardState(from gameBoard: GameBoard) -> [[String?]] {
        var boardState: [[String?]] = []
        
        for row in 0..<gameBoard.rows {
            var rowState: [String?] = []
            for col in 0..<gameBoard.columns {
                // Check if there's a block at this position
                if let block = gameBoard.getBlockAt(row: row, column: col) {
                    // Extract color name from the block
                    let colorName = extractColorName(from: block.fillColor)
                    rowState.append(colorName)
                } else {
                    rowState.append(nil)
                }
            }
            boardState.append(rowState)
        }
        
        print("GameStateManager: Captured board state - \(countFilledCells(boardState)) filled cells")
        return boardState
    }
    
    /// Capture the shapes of current pieces
    private static func capturePieceShapes(from pieceNodes: [PieceNode]) -> [String] {
        let pieceShapes = pieceNodes.map { $0.gridPiece.shape.displayName }
        print("GameStateManager: Captured \(pieceShapes.count) piece shapes: \(pieceShapes)")
        return pieceShapes
    }
    
    // MARK: - State Restoration Methods
    
    /// Restore game state to GameController and GameScene
    /// - Parameters:
    ///   - gameState: The saved game state to restore
    ///   - gameController: The game controller to restore to
    ///   - gameScene: The game scene to restore to
    /// - Returns: True if restoration was successful
    static func restoreGameState(_ gameState: GameState, to gameController: GameController, gameScene: GameScene) -> Bool {
        guard gameState.isValid else {
            print("GameStateManager: Cannot restore - saved state is too old")
            return false
        }
        
        // Restore score
        gameController.score = gameState.score
        
        // Restore selection mode
        gameController.selectionMode = convertStringToSelectionMode(gameState.selectionMode)
        
        // Restore board state
        restoreBoardState(gameState.boardState, to: gameScene.gameBoard)
        
        // Instead of restoring old pieces, generate 3 NEW pieces for the player
        // This gives the player fresh options to continue the game
        gameScene.setupDraggablePieces()
        
        print("GameStateManager: Successfully restored game state - Score: \(gameState.score), Generated 3 new pieces")
        return true
    }
    
    /// Restore the board state by placing blocks in the correct positions
    private static func restoreBoardState(_ boardState: [[String?]], to gameBoard: GameBoard) {
        // First, reset the board to clear any existing blocks
        gameBoard.resetBoard()
        
        // Place blocks according to the saved state
        for row in 0..<min(boardState.count, gameBoard.rows) {
            let rowData = boardState[row]
            for col in 0..<min(rowData.count, gameBoard.columns) {
                if let colorName = rowData[col] {
                    let color = convertColorNameToSKColor(colorName)
                    gameBoard.placeRestoredBlock(at: GridCell(column: col, row: row), color: color)
                }
            }
        }
        
        print("GameStateManager: Board state restored with \(countFilledCells(boardState)) blocks")
    }
    
    /// Restore specific piece shapes to the game scene
    private static func restorePieceShapes(_ pieceShapeNames: [String], to gameScene: GameScene) {
        // Convert shape names back to TetrominoShape objects
        var shapes: [TetrominoShape] = []
        
        for shapeName in pieceShapeNames {
            if let shape = TetrominoShape.allCases.first(where: { $0.displayName == shapeName }) {
                shapes.append(shape)
            } else {
                print("GameStateManager: Warning - Could not find shape for name: \(shapeName)")
            }
        }
        
        // Setup pieces with the specific shapes
        gameScene.setupDraggablePieces(withSpecificShapes: shapes)
        
        print("GameStateManager: Restored \(shapes.count) specific pieces")
    }
    
    // MARK: - Helper Methods
    
    /// Extract a string representation of a color for saving
    private static func extractColorName(from color: SKColor) -> String {
        // Convert SKColor to a string representation
        // This is a simplified approach - in a real implementation you might want
        // to map colors to specific block types or save RGB values
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Create a simple string representation
        return String(format: "%.2f,%.2f,%.2f,%.2f", red, green, blue, alpha)
    }
    
    /// Convert a color name string back to SKColor
    private static func convertColorNameToSKColor(_ colorName: String) -> SKColor {
        let components = colorName.split(separator: ",").compactMap { Double($0) }
        
        guard components.count == 4 else {
            print("GameStateManager: Warning - Invalid color format: \(colorName)")
            return SKColor.gray // Default fallback color
        }
        
        return SKColor(
            red: CGFloat(components[0]),
            green: CGFloat(components[1]),
            blue: CGFloat(components[2]),
            alpha: CGFloat(components[3])
        )
    }
    
    /// Count filled cells in board state for debugging
    private static func countFilledCells(_ boardState: [[String?]]) -> Int {
        return boardState.flatMap { $0 }.compactMap { $0 }.count
    }
    
    /// Convert SelectionMode to String for storage
    private static func convertSelectionModeToString(_ mode: TetrominoShape.SelectionMode) -> String {
        switch mode {
        case .balanced:
            return "balanced"
        case .weightedRandom:
            return "weightedRandom"
        case .balancedWeighted:
            return "balancedWeighted"
        case .categoryBalanced:
            return "categoryBalanced"
        case .adaptiveBalanced:
            return "adaptiveBalanced"
        case .strategicWeighted:
            return "strategicWeighted"
        }
    }
    
    /// Convert String back to SelectionMode for restoration
    private static func convertStringToSelectionMode(_ modeString: String) -> TetrominoShape.SelectionMode {
        switch modeString {
        case "balanced":
            return .balanced
        case "weightedRandom":
            return .weightedRandom
        case "balancedWeighted":
            return .balancedWeighted
        case "categoryBalanced":
            return .categoryBalanced
        case "adaptiveBalanced":
            return .adaptiveBalanced
        case "strategicWeighted":
            return .strategicWeighted
        default:
            return .balancedWeighted // Default fallback
        }
    }
}

// MARK: - GameBoard Extension for State Management

extension GameBoard {
    /// Get the block at a specific grid position (needed for state capture)
    func getBlockAt(row: Int, column: Int) -> SKShapeNode? {
        guard row >= 0 && row < rows && column >= 0 && column < columns else {
            return nil
        }
        return grid[row][column]
    }
    
    /// Place a restored block at a specific position (needed for state restoration)
    func placeRestoredBlock(at cell: GridCell, color: SKColor) {
        guard cell.row >= 0 && cell.row < rows && 
              cell.column >= 0 && cell.column < columns else {
            print("GameBoard: Invalid cell position for restored block: \(cell)")
            return
        }
        
        // Create a new block at the specified position
        let position = GameBoardVisuals.positionForCell(cell, blockSize: blockSize)
        let block = GameBoardVisuals.createBlock(at: position, blockSize: blockSize, color: color)
        
        // Place it in the grid and add to the scene
        grid[cell.row][cell.column] = block
        boardNode.addChild(block)
    }
}

// MARK: - GameScene Extension for State Management

extension GameScene {
    /// Setup draggable pieces with specific shapes (needed for state restoration)
    func setupDraggablePieces(withSpecificShapes shapes: [TetrominoShape]) {
        // Clear any existing pieces
        pieceNodes.forEach { $0.removeFromParent() }
        pieceNodes.removeAll()
        
        // Remove any existing containers
        children.filter { $0.name?.starts(with: "pieceContainer") ?? false }.forEach { $0.removeFromParent() }
        
        // Use the provided shapes instead of random selection
        let selectedShapes = shapes.isEmpty ? 
            TetrominoShape.selection(count: 3, mode: gameController?.selectionMode ?? .balancedWeighted, gameBoard: gameBoard) :
            Array(shapes.prefix(3)) // Take up to 3 shapes
        
        // Calculate position below the grid
        let gridBottom = gameBoard.boardNode.position.y - (CGFloat(gameBoard.rows) * gameBoard.blockSize / 2)
        let yPosition = gridBottom + 80
        
        // Calculate container width based on the board width
        let boardWidth = CGFloat(gameBoard.columns) * gameBoard.blockSize
        let containerWidth = boardWidth / 3
        
        // Create and position the containers with specific shapes
        for i in 0..<3 {
            // Create container node
            let container = SKNode()
            container.name = "pieceContainer\(i)"
            container.position = CGPoint(
                x: gameBoard.boardNode.position.x + containerWidth * CGFloat(i) + containerWidth/2,
                y: yPosition
            )
            addChild(container)
            
            // Create touch target
            let touchTarget = SKShapeNode(rectOf: CGSize(width: containerWidth, height: containerWidth))
            touchTarget.fillColor = .clear
            touchTarget.strokeColor = .clear
            touchTarget.alpha = 0.8
            touchTarget.name = "draggable_piece"
            touchTarget.userData = NSMutableDictionary()
            touchTarget.userData?.setValue(i, forKey: "containerIndex")
            container.addChild(touchTarget)
            
            // Add piece to container if we have one for this position
            if i < selectedShapes.count {
                let shape = selectedShapes[i]
                let piece = PieceNode(shape: shape, color: shape.color)
                
                // Apply scale and positioning (same as original setupDraggablePieces)
                piece.setScale(0.6)
                
                let tempNode = SKNode()
                self.addChild(tempNode)
                tempNode.addChild(piece)
                
                let bounds = piece.calculateAccumulatedFrame()
                let centerOffsetX = bounds.midX - piece.position.x
                let centerOffsetY = bounds.midY - piece.position.y
                
                piece.removeFromParent()
                tempNode.removeFromParent()
                
                piece.position = CGPoint(x: -centerOffsetX, y: -centerOffsetY)
                piece.name = "piece"
                piece.zPosition = 100
                container.addChild(piece)
                pieceNodes.append(piece)
                
                // Store metadata
                piece.userData = NSMutableDictionary()
                piece.userData?.setValue(NSValue(cgPoint: CGPoint(x: centerOffsetX, y: centerOffsetY)), forKey: "centerOffset")
                
                touchTarget.userData?.setValue(piece.gridPiece.shape, forKey: "pieceShape")
                touchTarget.userData?.setValue(piece.gridPiece.shape.color, forKey: "pieceColor")
                
                // Add floating animation
                let moveAction = SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 5, duration: 0.5),
                    SKAction.moveBy(x: 0, y: -5, duration: 0.5)
                ])
                piece.run(SKAction.repeatForever(moveAction))
            }
        }
        
        print("GameScene: Setup pieces with specific shapes: \(selectedShapes.map { $0.displayName })")
    }
}
