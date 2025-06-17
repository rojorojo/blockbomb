import Foundation
import UIKit

/// Represents a gameplay session for data logging
struct GameplaySession {
    let sessionId: String
    let startTime: Date
    let deviceId: String
    
    init() {
        self.sessionId = UUID().uuidString
        self.startTime = Date()
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
}

/// Represents a single gameplay move for logging
struct GameplayMove {
    let sessionId: String
    let timestamp: Date
    let boardState: String           // Flattened board as "0,1,0,1,..."
    let availablePieces: String      // Binary encoding "1,0,1,0,..."
    let selectedPiece: Int           // Piece type ID
    let scoreDelta: Int              // Score change from this move
    let linesCleared: Int            // Number of lines cleared
    let gameDuration: TimeInterval   // Time since game started
    
    /// Convert to CSV row format
    func toCSVRow() -> String {
        let formatter = ISO8601DateFormatter()
        return "\(sessionId),\(formatter.string(from: timestamp)),\(boardState),\(availablePieces),\(selectedPiece),\(scoreDelta),\(linesCleared),\(gameDuration)"
    }
    
    /// CSV header for the data format
    static let csvHeader = "session_id,timestamp,board_state,available_pieces,selected_piece,score_delta,lines_cleared,game_duration"
}
