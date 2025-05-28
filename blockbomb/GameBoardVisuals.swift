import SpriteKit

/// Centralized visual configuration and management for the game board
struct GameBoardVisuals {
    
    // MARK: - Visual Constants
    
    /// Color scheme for the game board
    struct Colors {
        static let sceneBackground = SKColor(red: 0.02, green: 0, blue: 0.22, alpha: 1.0)
        static let boardBackground = SKColor(red: 0.53, green: 0.48, blue: 1, alpha: 0.15)
        static let gridLines = SKColor(white: 0, alpha: 0.9)
        static let border = SKColor(red: 0.53, green: 0.48, blue: 1, alpha: 0.3)
    }
    
    /// Visual sizing and styling parameters
    struct Style {
        static let gridLineWidth: CGFloat = 1.0
        static let borderWidth: CGFloat = 2.0
        static let borderPadding: CGFloat = 2.0
        static let blockCornerRadius: CGFloat = 3.0
        static let ghostAlpha: CGFloat = 0.3
    }
    
    // MARK: - Board Visual Setup
    
    /// Creates and configures the complete visual representation of the game board
    /// - Parameters:
    ///   - columns: Number of columns in the grid
    ///   - rows: Number of rows in the grid
    ///   - blockSize: Size of each grid cell
    ///   - boardNode: The SKNode to add visual elements to
    static func setupBoardVisuals(columns: Int, rows: Int, blockSize: CGFloat, boardNode: SKNode) {
        // Clear any existing visual elements
        clearBoardVisuals(boardNode: boardNode)
        
        // Add background
        let background = createBackground(columns: columns, rows: rows, blockSize: blockSize)
        boardNode.addChild(background)
        
        // Add grid lines
        let gridLines = createGridLines(columns: columns, rows: rows, blockSize: blockSize)
        boardNode.addChild(gridLines)
    }
    
    /// Creates the board background
    private static func createBackground(columns: Int, rows: Int, blockSize: CGFloat) -> SKShapeNode {
        let background = SKShapeNode(rectOf: CGSize(
            width: CGFloat(columns) * blockSize,
            height: CGFloat(rows) * blockSize
        ))
        background.fillColor = Colors.boardBackground
        background.strokeColor = .clear
        background.lineWidth = 0
        background.position = CGPoint(
            x: CGFloat(columns) * blockSize / 2,
            y: CGFloat(rows) * blockSize / 2
        )
        background.name = "gridBackground"
        background.zPosition = -2 // Behind grid lines and pieces
        return background
    }
    
