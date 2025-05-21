import SpriteKit

class ShapeDebugScene: SKScene {
    
    private let blockSize: CGFloat = 20
    private let paddingBetweenShapes: CGFloat = 30
    private let titleHeight: CGFloat = 50
    
    // Scrolling support
    private var contentNode: SKNode!
    private var contentHeight: CGFloat = 0
    private var isDragging = false
    private var lastTouchPosition: CGPoint?
    private var touchStartPosition: CGPoint?
    private let scrollSpeed: CGFloat = 1.0
    private var scrollableArea: CGRect!
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        
        // Setup scrollable content container
        contentNode = SKNode()
        addChild(contentNode)
        
        // Define scrollable area
        let safeAreaInsets = getSafeAreaInsets(for: view)
        let topMargin: CGFloat = 120 // Space for title and instructions
        
        scrollableArea = CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: frame.height - topMargin
        )
        
        // Add title with fixed position outside scrollable area
        let titleLabel = SKLabelNode(text: "Tetromino Shape Gallery")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height - safeAreaInsets.top - 30)
        addChild(titleLabel)
        
        // Add back button with fixed position - positioned to the left of the title
        let backButton = SKLabelNode(text: "< Back to Game")
        backButton.fontName = "AvenirNext-Medium"
        backButton.fontSize = 18
        backButton.position = CGPoint(x: safeAreaInsets.left + 100, y: frame.height - safeAreaInsets.top - 30)
        backButton.horizontalAlignmentMode = .left
        backButton.name = "backButton"
        addChild(backButton)
        
        // Add instructions for scrolling
        let instructionsLabel = SKLabelNode(text: "Drag up or down to scroll")
        instructionsLabel.fontName = "AvenirNext-Medium"
        instructionsLabel.fontSize = 16
        instructionsLabel.fontColor = .gray
        instructionsLabel.position = CGPoint(x: frame.midX, y: frame.height - safeAreaInsets.top - 70)
        addChild(instructionsLabel)
        
        // Display all shapes in the scrollable container
        displayAllShapes()
        
        // Add debug info to diagnose issues
        printDebugInfo()
    }
    
    private func getSafeAreaInsets(for view: SKView) -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0) // Default values for older iOS
        }
    }
    
    private func printDebugInfo() {
        print("Screen size: \(frame.width) x \(frame.height)")
        print("Content height: \(contentHeight)")
        print("Number of shapes: \(TetrominoShape.allCases.count)")
        print("Content node position: \(contentNode.position)")
        print("Scrollable area: \(scrollableArea)")
    }
    
    private func displayAllShapes() {
        // Calculate layout
        let numColumns = 3
        let columnWidth = frame.width / CGFloat(numColumns)
        let startY: CGFloat = scrollableArea.height - 100 // Start below the header area
        
        var currentX: CGFloat = columnWidth / 2
        var currentY: CGFloat = startY
        var column = 0
        
        print("Starting to display shapes at Y: \(startY)")
        
        // Setup shape display
        for (index, shape) in TetrominoShape.allCases.enumerated() {
            // Create container for this shape
            let container = SKNode()
            container.position = CGPoint(x: currentX, y: currentY)
            container.name = "shape_container_\(index)"
            contentNode.addChild(container)
            
            // Create shape visual
            let pieceNode = createShapeNode(for: shape)
            pieceNode.position = CGPoint(x: 0, y: 20)
            container.addChild(pieceNode)
            
            // Add shape name
            let nameLabel = SKLabelNode(text: String(describing: shape))
            nameLabel.fontName = "AvenirNext-Regular"
            nameLabel.fontSize = 16
            nameLabel.position = CGPoint(x: 0, y: -30)
            nameLabel.verticalAlignmentMode = .top
            container.addChild(nameLabel)
            
            print("Added shape \(shape) at \(container.position)")
            
            // Update position for next shape
            column += 1
            if column >= numColumns {
                column = 0
                currentX = columnWidth / 2
                currentY -= 120 // Move down for the next row
            } else {
                currentX += columnWidth
            }
        }
        
        // Calculate the total content height needed
        let totalRows = ceil(CGFloat(TetrominoShape.allCases.count) / CGFloat(numColumns))
        contentHeight = totalRows * 120
        
        // Position the content node at the start
        contentNode.position = CGPoint(x: 0, y: 0)
        
        print("Final content height: \(contentHeight), total rows: \(totalRows)")
    }
    
    private func createShapeNode(for shape: TetrominoShape) -> SKNode {
        let container = SKNode()
        
        // Get cells for this shape
        let cells = shape.cells()
        
        // Find minimum and maximum coordinates to center the shape
        var minX = Int.max, minY = Int.max
        var maxX = Int.min, maxY = Int.min
        
        for cell in cells {
            minX = min(minX, cell.column)
            minY = min(minY, cell.row)
            maxX = max(maxX, cell.column)
            maxY = max(maxY, cell.row)
        }
        
        let width = maxX - minX + 1
        let height = maxY - minY + 1
        
        // Create blocks
        for cell in cells {
            let block = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 3)
            block.fillColor = shape.color
            block.strokeColor = .white
            block.lineWidth = 1
            
            // Position block relative to shape center
            let xOffset = CGFloat(cell.column - minX - width/2) * blockSize
            let yOffset = CGFloat(cell.row - minY - height/2) * blockSize
            block.position = CGPoint(x: xOffset + blockSize/2, y: yOffset + blockSize/2)
            
            container.addChild(block)
        }
        
        return container
    }
    
    // MARK: - Touch Handling for Scrolling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if back button was touched
        if let touchedNode = nodes(at: location).first, touchedNode.name == "backButton" {
            // Go back to the game scene
            let gameScene = GameScene(size: size)
            gameScene.scaleMode = scaleMode
            view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.5))
            return
        }
        
        // Start tracking for scrolling
        isDragging = true
        lastTouchPosition = location
        touchStartPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first, let lastPosition = lastTouchPosition else { return }
        
        let location = touch.location(in: self)
        let deltaY = location.y - lastPosition.y
        lastTouchPosition = location
        
        // Scroll content
        let newY = contentNode.position.y + deltaY
        
        // Only scroll if content is taller than the view
        if contentHeight > scrollableArea.height {
            // Limit scrolling to keep content visible
            let minY = scrollableArea.height - contentHeight
            let maxY = 0.0
            
            if newY <= maxY && newY >= minY {
                contentNode.position.y = newY
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastTouchPosition = nil
        touchStartPosition = nil
        
        // Snap back if overscrolled
        var newY = contentNode.position.y
        if newY > 0 {
            newY = 0
        } else if contentHeight > scrollableArea.height && newY < scrollableArea.height - contentHeight {
            newY = scrollableArea.height - contentHeight
        }
        
        if newY != contentNode.position.y {
            let moveAction = SKAction.moveTo(y: newY, duration: 0.2)
            moveAction.timingMode = .easeOut
            contentNode.run(moveAction)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastTouchPosition = nil
        touchStartPosition = nil
    }
}
