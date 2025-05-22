import SpriteKit
import GameplayKit
import SwiftUI

// GameScene.swift - The main game scene implementation
class GameScene: SKScene {
    
    // Game components
    private var gameBoard: GameBoard!
    private var pieceNodes: [PieceNode] = []
    private var scoreLabel: SKLabelNode!
    private var scoreValueLabel: SKLabelNode!
    private var score = 0 {
        didSet {
            scoreUpdateHandler?(score)
        }
    }
    private var scorePopups: [SKNode] = []
    
    // Communication with SwiftUI
    var scoreUpdateHandler: ((Int) -> Void)?
    var shapeGalleryRequestHandler: (() -> Void)?
    var gameOverHandler: ((Int) -> Void)?  // New handler for game over
    
    // Flag to control score display in SpriteKit
    var shouldDisplayScore: Bool = true
    
    // Flag to control game over display in SpriteKit
    var shouldDisplayGameOver: Bool = true
    
    // Dragging support
    private var selectedNode: PieceNode?
    private var originalPosition: CGPoint?
    private var currentGridCell: GridCell?
    
    // Game state
    private var isGameOver = false
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        
        // Get safe area insets
        let safeAreaInsets = getSafeAreaInsets(for: view)
        
        // Setup game board - 10x10 grid
        gameBoard = GameBoard()
        gameBoard.boardNode.position = CGPoint(
            x: frame.midX - (CGFloat(gameBoard.columns) * gameBoard.blockSize / 2),
            y: frame.midY - (CGFloat(gameBoard.rows) * gameBoard.blockSize / 2) + 20 // Adjust position
        )
        addChild(gameBoard.boardNode)
        
        // Setup score display - position below top safe area
        setupScoreDisplay(safeAreaInsets: safeAreaInsets)
        
        // Add border around game area
        addBoardBorder()
        
        // Setup pieces to drag
        setupDraggablePieces()
        
