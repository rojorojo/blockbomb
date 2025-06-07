import Foundation
import SpriteKit
import SwiftUI

// Protocol to avoid circular imports with GameController
protocol PostReviveTracker {
    func isInPostReviveMode() -> Bool
    func getPostRevivePiecesRemaining() -> Int
    func onPiecesGenerated()
}

// Update the enum definition to add needed conformance
enum TetrominoShape: CaseIterable {
    case squareSmall, squareBig
    case rectWide, rectTall
    case stick3, stick4, stick5
    case stick3Vert, stick4Vert, stick5Vert
    case lShapeSitRight, lShapeSitLeft, lShapeReversed, lShapeLayingDown, lShapeStandRight, lShapeStandLeft
    case cornerTopLeft, cornerBottomLeft, cornerBottomRight, cornerTopRight
    case elbowTopLeft, elbowBottomLeft, elbowBottomRight, elbowTopRight
    case tShapeDown, tShapeUp, tShapeTallLeft, tShapeTallRight
    case cross, blockSingle
    case sLeft, sRight, sTallLeft, sTallRight
    
    /// Rarity levels for pieces - reflects strategic value and versatility
    enum Rarity: String, CaseIterable {
        case common = "Common"        // 50% - Basic building blocks, frequent use
        case useful = "Useful"        // 30% - Solid utility pieces
        case valuable = "Valuable"    // 15% - High strategic value
        case premium = "Premium"      // 5% - Maximum versatility and game-changing potential
        
        /// Weight for weighted random selection - rebalanced for utility
        var weight: Int {
            switch self {
            case .common: return 50
            case .useful: return 30
            case .valuable: return 15
            case .premium: return 5
            }
        }
    }
    
    /// Selection mode for piece generation
    enum SelectionMode {
        case balanced          // Category-balanced selection (current behavior)
        case weightedRandom    // Pure weighted random selection
        case balancedWeighted  // Rarity-weighted selection (respects 1% Epic frequency)
        case categoryBalanced  // True category-balanced with weighted selection within categories
        case adaptiveBalanced  // Adjusts selection based on board state and capacity
        case strategicWeighted // Considers piece utility relative to current board layout
    }
    
    /// Utility classification for strategic selection
    enum Utility: String, CaseIterable {
        case filler = "Filler"           // Small pieces for tight spaces
        case lineMaker = "Line Maker"    // Good for completing rows/columns
        case spaceFiller = "Space Filler" // Medium pieces for general use
        case bulky = "Bulky"            // Large pieces, harder to place when board is full
        case versatile = "Versatile"     // Single blocks and very flexible pieces
    }
    
    /// Categories for organizing shapes
    enum Category: String, CaseIterable {
        case squares = "Squares"
        case rectangles = "Rectangles"
        case sticks = "Sticks"
        case lShapes = "L Shapes"
        case corners = "Corners"
        case tShapes = "T Shapes"
        case elbows = "Elbows"
        case sShapes = "S Shapes"
        case special = "Special"
    }
    
    /// Get the rarity of this shape based on strategic value and versatility
    var rarity: Rarity {
        switch self {
        // Common (50%) - Basic building blocks with frequent utility
        case .squareSmall, .stick3, .stick3Vert:
            return .common
        case .cornerTopLeft, .cornerBottomLeft, .cornerTopRight, .cornerBottomRight:
            return .common
        case .rectWide, .rectTall:
            return .common
        case .sRight, .sLeft, .sTallLeft, .sTallRight:
            return .common

        // Useful (30%) - Solid strategic value, good utility
        case .stick4, .stick4Vert, .squareBig:
            return .useful
        case .lShapeSitLeft, .lShapeSitRight, .lShapeStandLeft:
            return .useful
        case .tShapeDown, .tShapeUp, .tShapeTallLeft, .tShapeTallRight:
            return .useful
        case .elbowTopLeft, .elbowBottomLeft, .elbowTopRight, .elbowBottomRight:
            return .useful
        
        // Valuable (15%) - High strategic value, line-making potential
        case .stick5, .stick5Vert:
            return .valuable
        case .lShapeReversed, .lShapeLayingDown, .lShapeStandRight:
            return .valuable
            
        // Premium (5%) - Maximum versatility and game-changing potential
        case .blockSingle, .cross:
            return .premium
        }
    }
    
    /// Get the category this shape belongs to
    var category: Category {
        switch self {
        case .squareSmall, .squareBig, .blockSingle:
            return .squares
        case .rectWide, .rectTall:
            return .rectangles
        case .stick3, .stick4, .stick5, .stick3Vert, .stick4Vert, .stick5Vert:
            return .sticks
        case .lShapeSitRight, .lShapeReversed, .lShapeLayingDown, .lShapeStandRight, .lShapeSitLeft, .lShapeStandLeft:
            return .lShapes
        case .cornerTopLeft, .cornerBottomLeft, .cornerBottomRight, .cornerTopRight:
            return .corners
        case .elbowTopLeft, .elbowBottomLeft, .elbowBottomRight, .elbowTopRight:
            return .elbows 
        case .tShapeDown, .tShapeUp, .tShapeTallLeft, .tShapeTallRight:
            return .tShapes
        case .sLeft, .sRight, .sTallLeft, .sTallRight:
            return .sShapes
        case .cross:
            return .special
        
        }
    }

