import SpriteKit

// Represents a tetromino in terms of grid cells
class GridPiece {
    var cells: [GridCell]
    let color: SKColor
    let shape: TetrominoShape
    
    init(shape: TetrominoShape, color: SKColor) {
        self.shape = shape
        // Use the shape's color by default, but allow override
        self.color = color
        self.cells = shape.relativeCells(rotation: 0)
    }
    
    // Returns the cells this piece would occupy if placed at the given origin
    func absoluteCells(at origin: GridCell) -> [GridCell] {
        return cells.map { $0 + origin }
    }
    
    // Rotate the piece clockwise
    func rotate() {
        let rotationIndex = (shape.rotationIndexFor(cells: cells) + 1) % shape.rotationCount
        cells = shape.relativeCells(rotation: rotationIndex)
    }
}
