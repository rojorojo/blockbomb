
//
//  GameBoard+Glow.swift
//  blockbomb
//
//  Created by Copilot on 7/12/24.
//

import Foundation
import SpriteKit

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
