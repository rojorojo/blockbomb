import SpriteKit

// Represents a tetromino in terms of grid cells
class GridPiece {
    var cells: [GridCell]
    let color: SKColor
    let shape: TetrominoShape
    
    init(shape: TetrominoShape, color: SKColor) {
        self.shape = shape
        self.color = color
        self.cells = shape.cells()
    }
    
    // Returns the cells this piece would occupy if placed at the given origin
    func absoluteCells(at origin: GridCell) -> [GridCell] {
        return cells.map { $0 + origin }
    }

}
