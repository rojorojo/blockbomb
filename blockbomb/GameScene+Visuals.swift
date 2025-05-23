import SpriteKit

// Extension containing all visual effects and UI functionality
extension GameScene {
    // MARK: - UI Setup
    func setupScoreDisplay(safeAreaInsets: UIEdgeInsets) {
        // Only set up score display if flag is true
        guard shouldDisplayScore else { return }
        // Score title label
        scoreLabel = SKLabelNode(text: "Score:")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.position = CGPoint(x: frame.midX - 40, y: frame.height - safeAreaInsets.top - 80)
        scoreLabel.horizontalAlignmentMode = .right
        addChild(scoreLabel)
        // Score value label (separate for animation effects)
        scoreValueLabel = SKLabelNode(text: "0")
        scoreValueLabel.fontName = "AvenirNext-Bold"
        scoreValueLabel.fontSize = 30
        scoreValueLabel.fontColor = .yellow
        scoreValueLabel.position = CGPoint(x: frame.midX + 20, y: frame.height - safeAreaInsets.top - 80)
        scoreValueLabel.horizontalAlignmentMode = .left
        addChild(scoreValueLabel)
    }
    
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
        let boardWidth = CGFloat(gameBoard.columns) * gameBoard.blockSize
        let boardHeight = CGFloat(gameBoard.rows) * gameBoard.blockSize
        
        let borderNode = SKShapeNode(rect: CGRect(x: gameBoard.boardNode.position.x - 2,
                                                y: gameBoard.boardNode.position.y - 2,
                                                width: boardWidth + 4,
                                                height: boardHeight + 4))
        borderNode.lineWidth = 2.0
        borderNode.strokeColor = SKColor(white: 0.7, alpha: 0.5)
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
        // Animate the score change
        animateScoreChange(from: oldScore, to: score)
        
        // Show score popup if points were gained
        if scoreIncrement > 0 {
            showScorePopup(points: scoreIncrement)
        }
    }
    
    func animateScoreChange(from oldScore: Int, to newScore: Int) {
        // Scale up animation
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        // Create animation sequence
        let animationSequence = SKAction.sequence([scaleUp, scaleDown])
        
        // Update the score with animation
        scoreValueLabel.run(animationSequence) { [weak self] in
            self?.scoreValueLabel.text = "\(newScore)"
        }
    }
    
    func showScorePopup(points: Int) {
        guard let gridCell = currentGridCell else { return }
        
        // Convert grid cell to scene coordinates
        let popupPosition = gameBoard.boardPositionForCell(gridCell)
        let scenePosition = gameBoard.boardNode.convert(popupPosition, to: self)
        
        // Create popup node
        let popupNode = SKNode()
        popupNode.position = scenePosition
        popupNode.zPosition = 300
        addChild(popupNode)
        scorePopups.append(popupNode)
        
        // Add text with points
        let pointsLabel = SKLabelNode(text: "+\(points)")
        pointsLabel.fontName = "AvenirNext-Bold"
        pointsLabel.fontSize = 22
        pointsLabel.fontColor = .green
        popupNode.addChild(pointsLabel)
        
        // Animate popup
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
        popupNode.run(sequence) { [weak self] in
            if let index = self?.scorePopups.firstIndex(of: popupNode) {
                self?.scorePopups.remove(at: index)
            }
        }
    }
    
    // MARK: - Visual Effects
    
    // Visual debugging helper
    func highlightBoardArea() {
        // Remove any existing highlight
        if let existingHighlight = childNode(withName: "boardHighlight") {
            existingHighlight.removeFromParent()
        }
        
        let highlight = SKShapeNode(rect: CGRect(
            x: gameBoard.boardNode.position.x,
            y: gameBoard.boardNode.position.y,
            width: CGFloat(gameBoard.columns) * gameBoard.blockSize,
            height: CGFloat(gameBoard.rows) * gameBoard.blockSize
        ))
        highlight.strokeColor = .red
        highlight.lineWidth = 2
        highlight.name = "boardHighlight"
        highlight.zPosition = 200
        
        // Make it flash and then remove
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ])
        highlight.run(sequence)
        addChild(highlight)
    }
    
    // Visual feedback for successful placement
    func flashConfirmation(at position: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.position = position
        flash.fillColor = .green
        flash.alpha = 0.5
        flash.zPosition = 200
        addChild(flash)
        
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        flash.run(sequence)
    }
    
    // Visual feedback for clearing lines
    func flashLinesClearedConfirmation(at position: CGPoint, rows: Int, columns: Int) {
        // First, show a flash effect
        let flash = SKShapeNode(circleOfRadius: 60)
        flash.position = position
        flash.fillColor = .green
        flash.alpha = 0.3
        flash.zPosition = 200
        addChild(flash)
        
        // Create the text label showing what was cleared
        let messageNode = SKNode()
        messageNode.position = position
        messageNode.zPosition = 200
        addChild(messageNode)
        
        // Text showing what was cleared
        var message = ""
        if (rows > 0 && columns > 0) {
            message = "COMBO!\n\(rows) rows\n\(columns) columns"
        } else if (rows > 0) {
            message = "\(rows) " + (rows == 1 ? "row" : "rows")
        } else if (columns > 0) {
            message = "\(columns) " + (columns == 1 ? "column" : "columns")
        }
        
        let label = SKLabelNode(text: message)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = .yellow
        label.numberOfLines = 3
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        messageNode.addChild(label)
        
        // Create animations
        let flashSequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        
        let messageSequence = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.wait(forDuration: 0.8),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 50, duration: 0.7),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ])
        
        flash.run(flashSequence)
        messageNode.run(messageSequence)
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
