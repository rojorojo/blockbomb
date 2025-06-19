import Foundation
import GameKit

// MARK: - Type Definitions

extension MultiplayerGameController {
    
    /// Reasons for game ending in multiplayer
    enum GameEndReason {
        case none
        case playerWon
        case opponentWon
        case playerResigned
        case opponentResigned
        case connectionLost
        case gameTimeout
    }
    
    // MARK: - Constants
    static let maxTurnTimeLimit: TimeInterval = 300 // 5 minutes per turn
    static let emergencyTimeoutLimit: TimeInterval = 900 // 15 minutes absolute max
}

// MARK: - Extensions

extension TetrominoShape {
    /// Get color name for multiplayer synchronization
    var colorName: String {
        // Return a default color name based on the shape's category
        switch self.category {
        case .squares: return "yellow"
        case .rectangles: return "blue"
        case .sticks: return "cyan"
        case .lShapes: return "orange"
        case .corners: return "green"
        case .tShapes: return "purple"
        case .elbows: return "red"
        case .sShapes: return "pink"
        case .special: return "teal"
        }
    }
}
