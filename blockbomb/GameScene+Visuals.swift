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
    
    // Visual feedback for successful placement
    func flashConfirmation(at position: CGPoint) {
        // Create multiple expanding rings for depth
        for i in 0..<3 {
            let flash = SKShapeNode(circleOfRadius: 15)
            flash.position = position
            flash.fillColor = .clear
            flash.strokeColor = SKColor.green.withAlphaComponent(0.8 - CGFloat(i) * 0.2)
            flash.lineWidth = 3.0
            flash.alpha = 0
            flash.zPosition = 200 - CGFloat(i)
            addChild(flash)
            
            let delay = Double(i) * 0.05
            let expandSequence = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.1),
                    SKAction.scale(to: 2.5 + CGFloat(i) * 0.5, duration: 0.4)
                ]),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ])
            flash.run(expandSequence)
        }
        
        // Add a bright center flash
        let centerFlash = SKShapeNode(circleOfRadius: 20)
        centerFlash.position = position
        centerFlash.fillColor = SKColor.green.withAlphaComponent(0.6)
        centerFlash.strokeColor = .clear
        centerFlash.zPosition = 205
        addChild(centerFlash)
        
        let centerSequence = SKAction.sequence([
            SKAction.scale(to: 0.1, duration: 0.0),
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ])
        centerFlash.run(centerSequence)
    }
    
    // Visual feedback for clearing lines
    func flashLinesClearedConfirmation(at position: CGPoint, rows: Int, columns: Int) {
        // Create spectacular explosion effect with multiple layers
        createExplosionEffect(at: position, isCombo: rows > 0 && columns > 0)
        
        // Create the text label showing what was cleared
        let messageNode = SKNode()
        messageNode.position = position
        messageNode.zPosition = 220
        addChild(messageNode)
        
        // Text showing what was cleared with enhanced styling
        var message = ""
        var textColor = SKColor.cyan
        var fontSize: CGFloat = 28
        
        if (rows > 0 && columns > 0) {
            message = "🎉 COMBO! 🎉\n\(rows) rows + \(columns) columns"
            textColor = SKColor.orange
            fontSize = 32
        } else if (rows > 0) {
            let rowText = rows == 1 ? "row" : "rows"
            message = "💥 \(rows) \(rowText) cleared!"
            textColor = SKColor.yellow
        } else if (columns > 0) {
            let colText = columns == 1 ? "column" : "columns"
            message = "⚡ \(columns) \(colText) cleared!"
            textColor = SKColor.cyan
        }
        
        // Create main text label with shadow effect
        let shadowLabel = SKLabelNode(text: message)
        shadowLabel.fontName = "AvenirNext-Heavy"
        shadowLabel.fontSize = fontSize
        shadowLabel.fontColor = SKColor.black.withAlphaComponent(0.5)
        shadowLabel.numberOfLines = 3
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.verticalAlignmentMode = .center
        shadowLabel.position = CGPoint(x: 2, y: -2) // Shadow offset
        messageNode.addChild(shadowLabel)
        
        let label = SKLabelNode(text: message)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = fontSize
        label.fontColor = textColor
        label.numberOfLines = 3
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        messageNode.addChild(label)
        
        // Add glow effect to text
        let glowLabel = SKLabelNode(text: message)
        glowLabel.fontName = "AvenirNext-Heavy"
        glowLabel.fontSize = fontSize + 2
        glowLabel.fontColor = textColor.withAlphaComponent(0.3)
        glowLabel.numberOfLines = 3
        glowLabel.horizontalAlignmentMode = .center
        glowLabel.verticalAlignmentMode = .center
        glowLabel.zPosition = -1
        messageNode.addChild(glowLabel)
        
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
            createSparkleEffect(at: position)
        }
    }
    
    // Create explosion effect with radiating circles
    private func createExplosionEffect(at position: CGPoint, isCombo: Bool) {
        let ringCount = isCombo ? 6 : 4
        let baseRadius: CGFloat = 40
        let maxRadius: CGFloat = isCombo ? 150 : 100
        
        for i in 0..<ringCount {
            let delay = Double(i) * 0.08
            let ring = SKShapeNode(circleOfRadius: baseRadius)
            ring.position = position
            ring.fillColor = .clear
            ring.strokeColor = isCombo ? SKColor.orange : SKColor.green
            ring.lineWidth = isCombo ? 5.0 : 3.0
            ring.alpha = 0
            ring.zPosition = 210 - CGFloat(i)
            addChild(ring)
            
            let ringAnimation = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.8, duration: 0.1),
                    SKAction.scale(to: maxRadius / baseRadius, duration: 0.6)
                ]),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ])
            ringAnimation.timingMode = .easeOut
            ring.run(ringAnimation)
        }
        
        // Add rotating energy beams for combo
        if isCombo {
            for i in 0..<8 {
                let beam = SKSpriteNode(color: SKColor.orange.withAlphaComponent(0.6), size: CGSize(width: 4, height: 80))
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
        for i in 0..<15 {
            let sparkle = SKShapeNode(circleOfRadius: 3)
            sparkle.fillColor = [SKColor.yellow, SKColor.orange, SKColor.white].randomElement()!
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
