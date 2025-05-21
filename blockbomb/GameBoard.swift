import SpriteKit

class GameBoard {
    let rows = 10
    let columns = 10
    let blockSize: CGFloat = 30
    let boardNode = SKNode()
    
    // Grid state
    private var grid: [[SKShapeNode?]]
    
    // Ghost piece visualization
    private var ghostBlocks: [SKShapeNode] = []
    
    init() {
        // Initialize empty grid
        grid = Array(repeating: Array(repeating: nil, count: columns), count: rows)
        
        // Draw background
        let background = SKShapeNode(rectOf: CGSize(width: CGFloat(columns) * blockSize,
                                                  height: CGFloat(rows) * blockSize))
        background.fillColor = SKColor(white: 0.2, alpha: 0.8)
        background.strokeColor = .clear
        background.lineWidth = 0
        background.position = CGPoint(x: CGFloat(columns) * blockSize / 2, y: CGFloat(rows) * blockSize / 2)
        boardNode.addChild(background)
        
        // Draw grid lines
        let gridLines = SKShapeNode()
        let path = CGMutablePath()
        
        // Vertical lines
        for i in 0...columns {
            let x = CGFloat(i) * blockSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: CGFloat(rows) * blockSize))
        }
        
        // Horizontal lines
        for i in 0...rows {
            let y = CGFloat(i) * blockSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: CGFloat(columns) * blockSize, y: y))
        }
        
        gridLines.path = path
        gridLines.strokeColor = SKColor(white: 0.0, alpha: 0.9)
        gridLines.lineWidth = 1
        boardNode.addChild(gridLines)
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
    func placePiece(_ piece: GridPiece, at origin: GridCell) -> Int {
        let cellsToOccupy = piece.absoluteCells(at: origin)
        
        // Place blocks on the grid
        for cell in cellsToOccupy {
            let block = createBlock(at: cell, color: piece.color)
            grid[cell.row][cell.column] = block
            boardNode.addChild(block)
        }
        
        clearGhostPiece()
        
        // Check for completed rows
        return clearCompletedRows()
    }
    
    // Show a ghost preview of where the piece would be placed
    func showGhostPiece(_ piece: GridPiece, at origin: GridCell) {
        clearGhostPiece()
        
        // Only show ghost if piece can be placed
        if canPlacePiece(piece, at: origin) {
            let cellsToOccupy = piece.absoluteCells(at: origin)
            
            for cell in cellsToOccupy {
                let ghost = createBlock(at: cell, color: piece.color.withAlphaComponent(0.3))
                ghost.strokeColor = piece.color
                ghost.fillColor = piece.color.withAlphaComponent(0.3)
                ghost.lineWidth = 2
                boardNode.addChild(ghost)
                ghostBlocks.append(ghost)
            }
        }
    }
    
    private func clearGhostPiece() {
        for ghost in ghostBlocks {
            ghost.removeFromParent()
        }
        ghostBlocks.removeAll()
    }
    
    private func createBlock(at cell: GridCell, color: SKColor) -> SKShapeNode {
        let block = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 3)
        block.position = CGPoint(
            x: CGFloat(cell.column) * blockSize + blockSize/2,
            y: CGFloat(cell.row) * blockSize + blockSize/2
        )
        block.fillColor = color
        block.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        block.lineWidth = 1
        return block
    }
    
    private func clearCompletedRows() -> Int {
        var rowsCleared = 0
        
        for row in 0..<rows {
            var rowComplete = true
            
            // Check if row is complete
            for col in 0..<columns {
                if grid[row][col] == nil {
                    rowComplete = false
                    break
                }
            }
            
            if rowComplete {
                clearRow(row)
                //shiftRowsDown(startingAt: row + 1)
                rowsCleared += 1
            }
        }
        
        return rowsCleared
    }
    
    private func clearRow(_ row: Int) {
        for col in 0..<columns {
            if let block = grid[row][col] {
                block.run(SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.05),
                    SKAction.scale(to: 0.1, duration: 0.1),
                    SKAction.removeFromParent()
                ]))
                grid[row][col] = nil
            }
        }
    }
    
    private func shiftRowsDown(startingAt startRow: Int) {
        for row in (startRow..<rows).reversed() {
            for col in 0..<columns {
                if let block = grid[row][col] {
                    grid[row-1][col] = block
                    block.run(SKAction.moveBy(x: 0, y: -blockSize, duration: 0.1))
                    grid[row][col] = nil
                }
            }
        }
    }
}