        // Add debug button
        addDebugButton(safeAreaInsets: safeAreaInsets)
    }
    
    // Helper method to get safe area insets
    private func getSafeAreaInsets(for view: SKView) -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0) // Default values for older iOS
        }
    }
    
    private func addBoardBorder() {
        let boardWidth = CGFloat(gameBoard.columns) * gameBoard.blockSize
        let boardHeight = CGFloat(gameBoard.rows) * gameBoard.blockSize
        
        let borderNode = SKShapeNode(rect: CGRect(x: gameBoard.boardNode.position.x - 2,
                                                y: gameBoard.boardNode.position.y - 2,
                                                width: boardWidth + 4,
                                                height: boardHeight + 4))
        borderNode.lineWidth = 2.0
        borderNode.strokeColor = .white
        addChild(borderNode)
    }
    
    private func setupDraggablePieces() {
        // Clear any existing pieces
        pieceNodes.forEach { $0.removeFromParent() }
        pieceNodes.removeAll()
        
        // Get a more varied selection of shapes to display
        let availableShapes = TetrominoShape.allCases
        
        // Prioritize displaying a mix of different shape categories
        let shapeCategories: [[TetrominoShape]] = [
            [.squareSmall, .squareBig],                      // Square shapes
            [.rectWide, .rectTall],                          // Rectangle shapes
            [.stick3, .stick4, .stick5],                     // Sticks
            [.lShapeSit, .lShapeReversed, .lShapeLayingDown, .lShapeStand],              // L shapes
            [.cornerTopLeft, .cornerBottomLeft, .cornerBottomRight, .cornerTopRight],                    // Corner shapes
            [.tShapeDown, .tShapeUp],                       // T shapes
            [.cross, .blockSingle] // Special shapes
        ]
        
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
        let yPosition = gridBottom - 80 // Add more space below the grid
        
        // Calculate horizontal spacing based on number of pieces
        let numberOfPieces = selectedShapes.count
        let boardWidth = CGFloat(gameBoard.columns) * gameBoard.blockSize
        let pieceSpacing = boardWidth / CGFloat(numberOfPieces + 1)
        let startX = gameBoard.boardNode.position.x + pieceSpacing
        
        for (index, shape) in selectedShapes.enumerated() {
            let piece = PieceNode(shape: shape, color: shape.color)
            piece.position = CGPoint(x: startX + pieceSpacing * CGFloat(index), y: yPosition)
            piece.name = "draggable_piece"
            piece.zPosition = 100
            piece.setScale(0.6) // Scale down for better fit
            addChild(piece)
            pieceNodes.append(piece)
            
            // Add a subtle animation
            let moveAction = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 0.5),
                SKAction.moveBy(x: 0, y: -5, duration: 0.5)
            ])
            piece.run(SKAction.repeatForever(moveAction))
        }
        
        // Instruction label - positioned below pieces
        let instructionLabel = SKLabelNode(text: "Drag pieces onto the grid")
        instructionLabel.fontName = "AvenirNext-Medium"
        instructionLabel.fontSize = 18
        instructionLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        instructionLabel.position = CGPoint(x: frame.midX, y: yPosition - 50)
        addChild(instructionLabel)
        
        // After creating pieces, check if any of them can be placed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkForGameOver()
        }
    }
    
    private func addDebugButton(safeAreaInsets: UIEdgeInsets) {
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
    
    private func setupScoreDisplay(safeAreaInsets: UIEdgeInsets) {
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
    
    private func updateScoreLabel() {
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
    
    private func animateScoreChange(from oldScore: Int, to newScore: Int) {
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
    
    private func showScorePopup(points: Int) {
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
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if we touched the debug button
        if let touchedNode = nodes(at: location).first, touchedNode.name == "debugButton" {
            // Present the SwiftUI gallery view instead of the SpriteKit version
            presentSwiftUIShapeGallery()
            return
        }
        
        // Check if we touched a draggable piece
        if let node = nodes(at: location).first(where: { $0.name == "draggable_piece" }) as? PieceNode {
            selectedNode = node
            originalPosition = node.position
            
            // Scale up slightly to indicate selection
            node.run(SKAction.scale(to: 1.1, duration: 0.1))
            node.zPosition = 150
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let selectedNode = selectedNode else { return }
        let location = touch.location(in: self)
        selectedNode.position = location
        
        // Update ghost piece preview
        if let gridCell = gameBoard.gridCellAt(scenePosition: location) {
            if gridCell != currentGridCell {
                currentGridCell = gridCell
                gameBoard.showGhostPiece(selectedNode.gridPiece, at: gridCell)
            }
        } else {
            // Not over grid, clear ghost
            currentGridCell = nil
            // Clear ghost display if needed
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let selectedNode = selectedNode, let originalPosition = originalPosition else { return }
        
        // Check if we have a valid grid cell
        if let gridCell = currentGridCell {
            // Try to place the piece at this grid cell
            if gameBoard.canPlacePiece(selectedNode.gridPiece, at: gridCell) {
                // Place the piece on the board
                selectedNode.removeAllActions()
                
                // Place piece on grid and get lines cleared
                let linesCleared = gameBoard.placePiece(selectedNode.gridPiece, at: gridCell)
                
                // Award points for the piece and cleared lines
                let piecePoints = calculatePointsForPiece(selectedNode.gridPiece)
                let rowPoints = calculatePoints(forLines: linesCleared.rows)
                let columnPoints = calculatePoints(forLines: linesCleared.columns) 
                
                // Add bonus for clearing both rows and columns at once
                let comboBonus = (linesCleared.rows > 0 && linesCleared.columns > 0) ? 500 : 0
                
                // Update score
                let totalPoints = piecePoints + rowPoints + columnPoints + comboBonus
                score += totalPoints
                updateScoreLabel()
                
                // Show appropriate confirmation based on what was cleared
                if linesCleared.rows > 0 || linesCleared.columns > 0 {
                    // Show more dramatic confirmation for line clears
                    flashLinesClearedConfirmation(at: selectedNode.position, 
                                               rows: linesCleared.rows, 
                                               columns: linesCleared.columns)
                } else {
                    // Simple confirmation for just placing a piece
                    flashConfirmation(at: selectedNode.position)
                }
                
                // Remove from draggable pieces array
                if let index = pieceNodes.firstIndex(of: selectedNode) {
                    pieceNodes.remove(at: index)
                }
                
                // Remove the piece node from the scene
                selectedNode.removeFromParent()
                
                // Check if we need new pieces
                if pieceNodes.isEmpty {
                    setupDraggablePieces()
                } else {
                    // Check if remaining pieces can still be placed
                    checkGameStateAfterPlacement()
                }
                
                // Reset selection
                self.selectedNode = nil
                self.originalPosition = nil
                self.currentGridCell = nil
                return
            }
        }
        
        // If we couldn't place the piece, return it to its original position
        returnPieceToOriginalPosition()
        
        // Reset selection
        selectedNode.zPosition = 100
        selectedNode.run(SKAction.scale(to: 1.0, duration: 0.1))
        self.selectedNode = nil
        self.originalPosition = nil
        self.currentGridCell = nil
    }
    
    private func returnPieceToOriginalPosition() {
        guard let selectedNode = selectedNode, let originalPosition = originalPosition else { return }
        let moveBack = SKAction.move(to: originalPosition, duration: 0.2)
        selectedNode.run(moveBack)
    }
    
    private func isOverGameBoard(_ position: CGPoint) -> Bool {
        let boardRect = CGRect(
            x: gameBoard.boardNode.position.x,
            y: gameBoard.boardNode.position.y,
            width: CGFloat(gameBoard.columns) * gameBoard.blockSize,
            height: CGFloat(gameBoard.rows) * gameBoard.blockSize
        )
        return boardRect.contains(position)
    }
    
    // Visual debugging helper
    private func highlightBoardArea() {
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
    private func flashConfirmation(at position: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.position = position
        flash.fillColor = .green
        flash.alpha = 0.5
        flash.zPosition = 200
        addChild(flash)
        
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        flash.run(sequence)
    }
    
    // Visual feedback for clearing lines
    private func flashLinesClearedConfirmation(at position: CGPoint, rows: Int, columns: Int) {
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
    
    private func calculatePoints(forLines lines: Int) -> Int {
        switch lines {
        case 1: return 100
        case 2: return 300
        case 3: return 500
        case 4: return 800
        case 5...: return 1000 + (lines - 5) * 200  // Higher bonus for more lines
        default: return 0
        }
    }
    
    private func calculatePointsForPiece(_ piece: GridPiece) -> Int {
        // Award points based on piece complexity
        return piece.cells.count * 5
    }
    
    // Add this new method to present SwiftUI view
    private func presentSwiftUIShapeGallery() {
        // Get the view controller that's presenting the game
        guard let viewController = self.view?.window?.rootViewController else { return }
        
        // Create and configure the SwiftUI view
        let galleryView = ShapeGalleryView()
        let hostingController = UIHostingController(rootView: galleryView)
        hostingController.modalPresentationStyle = .fullScreen
        
        // Present the SwiftUI view controller
        viewController.present(hostingController, animated: true)
    }
    
    // MARK: - Game Over Logic
    
    /// Check if any of the current pieces can be placed on the board
    private func checkForGameOver() {
        guard !isGameOver && !pieceNodes.isEmpty else { return }
        
        // Debug logging
        print("Checking for game over with \(pieceNodes.count) pieces")
        
        var canPlaceAnyPiece = false
        
        for piece in pieceNodes {
            // Check if the piece can be placed anywhere (no rotations allowed)
            if gameBoard.canPlacePieceAnywhere(piece.gridPiece) {
                canPlaceAnyPiece = true
                print("Piece \(piece.gridPiece.shape) can be placed")
                break // At least one piece can be placed, game continues
            } else {
                print("Piece \(piece.gridPiece.shape) cannot be placed anywhere")
            }
        }
        
        if !canPlaceAnyPiece {
            print("GAME OVER: No pieces can be placed")
            handleGameOver()
        }
    }
    
    /// Check if a specific piece can be placed anywhere on the board
    private func canPlacePieceAnywhere(_ piece: GridPiece) -> Bool {
        // Delegate to the GameBoard implementation
        return gameBoard.canPlacePieceAnywhere(piece)
    }
    
    // Add a forced check that runs after each piece placement
    private func checkGameStateAfterPlacement() {
        // Give a moment for animations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkForGameOver()
        }
    }
    
    /// Handle the game over state
    private func handleGameOver() {
        isGameOver = true
        
        // Stop all piece animations
        pieceNodes.forEach { $0.removeAllActions() }
        
        // Show game over effect in SpriteKit if enabled
        showGameOverEffect()
        
        // Call the SwiftUI handler to show game over screen
        gameOverHandler?(score)
    }
    
    /// Visual effect for game over
    private func showGameOverEffect() {
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
    
    /// Reset the game to starting state
    func resetGame() {
        isGameOver = false
        
        // Remove game over visuals
        self.children.filter { $0.zPosition >= 500 }.forEach { $0.removeFromParent() }
        
        // Reset the game board
        gameBoard.resetBoard()
        
        // Reset score
        score = 0
        updateScoreLabel()
        
        // Set up new pieces
        setupDraggablePieces()
    }
}

