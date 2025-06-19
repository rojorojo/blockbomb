//
//  GameBoard+Analysis.swift
//  blockbomb
//
//  Created by Copilot on 7/12/24.
//

import Foundation
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

// MARK: - Board Analysis
extension GameBoard {
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
}
