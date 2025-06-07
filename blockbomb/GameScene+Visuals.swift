import SpriteKit

// Extension containing all visual effects and UI functionality
extension GameScene {
    // MARK: - UI Setup
    
    func addDebugButton(safeAreaInsets: UIEdgeInsets) {
        // Debug buttons removed - now using SwiftUI DebugPanelView
        // This method kept for compatibility but no longer adds any buttons
    }
    
    func addBoardBorder() {
        // Remove any existing border
        childNode(withName: "boardBorder")?.removeFromParent()
        
        // Create border using centralized system
        let borderNode = GameBoardVisuals.createBoardBorder(
            boardPosition: gameBoard.boardNode.position,
            columns: gameBoard.columns,
            rows: gameBoard.rows,
            blockSize: gameBoard.blockSize
        )
        addChild(borderNode)
    }
    
    // MARK: - Score Handling
    func updateScoreLabel() {
        // Only update if we should display score
        guard shouldDisplayScore else { 
            // Just notify the handler of the score change
            scoreUpdateHandler?(score)
            return
        }
        // Create a score update animation
        let oldScore = Int(scoreValueLabel.text ?? "0") ?? 0
        let scoreIncrement = score - oldScore
        
    }
    
    
    
    
    
    // MARK: - Visual Effects
    
    // Helper method to calculate the center of the game board
    private func calculateBoardCenter() -> CGPoint {
        let boardWidth = CGFloat(gameBoard.columns) * gameBoard.blockSize
        let boardHeight = CGFloat(gameBoard.rows) * gameBoard.blockSize
        
        return CGPoint(
            x: gameBoard.boardNode.position.x + boardWidth / 2,
            y: gameBoard.boardNode.position.y + boardHeight / 2
        )
    }
    
    // Visual feedback for successful placement
    func flashConfirmation() {
        // Green ring effect removed per user request
        // Method kept for compatibility but no visual effects are shown
    }
    
    // Visual feedback for clearing lines
    func flashLinesClearedConfirmation(rows: Int, columns: Int, totalPoints: Int) {
        // Use board center instead of piece placement position
        let boardCenter = calculateBoardCenter()
        
        // Create spectacular explosion effect with multiple layers
        createExplosionEffect(at: boardCenter, isCombo: rows > 0 && columns > 0)
        
        // Create the text label showing what was cleared
        let messageNode = SKNode()
        messageNode.position = boardCenter
        messageNode.zPosition = 220
        addChild(messageNode)
        
        // Text showing what was cleared with enhanced styling using tetromino colors
        var mainMessage = ""
        var mainFontSize: CGFloat = 36
        
        if (rows > 0 && columns > 0) {
            mainMessage = "COMBO!\n\(rows) rows + \(columns) columns"
            mainFontSize = 32
        } else if (rows > 0) {
            let rowText = rows == 1 ? "row" : "rows"
            mainMessage = "\(rows) \(rowText) cleared!"
        } else if (columns > 0) {
            let colText = columns == 1 ? "column" : "columns"
            mainMessage = "\(columns) \(colText) cleared!"
        }
        
        // Create main message label with gradient effect and stroke
        let mainFontName = "AvenirNext-Heavy"
        let mainPosition = CGPoint(x: 0, y: 15)
        
        // Determine gradient colors based on message type
        var topColor: UIColor
        var bottomColor: UIColor
        var strokeColor: SKColor
        
        if (rows > 0 && columns > 0) {
            // Combo colors - vibrant orange gradient
            topColor = UIColor(red: 1, green: 0.92, blue: 0.8, alpha: 1) // Light orange
            bottomColor = UIColor(red: 0.56, green: 0.32, blue: 1, alpha: 1) // Deep orange
            strokeColor = SKColor(red: 0.56, green: 0.32, blue: 1, alpha: 1) // Dark orange stroke
        } else if (rows > 0) {
            // Row clearing colors - vibrant green gradient
            topColor = UIColor(red: 0.8, green: 1.0, blue: 0.6, alpha: 1.0) // Light lime
            bottomColor = UIColor(red: 0.2, green: 0.8, blue: 0.0, alpha: 1.0) // Deep lime
            strokeColor = SKColor(red: 0.1, green: 0.5, blue: 0.0, alpha: 1.0) // Dark green stroke
        } else {
            // Column clearing colors - vibrant teal gradient
            topColor = UIColor(red: 0.6, green: 1.0, blue: 0.9, alpha: 1.0) // Light teal
            bottomColor = UIColor(red: 0.0, green: 0.8, blue: 0.6, alpha: 1.0) // Deep teal
            strokeColor = SKColor(red: 0.0, green: 0.4, blue: 0.3, alpha: 1.0) // Dark teal stroke
        }
        
        // Create the styled message using the reusable function
        let mainMessageNode = createStyledTextNode(
            text: mainMessage,
            fontName: mainFontName,
            fontSize: mainFontSize,
            position: mainPosition,
            topColor: topColor,
            bottomColor: bottomColor,
            strokeColor: strokeColor
        )
        messageNode.addChild(mainMessageNode)
        
        // Create points label with gradient effect and stroke using reusable function
        let pointsText = "+\(totalPoints)"
        let pointsFontName = "AvenirNext-Heavy"
        let pointsFontSize: CGFloat = mainFontSize + 8
        let pointsPosition = CGPoint(x: 0, y: -25)
        
        // Points colors - cream to orange gradient
        let pointsTopColor = UIColor(red: 1.0, green: 0.92, blue: 0.8, alpha: 1.0) // Light cream
        let pointsBottomColor = UIColor(red: 0.99, green: 0.48, blue: 0.0, alpha: 1.0) // Darker orange
        let pointsStrokeColor = SKColor(red: 1.0, green: 0.41, blue: 0.0, alpha: 1.0) // Orange stroke
        
        let pointsMessageNode = createStyledTextNode(
            text: pointsText,
            fontName: pointsFontName,
            fontSize: pointsFontSize,
            position: pointsPosition,
            topColor: pointsTopColor,
            bottomColor: pointsBottomColor,
            strokeColor: pointsStrokeColor
        )
        messageNode.addChild(pointsMessageNode)
     
        
        // Enhanced animations with bounce and sparkle effects
        messageNode.setScale(0.1) // Set initial scale
        let appearAnimation = SKAction.group([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.2)
        ])
        appearAnimation.timingMode = .easeOut
        
