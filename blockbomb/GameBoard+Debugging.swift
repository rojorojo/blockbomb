
//
//  GameBoard+Debugging.swift
//  blockbomb
//
//  Created by Copilot on 7/12/24.
//

import Foundation
import SpriteKit

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
