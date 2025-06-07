import SpriteKit

// Board difficulty levels for progressive rescue system
enum BoardDifficultyLevel: String, CaseIterable {
    case comfortable = "Comfortable"    // 0-50% filled
    case moderate = "Moderate"          // 50-60% filled
    case challenging = "Challenging"    // 60-75% filled
    case difficult = "Difficult"       // 75-85% filled
    case critical = "Critical"          // 85%+ filled
}

// Analysis of line completion opportunities
struct LineCompletionAnalysis {
    let rowGaps: [Int: Int]              // row index -> number of empty cells
    let columnGaps: [Int: Int]           // column index -> number of empty cells
    let singleGapRows: Int               // number of rows with only 1 empty cell
    let singleGapColumns: Int            // number of columns with only 1 empty cell
    let totalNearCompletionLines: Int    // total rows + columns close to completion
    let potentialMultiLineClear: Int     // estimated potential for clearing multiple lines simultaneously
    
    var hasHighClearingPotential: Bool {
        return singleGapRows + singleGapColumns >= 2 || totalNearCompletionLines >= 4
    }
}

// Analysis of empty space patterns
struct SpacePatternAnalysis {
    let largestContiguousArea: Int       // size of largest empty area
    let totalEmptySpaces: Int            // total empty cells
    let contiguousAreas: [Int]           // sizes of all contiguous areas
    let averageAreaSize: Int             // average size of empty areas
    let fragmentationLevel: Float        // how fragmented the empty space is (0-1)
    
    var isHighlyFragmented: Bool {
        return fragmentationLevel > 0.3 || averageAreaSize < 3
    }
    
    // Computed properties for strategic placement analysis
    var isolatedSpaces: Int {
        return contiguousAreas.filter { $0 == 1 }.count
    }
    
    var smallClusters: Int {
        return contiguousAreas.filter { $0 >= 2 && $0 <= 3 }.count
    }
    
    var fragmentationScore: Float {
        return fragmentationLevel * 100 // Convert to 0-100 scale
    }
}

// Analysis of strategic placement opportunities for 4+ cell gaps
struct StrategicPlacementAnalysis {
    let largeRowGaps: [Int: [StrategicGap]]     // row index -> gaps of 4+ cells
    let largeColumnGaps: [Int: [StrategicGap]]  // column index -> gaps of 4+ cells
    let optimalPlacements: [PlacementOpportunity] // specific shape placement recommendations
    let totalLargeGaps: Int                     // total number of 4+ cell gaps
    let averageGapSize: Float                   // average size of large gaps
    
    var hasStrategicOpportunities: Bool {
        return totalLargeGaps >= 2 || optimalPlacements.count >= 3
    }
}

// Represents a strategic gap in a row or column
struct StrategicGap {
    let startIndex: Int      // starting position of the gap
    let length: Int          // length of the gap
    let isContiguous: Bool   // whether the gap is uninterrupted
    let recommendedShapes: [TetrominoShape] // shapes that would fit well
}

