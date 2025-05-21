//
//  PieceNode.swift
//  blockbomb
//
//  Created by Robert Johnson on 5/15/25.
//
import SpriteKit

class PieceNode: SKNode {
    private let blockSize: CGFloat = 30
    private var blocks: [SKShapeNode] = []
    private var shape: TetrominoShape
    private var currentRotation = 0
    var gridPiece: GridPiece
    
    init(shape: TetrominoShape, color: SKColor) {
        self.shape = shape
        // Always use the shape's designated color for consistency
        self.gridPiece = GridPiece(shape: shape, color: shape.color)
        super.init()
        
        setupBlocks(color: shape.color) // Use the shape's color by default
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBlocks(color: SKColor) {
        // Clear any existing blocks
        blocks.forEach { $0.removeFromParent() }
        blocks.removeAll()
        
        // Create blocks based on the grid piece
        for cell in gridPiece.cells {
            let block = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 3)
            block.fillColor = color
            block.strokeColor = SKColor(white: 0.3, alpha: 0.5)
            block.lineWidth = 1.0
            block.position = CGPoint(x: CGFloat(cell.column) * blockSize, y: CGFloat(cell.row) * blockSize)
            addChild(block)
            blocks.append(block)
        }
    }
    
    func rotate() {
        // Keep track of the current rotation for display purposes
        gridPiece.rotate()
        setupBlocks(color: gridPiece.color)
        
        // Play a subtle rotation sound or effect if available
        // This could be added in the future
    }
    
    // Legacy method kept for compatibility
    func blockPositions() -> [CGPoint] {
        return blocks.map { $0.position }
    }
}
