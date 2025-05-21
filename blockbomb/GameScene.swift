import SpriteKit
import GameplayKit

// GameScene.swift - The main game scene implementation
class GameScene: SKScene {
    
    // Game components
    private var gameBoard: GameBoard!
    private var pieceNodes: [PieceNode] = []
    private var scoreLabel: SKLabelNode!
    private var score = 0
    
    // Dragging support
    private var selectedNode: PieceNode?
    private var originalPosition: CGPoint?
    private var currentGridCell: GridCell?
    
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
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.height - safeAreaInsets.top - 40)
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
        
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
            [.lShapeSit, .lShapeReversed],              // L shapes
            [.blockSingle, .blockDouble],                    // Block pieces
            [.cornerSmall, .cornerWide],                     // Corner shapes
            [.tShape, .zigzag, .cross]                       // Special shapes
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
        
        // Create and position pieces along the bottom - respect safe area
        let spacing: CGFloat = frame.width / 4
        let safeAreaInsets = getSafeAreaInsets(for: self.view!)
        let yPosition = safeAreaInsets.bottom + 220 // Position above bottom safe area
        
        for (index, shape) in selectedShapes.enumerated() {
            let piece = PieceNode(shape: shape, color: shape.color)
            piece.position = CGPoint(x: spacing * CGFloat(index + 1), y: yPosition)
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
        
        // Instruction label - positioned above pieces
        let instructionLabel = SKLabelNode(text: "Drag pieces onto the grid")
        instructionLabel.fontName = "AvenirNext-Medium"
        instructionLabel.fontSize = 18
        instructionLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        instructionLabel.position = CGPoint(x: frame.midX, y: yPosition - 40)
        addChild(instructionLabel)
    }
    
    private func addDebugButton(safeAreaInsets: UIEdgeInsets) {
        let debugButton = SKLabelNode(text: "View All Shapes")
        debugButton.fontName = "AvenirNext-Medium"
        debugButton.fontSize = 16
        debugButton.fontColor = .white
        debugButton.position = CGPoint(x: frame.width - 80, y: safeAreaInsets.bottom + 40)
        debugButton.name = "debugButton"
        addChild(debugButton)
    }
    
    private func updateScoreLabel() {
        scoreLabel.text = "Score: \(score)"
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if we touched the debug button
        if let touchedNode = nodes(at: location).first, touchedNode.name == "debugButton" {
            // Show the shape debug scene
            let debugScene = ShapeDebugScene(size: size)
            debugScene.scaleMode = scaleMode
            view?.presentScene(debugScene, transition: SKTransition.fade(withDuration: 0.5))
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
                
                // Update score if lines were cleared
                if linesCleared > 0 {
                    let basePoints = calculatePoints(forLines: linesCleared)
                    score += basePoints
                    updateScoreLabel()
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
    
    private func calculatePoints(forLines lines: Int) -> Int {
        switch lines {
        case 1: return 100
        case 2: return 300
        case 3: return 500
        case 4: return 800
        default: return 0
        }
    }
}

