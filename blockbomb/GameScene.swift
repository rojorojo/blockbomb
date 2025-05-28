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
    
    // Reference to game controller for configuration
    weak var gameController: GameController?
    
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
        // Setup scene background using centralized colors
        backgroundColor = GameBoardVisuals.Colors.sceneBackground
        
        // Get safe area insets
        let safeAreaInsets = getSafeAreaInsets(for: view)
        
        // Setup game board - 8x8 grid
        gameBoard = GameBoard()
        gameBoard.boardNode.position = GameBoardVisuals.calculateBoardPosition(
            sceneSize: frame.size,
            columns: gameBoard.columns,
            rows: gameBoard.rows,
            blockSize: gameBoard.blockSize,
            verticalOffset: 20
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

