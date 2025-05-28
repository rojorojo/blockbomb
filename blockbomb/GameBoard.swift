import SpriteKit

class GameBoard {
    let rows = 8
    let columns = 8
    let blockSize: CGFloat = 40
    let boardNode = SKNode()
    
    // Grid state
    private var grid: [[SKShapeNode?]]
    
    // Ghost piece visualization
    private var ghostBlocks: [SKShapeNode] = []
    
    // Storage for glow effects
    private var glowNodes: [SKNode] = []
    
    // Storage for block color changes during glow preview
    private var originalBlockColors: [GridCell: (fill: SKColor, stroke: SKColor)] = [:]
    
    // Line clearing state management
    private var clearingInProgress: Bool = false
    private var blocksPendingClear: Set<GridCell> = []
    
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
    
    private func createBlock(at cell: GridCell, color: SKColor) -> SKShapeNode {
        let position = GameBoardVisuals.positionForCell(cell, blockSize: blockSize)
        return GameBoardVisuals.createBlock(at: position, blockSize: blockSize, color: color)
    }
    
    // Modified method to check and clear both rows and columns with proper synchronization
    func clearCompletedLines() -> (rows: Int, columns: Int) {
        // Prevent concurrent clearing operations
        guard !clearingInProgress else {
            return (rows: 0, columns: 0)
        }
        
        var rowsCleared = 0
        var columnsCleared = 0
        
        // Track which rows/columns need to be cleared
        var rowsToClear = Set<Int>()
        var columnsToClear = Set<Int>()
        
        // Check for completed rows (considering blocks pending clear)
        for row in 0..<rows {
            var rowComplete = true
            for col in 0..<columns {
                let cell = GridCell(column: col, row: row)
                // Consider cell empty if it's nil OR pending clear
                if grid[row][col] == nil || blocksPendingClear.contains(cell) {
                    rowComplete = false
                    break
                }
            }
            
            if rowComplete {
                rowsToClear.insert(row)
                rowsCleared += 1
            }
        }
        
        // Check for completed columns (considering blocks pending clear)
        for col in 0..<columns {
            var columnComplete = true
            for row in 0..<rows {
                let cell = GridCell(column: col, row: row)
                // Consider cell empty if it's nil OR pending clear
                if grid[row][col] == nil || blocksPendingClear.contains(cell) {
                    columnComplete = false
                    break
                }
            }
            
            if columnComplete {
                columnsToClear.insert(col)
                columnsCleared += 1
            }
        }
        
        // If no lines to clear, return early
        if rowsToClear.isEmpty && columnsToClear.isEmpty {
            return (rows: 0, columns: 0)
        }
        
        // Mark clearing in progress
        clearingInProgress = true
        
        // Collect all cells that need to be cleared
        var cellsToClear = Set<GridCell>()
        
        for row in rowsToClear {
            for col in 0..<columns {
                cellsToClear.insert(GridCell(column: col, row: row))
            }
        }
        
        for col in columnsToClear {
            for row in 0..<rows {
                cellsToClear.insert(GridCell(column: col, row: row))
            }
        }
        
        // Add to pending clear set
        blocksPendingClear.formUnion(cellsToClear)
        
        // Start animations and clear cells after animation completes
        clearCellsWithSynchronizedAnimation(cellsToClear)
        
        // Return the counts
        return (rowsCleared, columnsCleared)
    }
    
    // Legacy methods - kept for potential debugging but not used in main clearing system
    // These are replaced by the synchronized clearing system above
    
    // Clear a single row with animation (deprecated - use synchronized system)
    private func clearRow(_ row: Int) {
        print("Warning: Using deprecated clearRow method - should use synchronized clearing")
        for col in 0..<columns {
            if let block = grid[row][col] {
                animateBlockClearing(block)
                grid[row][col] = nil
            }
        }
    }
    
    // Clear a single column with animation (deprecated - use synchronized system)
    private func clearColumn(_ col: Int) {
        print("Warning: Using deprecated clearColumn method - should use synchronized clearing")
        for row in 0..<rows {
            if let block = grid[row][col] {
                animateBlockClearing(block)
                grid[row][col] = nil
            }
        }
    }
    