    /// Creates the grid lines
    private static func createGridLines(columns: Int, rows: Int, blockSize: CGFloat) -> SKShapeNode {
        let gridLines = SKShapeNode()
        let path = CGMutablePath()
        
        // Vertical lines
        for i in 0...columns {
            let x = CGFloat(i) * blockSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: CGFloat(rows) * blockSize))
        }
        
        // Horizontal lines
        for i in 0...rows {
            let y = CGFloat(i) * blockSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: CGFloat(columns) * blockSize, y: y))
        }
        
        gridLines.path = path
        gridLines.strokeColor = Colors.gridLines
        gridLines.lineWidth = Style.gridLineWidth
        gridLines.name = "gridLines"
        gridLines.zPosition = -1 // Behind pieces but above background
        return gridLines
    }
    
    /// Removes all visual elements from the board
    static func clearBoardVisuals(boardNode: SKNode) {
        boardNode.children.forEach { child in
            if child.name == "gridBackground" || child.name == "gridLines" {
                child.removeFromParent()
            }
        }
    }
    
    // MARK: - Board Border
    
    /// Creates a border around the game board
    /// - Parameters:
    ///   - boardPosition: Position of the board node
    ///   - columns: Number of columns
    ///   - rows: Number of rows
    ///   - blockSize: Size of each grid cell
    /// - Returns: SKShapeNode representing the border
    static func createBoardBorder(boardPosition: CGPoint, columns: Int, rows: Int, blockSize: CGFloat) -> SKShapeNode {
        let boardWidth = CGFloat(columns) * blockSize
        let boardHeight = CGFloat(rows) * blockSize
        
        let borderNode = SKShapeNode(rect: CGRect(
            x: boardPosition.x - Style.borderPadding,
            y: boardPosition.y - Style.borderPadding,
            width: boardWidth + (Style.borderPadding * 2),
            height: boardHeight + (Style.borderPadding * 2)
        ))
        borderNode.lineWidth = Style.borderWidth
        borderNode.strokeColor = Colors.border
        borderNode.fillColor = .clear
        borderNode.name = "boardBorder"
        borderNode.zPosition = 10 // Above board but below UI elements
        return borderNode
    }
    
    // MARK: - Board Positioning
    
    /// Calculates the optimal position for the game board within the scene
    /// - Parameters:
    ///   - sceneSize: Size of the game scene
    ///   - columns: Number of columns
    ///   - rows: Number of rows
    ///   - blockSize: Size of each grid cell
    ///   - verticalOffset: Additional vertical offset (positive moves up)
    /// - Returns: CGPoint for board positioning
    static func calculateBoardPosition(sceneSize: CGSize, columns: Int, rows: Int, blockSize: CGFloat, verticalOffset: CGFloat = 20) -> CGPoint {
        let boardWidth = CGFloat(columns) * blockSize
        let boardHeight = CGFloat(rows) * blockSize
        
        return CGPoint(
            x: sceneSize.width / 2 - boardWidth / 2,
            y: sceneSize.height / 2 - boardHeight / 2 + verticalOffset
        )
    }
    
    // MARK: - Utility Methods
    
    /// Converts a grid cell to a position in board coordinates
    /// - Parameters:
    ///   - cell: The grid cell to convert
    ///   - blockSize: Size of each grid cell
    /// - Returns: CGPoint position for the cell
    static func positionForCell(_ cell: GridCell, blockSize: CGFloat) -> CGPoint {
        return CGPoint(
            x: CGFloat(cell.column) * blockSize + blockSize / 2,
            y: CGFloat(cell.row) * blockSize + blockSize / 2
        )
    }
    
    // MARK: - Block Creation
    
    /// Creates a standardized game block with consistent styling
    /// - Parameters:
    ///   - position: Position for the block
    ///   - blockSize: Size of the block
    ///   - color: Fill color for the block
    ///   - isGhost: Whether this is a ghost/preview block
    /// - Returns: Configured SKShapeNode block
    static func createBlock(at position: CGPoint, blockSize: CGFloat, color: SKColor, isGhost: Bool = false) -> SKShapeNode {
        let block = SKShapeNode(
            rectOf: CGSize(width: blockSize - 2, height: blockSize - 2),
            cornerRadius: Style.blockCornerRadius
        )
        block.position = position
        
        if isGhost {
            block.fillColor = color.withAlphaComponent(Style.ghostAlpha)
            block.strokeColor = color
            block.lineWidth = 2
        } else {
            block.fillColor = color
            block.strokeColor = SKColor(white: 0.3, alpha: 0.5)
            block.lineWidth = 1
        }
        
        return block
    }
    
    // MARK: - Completion Glow Effects
    
    /// Visual styling for completion glow effects
    struct GlowStyle {
        static let fillAlpha: CGFloat = 0.6
        static let strokeAlpha: CGFloat = 0.9
        static let lineWidth: CGFloat = 4.0
        static let pulseAnimationDuration: TimeInterval = 0.8
        static let fadeInDuration: TimeInterval = 0.2
        static let fadeOutDuration: TimeInterval = 0.15
        static let pulseMinAlpha: CGFloat = 0.4
        static let pulseMaxAlpha: CGFloat = 0.8
    }
    
    /// Creates a glow effect for a completed row
    /// - Parameters:
    ///   - row: Row index to highlight
    ///   - columns: Total number of columns in the grid
    ///   - blockSize: Size of each grid cell
    ///   - color: Color for the glow effect
    /// - Returns: SKNode representing the row glow with layered effects
    static func createRowGlow(row: Int, columns: Int, blockSize: CGFloat, color: SKColor) -> SKNode {
        let glowWidth = CGFloat(columns) * blockSize
        let glowHeight = blockSize
        
        // Create container node for layered glow effect
        let glowContainer = SKNode()
        glowContainer.name = "rowGlow_\(row)"
        glowContainer.zPosition = 5 // Above background but below pieces
        
        // Outer glow (softer, larger)
        let outerGlow = SKShapeNode(rectOf: CGSize(width: glowWidth + 4, height: glowHeight + 4))
        outerGlow.position = CGPoint(
            x: glowWidth / 2,
            y: CGFloat(row) * blockSize + blockSize / 2
        )
        outerGlow.fillColor = color.withAlphaComponent(GlowStyle.fillAlpha * 0.3)
        outerGlow.strokeColor = .clear
        outerGlow.lineWidth = 0
        outerGlow.zPosition = -1
        
        // Main glow
        let rowGlow = SKShapeNode(rectOf: CGSize(width: glowWidth, height: glowHeight))
        rowGlow.position = CGPoint(
            x: glowWidth / 2,
            y: CGFloat(row) * blockSize + blockSize / 2
        )
        
        // Configure glow appearance with more vibrant colors
        rowGlow.fillColor = color.withAlphaComponent(GlowStyle.fillAlpha)
        rowGlow.strokeColor = color.withAlphaComponent(GlowStyle.strokeAlpha)
        rowGlow.lineWidth = GlowStyle.lineWidth
        rowGlow.zPosition = 0
        
        glowContainer.addChild(outerGlow)
        glowContainer.addChild(rowGlow)
        
        return glowContainer
    }
    
    /// Creates a glow effect for a completed column
    /// - Parameters:
    ///   - column: Column index to highlight
    ///   - rows: Total number of rows in the grid
    ///   - blockSize: Size of each grid cell
    ///   - color: Color for the glow effect
    /// - Returns: SKNode representing the column glow with layered effects
    static func createColumnGlow(column: Int, rows: Int, blockSize: CGFloat, color: SKColor) -> SKNode {
        let glowWidth = blockSize
        let glowHeight = CGFloat(rows) * blockSize
        
        // Create container node for layered glow effect
        let glowContainer = SKNode()
        glowContainer.name = "columnGlow_\(column)"
        glowContainer.zPosition = 5 // Above background but below pieces
        
        // Outer glow (softer, larger)
        let outerGlow = SKShapeNode(rectOf: CGSize(width: glowWidth + 4, height: glowHeight + 4))
        outerGlow.position = CGPoint(
            x: CGFloat(column) * blockSize + blockSize / 2,
            y: glowHeight / 2
        )
        outerGlow.fillColor = color.withAlphaComponent(GlowStyle.fillAlpha * 0.3)
        outerGlow.strokeColor = .clear
        outerGlow.lineWidth = 0
        outerGlow.zPosition = -1
        
        // Main glow
        let columnGlow = SKShapeNode(rectOf: CGSize(width: glowWidth, height: glowHeight))
        columnGlow.position = CGPoint(
            x: CGFloat(column) * blockSize + blockSize / 2,
            y: glowHeight / 2
        )
        
        // Configure glow appearance with more vibrant colors
        columnGlow.fillColor = color.withAlphaComponent(GlowStyle.fillAlpha)
        columnGlow.strokeColor = color.withAlphaComponent(GlowStyle.strokeAlpha)
        columnGlow.lineWidth = GlowStyle.lineWidth
        columnGlow.zPosition = 0
        
        glowContainer.addChild(outerGlow)
        glowContainer.addChild(columnGlow)
        
        return glowContainer
    }
    
    /// Creates an animated pulse effect for glow elements
    /// - Returns: SKAction for the pulse animation
    static func createGlowPulseAnimation() -> SKAction {
        // Alpha pulse
        let pulseIn = SKAction.fadeAlpha(to: GlowStyle.pulseMaxAlpha, duration: GlowStyle.pulseAnimationDuration / 2)
        pulseIn.timingMode = .easeInEaseOut
        
        let pulseOut = SKAction.fadeAlpha(to: GlowStyle.pulseMinAlpha, duration: GlowStyle.pulseAnimationDuration / 2)
        pulseOut.timingMode = .easeInEaseOut
        
        // Subtle scale pulse
        let scaleUp = SKAction.scale(to: 1.02, duration: GlowStyle.pulseAnimationDuration / 2)
        scaleUp.timingMode = .easeInEaseOut
        
        let scaleDown = SKAction.scale(to: 1.0, duration: GlowStyle.pulseAnimationDuration / 2)
        scaleDown.timingMode = .easeInEaseOut
        
        let alphaSequence = SKAction.sequence([pulseIn, pulseOut])
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        
        let combinedPulse = SKAction.group([alphaSequence, scaleSequence])
        return SKAction.repeatForever(combinedPulse)
    }
    
    /// Creates a fade-in animation for glow effects
    /// - Returns: SKAction for fade-in animation
    static func createGlowFadeInAnimation() -> SKAction {
        let fadeIn = SKAction.fadeAlpha(to: GlowStyle.fillAlpha, duration: GlowStyle.fadeInDuration)
        fadeIn.timingMode = .easeOut
        return fadeIn
    }
    
    /// Creates a fade-out animation for glow effects
    /// - Returns: SKAction for fade-out animation
    static func createGlowFadeOutAnimation() -> SKAction {
        let fadeOut = SKAction.fadeOut(withDuration: GlowStyle.fadeOutDuration)
        fadeOut.timingMode = .easeIn
        return SKAction.sequence([fadeOut, SKAction.removeFromParent()])
    }
    
    /// Removes all glow effects from a board node
    /// - Parameter boardNode: The board node to clear glow effects from
    static func clearAllGlowEffects(from boardNode: SKNode) {
        boardNode.children.forEach { child in
            if let name = child.name, 
               (name.hasPrefix("rowGlow_") || name.hasPrefix("columnGlow_")) {
                child.run(createGlowFadeOutAnimation())
            }
        }
    }
    
    // MARK: - Animation Methods
    
    /// Creates a block clearing animation
    /// - Returns: SKAction for animating block removal
    static func createBlockClearingAnimation() -> SKAction {
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.15)
        
        let animationGroup = SKAction.group([fadeOut, scaleDown])
        let sequence = SKAction.sequence([scaleUp, animationGroup])
        
        return sequence
    }
    

}

// MARK: - Extensions

extension GameBoardVisuals {
    /// Convenience method to completely refresh board visuals
    /// - Parameters:
    ///   - boardNode: The board node to refresh
    ///   - columns: Number of columns
    ///   - rows: Number of rows
    ///   - blockSize: Size of each grid cell
    static func refreshBoardVisuals(boardNode: SKNode, columns: Int, rows: Int, blockSize: CGFloat) {
        setupBoardVisuals(columns: columns, rows: rows, blockSize: blockSize, boardNode: boardNode)
    }
}
