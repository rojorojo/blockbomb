import SpriteKit

class ShapeDebugScene: SKScene {
    
    private let blockSize: CGFloat = 20
    private let paddingBetweenShapes: CGFloat = 30
    private let titleHeight: CGFloat = 50
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        
        // Add title
        let titleLabel = SKLabelNode(text: "Tetromino Shape Gallery")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height - titleHeight/2)
        addChild(titleLabel)
        
        // Add back button
        let backButton = SKLabelNode(text: "< Back to Game")
        backButton.fontName = "AvenirNext-Medium"
        backButton.fontSize = 18
        backButton.position = CGPoint(x: 100, y: frame.height - titleHeight/2)
        backButton.name = "backButton"
        addChild(backButton)
        
        // Display all shapes
        displayAllShapes()
    }
    
    private func displayAllShapes() {
        // Calculate layout
        let numColumns = 3
        let columnWidth = frame.width / CGFloat(numColumns)
        let startY = frame.height - titleHeight - 30
        
        var currentX: CGFloat = columnWidth / 2
        var currentY: CGFloat = startY
        var column = 0
        
        for shape in TetrominoShape.allCases {
            // Create container for this shape
            let container = SKNode()
            container.position = CGPoint(x: currentX, y: currentY)
            addChild(container)
            
            // Create shape visual
            let pieceNode = createShapeNode(for: shape)
            pieceNode.position = CGPoint(x: 0, y: 20)
            container.addChild(pieceNode)
            
            // Add shape name
            let nameLabel = SKLabelNode(text: String(describing: shape))
            nameLabel.fontName = "AvenirNext-Regular"
            nameLabel.fontSize = 16
            nameLabel.position = CGPoint(x: 0, y: -30)
            container.addChild(nameLabel)
            
            // Update position for next shape
            column += 1
            if column >= numColumns {
                column = 0
                currentX = columnWidth / 2
                currentY -= 120
            } else {
                currentX += columnWidth
            }
        }
    }
    
    private func createShapeNode(for shape: TetrominoShape) -> SKNode {
        let container = SKNode()
        
        // Get cells for this shape
        let cells = shape.relativeCells(rotation: 0)
        
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let touchedNode = nodes(at: location).first, touchedNode.name == "backButton" {
            // Go back to the game scene
            let gameScene = GameScene(size: size)
            gameScene.scaleMode = scaleMode
            view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }
}
