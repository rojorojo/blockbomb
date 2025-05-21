import Foundation
import SpriteKit

enum TetrominoShape: CaseIterable {
    // Square shapes
    case squareSmall  // 2x2 square
    case squareBig    // 3x3 square
    
    // Rectangle shapes
    case rectWide     // 3x2 rectangle (wide)
    case rectTall     // 2x3 rectangle (tall)
    case stick3       // 3-block row/column
    case stick4       // 4-block row/column
    case stick5       // 5-block row/column
    
    // L-shaped pieces
    case lShapeSit    // Standard L shape
    case lShapeReversed    // Reversed L shape
    
    // T-shaped pieces
    case tShape       // T shape
    
    // Small pieces
    case blockSingle  // Single block
    case blockDouble  // 2 blocks
    
    // Corner shapes
    case cornerSmall  // L shape with 2 blocks on each side
    case cornerWide   // Corner with extension
    
    // Special shapes
    case zigzag       // Z shape
    case cross        // Plus sign shape
    
    // Returns the cells for a specific rotation of this shape
    func relativeCells(rotation: Int) -> [GridCell] {
        let rotations = cellRotations()
        let index = rotation % rotations.count
        return rotations[index]
    }
    
    // Returns the number of possible rotations for this shape
    var rotationCount: Int {
        return cellRotations().count
    }
    
    // Determines which rotation index the current cells represent
    func rotationIndexFor(cells: [GridCell]) -> Int {
        let rotations = cellRotations()
        for (index, rotation) in rotations.enumerated() {
            if rotation == cells {
                return index
            }
        }
        return 0 // Default to first rotation if not found
    }
    
    // All possible rotations of this shape
    private func cellRotations() -> [[GridCell]] {
        switch self {
        case .squareBig:  // 3x3 square
            return [
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1),
                    GridCell(column: 0, row: 2), GridCell(column: 1, row: 2), GridCell(column: 2, row: 2)
                ]
            ]
        
        case .rectWide:  // 3x2 rectangle
            return [
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
                ],
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1),
                    GridCell(column: 0, row: 2), GridCell(column: 1, row: 2)
                ]
            ]
        
        case .rectTall:  // 2x3 rectangle
            return [
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1),
                    GridCell(column: 0, row: 2), GridCell(column: 1, row: 2)
                ],
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
                ]
            ]
        
        case .lShapeSit:  // L shape
            return [
                [
                    GridCell(column: 0, row: 0), 
                    GridCell(column: 0, row: 1), 
                    GridCell(column: 0, row: 2), GridCell(column: 1, row: 2)
                ],
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                    GridCell(column: 0, row: 1)
                ],
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                    GridCell(column: 1, row: 1),
                    GridCell(column: 1, row: 2)
                ],
                [
                    GridCell(column: 2, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
                ]
            ]
        
        case .cornerWide:  // Corner shape with extension
            return [
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                    GridCell(column: 0, row: 1),
                    GridCell(column: 0, row: 2)
                ],
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0),
                    GridCell(column: 2, row: 1)
                ],
                [
                    GridCell(column: 1, row: 0),
                    GridCell(column: 1, row: 1),
                    GridCell(column: 0, row: 2), GridCell(column: 1, row: 2)
                ],
                [
                    GridCell(column: 0, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
                ]
            ]
        
        case .squareSmall:  // 2x2 square
            return [
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1)
                ]
            ]
        
        // Formerly shape1-7
        case .lShapeReversed:  // L with top piece (formerly shape1)
            return [
                [
                    GridCell(column: 0, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
                ],
                // Add other rotations as needed
            ]
            
        case .cornerSmall:  // Corner with top left (formerly shape2)
            return [
                [
                    GridCell(column: 0, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0)
                ],
                // Add other rotations as needed
            ]
            
        case .tShape:  // T shape (formerly shape3)
            return [
                [
                    GridCell(column: 1, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1)
                ],
                // Add other rotations as needed
            ]
            
        case .blockDouble:  // 2-block corner (formerly shape4)
            return [
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                    GridCell(column: 0, row: 1)
                ],
                // Add other rotations as needed
            ]
            
        case .zigzag:  // Corner with top and right (formerly shape5)
            return [
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0),
                    GridCell(column: 1, row: 1)
                ],
                // Add other rotations as needed
            ]
            
        case .stick3:  // Row/column of 3 blocks (combines threeBlock and threeColumn)
            return [
                // Horizontal orientation
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0)
                ],
                // Vertical orientation
                [
                    GridCell(column: 0, row: 0),
                    GridCell(column: 0, row: 1),
                    GridCell(column: 0, row: 2)
                ]
            ]
            
        case .stick4:  // Row/column of 4 blocks (combines fourBlock and fourColumn)
            return [
                // Horizontal orientation
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), 
                    GridCell(column: 2, row: 0), GridCell(column: 3, row: 0)
                ],
                // Vertical orientation
                [
                    GridCell(column: 0, row: 0),
                    GridCell(column: 0, row: 1),
                    GridCell(column: 0, row: 2),
                    GridCell(column: 0, row: 3)
                ]
            ]
            
        case .stick5:  // Row/column of 5 blocks (combines fiveBlock and fiveColumn)
            return [
                // Horizontal orientation
                [
                    GridCell(column: 0, row: 0), GridCell(column: 1, row: 0), GridCell(column: 2, row: 0), 
                    GridCell(column: 3, row: 0), GridCell(column: 4, row: 0)
                ],
                // Vertical orientation
                [
                    GridCell(column: 0, row: 0),
                    GridCell(column: 0, row: 1),
                    GridCell(column: 0, row: 2),
                    GridCell(column: 0, row: 3),
                    GridCell(column: 0, row: 4)
                ]
            ]
            
        case .blockSingle:  // Single block
            return [
                [
                    GridCell(column: 0, row: 0)
                ]
            ]
            
        case .cross:  // Plus shape (additional shape)
            return [
                [
                    GridCell(column: 1, row: 0),
                    GridCell(column: 0, row: 1), GridCell(column: 1, row: 1), GridCell(column: 2, row: 1),
                    GridCell(column: 1, row: 2)
                ]
            ]
        }
    }
    
    // Define colors for each shape
    var color: SKColor {
        switch self {
        case .squareBig: return .red
        case .rectWide: return .orange
        case .rectTall: return .yellow
        case .lShapeSit: return .green
        case .cornerWide: return .blue
        case .squareSmall: return .purple
        case .lShapeReversed: return .cyan
        case .cornerSmall: return .magenta
        case .tShape: return SKColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0)  // Purple
        case .blockDouble: return SKColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)  // Olive
        case .zigzag: return SKColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)  // Pink
        case .stick3: return SKColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)  // Teal
        case .stick4: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)  // Gray
        case .stick5: return SKColor(red: 0.7, green: 0.3, blue: 0.1, alpha: 1.0)  // Brown
        case .blockSingle: return SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)  // Light gray
        case .cross: return SKColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 1.0)  // Lime green
        }
    }
    
    // The block offsets are kept for backward compatibility
    var blockOffsets: [[CGPoint]] {
        // Convert grid cells to points for backwards compatibility
        return cellRotations().map { rotation in
            rotation.map { CGPoint(x: CGFloat($0.column), y: CGFloat($0.row)) }
        }
    }
}
