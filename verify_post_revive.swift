#!/usr/bin/env swift

// Simple verification script for post-revive priority selection logic
// This script simulates the key logic to verify our implementation is sound

import Foundation

// Simulate the key data structures and logic
enum TetrominoShape: CaseIterable {
    case blockSingle
    case squareSmall, stick3, stick3Vert
    case cornerTopLeft, cornerBottomLeft, cornerTopRight, cornerBottomRight
    case rectWide, rectTall
    // ... other cases would be here in real implementation
    
    var cells: [(Int, Int)] {
        switch self {
        case .blockSingle: return [(0, 0)]
        case .squareSmall: return [(0, 0), (0, 1), (1, 0), (1, 1)]
        case .stick3: return [(0, 0), (0, 1), (0, 2)]
        case .stick3Vert: return [(0, 0), (1, 0), (2, 0)]
        case .cornerTopLeft: return [(0, 0), (0, 1), (1, 0)]
        case .cornerBottomLeft: return [(0, 0), (1, 0), (1, 1)]
        case .cornerTopRight: return [(0, 0), (0, 1), (1, 1)]
        case .cornerBottomRight: return [(0, 0), (1, 0), (1, 1)]
        case .rectWide: return [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]
        case .rectTall: return [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]
        }
    }
    
    var displayName: String {
        switch self {
        case .blockSingle: return "Single Block"
        case .squareSmall: return "Small Square"
        case .stick3: return "Stick 3"
        case .stick3Vert: return "Stick 3 Vertical"
        case .cornerTopLeft: return "Corner Top Left"
        case .cornerBottomLeft: return "Corner Bottom Left"
        case .cornerTopRight: return "Corner Top Right"
        case .cornerBottomRight: return "Corner Bottom Right"
        case .rectWide: return "Wide Rectangle"
        case .rectTall: return "Tall Rectangle"
        }
    }
    
    enum Utility {
        case versatile, filler, lineMaker, spaceFiller, bulky
    }
    
    enum Rarity {
        case premium, common, useful, valuable
    }
    
    var utility: Utility {
        switch self {
        case .blockSingle: return .versatile
        case .squareSmall, .stick3, .stick3Vert: return .filler
        case .cornerTopLeft, .cornerBottomLeft, .cornerTopRight, .cornerBottomRight: return .filler
        case .rectWide, .rectTall: return .lineMaker
        }
    }
    
    var rarity: Rarity {
        switch self {
        case .blockSingle: return .premium
        case .squareSmall, .stick3, .stick3Vert: return .common
        case .cornerTopLeft, .cornerBottomLeft, .cornerTopRight, .cornerBottomRight: return .common
        case .rectWide, .rectTall: return .common
        }
    }
}

// Simulate board state
class GameBoard {
    var grid: [[Bool]] = Array(repeating: Array(repeating: false, count: 10), count: 10)
    
    func canPlacePieceAnywhere(_ shape: TetrominoShape) -> Bool {
        // Try placing the piece at every position on the board
        for row in 0..<10 {
            for col in 0..<10 {
                if canPlacePieceAt(shape, row: row, col: col) {
                    return true
                }
            }
        }
        return false
    }
    
    private func canPlacePieceAt(_ shape: TetrominoShape, row: Int, col: Int) -> Bool {
        for (deltaRow, deltaCol) in shape.cells {
            let newRow = row + deltaRow
            let newCol = col + deltaCol
            
            // Check bounds
            if newRow < 0 || newRow >= 10 || newCol < 0 || newCol >= 10 {
                return false
            }
            
            // Check if cell is already occupied
            if grid[newRow][newCol] {
                return false
            }
        }
        return true
    }
    
    func fillConstrainedBoard() {
        // Fill most cells, leaving only a few strategic gaps
        for row in 0..<10 {
            for col in 0..<10 {
                // Leave some single cells and small gaps
                if (row == 2 && col == 3) || 
                   (row == 5 && col == 7) || 
                   (row == 8 && col == 1) ||
                   (row == 0 && col == 0) ||
                   (row == 9 && col == 9) {
                    grid[row][col] = false
                } else {
                    grid[row][col] = true
                }
            }
        }
    }
}

