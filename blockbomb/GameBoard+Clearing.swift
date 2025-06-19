
//
//  GameBoard+Clearing.swift
//  blockbomb
//
//  Created by Copilot on 7/12/24.
//

import Foundation
import SpriteKit

// MARK: - Synchronized Clearing System

extension GameBoard {
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
}