    // Common animation for clearing blocks (deprecated - use synchronized system)
    private func animateBlockClearing(_ block: SKShapeNode) {
        print("Warning: Using deprecated animateBlockClearing method - should use synchronized clearing")
        // Use centralized animation
        block.run(GameBoardVisuals.createBlockClearingAnimation())
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
        for row in 0..<rows {
            for col in 0..<columns {
                let cell = GridCell(column: col, row: row)
                if canPlacePiece(piece, at: cell) {
                    return true
                }
            }
        }
        return false
    }
    
    // Calculate board capacity as percentage of filled cells
    func getBoardCapacity() -> Float {
        var filledCells = 0
        let totalCells = rows * columns
        
        for row in 0..<rows {
            for col in 0..<columns {
                if grid[row][col] != nil {
                    filledCells += 1
                }
            }
        }
        
        return Float(filledCells) / Float(totalCells)
    }
    
    // Check if board is in "rescue mode" (80% or more filled)
    func isInRescueMode() -> Bool {
        return getBoardCapacity() >= 0.8
    }
}

// MARK: - Completion Detection for Glow Preview

extension GameBoard {
    // Check which rows and columns would be completed if piece is placed at origin
    func getCompletionPreview(for piece: GridPiece, at origin: GridCell) -> (rows: Set<Int>, columns: Set<Int>) {
        guard canPlacePiece(piece, at: origin) else {
            return (rows: Set<Int>(), columns: Set<Int>())
        }
        
        let cellsToOccupy = piece.absoluteCells(at: origin)
        var rowsToCheck = Set<Int>()
        var columnsToCheck = Set<Int>()
        
        // Collect all rows and columns that would be affected by placing this piece
        for cell in cellsToOccupy {
            rowsToCheck.insert(cell.row)
            columnsToCheck.insert(cell.column)
        }
        
        var completedRows = Set<Int>()
        var completedColumns = Set<Int>()
        
        // Check each affected row for completion
        for row in rowsToCheck {
            if wouldRowBeCompleted(row, withPieceCells: cellsToOccupy) {
                completedRows.insert(row)
            }
        }
        
        // Check each affected column for completion
        for column in columnsToCheck {
            if wouldColumnBeCompleted(column, withPieceCells: cellsToOccupy) {
                completedColumns.insert(column)
            }
        }
        
        return (rows: completedRows, columns: completedColumns)
    }
    
    // Check if a row would be completed with the addition of piece cells
    private func wouldRowBeCompleted(_ row: Int, withPieceCells pieceCells: [GridCell]) -> Bool {
        for col in 0..<columns {
            let cell = GridCell(column: col, row: row)
            
            // Cell is filled if it already has a block OR the piece would place a block there
            let isAlreadyFilled = grid[row][col] != nil
            let wouldBeFilled = pieceCells.contains(cell)
            
            if !isAlreadyFilled && !wouldBeFilled {
                return false
            }
        }
        return true
    }
    
    // Check if a column would be completed with the addition of piece cells
    private func wouldColumnBeCompleted(_ column: Int, withPieceCells pieceCells: [GridCell]) -> Bool {
        for row in 0..<rows {
            let cell = GridCell(column: column, row: row)
            
            // Cell is filled if it already has a block OR the piece would place a block there
            let isAlreadyFilled = grid[row][column] != nil
            let wouldBeFilled = pieceCells.contains(cell)
            
            if !isAlreadyFilled && !wouldBeFilled {
                return false
            }
        }
        return true
    }
}

// MARK: - Glow Effect Management

extension GameBoard {
    // Show glow effects for rows and columns that would be completed
    func showCompletionGlow(for piece: GridPiece, at origin: GridCell) {
        clearCompletionGlow()
        
        let completion = getCompletionPreview(for: piece, at: origin)
        
        // Create glow effects for completed rows
        for row in completion.rows {
            let glowNode = GameBoardVisuals.createRowGlow(
                row: row,
                columns: columns,
                blockSize: blockSize,
                color: piece.color
            )
            boardNode.addChild(glowNode)
            glowNodes.append(glowNode)
            
            // Start glow animation
            glowNode.run(GameBoardVisuals.createGlowPulseAnimation())
            
            // Change colors of existing blocks in this row
            changeBlockColorsInRow(row, to: piece.color)
        }
        
        // Create glow effects for completed columns
        for column in completion.columns {
            let glowNode = GameBoardVisuals.createColumnGlow(
                column: column,
                rows: rows,
                blockSize: blockSize,
                color: piece.color
            )
            boardNode.addChild(glowNode)
            glowNodes.append(glowNode)
            
            // Start glow animation
            glowNode.run(GameBoardVisuals.createGlowPulseAnimation())
            
            // Change colors of existing blocks in this column
            changeBlockColorsInColumn(column, to: piece.color)
        }
    }
    