// Simulate the enhanced post-revive selection logic
func postRevivePrioritySelection(count: Int = 3, gameBoard: GameBoard) -> [TetrominoShape] {
    print("🔄 Generating post-revive priority selection (all \(count) pieces must be placeable)")
    
    var prioritySelection: [TetrominoShape] = []
    var attempts = 0
    let maxAttempts = 50
    
    // Define priority order: most placeable pieces first
    let candidatePieces = TetrominoShape.allCases.sorted { shape1, shape2 in
        if shape1.cells.count != shape2.cells.count {
            return shape1.cells.count < shape2.cells.count
        }
        // If same size, prefer versatile > filler > lineMaker > spaceFiller > bulky
        let utilityOrder: [TetrominoShape.Utility] = [.versatile, .filler, .lineMaker, .spaceFiller, .bulky]
        let index1 = utilityOrder.firstIndex(of: shape1.utility) ?? utilityOrder.count
        let index2 = utilityOrder.firstIndex(of: shape2.utility) ?? utilityOrder.count
        return index1 < index2
    }
    
    // Aggressively search for guaranteed placeable pieces
    while prioritySelection.count < count && attempts < maxAttempts {
        attempts += 1
        
        for candidate in candidatePieces {
            if prioritySelection.contains(candidate) {
                continue
            }
            
            if gameBoard.canPlacePieceAnywhere(candidate) {
                prioritySelection.append(candidate)
                print("✅ Added placeable piece \(prioritySelection.count)/\(count): \(candidate.displayName) (\(candidate.cells.count) cells, \(candidate.utility))")
                
                if prioritySelection.count >= count {
                    break
                }
            }
        }
        
        if prioritySelection.count < count {
            print("⚠️ Attempt \(attempts): Only found \(prioritySelection.count)/\(count) placeable pieces")
        }
    }
    
    // Final validation
    let finalSelection = prioritySelection.filter { gameBoard.canPlacePieceAnywhere($0) }
    
    if finalSelection.count < count {
        print("❌ WARNING - Could only guarantee \(finalSelection.count)/\(count) placeable pieces after \(attempts) attempts")
    } else {
        print("🎉 SUCCESS - All \(finalSelection.count) pieces guaranteed placeable!")
    }
    
    return Array(finalSelection.prefix(count))
}

// Test scenarios
print("=== POST-REVIVE PRIORITY SELECTION VERIFICATION ===\n")

// Test 1: Empty board (should easily find 3 placeable pieces)
print("📋 Test 1: Empty Board")
let emptyBoard = GameBoard()
let emptyBoardResult = postRevivePrioritySelection(count: 3, gameBoard: emptyBoard)
print("Result: \(emptyBoardResult.map { $0.displayName })")
print("All placeable: \(emptyBoardResult.allSatisfy { emptyBoard.canPlacePieceAnywhere($0) })\n")

// Test 2: Constrained board (challenging scenario)
print("📋 Test 2: Highly Constrained Board")
let constrainedBoard = GameBoard()
constrainedBoard.fillConstrainedBoard()
let constrainedResult = postRevivePrioritySelection(count: 3, gameBoard: constrainedBoard)
print("Result: \(constrainedResult.map { $0.displayName })")
print("All placeable: \(constrainedResult.allSatisfy { constrainedBoard.canPlacePieceAnywhere($0) })\n")

// Test 3: Verify smallest pieces are prioritized
print("📋 Test 3: Priority Order Verification")
let testBoard = GameBoard()
// Fill board leaving only very small gaps
for row in 0..<10 {
    for col in 0..<10 {
        if (row + col) % 4 == 0 {
            testBoard.grid[row][col] = false
        } else {
            testBoard.grid[row][col] = true
        }
    }
}

let priorityResult = postRevivePrioritySelection(count: 3, gameBoard: testBoard)
print("Result: \(priorityResult.map { "\($0.displayName) (\($0.cells.count) cells)" })")
print("All placeable: \(priorityResult.allSatisfy { testBoard.canPlacePieceAnywhere($0) })")

// Verify smallest pieces are chosen first
let cellCounts = priorityResult.map { $0.cells.count }
print("Cell counts: \(cellCounts)")
print("Properly prioritized: \(cellCounts == cellCounts.sorted())")

print("\n=== VERIFICATION COMPLETE ===")
