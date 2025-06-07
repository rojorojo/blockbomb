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
        
        // Get selection using the new weighted rarity system
        // Default to balancedWeighted if gameController is not available
        let selectionMode = gameController?.selectionMode ?? .balancedWeighted
        let selectedShapes = TetrominoShape.selection(count: 3, mode: selectionMode, gameBoard: gameBoard, gameController: gameController)
        
        // Notify game controller that pieces were generated (for post-revive tracking)
        gameController?.onPiecesGenerated()
        
        // Log selection for debugging (only in debug builds)
        #if DEBUG
        TetrominoShape.logSelection(selectedShapes)
        print("Selected shapes: \(selectedShapes.map { $0.displayName })")
        print("Rarity distribution: \(selectedShapes.map { "\($0.displayName): \($0.rarity.rawValue)" })")
        
        // Print statistics every 10 selections
        let stats = TetrominoShape.getSelectionStats()
        if let totalSelections = stats["totalSelections"] as? Int, totalSelections % 30 == 0 {
            print("\n=== Selection Statistics after \(totalSelections) selections ===")
            if let rarityPercentages = stats["rarityPercentages"] as? [String: Double] {
                for (rarity, percentage) in rarityPercentages.sorted(by: { $0.key < $1.key }) {
                    print("\(rarity): \(String(format: "%.2f", percentage))%")
                }
            }
            print("===")
        }
        #endif
        
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
            
            // Create a touch target node that fills the container and make it draggable
            let touchTarget = SKShapeNode(rectOf: CGSize(width: containerWidth, height: containerWidth))
            touchTarget.fillColor = .clear
            touchTarget.strokeColor = .clear
            touchTarget.alpha = 0.8 // Almost invisible but touchable
            touchTarget.name = "draggable_piece" // Use the original draggable name to work with existing code
            touchTarget.userData = NSMutableDictionary()
            touchTarget.userData?.setValue(i, forKey: "containerIndex") // Store which container this belongs to
            container.addChild(touchTarget)
            
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
                piece.name = "piece" // Not directly draggable - container handles this
                piece.zPosition = 100
                container.addChild(piece)
                pieceNodes.append(piece)
                
                // Save the calculated center offset with the piece for later repositioning
                piece.userData = NSMutableDictionary()
                piece.userData?.setValue(NSValue(cgPoint: CGPoint(x: centerOffsetX, y: centerOffsetY)), forKey: "centerOffset")
                
                // Also link the touch target to this piece
                touchTarget.userData?.setValue(piece.gridPiece.shape, forKey: "pieceShape")
                touchTarget.userData?.setValue(piece.gridPiece.shape.color, forKey: "pieceColor")
                
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