    /// User-friendly name for the shape
    var displayName: String {
        switch self {
        case .squareSmall: return "Small Square"
        case .squareBig: return "Large Square"
        case .rectWide: return "Wide Rectangle"
        case .rectTall: return "Tall Rectangle"
        case .stick3: return "3-Block Stick"
        case .stick4: return "4-Block Stick"
        case .stick5: return "5-Block Stick"
        case .stick3Vert: return "3-Block Vertical Stick"
        case .stick4Vert: return "4-Block Vertical Stick"
        case .stick5Vert: return "5-Block Vertical Stick"
        case .lShapeSitRight: return "L Shape"
        case .lShapeReversed: return "Reversed L"
        case .lShapeLayingDown: return "Flat L"
        case .lShapeStandRight: return "Standing L"
        case .lShapeSitLeft: return "L Shape Left"
        case .lShapeStandLeft: return "Standing L Left"
        case .cornerTopLeft: return "Top-Left Corner"
        case .cornerBottomLeft: return "Bottom-Left Corner"
        case .cornerBottomRight: return "Bottom-Right Corner"
        case .cornerTopRight: return "Top-Right Corner"
        case .tShapeDown: return "T Shape Down"
        case .tShapeUp: return "T Shape Up"
        case .tShapeTallLeft: return "T Shape Tall Left"
        case .tShapeTallRight: return "T Shape Tall Right"
        case .cross: return "Cross"
        case .blockSingle: return "Single Block"
        case .elbowTopLeft: return "Elbow Top-Left Corner"
        case .elbowBottomLeft: return "Elbow Bottom-Left Corner"
        case .elbowBottomRight: return "Elbow Bottom-Right Corner"
        case .elbowTopRight: return "Elbow Top-Right Corner"
        case .sLeft: return "S Shape Left"
        case .sRight: return "S Shape Right"
        case .sTallLeft: return "S Shape Tall Left"
        case .sTallRight: return "S Shape Tall Right"
        }
    }
    
    /// Default color for the shape (using BlockColors)
    var uiColor: Color {
        switch self.category {
        case .squares:
            return BlockColors.red
        case .rectangles:
            return BlockColors.blue
        case .sticks:
            return BlockColors.teal
        case .lShapes:
            return BlockColors.orange
        case .corners:
            return BlockColors.green
        case .tShapes:
            return BlockColors.purple
        case .special:
            return BlockColors.yellow
        case .elbows:
            return BlockColors.fuchsia
        case .sShapes:
            return BlockColors.pink
        }
    }

     /// SpriteKit color for the shape
    var color: SKColor {
        return SKColor(uiColor)
    }
    
    /// Get a random color from BlockColors
    static var randomColor: Color {
        return BlockColors.randomBlockColor()
    }
    
    /// Get all shapes in a specific category
    static func shapes(in category: Category) -> [TetrominoShape] {
        return TetrominoShape.allCases.filter { $0.category == category }
    }
    
    /// Get all shapes of a specific rarity
    static func shapes(with rarity: Rarity) -> [TetrominoShape] {
        return TetrominoShape.allCases.filter { $0.rarity == rarity }
    }
    
    /// Get all shapes of a specific utility type
    static func shapes(with utility: Utility) -> [TetrominoShape] {
        return TetrominoShape.allCases.filter { $0.utility == utility }
    }
    
    /// Get a weighted random shape based on rarity
    static func weightedRandomShape() -> TetrominoShape {
        let totalWeight = Rarity.allCases.reduce(0) { $0 + $1.weight }
        let randomValue = Int.random(in: 1...totalWeight)
        
        var currentWeight = 0
        for rarity in Rarity.allCases {
            currentWeight += rarity.weight
            if randomValue <= currentWeight {
                let shapesInRarity = shapes(with: rarity)
                return shapesInRarity.randomElement()!
            }
        }
        
        // Fallback (should never reach here)
        return allCases.randomElement()!
    }
    
    /// Get a weighted random selection of shapes
    static func weightedRandomSelection(count: Int = 3) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        var attempts = 0
        let maxAttempts = count * 10 // Prevent infinite loops
        
        while selectedShapes.count < count && attempts < maxAttempts {
            let shape = weightedRandomShape()
            if !selectedShapes.contains(shape) {
                selectedShapes.append(shape)
            }
            attempts += 1
        }
        
        // If we couldn't get enough unique shapes with weighted selection,
        // fill remaining slots with random shapes
        if selectedShapes.count < count {
            let remainingShapes = allCases.filter { !selectedShapes.contains($0) }.shuffled()
            selectedShapes.append(contentsOf: remainingShapes.prefix(count - selectedShapes.count))
        }
        
