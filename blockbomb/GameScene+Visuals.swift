import SpriteKit

// Extension containing all visual effects and UI functionality
extension GameScene {
    // MARK: - UI Setup
    
    func addDebugButton(safeAreaInsets: UIEdgeInsets) {
        let debugButton = SKLabelNode(text: "View All Shapes")
        debugButton.fontName = "AvenirNext-Medium"
        debugButton.fontSize = 16
        debugButton.fontColor = .white
        // Position the button below the pieces
        let gridBottom = gameBoard.boardNode.position.y - (CGFloat(gameBoard.rows) * gameBoard.blockSize / 2)
        debugButton.position = CGPoint(x: frame.width - 80, y: gridBottom - 120)
        debugButton.name = "debugButton"
        addChild(debugButton)
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
    func flashLinesClearedConfirmation(rows: Int, columns: Int) {
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
        var message = ""
        var textColor = SKColor.cyan
        var fontSize: CGFloat = 28
        
        if (rows > 0 && columns > 0) {
            message = "COMBO!\n\(rows) rows + \(columns) columns"
            textColor = SKColor(BlockColors.orange) // L-Shape color for combo excitement
            fontSize = 32
        } else if (rows > 0) {
            let rowText = rows == 1 ? "row" : "rows"
            message = "\(rows) \(rowText) cleared!"
            textColor = SKColor(BlockColors.lime) // Bright green for row clearing achievements
        } else if (columns > 0) {
            let colText = columns == 1 ? "column" : "columns"
            message = "\(columns) \(colText) cleared!"
            textColor = SKColor(BlockColors.teal) // Stick color for linear clearing
        }
        
        // Create main text label with shadow effect
        /*let shadowLabel = SKLabelNode(text: message)
        shadowLabel.fontName = "AvenirNext-Heavy"
        shadowLabel.fontSize = fontSize
        shadowLabel.fontColor = SKColor.black.withAlphaComponent(0.5)
        shadowLabel.numberOfLines = 3
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.verticalAlignmentMode = .center
        shadowLabel.position = CGPoint(x: 2, y: -2) // Shadow offset
        messageNode.addChild(shadowLabel)*/
        
        let label = SKLabelNode(text: message)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = fontSize
        label.fontColor = textColor
        label.numberOfLines = 3
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        messageNode.addChild(label)
        
        // Add glow effect to text
        /*let glowLabel = SKLabelNode(text: message)
        glowLabel.fontName = "AvenirNext-Heavy"
        glowLabel.fontSize = fontSize + 2
        glowLabel.fontColor = textColor.withAlphaComponent(0.3)
        glowLabel.numberOfLines = 3
        glowLabel.horizontalAlignmentMode = .center
        glowLabel.verticalAlignmentMode = .center
        glowLabel.zPosition = -1
        messageNode.addChild(glowLabel)*/
        
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
