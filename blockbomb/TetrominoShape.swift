import Foundation
import SpriteKit
import SwiftUI

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
    
    /// Rarity levels for pieces - rare pieces are more powerful
    enum Rarity: String, CaseIterable {
        case common = "Common"        // 60% - Basic building blocks
        case uncommon = "Uncommon"    // 25% - Moderately useful
        case rare = "Rare"           // 12% - Powerful but bulky
        case epic = "Epic"           // 1% - Game-changing
        
        /// Weight for weighted random selection
        var weight: Int {
            switch self {
            case .common: return 60
            case .uncommon: return 25
            case .rare: return 12
            case .epic: return 1
            }
        }
    }
    
    /// Selection mode for piece generation
    enum SelectionMode {
        case balanced          // Category-balanced selection (current behavior)
        case weightedRandom    // Pure weighted random selection
        case balancedWeighted  // Rarity-weighted selection (respects 1% Epic frequency)
        case categoryBalanced  // True category-balanced with weighted selection within categories
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
    
    /// Get the rarity of this shape based on power/utility
    var rarity: Rarity {
        switch self {
        // Common (60%) - Basic building blocks, small and simple
        case  .squareSmall, .stick3, .stick3Vert, .squareBig:
            return .common
        case .cornerTopLeft, .cornerBottomLeft:
            return .common
        case .sLeft, .sRight, .sTallLeft, .sTallRight:
            return .common
        case .elbowTopLeft, .elbowBottomLeft, .elbowTopRight, .elbowBottomRight:
            return .common
            
        // Uncommon (25%) - Moderately useful, medium complexity
        case .rectWide, .rectTall, .stick4, .stick4Vert:
            return .uncommon
        case .lShapeSitRight, .lShapeReversed, .cornerTopRight, .cornerBottomRight, 
             .lShapeSitLeft, .lShapeStandLeft:
            return .uncommon
        case .tShapeDown, .tShapeUp, .tShapeTallLeft, .tShapeTallRight:
            return .uncommon
            
        // Rare (12%) - Powerful but bulky, high utility
        case .stick5, .stick5Vert:
            return .rare
        case .lShapeLayingDown, .lShapeStandRight:
            return .rare
            
        // Epic (3%) - Game-changing, very versatile
        case .blockSingle, .cross:
            return .epic
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
    static func selection(count: Int = 3, mode: SelectionMode, gameBoard: GameBoard? = nil) -> [TetrominoShape] {
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
    
    /// Get shapes sorted by size (smallest first) for rescue mode, preferring common pieces
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
}
