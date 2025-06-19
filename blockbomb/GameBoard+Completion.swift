
//
//  GameBoard+Completion.swift
//  blockbomb
//
//  Created by Copilot on 7/12/24.
//

import Foundation
import SpriteKit

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