        let bounceAnimation = SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.scale(to: 1.05, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        let exitAnimation = SKAction.group([
            SKAction.moveBy(x: 0, y: 80, duration: 1.0),
            SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ])
        ])
        exitAnimation.timingMode = .easeOut
        
        let fullSequence = SKAction.sequence([
            appearAnimation,
            bounceAnimation,
            SKAction.wait(forDuration: 0.5),
            exitAnimation,
            SKAction.removeFromParent()
        ])
        
        messageNode.run(fullSequence)
        
        // Add sparkle particles for combo
        if (rows > 0 && columns > 0) {
            createSparkleEffect(at: boardCenter)
        }
    }
    
    // Create explosion effect with energy beams for combos
    private func createExplosionEffect(at position: CGPoint, isCombo: Bool) {
        // Add rotating energy beams for combo using harmonious colors
        if isCombo {
            for i in 0..<8 {
                // Alternate between orange and amber for visual harmony
                let beamColor = i % 2 == 0 ? BlockColors.orange : BlockColors.amber
                let beam = SKSpriteNode(color: SKColor(beamColor).withAlphaComponent(0.6), size: CGSize(width: 4, height: 80))
                beam.position = position
                beam.zPosition = 205
                beam.zRotation = CGFloat(i) * .pi / 4
                addChild(beam)
                
                let beamAnimation = SKAction.sequence([
                    SKAction.group([
                        SKAction.scaleY(to: 2.0, duration: 0.3),
                        SKAction.rotate(byAngle: .pi, duration: 0.8)
                    ]),
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.removeFromParent()
                ])
                beam.run(beamAnimation)
            }
        }
    }
    
    // Create sparkle particle effect
    private func createSparkleEffect(at position: CGPoint) {
        // Use harmonious colors from tetromino palette for sparkles
        let sparkleColors = [
            BlockColors.yellow,    // Special pieces
            BlockColors.amber,     // Warm highlight  
            BlockColors.orange,    // L-shapes
            BlockColors.lime,      // Bright accent
            BlockColors.teal,      // Sticks
            BlockColors.cyan       // Cool accent
        ]
        
        for i in 0..<15 {
            let sparkle = SKShapeNode(circleOfRadius: 3)
            sparkle.fillColor = SKColor(sparkleColors.randomElement()!)
            sparkle.strokeColor = .clear
            sparkle.position = position
            sparkle.zPosition = 215
            addChild(sparkle)
            
            let angle = CGFloat(i) * 2 * .pi / 15
            let distance = CGFloat.random(in: 50...120)
            let targetX = position.x + cos(angle) * distance
            let targetY = position.y + sin(angle) * distance
            
            let sparkleAnimation = SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0...0.3)),
                SKAction.group([
                    SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.8),
                    SKAction.sequence([
                        SKAction.scale(to: 1.5, duration: 0.2),
                        SKAction.scale(to: 0.5, duration: 0.6)
                    ]),
                    SKAction.sequence([
                        SKAction.wait(forDuration: 0.4),
                        SKAction.fadeOut(withDuration: 0.4)
                    ])
                ]),
                SKAction.removeFromParent()
            ])
            sparkleAnimation.timingMode = .easeOut
            sparkle.run(sparkleAnimation)
        }
    }
    
    // MARK: - Gradient Texture Creation
    
    /// Creates a reusable styled text node with gradient and stroke effects
    private func createStyledTextNode(
        text: String,
        fontName: String,
        fontSize: CGFloat,
        position: CGPoint,
        topColor: UIColor,
        bottomColor: UIColor,
        strokeColor: SKColor
    ) -> SKNode {
        let containerNode = SKNode()
        
        // Create base label for measurements and copying
        let baseLabel = SKLabelNode(text: text)
        baseLabel.fontName = fontName
        baseLabel.fontSize = fontSize
        baseLabel.verticalAlignmentMode = .center
        baseLabel.horizontalAlignmentMode = .center
        baseLabel.numberOfLines = 0 // Allow multi-line text
        
        // Stroke simulation with 8-offset copies
        let strokeOffsets: [CGPoint] = [
            CGPoint(x: -3, y: -3), CGPoint(x: 0, y: -3), CGPoint(x: 3, y: -3),
            CGPoint(x: -3, y:  0),                       CGPoint(x: 3, y:  0),
            CGPoint(x: -3, y:  3), CGPoint(x: 0, y:  3), CGPoint(x: 3, y:  3)
        ]
        
        for offset in strokeOffsets {
            let stroke = baseLabel.copy() as! SKLabelNode
            stroke.fontColor = strokeColor
            stroke.position = CGPoint(x: offset.x, y: offset.y)
            stroke.zPosition = 0
            containerNode.addChild(stroke)
        }
        
        // Create gradient texture
        let gradientTexture = makeGradientTexture(
            size: CGSize(width: 400, height: 120),
            topColor: topColor,
            bottomColor: bottomColor
        )
        let gradientSprite = SKSpriteNode(texture: gradientTexture)
        gradientSprite.position = .zero
        
        // Mask label for gradient
        let maskLabel = baseLabel.copy() as! SKLabelNode
        maskLabel.position = .zero
        
        // Crop node to apply gradient to text shape
        let cropNode = SKCropNode()
        cropNode.maskNode = maskLabel
        cropNode.addChild(gradientSprite)
        cropNode.position = .zero
        cropNode.zPosition = 1
        containerNode.addChild(cropNode)
        
        // Set the final position
        containerNode.position = position
        
        return containerNode
    }
    
    /// Creates a gradient texture with customizable colors
    private func makeGradientTexture(size: CGSize, topColor: UIColor, bottomColor: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let colors = [topColor.cgColor, bottomColor.cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1])!
            
            // Draw gradient from top to bottom
            ctx.cgContext.drawLinearGradient(gradient,
                                             start: CGPoint(x: 0, y: size.height),
                                             end: CGPoint(x: 0, y: 0),
                                             options: [])
        }
        return SKTexture(image: image)
    }
    
    // MARK: - Game Over Visuals
    
    /// Visual effect for game over
    func showGameOverEffect() {
        // Only show game over effect if flag is true
        guard shouldDisplayGameOver else { return }
        
        // Darken the screen
        let overlay = SKShapeNode(rect: self.frame)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = SKColor.clear
        overlay.zPosition = 500
        overlay.alpha = 0
        addChild(overlay)
        
        // Fade in the overlay
        overlay.run(SKAction.fadeIn(withDuration: 0.5))
        
        // Add game over text
        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        gameOverLabel.alpha = 0
        gameOverLabel.zPosition = 501
        addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(text: "Final Score: \(score)")
        scoreLabel.fontName = "AvenirNext-Medium"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY - 10)
        scoreLabel.alpha = 0
        scoreLabel.zPosition = 501
        addChild(scoreLabel)
        
        let tapInfoLabel = SKLabelNode(text: "Tap to continue")
        tapInfoLabel.fontName = "AvenirNext-Medium"
        tapInfoLabel.fontSize = 20
        tapInfoLabel.fontColor = .lightGray
        tapInfoLabel.position = CGPoint(x: frame.midX, y: frame.midY - 60)
        tapInfoLabel.alpha = 0
        tapInfoLabel.zPosition = 501
        addChild(tapInfoLabel)
        
        // Animate text
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        gameOverLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.3), fadeIn]))
        scoreLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.6), fadeIn]))
        tapInfoLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.9), fadeIn]))
    }
}
