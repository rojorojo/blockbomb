import Foundation
import SpriteKit
import SwiftUI

// Update the enum definition to add needed conformance
enum TetrominoShape: CaseIterable {
    case squareSmall, squareBig
    case rectWide, rectTall
    case stick3, stick4, stick5
    case stick3Vert, stick4Vert, stick5Vert
    case lShapeSit, lShapeReversed, lShapeLayingDown, lShapeStand
    case cornerTopLeft, cornerBottomLeft, cornerBottomRight, cornerTopRight
    case tShapeDown, tShapeUp
    case cross, blockSingle
    
    /// Categories for organizing shapes
    enum Category: String, CaseIterable {
        case squares = "Squares"
        case rectangles = "Rectangles"
        case sticks = "Sticks"
        case lShapes = "L Shapes"
        case corners = "Corners"
        case tShapes = "T Shapes"
        case special = "Special"
    }
    
    /// Get the category this shape belongs to
    var category: Category {
        switch self {
        case .squareSmall, .squareBig:
            return .squares
        case .rectWide, .rectTall:
            return .rectangles
        case .stick3, .stick4, .stick5, .stick3Vert, .stick4Vert, .stick5Vert:
            return .sticks
        case .lShapeSit, .lShapeReversed, .lShapeLayingDown, .lShapeStand:
            return .lShapes
        case .cornerTopLeft, .cornerBottomLeft, .cornerBottomRight, .cornerTopRight:
            return .corners
        case .tShapeDown, .tShapeUp:
            return .tShapes
        case .cross, .blockSingle:
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
        case .lShapeSit: return "L Shape"
        case .lShapeReversed: return "Reversed L"
        case .lShapeLayingDown: return "Flat L"
        case .lShapeStand: return "Standing L"
        case .cornerTopLeft: return "Top-Left Corner"
        case .cornerBottomLeft: return "Bottom-Left Corner"
        case .cornerBottomRight: return "Bottom-Right Corner"
        case .cornerTopRight: return "Top-Right Corner"
        case .tShapeDown: return "T Shape Down"
        case .tShapeUp: return "T Shape Up"
        case .cross: return "Cross"
        case .blockSingle: return "Single Block"
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
    
    /// Get a random shape from a specific category
    static func randomShape(from category: Category) -> TetrominoShape {
        let shapes = TetrominoShape.shapes(in: category)
        return shapes.randomElement()!
    }
    
    /// Get a balanced selection of shapes across categories
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
        
        case .lShapeSit:  // L shape
            return [
                GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2),
            ]
        
        case .lShapeStand:  // Standing L shape
            return [
                GridCell(column: 0, row: 0),
                GridCell(column: 0, row: 1),
                GridCell(column: 0, row: 2), GridCell(column: 1, row: 2)
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
    
    
}
