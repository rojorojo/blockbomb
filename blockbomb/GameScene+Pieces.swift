import SpriteKit
import SwiftUI

// Extension containing all piece-related functionality
extension GameScene {
    // MARK: - Pieces Setup
    func setupDraggablePieces() {
        // Clear any existing pieces
        pieceNodes.forEach { $0.removeFromParent() }
        pieceNodes.removeAll()
        
        // Remove any existing containers
        children.filter { $0.name?.starts(with: "pieceContainer") ?? false }.forEach { $0.removeFromParent() }
        
        // Get a more varied selection of shapes to display
        let availableShapes = TetrominoShape.allCases
        
        // Get shape categories from TetrominoShape
        let shapeCategories = TetrominoShape.shapeCategories
        
        var selectedShapes: [TetrominoShape] = []
        
        // Try to select one shape from each category
        for category in shapeCategories.shuffled() {
            if selectedShapes.count >= 3 { break }
            
            if let shape = category.shuffled().first, !selectedShapes.contains(shape) {
                selectedShapes.append(shape)
            }
        }
        
        // If we need more shapes, fill with random ones
        if selectedShapes.count < 3 {
            let remainingShapes = availableShapes.filter { !selectedShapes.contains($0) }.shuffled()
            selectedShapes.append(contentsOf: remainingShapes.prefix(3 - selectedShapes.count))
        }
        
        // Calculate position below the grid
        let gridBottom = gameBoard.boardNode.position.y - (CGFloat(gameBoard.rows) * gameBoard.blockSize / 2)
        let safeAreaInsets = getSafeAreaInsets(for: self.view!)
        let yPosition = gridBottom + 80 // Add more space below the grid
        
        // Calculate container width based on the board width
        let boardWidth = CGFloat(gameBoard.columns) * gameBoard.blockSize
        let containerWidth = boardWidth / 3
        
        // Create and position the containers
        for i in 0..<3 {
            // Create container node
            let container = SKNode()
            container.name = "pieceContainer\(i)"
            container.position = CGPoint(
                x: gameBoard.boardNode.position.x + containerWidth * CGFloat(i) + containerWidth/2,
                y: yPosition
            )
            addChild(container)
            
            // Add debug border for the container
            /*let borderRect = SKShapeNode(rectOf: CGSize(width: containerWidth, height: containerWidth))
            borderRect.strokeColor = .cyan
            borderRect.lineWidth = 1.0
            borderRect.fillColor = .clear
            borderRect.alpha = 0.5 // Subtle border
            container.addChild(borderRect)*/
            
            // Add piece to container if we have one for this position
            if i < selectedShapes.count {
                let shape = selectedShapes[i]
                let piece = PieceNode(shape: shape, color: shape.color)
                
                // Apply scale before any measurements
                piece.setScale(0.6)
                
                // First, calculate the bounds of the piece to determine its center
                // We'll create a temporary node with the piece to measure it accurately
                let tempNode = SKNode()
                self.addChild(tempNode)
                tempNode.addChild(piece)
                
                // Get the bounding box of the piece
                let bounds = piece.calculateAccumulatedFrame()
                
                // Calculate the offset from the piece's registration point to its visual center
                let centerOffsetX = bounds.midX - piece.position.x
                let centerOffsetY = bounds.midY - piece.position.y
                
                // Remove from temp measurement node
                piece.removeFromParent()
                tempNode.removeFromParent()
                
                // Now add to its proper container, but with position adjusted to center the visual content
                // We negate the offset to move the visual center to the container's center
                piece.position = CGPoint(x: -centerOffsetX, y: -centerOffsetY)
                piece.name = "draggable_piece"
                piece.zPosition = 100
                container.addChild(piece)
                pieceNodes.append(piece)
                
                // Debug visualization of the piece's center and bounds
               /* if true { // Set to false to hide debug visuals
                    // Container center marker
                    let centerMarker = SKShapeNode(circleOfRadius: 3)
                    centerMarker.fillColor = .red
                    centerMarker.strokeColor = .clear
                    centerMarker.position = .zero
                    centerMarker.zPosition = 110
                    centerMarker.alpha = 0.7
                    container.addChild(centerMarker)
                    
                    // Piece bounds visualization - adjust to show the actual bounds centered on the piece
                    let boundsMarker = SKShapeNode(rect: CGRect(origin: CGPoint(x: -bounds.width/2, 
                                                                               y: -bounds.height/2),
                                                               size: bounds.size))
                    boundsMarker.strokeColor = .green
                    boundsMarker.lineWidth = 1.0
                    boundsMarker.fillColor = .clear
                    boundsMarker.alpha = 0.3
                    boundsMarker.zPosition = 105
                    container.addChild(boundsMarker)
                }*/
                
                // Save the calculated center offset with the piece for later repositioning
                piece.userData = NSMutableDictionary()
                piece.userData?.setValue(NSValue(cgPoint: CGPoint(x: centerOffsetX, y: centerOffsetY)), forKey: "centerOffset")
                
                // Add a subtle animation that keeps the piece within its container
                let moveAction = SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 5, duration: 0.5),
                    SKAction.moveBy(x: 0, y: -5, duration: 0.5)
                ])
                piece.run(SKAction.repeatForever(moveAction))
            }
        }
        
        // Instruction label - positioned below pieces
        /*let instructionLabel = SKLabelNode(text: "Drag pieces onto the grid")
        instructionLabel.fontName = "AvenirNext-Medium"
        instructionLabel.fontSize = 18
        instructionLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        instructionLabel.position = CGPoint(x: frame.midX, y: yPosition - 50)
        addChild(instructionLabel)*/
        
        // After creating pieces, check if any of them can be placed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkForGameOver()
        }
    }
    
    // Calculate the center point of a piece's bounding box
    func calculatePieceCenterOffset(_ piece: PieceNode) -> CGPoint {
        let cells = piece.gridPiece.cells
        
        // If no cells, return zero offset
        guard !cells.isEmpty else { return .zero }
        
        // Find the min and max coordinates
        var minRow = Int.max
        var maxRow = Int.min
        var minColumn = Int.max
        var maxColumn = Int.min
        
        for cell in cells {
            minRow = min(minRow, cell.row)
            maxRow = max(maxRow, cell.row)
            minColumn = min(minColumn, cell.column)
            maxColumn = max(maxColumn, cell.column)
        }
        
        // Calculate the center of the bounding box in grid coordinates
        let centerRow = Float(minRow + maxRow) / 2.0
        let centerColumn = Float(minColumn + maxColumn) / 2.0
        
        // Convert to points (assuming each cell is blockSize x blockSize)
        let blockSize = gameBoard.blockSize
        let centerX = CGFloat(centerColumn) * blockSize
        let centerY = CGFloat(centerRow) * blockSize
        
        return CGPoint(x: centerX, y: centerY)
    }
    
    func calculatePointsForPiece(_ piece: GridPiece) -> Int {
        // Award points based on piece complexity
        return piece.cells.count * 5
    }
    
    // Helper for showing a SwiftUI gallery of all piece shapes
    func presentSwiftUIShapeGallery() {
        // Get the view controller that's presenting the game
        guard let viewController = self.view?.window?.rootViewController else { return }
        
        // Create and configure the SwiftUI view
        let galleryView = ShapeGalleryView()
        let hostingController = UIHostingController(rootView: galleryView)
        hostingController.modalPresentationStyle = .fullScreen
        
        // Present the SwiftUI view controller
        viewController.present(hostingController, animated: true)
    }
}
