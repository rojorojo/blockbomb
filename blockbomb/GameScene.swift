import SpriteKit
import GameplayKit
import SwiftUI

// GameScene.swift - The main game scene implementation
class GameScene: SKScene {
    
    // Game components
    var gameBoard: GameBoard!
    var pieceNodes: [PieceNode] = []
    var scoreLabel: SKLabelNode!
    var scoreValueLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreUpdateHandler?(score)
        }
    }
    var scorePopups: [SKNode] = []
    
    // Communication with SwiftUI
    var scoreUpdateHandler: ((Int) -> Void)?
    var shapeGalleryRequestHandler: (() -> Void)?
    var gameOverHandler: ((Int) -> Void)?  // New handler for game over
    
    // Flag to control score display in SpriteKit
    var shouldDisplayScore: Bool = true
    
    // Flag to control game over display in SpriteKit
    var shouldDisplayGameOver: Bool = true
    
    // Dragging support
    var selectedNode: PieceNode?
    var originalPosition: CGPoint?
    var currentGridCell: GridCell?
    var touchOffset: CGPoint = .zero // Store offset between touch point and piece center
    let dragVerticalOffset: CGFloat = 100 // Increase from 60 to 100 for more distance from finger
    
    // Game state
    var isGameOver = false
    
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
}

