import Foundation
import SpriteKit

// Represents a position in the grid
struct GridCell: Equatable, Hashable {
    let column: Int
    let row: Int
    
    static func + (lhs: GridCell, rhs: GridCell) -> GridCell {
        return GridCell(column: lhs.column + rhs.column, row: lhs.row + rhs.row)
    }
    
    static func - (lhs: GridCell, rhs: GridCell) -> GridCell {
        return GridCell(column: lhs.column - rhs.column, row: lhs.row - rhs.row)
    }
}
