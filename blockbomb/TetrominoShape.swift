import Foundation
import SpriteKit

// Update the enum definition to add needed conformance
enum TetrominoShape: String, CaseIterable, Hashable {
    // Square shapes
    case squareSmall  // 2x2 square
    case squareBig    // 3x3 square
    
    // Rectangle shapes
    case rectWide     // 3x2 rectangle (wide)
    case rectTall     // 2x3 rectangle (tall)
    case stick3       // 3-block row
    case stick3Vert   // 3-block column
    case stick4       // 4-block row
    case stick4Vert   // 4-block column
    case stick5       // 5-block row
    case stick5Vert   // 5-block column
    
    // L-shaped pieces
    case lShapeSit    // Standard L shape
    case lShapeReversed    // Reversed L shape
    case lShapeStand   // Standing L shape
    case lShapeLayingDown // L shape laying down on its back

    // T-shaped pieces
    case tShapeDown       // T shape pointing down
    case tShapeUp         // T shape pointing up


    // Small pieces
    case blockSingle  // Single block
    
    
    // Corner shapes
    case cornerTopLeft // Corner with top left
    case cornerTopRight // Corner with top right
    case cornerBottomLeft // Corner with bottom left
    case cornerBottomRight // Corner with bottom right
    
    
    // Special shapes
   
    case cross        // Plus sign shape
    
    // Returns the cells for this shape (no rotation)
    func cells() -> [GridCell] {
        return shapeCells()
    }
    
    // All shape cells (no rotations)
    private func shapeCells() -> [GridCell] {
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
    
    // Define colors for each shape
    var color: SKColor {
        switch self {
        case .cornerTopRight: return SKColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 1.0)  // Blue
        case .cornerTopLeft: return SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)  // Red
        case .squareBig: return .red
        case .rectWide: return .orange
        case .rectTall: return .yellow
        case .lShapeSit: return .green
        case .lShapeStand: return .blue
        case .squareSmall: return .purple
        case .lShapeReversed: return .cyan
        case .lShapeLayingDown: return .magenta
        case .tShapeDown: return SKColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0)  // Purple
        case .tShapeUp: return SKColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)  // Olive
        case .cornerBottomLeft: return SKColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)  // Olive
        case .cornerBottomRight: return SKColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)  // Pink
        case .stick3: return SKColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)  // Teal
        case .stick3Vert: return SKColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)  // Teal
        case .stick4: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)  // Gray
        case .stick4Vert: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)  // Gray
        case .stick5: return SKColor(red: 0.7, green: 0.3, blue: 0.1, alpha: 1.0)  // Brown
        case .stick5Vert: return SKColor(red: 0.7, green: 0.3, blue: 0.1, alpha: 1.0)  // Brown
        case .blockSingle: return SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)  // Light gray
        case .cross: return SKColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 1.0)  // Lime green
        }
    }
    
    // For backward compatibility
    var blockOffsets: [CGPoint] {
        // Convert grid cells to points
        return cells().map { CGPoint(x: CGFloat($0.column), y: CGFloat($0.row)) }
    }
}