        return selectedShapes
    }
    
    /// Get a category-balanced selection with weighted selection within categories
    static func balancedWeightedSelection(count: Int = 3) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        
        // First, use rarity-based selection to ensure proper Epic frequency
        for _ in 0..<count {
            let shape = weightedRandomShape()
            if !selectedShapes.contains(shape) {
                selectedShapes.append(shape)
            }
        }
        
        // If we need more shapes due to duplicates, fill with weighted random selection
        if selectedShapes.count < count {
            var attempts = 0
            let maxAttempts = count * 10
            
            while selectedShapes.count < count && attempts < maxAttempts {
                let shape = weightedRandomShape()
                if !selectedShapes.contains(shape) {
                    selectedShapes.append(shape)
                }
                attempts += 1
            }
        }
        
        // Final fallback if still not enough shapes
        if selectedShapes.count < count {
            let remainingShapes = allCases.filter { !selectedShapes.contains($0) }.shuffled()
            selectedShapes.append(contentsOf: remainingShapes.prefix(count - selectedShapes.count))
        }
        
        return selectedShapes
    }
    
    /// Get a true category-balanced selection with weighted selection within categories
    static func categoryBalancedSelection(count: Int = 3) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        
        // Try to select one shape from each category using weighted selection
        for category in Category.allCases.shuffled() {
            if selectedShapes.count >= count { break }
            
            let shapesInCategory = shapes(in: category)
            if let shape = weightedRandomShapeFromArray(shapesInCategory), 
               !selectedShapes.contains(shape) {
                selectedShapes.append(shape)
            }
        }
        
        // If we need more shapes, fill with weighted random selection
        if selectedShapes.count < count {
            var attempts = 0
            let maxAttempts = count * 10
            
            while selectedShapes.count < count && attempts < maxAttempts {
                let shape = weightedRandomShape()
                if !selectedShapes.contains(shape) {
                    selectedShapes.append(shape)
                }
                attempts += 1
            }
        }
        
        return selectedShapes
    }
    
    /// Helper method to get a weighted random shape from a specific array of shapes
    private static func weightedRandomShapeFromArray(_ shapes: [TetrominoShape]) -> TetrominoShape? {
        guard !shapes.isEmpty else { return nil }
        
        let totalWeight = shapes.reduce(0) { $0 + $1.rarity.weight }
        let randomValue = Int.random(in: 1...totalWeight)
        
        var currentWeight = 0
        for shape in shapes {
            currentWeight += shape.rarity.weight
            if randomValue <= currentWeight {
                return shape
            }
        }
        
        return shapes.randomElement()
    }
    
    /// Get a selection of shapes based on the specified mode and board state
    static func selection(count: Int = 3, mode: SelectionMode, gameBoard: GameBoard? = nil, gameController: PostReviveTracker? = nil) -> [TetrominoShape] {
        // Check if we should use post-revive priority mode
        if let controller = gameController, controller.isInPostReviveMode(), let board = gameBoard {
            print("TetrominoShape: Using post-revive priority selection (pieces remaining: \(controller.getPostRevivePiecesRemaining()))")
            return postRevivePrioritySelection(count: count, gameBoard: board)
        }
        
        // Check if we should use rescue mode
        if let board = gameBoard, board.isInRescueMode() {
            return rescueModeSelection(count: count, gameBoard: board)
        }
        
        // Normal selection based on mode
        switch mode {
        case .balanced:
            return balancedSelection(count: count)
        case .weightedRandom:
            return weightedRandomSelection(count: count)
        case .balancedWeighted:
            return balancedWeightedSelection(count: count)
        case .categoryBalanced:
            return categoryBalancedSelection(count: count)
        case .adaptiveBalanced:
            return adaptiveBalancedSelection(count: count, gameBoard: gameBoard!)
        case .strategicWeighted:
            return strategicWeightedSelection(count: count, gameBoard: gameBoard!)
        }
    }

    /// Get a random shape from a specific category
    static func randomShape(from category: Category) -> TetrominoShape {
        let shapes = TetrominoShape.shapes(in: category)
        return shapes.randomElement()!
    }
    
    /// Get a balanced selection of shapes across categories (existing method - preserved for compatibility)
    static func balancedSelection(count: Int = 3) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        
        // Try to select one shape from each category (shuffled for variety)
        for category in Category.allCases.shuffled() {
            if selectedShapes.count >= count { break }
            
            if let shape = shapes(in: category).shuffled().first,
               !selectedShapes.contains(shape) {
                selectedShapes.append(shape)
            }
        }
        
        // If we need more shapes, fill with random ones
        if selectedShapes.count < count {
            let remainingShapes = allCases.filter { !selectedShapes.contains($0) }.shuffled()
            selectedShapes.append(contentsOf: remainingShapes.prefix(count - selectedShapes.count))
        }
        
        return selectedShapes
    }

    /// Get the grid cells that make up this shape
    var cells: [GridCell] {
        switch self {
        case .sRight:  // S shape left
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
            ]
        case .sLeft:  // S shape right
            return [
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1),
                GridCell(column: 1, row: 0), GridCell(column: 2, row: 0)
            ]

        case .sTallLeft:  // Tall S shape left
            return [
                GridCell(column: 1, row: 0), GridCell(column: 0, row: 1),
                GridCell(column: 1, row: 1), GridCell(column: 0, row: 2)
            ]
        case .sTallRight:  // Tall S shape right
            return [
                GridCell(column: 0, row: 0), GridCell(column: 0, row: 1),
                GridCell(column: 1, row: 1), GridCell(column: 1, row: 2)
            ]

        case .elbowTopLeft:  // Elbow top left corner
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2), GridCell(column: 1, row: 2), GridCell(column: 2, row: 2)
            ]
        case .elbowBottomLeft:  // Elbow bottom left corner
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2)
            ]

        case .elbowBottomRight:  // Elbow bottom right corner
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                GridCell(column: 2, row: 1),
                GridCell(column: 2, row: 2)
            ]
        case .elbowTopRight:  // Elbow top right corner
            return [
                GridCell(column: 0, row: 2), GridCell(column: 1, row: 2), GridCell(column: 2, row: 2),
                GridCell(column: 2, row: 1),
                GridCell(column: 2, row: 0)
            ]


        case .cornerTopLeft:  // Corner top left
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1)
                
            ]

        case .cornerBottomLeft:  // Corner bottom left
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 0, row: 1)
            ]
            
        case .cornerBottomRight:  // Corner bottom right
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 1, row: 1)
            ]

        case .cornerTopRight:  // Corner top right
            return [
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1),
                GridCell(column: 1, row: 0),
            ]

        

        case .squareBig:  // 3x3 square
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1),
                GridCell(column: 0, row: 2), GridCell(column: 1, row: 2), GridCell(column: 2, row: 2)
            ]
        
        case .rectWide:  // 3x2 rectangle (wide)
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
            ]
        
        case .rectTall:  // 2x3 rectangle (tall)
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1),
                GridCell(column: 0, row: 2), GridCell(column: 1, row: 2)
            ]
        
        case .lShapeSitRight:  // L shape
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2),
            ]
        case .lShapeSitLeft:  // L shape left
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 1, row: 1),
                GridCell(column: 1, row: 2),
            ]
        
        case .lShapeStandRight:  // Standing L shape
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2), GridCell(column: 1, row: 2)
            ]
        case .lShapeStandLeft:  // Standing L shape left
            return [
                GridCell(column: 1, row: 0),
                GridCell(column: 1, row: 1),
                GridCell(column: 1, row: 2), GridCell(column: 0, row: 2)
            ]
        
        case .squareSmall:  // 2x2 square
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1)
            ]
        
        case .lShapeReversed:  // Reversed L shape
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
            ]
            
        case .lShapeLayingDown:  // Corner with top left
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0)
            ]
            
        case .tShapeDown:  // T shape
            return [
                GridCell(column: 1, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
            ]
            
        case .tShapeUp:  // T shape
            return [
                GridCell(column: 0, row: 0),GridCell(column: 1, row: 0),GridCell(column: 2, row: 0),
                GridCell(column: 1, row: 1),
            ]

        case .tShapeTallLeft:  // T shape tall left
            return [
                GridCell(column: 1, row: 0), GridCell(column: 0, row: 1),
                GridCell(column: 1, row: 2), GridCell(column: 1, row: 1)
            ]

        case .tShapeTallRight:  // T shape tall right
            return [
                GridCell(column: 0, row: 0), GridCell(column: 0, row: 1),
                GridCell(column: 1, row: 1), GridCell(column: 0, row: 2)
            ]
            
        case .stick3:  // 3-block horizontal row
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0)
            ]
            
        case .stick3Vert:  // 3-block vertical column
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2)
            ]
            
        case .stick4:  // 4-block horizontal row
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 2, row: 0), GridCell(column: 3, row: 0)
            ]
            
        case .stick4Vert:  // 4-block vertical column
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2),
                GridCell(column: 0, row: 3)
            ]
            
        case .stick5:  // 5-block horizontal row
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                GridCell(column: 3, row: 0), GridCell(column: 4, row: 0)
            ]
            
        case .stick5Vert:  // 5-block vertical column
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2),
                GridCell(column: 0, row: 3),
                GridCell(column: 0, row: 4)
            ]
            
        case .blockSingle:  // Single block
            return [
                GridCell(column: 0, row: 0)
            ]
            
        case .cross:  // Plus shape
            return [
                GridCell(column: 1, row: 0),
                GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1),
                GridCell(column: 1, row: 2)
            ]
        }

    }
    
    // Replace the duplicate shapeCategories with a property that uses the Category enum
    static var shapeCategories: [[TetrominoShape]] {
        return Category.allCases.map { category in
            shapes(in: category)
        }
    }
    
    /// Get shapes sorted by size (smaller first) for rescue mode, preferring common pieces
    static func shapesBySize() -> [TetrominoShape] {
        return allCases.sorted { shape1, shape2 in
            // First priority: size (smaller pieces first)
            if shape1.cells.count != shape2.cells.count {
                return shape1.cells.count < shape2.cells.count
            }
            
            // Second priority: prefer common rarity over epic when same size
            if shape1.rarity != shape2.rarity {
                return shape1.rarity.weight > shape2.rarity.weight
            }
            
            // Fallback: maintain consistent ordering
            return false
        }
    }
    
    /// Get a rescue mode selection ensuring at least one piece can be placed
    static func rescueModeSelection(count: Int = 3, gameBoard: GameBoard) -> [TetrominoShape] {
        // First, try normal weighted selection and filter for placeable pieces
        let normalSelection = balancedWeightedSelection(count: count)
        var placeableShapes: [TetrominoShape] = []
        
        // Check which pieces from normal selection can be placed
        for shape in normalSelection {
            let gridPiece = GridPiece(shape: shape, color: shape.color)
            if gameBoard.canPlacePieceAnywhere(gridPiece) {
                placeableShapes.append(shape)
            }
        }
        
        // If we have at least one placeable piece, use the normal selection
        if !placeableShapes.isEmpty {
            return normalSelection
        }
        
        // Otherwise, fallback to progressively smaller pieces
        let shapesBySize = shapesBySize()
        var rescueSelection: [TetrominoShape] = []
        
        // Try to find placeable pieces starting with smallest
        for shape in shapesBySize {
            let gridPiece = GridPiece(shape: shape, color: shape.color)
            if gameBoard.canPlacePieceAnywhere(gridPiece) && !rescueSelection.contains(shape) {
                rescueSelection.append(shape)
                if rescueSelection.count >= count {
                    break
                }
            }
        }
        
        // If still no placeable pieces, return smallest available pieces (fallback)
        if rescueSelection.isEmpty {
            return Array(shapesBySize.prefix(count))
        }
        
        // Fill remaining slots with small pieces if needed
        if rescueSelection.count < count {
            for shape in shapesBySize {
                if !rescueSelection.contains(shape) {
                    rescueSelection.append(shape)
                    if rescueSelection.count >= count {
                        break
                    }
                }
            }
        }
        
        return rescueSelection
    }
    
    /// Get a post-revive priority selection that ensures ALL pieces are placeable
    /// This method guarantees players get 3 fully placeable pieces in the 4 rounds after revival
    static func postRevivePrioritySelection(count: Int = 3, gameBoard: GameBoard) -> [TetrominoShape] {
        print("TetrominoShape: Generating post-revive priority selection (all \(count) pieces must be placeable)")
        
        var prioritySelection: [TetrominoShape] = []
        var attempts = 0
        let maxAttempts = 50
        
        // Define priority order: most placeable pieces first
        let candidatePieces = [
            // Premium versatile pieces (almost always placeable)
            shapes(with: .premium).filter { $0.utility == .versatile },
            // Common filler pieces (small and flexible)
            shapes(with: .common).filter { $0.utility == .filler },
            // Useful line makers (medium priority)
            shapes(with: .useful).filter { $0.utility == .lineMaker },
            // Other useful pieces
            shapes(with: .useful).filter { $0.utility == .spaceFiller },
            // Fallback to any common pieces
            shapes(with: .common)
        ].flatMap { $0 }
        
        // Sort candidates by size (smaller pieces first for better placement odds)
        let sortedCandidates = candidatePieces.sorted { shape1, shape2 in
            if shape1.cells.count != shape2.cells.count {
                return shape1.cells.count < shape2.cells.count
            }
            // If same size, prefer versatile > filler > lineMaker > spaceFiller > bulky
            let utilityOrder: [Utility] = [.versatile, .filler, .lineMaker, .spaceFiller, .bulky]
            let index1 = utilityOrder.firstIndex(of: shape1.utility) ?? utilityOrder.count
            let index2 = utilityOrder.firstIndex(of: shape2.utility) ?? utilityOrder.count
            return index1 < index2
        }
        
        // Aggressively search for 3 guaranteed placeable pieces
        while prioritySelection.count < count && attempts < maxAttempts {
            attempts += 1
            
            for candidate in sortedCandidates {
                if prioritySelection.contains(candidate) {
                    continue
                }
                
                let gridPiece = GridPiece(shape: candidate, color: candidate.color)
                if gameBoard.canPlacePieceAnywhere(gridPiece) {
                    prioritySelection.append(candidate)
                    print("TetrominoShape: Post-revive added placeable piece \(prioritySelection.count)/\(count): \(candidate.displayName) (\(candidate.cells.count) cells, \(candidate.utility.rawValue))")
                    
                    if prioritySelection.count >= count {
                        break
                    }
                }
            }
            
            // If we still don't have enough pieces, this means the board is extremely constrained
            if prioritySelection.count < count {
                print("TetrominoShape: Post-revive attempt \(attempts): Only found \(prioritySelection.count)/\(count) placeable pieces")
                
                // Try adding from rescue mode as last resort, but verify placeability
                let rescueShapes = rescueModeSelection(count: count - prioritySelection.count, gameBoard: gameBoard)
                for rescueShape in rescueShapes {
                    if prioritySelection.contains(rescueShape) {
                        continue
                    }
                    
                    let gridPiece = GridPiece(shape: rescueShape, color: rescueShape.color)
                    if gameBoard.canPlacePieceAnywhere(gridPiece) {
                        prioritySelection.append(rescueShape)
                        print("TetrominoShape: Post-revive added rescue piece \(prioritySelection.count)/\(count): \(rescueShape.displayName)")
                        
                        if prioritySelection.count >= count {
                            break
                        }
                    }
                }
            }
        }
        
        // Final validation: ensure all selected pieces are actually placeable
        let finalSelection = prioritySelection.filter { shape in
            let gridPiece = GridPiece(shape: shape, color: shape.color)
            return gameBoard.canPlacePieceAnywhere(gridPiece)
        }
        
        if finalSelection.count < count {
            print("TetrominoShape: WARNING - Post-revive could only guarantee \(finalSelection.count)/\(count) placeable pieces after \(attempts) attempts")
            print("TetrominoShape: This indicates an extremely constrained board state")
            
            // If we still can't get enough placeable pieces, pad with smallest available pieces
            let allShapes = TetrominoShape.allCases.sorted { $0.cells.count < $1.cells.count }
            var paddedSelection = finalSelection
            
            for shape in allShapes {
                if paddedSelection.count >= count {
                    break
                }
                if !paddedSelection.contains(shape) {
                    paddedSelection.append(shape)
                }
            }
            
            return Array(paddedSelection.prefix(count))
        }
        
        print("TetrominoShape: Post-revive SUCCESS - All \(finalSelection.count) pieces guaranteed placeable: \(finalSelection.map { $0.displayName })")
        return Array(finalSelection.prefix(count))
    }
    
    // MARK: - Debug and Statistics
    
    /// Track selection statistics for debugging
    private static var selectionStats: [TetrominoShape: Int] = [:]
    
    /// Log a shape selection for debugging purposes
    static func logSelection(_ shapes: [TetrominoShape]) {
        for shape in shapes {
            selectionStats[shape, default: 0] += 1
        }
    }
    
    /// Get current selection statistics
    static func getSelectionStats() -> [String: Any] {
        let totalSelections = selectionStats.values.reduce(0, +)
        guard totalSelections > 0 else { return [:] }
        
        var rarityStats: [Rarity: Int] = [:]
        var shapeStats: [String: Double] = [:]
        
        for (shape, count) in selectionStats {
            rarityStats[shape.rarity, default: 0] += count
            shapeStats[shape.displayName] = Double(count) / Double(totalSelections) * 100
        }
        
        var rarityPercentages: [String: Double] = [:]
        for (rarity, count) in rarityStats {
            rarityPercentages[rarity.rawValue] = Double(count) / Double(totalSelections) * 100
        }
        
        return [
            "totalSelections": totalSelections,
            "rarityPercentages": rarityPercentages,
            "shapePercentages": shapeStats
        ]
    }
    
    /// Reset selection statistics
    static func resetSelectionStats() {
        selectionStats.removeAll()
    }
    
    /// Get the utility classification for strategic selection
    var utility: Utility {
        switch self {
        // Versatile - Single blocks and highly flexible pieces
        case .blockSingle:
            return .versatile
        case .cross:
            return .versatile
            
        // Filler - Small pieces for tight spaces
        case .squareSmall, .stick3, .stick3Vert:
            return .filler
        case .cornerTopLeft, .cornerBottomLeft, .cornerTopRight, .cornerBottomRight:
            return .filler
            
        // Line Maker - Good for completing rows/columns
        case .stick4, .stick5, .stick4Vert, .stick5Vert:
            return .lineMaker
        case .rectWide, .rectTall:
            return .lineMaker
            
        // Space Filler - Medium pieces for general use
        case .lShapeSitRight, .lShapeSitLeft, .lShapeStandLeft:
            return .spaceFiller
        case .tShapeDown, .tShapeUp, .tShapeTallLeft, .tShapeTallRight:
            return .spaceFiller
        case .sLeft, .sRight, .sTallLeft, .sTallRight:
            return .spaceFiller
        case .elbowTopLeft, .elbowBottomLeft, .elbowTopRight, .elbowBottomRight:
            return .spaceFiller
            
        // Bulky - Large pieces, harder to place when board is full
        case .squareBig:
            return .bulky
        case .lShapeReversed, .lShapeLayingDown, .lShapeStandRight:
            return .bulky
        }
    }
    
    // MARK: - Adaptive and Strategic Selection Methods
    
    /// Adaptive balanced selection that adjusts based on board state
    static func adaptiveBalancedSelection(count: Int = 3, gameBoard: GameBoard) -> [TetrominoShape] {
        let difficultyLevel = gameBoard.getDifficultyLevel()
        let lineAnalysis = gameBoard.getLineCompletionOpportunities()
        let spaceAnalysis = gameBoard.getSpacePatternAnalysis()
        
        var selectedShapes: [TetrominoShape] = []
        
        // Adjust selection strategy based on difficulty level
        switch difficultyLevel {
        case .comfortable:
            // Normal category balanced selection with slight bias toward line makers
            return categoryBalancedWithBias(count: count, preferredUtility: .lineMaker, biasStrength: 0.2)
            
        case .moderate:
            // Start favoring smaller pieces and line makers
            return utilityBiasedSelection(count: count, utilities: [.filler: 0.5, .lineMaker: 0.3, .spaceFiller: 0.2])
            
        case .challenging:
            // Use weighted hybrid approach that considers both clearing and fragmentation
            return hybridWeightedSelection(count: count, lineAnalysis: lineAnalysis, spaceAnalysis: spaceAnalysis, gameBoard: gameBoard)
            
        case .difficult:
            // Heavy bias toward small, versatile pieces
            return utilityBiasedSelection(count: count, utilities: [.filler: 0.5, .versatile: 0.4, .lineMaker: 0.1])
            
        case .critical:
            // Emergency mode - guarantee at least one very small piece
            var selection = utilityBiasedSelection(count: count - 1, utilities: [.filler: 0.6, .versatile: 0.4])
            // Always include a single block or smallest piece available
            let emergencyPieces = shapes(with: .premium).filter { $0.cells.count == 1 }
            if let singleBlock = emergencyPieces.first, !selection.contains(singleBlock) {
                selection.append(singleBlock)
            } else {
                // Fallback to smallest available piece
                let smallestPieces = shapesBySize().prefix(3)
                for piece in smallestPieces {
                    if !selection.contains(piece) {
                        selection.append(piece)
                        break
                    }
                }
            }
            return selection
        }
    }
    
    /// Strategic weighted selection that considers board layout and clearing opportunities
    static func strategicWeightedSelection(count: Int = 3, gameBoard: GameBoard) -> [TetrominoShape] {
        let lineAnalysis = gameBoard.getLineCompletionOpportunities()
        let spaceAnalysis = gameBoard.getSpacePatternAnalysis()
        
        // Use weighted hybrid approach for all strategic selections
        return hybridWeightedSelection(count: count, lineAnalysis: lineAnalysis, spaceAnalysis: spaceAnalysis, gameBoard: gameBoard)
    }
    
    // MARK: - Helper Selection Methods
    
    /// Select pieces based on utility distribution
    static func utilityBiasedSelection(count: Int = 3, utilities: [Utility: Float]) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        var attempts = 0
        let maxAttempts = count * 15
        
        while selectedShapes.count < count && attempts < maxAttempts {
            // Select utility based on distribution
            let randomValue = Float.random(in: 0...1)
            var cumulativeWeight: Float = 0
            var selectedUtility: Utility = .spaceFiller
            
            for (utility, weight) in utilities {
                cumulativeWeight += weight
                if randomValue <= cumulativeWeight {
                    selectedUtility = utility
                    break
                }
            }
            
            // Get shapes with the selected utility
            let shapesWithUtility = allCases.filter { $0.utility == selectedUtility }
            if let shape = weightedRandomShapeFromArray(shapesWithUtility), !selectedShapes.contains(shape) {
                selectedShapes.append(shape)
            }
            
            attempts += 1
        }
        
        // Fill remaining slots with any available shapes
        if selectedShapes.count < count {
            let remainingShapes = allCases.filter { !selectedShapes.contains($0) }.shuffled()
            selectedShapes.append(contentsOf: remainingShapes.prefix(count - selectedShapes.count))
        }
        
        return selectedShapes
    }
    
    /// Category balanced selection with utility bias
    static func categoryBalancedWithBias(count: Int = 3, preferredUtility: Utility, biasStrength: Float) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        
        for category in Category.allCases.shuffled() {
            if selectedShapes.count >= count { break }
            
            let shapesInCategory = shapes(in: category)
            let preferredShapes = shapesInCategory.filter { $0.utility == preferredUtility }
            
            // Apply bias toward preferred utility
            let usePreferred = Float.random(in: 0...1) < biasStrength && !preferredShapes.isEmpty
            let candidateShapes = usePreferred ? preferredShapes : shapesInCategory
            
            if let shape = weightedRandomShapeFromArray(candidateShapes), !selectedShapes.contains(shape) {
                selectedShapes.append(shape)
            }
        }
        
        // Fill remaining slots
        if selectedShapes.count < count {
            let remainingShapes = allCases.filter { !selectedShapes.contains($0) }
            let preferredRemaining = remainingShapes.filter { $0.utility == preferredUtility }
            let candidates = !preferredRemaining.isEmpty ? preferredRemaining : remainingShapes
            
            selectedShapes.append(contentsOf: candidates.shuffled().prefix(count - selectedShapes.count))
        }
        
        return selectedShapes
    }
    
    /// Selection optimized for triggering line clearing opportunities
    static func clearingOpportunitySelection(count: Int = 3, lineAnalysis: LineCompletionAnalysis, gameBoard: GameBoard) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        
        // Prioritize single blocks for single-gap rows/columns
        if lineAnalysis.singleGapRows + lineAnalysis.singleGapColumns > 0 {
            let singleBlocks = shapes(with: .premium).filter { $0.cells.count == 1 }
            if let singleBlock = singleBlocks.first {
                selectedShapes.append(singleBlock)
            }
        }
        
        // Add line-making pieces for near-completion opportunities
        if lineAnalysis.totalNearCompletionLines >= 2 {
            let lineMakers = allCases.filter { $0.utility == .lineMaker && !selectedShapes.contains($0) }
            if let lineMaker = weightedRandomShapeFromArray(lineMakers) {
                selectedShapes.append(lineMaker)
            }
        }
        
        // Fill remaining slots with strategic pieces
        while selectedShapes.count < count {
            let remainingShapes = allCases.filter { !selectedShapes.contains($0) }
            let strategicShapes = remainingShapes.filter { shape in
                shape.utility == .filler || shape.utility == .versatile || shape.utility == .lineMaker
            }
            
            let candidates = !strategicShapes.isEmpty ? strategicShapes : remainingShapes
            if let shape = weightedRandomShapeFromArray(candidates) {
                selectedShapes.append(shape)
            } else {
                break
            }
        }
        
        return selectedShapes
    }
    
    /// Hybrid weighted selection that handles both clearing opportunities and fragmentation
    static func hybridWeightedSelection(count: Int = 3, lineAnalysis: LineCompletionAnalysis, spaceAnalysis: SpacePatternAnalysis, gameBoard: GameBoard) -> [TetrominoShape] {
        var selectedShapes: [TetrominoShape] = []
        
        // Get strategic placement analysis for 4+ cell gaps
        let strategicAnalysis = gameBoard.getStrategicPlacementAnalysis()
        
        // Calculate clearing opportunity weight (0.0 to 1.0)
        let clearingWeight = calculateClearingWeight(from: lineAnalysis)
        
        // Calculate fragmentation weight (0.0 to 1.0) 
        let fragmentationWeight = calculateFragmentationWeight(from: spaceAnalysis)
        
        // Calculate strategic placement weight (0.0 to 1.0)
        let strategicWeight = calculateStrategicPlacementWeight(from: strategicAnalysis)
        
        // Determine selection strategy based on combined weights (adjusted to include strategic weight)
        let clearingBias = clearingWeight * 0.5  // Clearing gets 50% influence
        let fragmentationBias = fragmentationWeight * 0.3  // Fragmentation gets 30% influence
        let strategicBias = strategicWeight * 0.2  // Strategic placement gets 20% influence
        
        // Create utility distribution based on board state
        var utilityWeights: [Utility: Float] = [:]
        
        if clearingBias > 0.5 {
            // Strong clearing opportunities - prioritize line makers and versatile pieces
            utilityWeights = [
                .lineMaker: 0.4 + clearingBias * 0.2,
                .versatile: 0.3 + clearingBias * 0.1,
                .filler: 0.2,
                .spaceFiller: 0.1,
                .bulky: 0.0
            ]
        } else if fragmentationBias > 0.5 {
            // High fragmentation - prioritize small, flexible pieces
            utilityWeights = [
                .filler: 0.4 + fragmentationBias * 0.2,
                .versatile: 0.3 + fragmentationBias * 0.1,
                .spaceFiller: 0.2,
                .lineMaker: 0.1,
                .bulky: 0.0
            ]
        } else if strategicBias > 0.3 {
            // Strong strategic opportunities - prioritize space fillers and versatile pieces
            utilityWeights = [
                .spaceFiller: 0.4 + strategicBias * 0.2,
                .versatile: 0.25 + strategicBias * 0.1,
                .lineMaker: 0.2,
                .filler: 0.15,
                .bulky: 0.0
            ]
        } else {
            // Balanced approach - moderate weights for mixed situations
            utilityWeights = [
                .spaceFiller: 0.3,
                .filler: 0.25,
                .lineMaker: 0.25,
                .versatile: 0.15,
                .bulky: 0.05
            ]
        }
        
        // Normalize weights to ensure they sum to 1.0
        let totalWeight = utilityWeights.values.reduce(0, +)
        for utility in utilityWeights.keys {
            utilityWeights[utility]! /= totalWeight
        }
        
        // Select pieces based on calculated utility distribution
        return utilityBiasedSelection(count: count, utilities: utilityWeights)
    }
    
    /// Calculate clearing opportunity weight based on line analysis
    private static func calculateClearingWeight(from lineAnalysis: LineCompletionAnalysis) -> Float {
        let maxPossibleOpportunities: Float = 20.0 // Reasonable maximum for normalization
        
        let singleGapWeight = Float(lineAnalysis.singleGapRows + lineAnalysis.singleGapColumns) * 0.4
        let nearCompletionWeight = Float(lineAnalysis.totalNearCompletionLines) * 0.3
        let potentialClearWeight = Float(lineAnalysis.potentialMultiLineClear) * 0.3
        
        let totalWeight = singleGapWeight + nearCompletionWeight + potentialClearWeight
        return min(totalWeight / maxPossibleOpportunities, 1.0)
    }
    
    /// Calculate fragmentation weight based on space analysis
    private static func calculateFragmentationWeight(from spaceAnalysis: SpacePatternAnalysis) -> Float {
        let maxFragmentation: Float = 100.0 // Reasonable maximum for normalization
        
        let isolatedSpacesWeight = Float(spaceAnalysis.isolatedSpaces) * 0.4
        let smallClustersWeight = Float(spaceAnalysis.smallClusters) * 0.3
        let fragmentationScoreWeight = spaceAnalysis.fragmentationScore * 0.3
        
        let totalWeight = isolatedSpacesWeight + smallClustersWeight + fragmentationScoreWeight
        return min(totalWeight / maxFragmentation, 1.0)
    }
    
    /// Calculate strategic placement weight based on strategic analysis
    private static func calculateStrategicPlacementWeight(from strategicAnalysis: StrategicPlacementAnalysis) -> Float {
        let maxStrategicOpportunities: Float = 15.0 // Reasonable maximum for normalization
        
        let largeGapsWeight = Float(strategicAnalysis.totalLargeGaps) * 0.4
        let placementOpportunitiesWeight = Float(strategicAnalysis.optimalPlacements.count) * 0.4
        let averageGapSizeWeight = strategicAnalysis.averageGapSize * 0.2
        
        let totalWeight = largeGapsWeight + placementOpportunitiesWeight + averageGapSizeWeight
        return min(totalWeight / maxStrategicOpportunities, 1.0)
    }
}