// Represents a specific placement opportunity
struct PlacementOpportunity {
    let shape: TetrominoShape
    let position: GridCell
    let efficiency: Float    // how well the shape fits (0.0-1.0)
    let clearingPotential: Int // number of lines this could help complete
}

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
    
    // Progressive difficulty levels based on board capacity
    func getDifficultyLevel() -> BoardDifficultyLevel {
        let capacity = getBoardCapacity()
        
        switch capacity {
        case 0.0..<0.4:
            return .comfortable
        case 0.4..<0.55:
            return .moderate
        case 0.55..<0.7:
            return .challenging
        case 0.7..<0.8:
            return .difficult
        default:
            return .critical
        }
    }
    
    // Check if board is in "rescue mode" (now starts earlier at 50%)
    func isInRescueMode() -> Bool {
        return getBoardCapacity() >= 0.5
    }
    
    // Analyze board for line completion opportunities
    func getLineCompletionOpportunities() -> LineCompletionAnalysis {
        var rowGaps: [Int: Int] = [:]  // row index -> number of empty cells
        var columnGaps: [Int: Int] = [:]  // column index -> number of empty cells
        
        // Analyze rows
        for row in 0..<rows {
            var emptyCount = 0
            for col in 0..<columns {
                if grid[row][col] == nil {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 && emptyCount <= 5 { // Consider rows that are close to completion (1-5 empty cells)
                rowGaps[row] = emptyCount
            }
        }
        
        // Analyze columns
        for col in 0..<columns {
            var emptyCount = 0
            for row in 0..<rows {
                if grid[row][col] == nil {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 && emptyCount <= 5 { // Consider columns that are close to completion (1-5 empty cells)
                columnGaps[col] = emptyCount
            }
        }
        
        // Calculate potential for multi-line clears
        let potentialMultiLineClear = calculatePotentialMultiLineClear(rowGaps: rowGaps, columnGaps: columnGaps)
        
        return LineCompletionAnalysis(
            rowGaps: rowGaps,
            columnGaps: columnGaps,
            singleGapRows: rowGaps.filter { $0.value == 1 }.keys.count,
            singleGapColumns: columnGaps.filter { $0.value == 1 }.keys.count,
            totalNearCompletionLines: rowGaps.count + columnGaps.count,
            potentialMultiLineClear: potentialMultiLineClear
        )
    }
    
    // Calculate potential for clearing multiple lines simultaneously
    private func calculatePotentialMultiLineClear(rowGaps: [Int: Int], columnGaps: [Int: Int]) -> Int {
        var multiLinePotential = 0
        
        // Count rows that could be completed with 1-2 pieces
        let nearCompleteRows = rowGaps.filter { $0.value <= 2 }.count
        let nearCompleteColumns = columnGaps.filter { $0.value <= 2 }.count
        
        // Higher potential if multiple rows/columns are close to completion
        if nearCompleteRows >= 2 {
            multiLinePotential += nearCompleteRows
        }
        
        if nearCompleteColumns >= 2 {
            multiLinePotential += nearCompleteColumns
        }
        
        // Bonus for intersecting near-complete lines (could clear both with one piece)
        for (row, rowGapCount) in rowGaps where rowGapCount <= 2 {
            for (col, colGapCount) in columnGaps where colGapCount <= 2 {
                if grid[row][col] == nil {
                    multiLinePotential += 1 // Intersection bonus
                }
            }
        }
        
        return multiLinePotential
    }
    
    // Analyze available space patterns for strategic piece selection
    func getSpacePatternAnalysis() -> SpacePatternAnalysis {
        var largestEmptyArea = 0
        var totalEmptySpaces = 0
        var contiguousAreas: [Int] = []
        var visited = Array(repeating: Array(repeating: false, count: columns), count: rows)
        
        // Find all contiguous empty areas using flood fill
        for row in 0..<rows {
            for col in 0..<columns {
                if grid[row][col] == nil && !visited[row][col] {
                    let areaSize = floodFillEmptyArea(row: row, col: col, visited: &visited)
                    contiguousAreas.append(areaSize)
                    largestEmptyArea = max(largestEmptyArea, areaSize)
                    totalEmptySpaces += areaSize
                }
            }
        }
        
        return SpacePatternAnalysis(
            largestContiguousArea: largestEmptyArea,
            totalEmptySpaces: totalEmptySpaces,
            contiguousAreas: contiguousAreas,
            averageAreaSize: contiguousAreas.isEmpty ? 0 : contiguousAreas.reduce(0, +) / contiguousAreas.count,
            fragmentationLevel: Float(contiguousAreas.count) / Float(max(1, totalEmptySpaces))
        )
    }
    
    // Analyze strategic placement opportunities for 4+ cell gaps
    func getStrategicPlacementAnalysis() -> StrategicPlacementAnalysis {
        var largeRowGaps: [Int: [StrategicGap]] = [:]
        var largeColumnGaps: [Int: [StrategicGap]] = [:]
        var optimalPlacements: [PlacementOpportunity] = []
        var totalLargeGaps = 0
        var totalGapSize = 0
        
        // Analyze rows for 4+ cell gaps
        for row in 0..<rows {
            let gaps = findStrategicGapsInRow(row)
            if !gaps.isEmpty {
                largeRowGaps[row] = gaps
                totalLargeGaps += gaps.count
                totalGapSize += gaps.reduce(0) { $0 + $1.length }
                
                // Find optimal placements for each gap
                for gap in gaps {
                    let placements = findOptimalPlacementsForGap(gap, inRow: row, isRowGap: true)
                    optimalPlacements.append(contentsOf: placements)
                }
            }
        }
        
        // Analyze columns for 4+ cell gaps
        for col in 0..<columns {
            let gaps = findStrategicGapsInColumn(col)
            if !gaps.isEmpty {
                largeColumnGaps[col] = gaps
                totalLargeGaps += gaps.count
                totalGapSize += gaps.reduce(0) { $0 + $1.length }
                
                // Find optimal placements for each gap
                for gap in gaps {
                    let placements = findOptimalPlacementsForGap(gap, inColumn: col, isRowGap: false)
                    optimalPlacements.append(contentsOf: placements)
                }
            }
        }
        
        // Sort placements by efficiency and clearing potential
        optimalPlacements.sort { placement1, placement2 in
            if placement1.clearingPotential != placement2.clearingPotential {
                return placement1.clearingPotential > placement2.clearingPotential
            }
            return placement1.efficiency > placement2.efficiency
        }
        
        // Keep only the top placements to avoid overwhelming the system
        optimalPlacements = Array(optimalPlacements.prefix(10))
        
        let averageGapSize = totalLargeGaps > 0 ? Float(totalGapSize) / Float(totalLargeGaps) : 0.0
        
        return StrategicPlacementAnalysis(
            largeRowGaps: largeRowGaps,
            largeColumnGaps: largeColumnGaps,
            optimalPlacements: optimalPlacements,
            totalLargeGaps: totalLargeGaps,
            averageGapSize: averageGapSize
        )
    }
    
    // Find strategic gaps (4+ cells) in a specific row
    private func findStrategicGapsInRow(_ row: Int) -> [StrategicGap] {
        var gaps: [StrategicGap] = []
        var currentGapStart: Int? = nil
        var currentGapLength = 0
        
        for col in 0..<columns {
            if grid[row][col] == nil {
                if currentGapStart == nil {
                    currentGapStart = col
                    currentGapLength = 1
                } else {
                    currentGapLength += 1
                }
            } else {
                if let gapStart = currentGapStart, currentGapLength >= 4 {
                    let gap = StrategicGap(
                        startIndex: gapStart,
                        length: currentGapLength,
                        isContiguous: true,
                        recommendedShapes: getRecommendedShapesForGap(length: currentGapLength, isHorizontal: true)
                    )
                    gaps.append(gap)
                }
                currentGapStart = nil
                currentGapLength = 0
            }
        }
        
        // Check for gap at end of row
        if let gapStart = currentGapStart, currentGapLength >= 4 {
            let gap = StrategicGap(
                startIndex: gapStart,
                length: currentGapLength,
                isContiguous: true,
                recommendedShapes: getRecommendedShapesForGap(length: currentGapLength, isHorizontal: true)
            )
            gaps.append(gap)
        }
        
        return gaps
    }
    
    // Find strategic gaps (4+ cells) in a specific column
    private func findStrategicGapsInColumn(_ col: Int) -> [StrategicGap] {
        var gaps: [StrategicGap] = []
        var currentGapStart: Int? = nil
        var currentGapLength = 0
        
        for row in 0..<rows {
            if grid[row][col] == nil {
                if currentGapStart == nil {
                    currentGapStart = row
                    currentGapLength = 1
                } else {
                    currentGapLength += 1
                }
            } else {
                if let gapStart = currentGapStart, currentGapLength >= 4 {
                    let gap = StrategicGap(
                        startIndex: gapStart,
                        length: currentGapLength,
                        isContiguous: true,
                        recommendedShapes: getRecommendedShapesForGap(length: currentGapLength, isHorizontal: false)
                    )
                    gaps.append(gap)
                }
                currentGapStart = nil
                currentGapLength = 0
            }
        }
        
        // Check for gap at end of column
        if let gapStart = currentGapStart, currentGapLength >= 4 {
            let gap = StrategicGap(
                startIndex: gapStart,
                length: currentGapLength,
                isContiguous: true,
                recommendedShapes: getRecommendedShapesForGap(length: currentGapLength, isHorizontal: false)
            )
            gaps.append(gap)
        }
        
        return gaps
    }
    
    // Get recommended shapes for a gap of specific length
    private func getRecommendedShapesForGap(length: Int, isHorizontal: Bool) -> [TetrominoShape] {
        let allShapes = TetrominoShape.allCases
        var recommendedShapes: [TetrominoShape] = []
        
        for shape in allShapes {
            let shapeWidth = getShapeWidth(shape)
            let shapeHeight = getShapeHeight(shape)
            
            if isHorizontal {
                // For horizontal gaps, check if shape width fits
                if shapeWidth <= length && shapeWidth >= length - 1 {
                    recommendedShapes.append(shape)
                }
            } else {
                // For vertical gaps, check if shape height fits
                if shapeHeight <= length && shapeHeight >= length - 1 {
                    recommendedShapes.append(shape)
                }
            }
        }
        
        return recommendedShapes
    }
    
    // Find optimal placements for a gap in a row
    private func findOptimalPlacementsForGap(_ gap: StrategicGap, inRow row: Int, isRowGap: Bool) -> [PlacementOpportunity] {
        var placements: [PlacementOpportunity] = []
        
        for shape in gap.recommendedShapes {
            if isRowGap {
                // Try different positions within the row gap
                for col in gap.startIndex...(gap.startIndex + gap.length - getShapeWidth(shape)) {
                    let position = GridCell(column: col, row: row)
                    if let opportunity = evaluatePlacementOpportunity(shape: shape, at: position) {
                        placements.append(opportunity)
                    }
                }
            }
        }
        
        return placements
    }
    
    // Find optimal placements for a gap in a column
    private func findOptimalPlacementsForGap(_ gap: StrategicGap, inColumn col: Int, isRowGap: Bool) -> [PlacementOpportunity] {
        var placements: [PlacementOpportunity] = []
        
        for shape in gap.recommendedShapes {
            if !isRowGap {
                // Try different positions within the column gap
                for row in gap.startIndex...(gap.startIndex + gap.length - getShapeHeight(shape)) {
                    let position = GridCell(column: col, row: row)
                    if let opportunity = evaluatePlacementOpportunity(shape: shape, at: position) {
                        placements.append(opportunity)
                    }
                }
            }
        }
        
        return placements
    }
    
    // Evaluate a specific placement opportunity
    private func evaluatePlacementOpportunity(shape: TetrominoShape, at position: GridCell) -> PlacementOpportunity? {
        let piece = GridPiece(shape: shape, color: shape.color)
        
        // Check if placement is valid
        guard canPlacePiece(piece, at: position) else { return nil }
        
        let absoluteCells = piece.absoluteCells(at: position)
        let shapeSize = absoluteCells.count
        
        // Calculate efficiency based on how well the shape fills the available space
        var efficiency: Float = 0.0
        var adjacentFilledCells = 0
        var clearingPotential = 0
        
        // Check adjacent cells to see how well this placement fits
        for cell in absoluteCells {
            let adjacentPositions = [
                GridCell(column: cell.column - 1, row: cell.row),
                GridCell(column: cell.column + 1, row: cell.row),
                GridCell(column: cell.column, row: cell.row - 1),
                GridCell(column: cell.column, row: cell.row + 1)
            ]
            
            for adjPos in adjacentPositions {
                if isValidPosition(adjPos) && grid[adjPos.row][adjPos.column] != nil {
                    adjacentFilledCells += 1
                }
            }
        }
        
        // Calculate efficiency based on adjacent filled cells (better fit = higher efficiency)
        efficiency = Float(adjacentFilledCells) / Float(shapeSize * 4) // Normalize by max possible adjacent cells
        
        // Calculate clearing potential
        let completionPreview = getCompletionPreview(for: piece, at: position)
        clearingPotential = completionPreview.rows.count + completionPreview.columns.count
        
        // Bonus for larger shapes in larger gaps
        let sizeBonusEfficiency = min(Float(shapeSize) / 9.0, 1.0) * 0.2 // Max 20% bonus for large shapes
        efficiency += sizeBonusEfficiency
        
        return PlacementOpportunity(
            shape: shape,
            position: position,
            efficiency: min(efficiency, 1.0), // Cap at 1.0
            clearingPotential: clearingPotential
        )
    }
    
    // Helper method to get shape width
    private func getShapeWidth(_ shape: TetrominoShape) -> Int {
        let cells = shape.cells
        let maxCol = cells.map { $0.column }.max() ?? 0
        let minCol = cells.map { $0.column }.min() ?? 0
        return maxCol - minCol + 1
    }
    
    // Helper method to get shape height
    private func getShapeHeight(_ shape: TetrominoShape) -> Int {
        let cells = shape.cells
        let maxRow = cells.map { $0.row }.max() ?? 0
        let minRow = cells.map { $0.row }.min() ?? 0
        return maxRow - minRow + 1
    }
    
    // Helper method for flood fill algorithm
    private func floodFillEmptyArea(row: Int, col: Int, visited: inout [[Bool]]) -> Int {
        if row < 0 || row >= rows || col < 0 || col >= columns ||
           visited[row][col] || grid[row][col] != nil {
            return 0
        }
        
        visited[row][col] = true
        var size = 1
        
        // Check all 4 directions
        size += floodFillEmptyArea(row: row - 1, col: col, visited: &visited)
        size += floodFillEmptyArea(row: row + 1, col: col, visited: &visited)
        size += floodFillEmptyArea(row: row, col: col - 1, visited: &visited)
        size += floodFillEmptyArea(row: row, col: col + 1, visited: &visited)
        
        return size
    }
    
    // Helper method to check if a position is within grid bounds
    private func isValidPosition(_ position: GridCell) -> Bool {
        return position.row >= 0 && position.row < rows && 
               position.column >= 0 && position.column < columns
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

// MARK: - Debugging

extension GameBoard {
    // Debug helper method to print the current board state
    func debugPrintBoardState() {
        print("DEBUG: Current board state (8x8):")
        print("     0 1 2 3 4 5 6 7")
        for row in 0..<rows {
            var rowString = "  \(row): "
            for col in 0..<columns {
                if grid[row][col] != nil {
                    rowString += "█ "
                } else {
                    rowString += "· "
                }
            }
            print(rowString)
        }
        print("DEBUG: Board capacity: \(String(format: "%.1f", getBoardCapacity() * 100))%")
    }
    
    // Debug method to create a nearly full board scenario for testing game over detection
    func debugCreateNearlyFullBoard() {
        print("DEBUG: Creating nearly full board scenario for testing...")
        
        // Clear existing board first
        resetBoard()
        
        // Fill the board leaving a few strategic spots empty
        // This creates a scenario where only certain pieces can fit
        let testColor = SKColor.gray
        
        // Fill most of the board, leaving specific patterns
        for row in 0..<rows {
            for col in 0..<columns {
                // Leave some strategic empty spaces that WON'T fit our test pieces
                let shouldLeaveEmpty = (
                    // Leave only 3 scattered single cells (but our pieces are 5-block, L-shape, T-shape)
                    (row == 0 && col == 0) ||
                    (row == 2 && col == 5) ||
                    (row == 7 && col == 7)
                )
                
                if !shouldLeaveEmpty {
                    let cell = GridCell(column: col, row: row)
                    let position = GameBoardVisuals.positionForCell(cell, blockSize: blockSize)
                    let block = GameBoardVisuals.createBlock(at: position, blockSize: blockSize, color: testColor)
                    grid[row][col] = block
                    boardNode.addChild(block)
                }
            }
        }
        
        print("DEBUG: Nearly full board created with only 3 single empty cells. Current state:")
        debugPrintBoardState()
    }
    
    // Debug method to simulate specific piece combinations that should trigger game over
    func debugTestGameOverScenario() {
        print("DEBUG: Testing game over scenario...")
        
        // Create the nearly full board
        debugCreateNearlyFullBoard()
        
        // The empty spaces are:
        // - Only 3 single cells at (0,0), (2,5), and (7,7)
        // - Our test pieces are: 5-block stick, L-shape, T-shape (all multi-cell pieces)
        // - None of these should fit in single cell spaces
        
        print("DEBUG: Board setup complete. Available spaces:")
        print("  - Single cells at (0,0), (2,5), and (7,7)")
        print("  - Test pieces: 5-block stick, L-shape, T-shape")
        print("DEBUG: This scenario SHOULD trigger game over since multi-cell pieces can't fit in single cells")
    }
    
    // Debug method to create specific problematic piece combinations
    func debugCreateProblematicPieces() -> [TetrominoShape] {
        print("🐛 Creating problematic pieces for testing...")
        
        // Return the exact pieces from user's image that should trigger game over
        // User corrected: "Elbow Top Left" and "T Shape Tall Right"
        let problematicShapes: [TetrominoShape] = [
            .elbowTopLeft,     // "Elbow Top Left" from user's image (5 cells in L-shaped corner pattern)
            .tShapeTallRight,  // "T Shape Tall Right" from user's image (4 cells in T pattern)
            .stick4            // Add a 4-block piece as third piece for testing
        ]
        
        problematicShapes.forEach { shape in
            print("🐛 Test piece: \(shape.displayName) (\(shape.cells.count) cells)")
        }
        
        return problematicShapes
    }
}
