//
//  GameBoard+Data.swift
//  blockbomb
//
//  Created by Copilot on 7/12/24.
//

import Foundation
import SpriteKit

// MARK: - Data Logging Support
    
extension GameBoard {
    /// Get the current board state as a 2D boolean array for logging
    func getBoardStateForLogging() -> [[Bool]] {
        var boardState: [[Bool]] = []
        
        for i in 0..<rows {
            var row: [Bool] = []
            for j in 0..<columns {
                row.append(grid[i][j] != nil)
            }
            boardState.append(row)
        }
        
        return boardState
    }
}

// MARK: - Multiplayer Support Methods
    
extension GameBoard {
    /// Set a block at a specific cell (for multiplayer game state restoration)
    func setBlock(at cell: GridCell, color: SKColor) {
        // Remove existing block if present
        if let existingBlock = grid[cell.row][cell.column] {
            existingBlock.removeFromParent()
        }
        
        // Create and place new block
        let block = createBlock(at: cell, color: color)
        grid[cell.row][cell.column] = block
        boardNode.addChild(block)
    }
    
    /// Get the color of a block at a specific cell
    func getBlockColor(at cell: GridCell) -> SKColor? {
        guard cell.row >= 0 && cell.row < rows && cell.column >= 0 && cell.column < columns else {
            return nil
        }
        
        if let block = grid[cell.row][cell.column] {
            return block.fillColor
        }
        
        return nil
    }
    
    /// Check if a cell is occupied
    func isOccupied(at cell: GridCell) -> Bool {
        guard cell.row >= 0 && cell.row < rows && cell.column >= 0 && cell.column < columns else {
            return false
        }
        
        return grid[cell.row][cell.column] != nil
    }
    
    // MARK: - Multiplayer Support
    
    /// Get the current board state for multiplayer synchronization
    /// Returns an 8x8 array representing the board state with color names for filled cells
    func getBoardStateForMultiplayer() -> [[String?]] {
        var boardState: [[String?]] = Array(repeating: Array(repeating: nil, count: columns), count: rows)
        
        for row in 0..<rows {
            for col in 0..<columns {
                if let block = grid[row][col] {
                    // Convert block color to color name for serialization
                    boardState[row][col] = getColorName(from: block.fillColor)
                }
            }
        }
        
        return boardState
    }
    
    /// Restore board state from multiplayer data
    /// - Parameter boardState: 8x8 array with color names for filled cells
    func restoreBoardState(_ boardState: [[String?]]) {
        guard boardState.count == rows else {
            print("GameBoard: Cannot restore board state - row count mismatch")
            return
        }
        
        // Clear current board
        resetBoard()
        
        // Restore filled cells
        for row in 0..<rows {
            guard row < boardState.count && boardState[row].count == columns else {
                print("GameBoard: Skipping invalid row \(row) in board state")
                continue
            }
            
            for col in 0..<columns {
                if let colorName = boardState[row][col] {
                    // Convert color name back to block
                    let color = getColor(from: colorName)
                    let cell = GridCell(column: col, row: row)
                    let blockNode = createBlock(at: cell, color: color)
                    grid[row][col] = blockNode
                    boardNode.addChild(blockNode)
                }
            }
        }
        
        print("GameBoard: Restored multiplayer board state")
    }
    
    /// Convert a color to a string name for serialization
    private func getColorName(from color: SKColor) -> String {
        // Map common colors to names - this should match the colors used in TetrominoShape
        switch color {
        case SKColor(BlockColors.cyan): return "cyan"
        case SKColor(BlockColors.yellow): return "yellow"
        case SKColor(BlockColors.purple): return "purple"
        case SKColor(BlockColors.green): return "green"
        case SKColor(BlockColors.red): return "red"
        case SKColor(BlockColors.blue): return "blue"
        case SKColor(BlockColors.orange): return "orange"
        default: return "unknown"
        }
    }
    
    /// Convert a color name back to a color
    private func getColor(from colorName: String) -> SKColor {
        switch colorName {
        case "cyan": return SKColor(BlockColors.cyan)
        case "yellow": return SKColor(BlockColors.yellow)
        case "purple": return SKColor(BlockColors.purple)
        case "green": return SKColor(BlockColors.green)
        case "red": return SKColor(BlockColors.red)
        case "blue": return SKColor(BlockColors.blue)
        case "orange": return SKColor(BlockColors.orange)
        default: return SKColor(BlockColors.gray) // fallback color
        }
    }
}
