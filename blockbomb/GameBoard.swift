import SpriteKit

class GameBoard {
    let rows = 8
    let columns = 8
    let blockSize: CGFloat = 40
    let boardNode = SKNode()
    
    // Grid state
    internal var grid: [[SKShapeNode?]]
    
    // Ghost piece visualization
    private var ghostBlocks: [SKShapeNode] = []
    
    // Storage for glow effects
    internal var glowNodes: [SKNode] = []
    
    // Storage for block color changes during glow preview
    internal var originalBlockColors: [GridCell: (fill: SKColor, stroke: SKColor)] = [:]
    
    // Line clearing state management
    internal var clearingInProgress: Bool = false
    internal var blocksPendingClear: Set<GridCell> = []
    
    init() {
        // Initialize empty grid
        grid = Array(repeating: Array(repeating: nil, count: columns), count: rows)
        
        // Setup board visuals using centralized system
        GameBoardVisuals.setupBoardVisuals(
            columns: columns,
            rows: rows,
            blockSize: blockSize,
            boardNode: boardNode
        )
    }
    
    func reset() {
        // Clear the grid
        for i in 0..<rows {
            for j in 0..<columns {
                if let block = grid[i][j] {
                    block.removeFromParent()
                    grid[i][j] = nil
                }
            }
        }
        
        clearGhostPiece()
    }
    
    // Convert a position in the scene to a grid cell
    func gridCellAt(scenePosition: CGPoint) -> GridCell? {
        let boardPosition = boardNode.convert(scenePosition, from: boardNode.scene!)
        
        let col = Int(floor(boardPosition.x / blockSize))
        let row = Int(floor(boardPosition.y / blockSize))
        
        if col >= 0 && col < columns && row >= 0 && row < rows {
            return GridCell(column: col, row: row)
        } else {
            return nil
        }
    }
    
    // Check if a piece can be placed at the given grid cell
    func canPlacePiece(_ piece: GridPiece, at origin: GridCell) -> Bool {
        let cellsToOccupy = piece.absoluteCells(at: origin)
        
        for cell in cellsToOccupy {
            // Check if outside grid bounds
            if cell.column < 0 || cell.column >= columns || cell.row < 0 || cell.row >= rows {
                return false
            }
            
            // Check if cell is already occupied
            if grid[cell.row][cell.column] != nil {
                return false
            }
        }
        
        return true
    }
    
    // Place a piece at the given grid cell
    func placePiece(_ piece: GridPiece, at origin: GridCell) -> (rows: Int, columns: Int) {
        let cellsToOccupy = piece.absoluteCells(at: origin)
        
        // Place blocks on the grid
        for cell in cellsToOccupy {
            let block = createBlock(at: cell, color: piece.color)
            grid[cell.row][cell.column] = block
            boardNode.addChild(block)
        }
        
        clearGhostPiece()
        
        // Check for completed rows and columns
        return clearCompletedLines()
    }
    
    // Show a ghost preview of where the piece would be placed
    func showGhostPiece(_ piece: GridPiece, at origin: GridCell) {
        clearGhostPiece()
        
        // Only show ghost if piece can be placed
        if canPlacePiece(piece, at: origin) {
            let cellsToOccupy = piece.absoluteCells(at: origin)
            
            for cell in cellsToOccupy {
                let position = GameBoardVisuals.positionForCell(cell, blockSize: blockSize)
                let ghost = GameBoardVisuals.createBlock(at: position, blockSize: blockSize, color: piece.color, isGhost: true)
                boardNode.addChild(ghost)
                ghostBlocks.append(ghost)
            }
        }
    }
    
    // Change from private to public
    func clearGhostPiece() {
        for ghost in ghostBlocks {
            ghost.removeFromParent()
        }
        ghostBlocks.removeAll()
        
        // Also clear glow effects when clearing ghost piece
        clearCompletionGlow()
    }
    
    internal func createBlock(at cell: GridCell, color: SKColor) -> SKShapeNode {
        let position = GameBoardVisuals.positionForCell(cell, blockSize: blockSize)
        return GameBoardVisuals.createBlock(at: position, blockSize: blockSize, color: color)
    }
    
    func boardPositionForCell(_ cell: GridCell) -> CGPoint {
        // Convert grid cell to position in board coordinates using centralized method
        return GameBoardVisuals.positionForCell(cell, blockSize: blockSize)
    }

    // Improved resetBoard method
    func resetBoard() {
        // Clear the grid data and remove blocks from the scene
        for row in 0..<rows {
            for column in 0..<columns {
                if let block = grid[row][column] {
                    block.removeFromParent()
                }
                grid[row][column] = nil
            }
        }
        
        clearGhostPiece()
        
        // Refresh board visuals using centralized system
        GameBoardVisuals.refreshBoardVisuals(
            boardNode: boardNode,
            columns: columns,
            rows: rows,
            blockSize: blockSize
        )
    }
    
    // Modified method without rotations - simply check if the piece can be placed anywhere
    func canPlacePieceAnywhereWithRotations(_ piece: GridPiece) -> Bool {
        // No rotations allowed, just check if the piece can be placed anywhere
        return canPlacePieceAnywhere(piece)
    }
    
    // Check if a piece can be placed anywhere on the board
    func canPlacePieceAnywhere(_ piece: GridPiece) -> Bool {
        let shapeName = piece.shape.displayName
        var validPositions = 0
        var totalPositions = 0
        
        for row in 0..<rows {
            for col in 0..<columns {
                totalPositions += 1
                let cell = GridCell(column: col, row: row)
                if canPlacePiece(piece, at: cell) {
                    validPositions += 1
                    // Found at least one valid position - piece can be placed
                    print("DEBUG: \(shapeName) CAN be placed at (\(col),\(row))")
                    return true
                }
            }
        }
        
        print("DEBUG: \(shapeName) CANNOT be placed anywhere - checked \(totalPositions) positions, found \(validPositions) valid")
        return false
    }
    
    // Helper method to check if a position is within grid bounds
    internal func isValidPosition(_ position: GridCell) -> Bool {
        return position.row >= 0 && position.row < rows && 
               position.column >= 0 && position.column < columns
    }
}