    // Clear all glow effects
    func clearCompletionGlow() {
        for glowNode in glowNodes {
            glowNode.removeFromParent()
        }
        glowNodes.removeAll()
        
        // Restore original block colors
        restoreOriginalBlockColors()
    }
    
    // MARK: - Block Color Management for Glow Effects
    
    /// Changes the colors of existing blocks in a specific row to match the glow
    private func changeBlockColorsInRow(_ row: Int, to color: SKColor) {
        for col in 0..<columns {
            let cell = GridCell(column: col, row: row)
            if let block = grid[row][col] {
                // Store original colors if not already stored
                if originalBlockColors[cell] == nil {
                    originalBlockColors[cell] = (fill: block.fillColor, stroke: block.strokeColor)
                }
                
                // Apply glow color to the block
                block.fillColor = color.withAlphaComponent(0.8)
                block.strokeColor = color
                block.lineWidth = 2
            }
        }
    }
    
    /// Changes the colors of existing blocks in a specific column to match the glow
    private func changeBlockColorsInColumn(_ column: Int, to color: SKColor) {
        for row in 0..<rows {
            let cell = GridCell(column: column, row: row)
            if let block = grid[row][column] {
                // Store original colors if not already stored (avoid overwriting if row already changed it)
                if originalBlockColors[cell] == nil {
                    originalBlockColors[cell] = (fill: block.fillColor, stroke: block.strokeColor)
                }
                
                // Apply glow color to the block
                block.fillColor = color.withAlphaComponent(0.8)
                block.strokeColor = color
                block.lineWidth = 2
            }
        }
    }
    
    /// Restores the original colors of all blocks that were changed for glow effects
    private func restoreOriginalBlockColors() {
        for (cell, colors) in originalBlockColors {
            if let block = grid[cell.row][cell.column] {
                block.fillColor = colors.fill
                block.strokeColor = colors.stroke
                block.lineWidth = 1 // Reset to default line width
            }
        }
        originalBlockColors.removeAll()
    }
}

// MARK: - Synchronized Clearing System

extension GameBoard {
    // Clear cells with synchronized animation to prevent race conditions
    private func clearCellsWithSynchronizedAnimation(_ cellsToClear: Set<GridCell>) {
        var blocksToAnimate: [SKShapeNode] = []
        
        // Collect all blocks that need animation
        for cell in cellsToClear {
            if let block = grid[cell.row][cell.column] {
                blocksToAnimate.append(block)
            }
        }
        
        // If no blocks to animate, complete immediately
        guard !blocksToAnimate.isEmpty else {
            completeClearingOperation(cellsToClear)
            return
        }
        
        // Create animation group with completion handler
        let animationGroup = SKAction.group(blocksToAnimate.map { _ in 
            GameBoardVisuals.createBlockClearingAnimation() 
        })
        
        // Run animation on a dummy node to track completion
        let dummyNode = SKNode()
        boardNode.addChild(dummyNode)
        
        // Start animations on all blocks
        for block in blocksToAnimate {
            block.run(GameBoardVisuals.createBlockClearingAnimation())
        }
        
        // Track completion using dummy node
        dummyNode.run(animationGroup) { [weak self] in
            dummyNode.removeFromParent()
            self?.completeClearingOperation(cellsToClear)
        }
    }
    
    // Complete the clearing operation after animations finish
    private func completeClearingOperation(_ cellsToClear: Set<GridCell>) {
        // Actually remove blocks from grid
        for cell in cellsToClear {
            if let block = grid[cell.row][cell.column] {
                block.removeFromParent()
                grid[cell.row][cell.column] = nil
            }
        }
        
        // Clear pending state
        blocksPendingClear.subtract(cellsToClear)
        
        // Reset clearing flag
        clearingInProgress = false
    }
}
