import Foundation
import UIKit

/// Handles accessibility features for multiplayer gameplay
class MultiplayerAccessibility {
    
    private weak var gameController: MultiplayerGameController?
    
    init(gameController: MultiplayerGameController) {
        self.gameController = gameController
    }
    
    /// Setup accessibility support for multiplayer mode
    func setupAccessibilitySupport() {
        // Configure VoiceOver announcements for multiplayer events
        configureVoiceOverSupport()
        
        // Setup accessibility notifications for game state changes
        setupAccessibilityNotifications()
        
        print("MultiplayerAccessibility: Accessibility support configured")
    }
    
    /// Announce accessibility updates
    func announceAccessibilityUpdate(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Get accessibility message for game end reason
    func getGameEndAccessibilityMessage(for reason: MultiplayerGameController.GameEndReason) -> String {
        guard let gameController = gameController else { return "Game ended" }
        
        switch reason {
        case .none:
            return "Game ended"
        case .playerWon:
            return "You won the game!"
        case .opponentWon:
            return "\(gameController.opponentName) won the game"
        case .playerResigned:
            return "You resigned from the game"
        case .opponentResigned:
            return "\(gameController.opponentName) resigned. You won!"
        case .connectionLost:
            return "Connection lost. Game ended."
        case .gameTimeout:
            return "Game timed out"
        }
    }
    
    /// Announce turn state changes
    func announceTurnStateChange(isMyTurn: Bool, opponentName: String) {
        let message = isMyTurn ? "It's your turn" : "Waiting for \(opponentName)"
        announceAccessibilityUpdate(message)
    }
    
    /// Announce opponent move
    func announceOpponentMove(opponentName: String, scoreGained: Int) {
        let message = "\(opponentName) scored \(scoreGained) points. It's your turn."
        announceAccessibilityUpdate(message)
    }
    
    /// Announce game start
    func announceGameStart(opponentName: String, isMyTurn: Bool) {
        let turnMessage = isMyTurn ? "You go first." : "\(opponentName) goes first."
        let message = "Multiplayer game started with \(opponentName). \(turnMessage)"
        announceAccessibilityUpdate(message)
    }
    
    /// Announce score update
    func announceScoreUpdate(playerScore: Int, opponentScore: Int, opponentName: String) {
        let message = "Score update: You have \(playerScore), \(opponentName) has \(opponentScore)"
        announceAccessibilityUpdate(message)
    }
    
    /// Announce connection status
    func announceConnectionStatus(_ status: String) {
        announceAccessibilityUpdate("Connection status: \(status)")
    }
    
    /// Announce turn submission
    func announceTurnSubmission() {
        announceAccessibilityUpdate("Turn submitted. Waiting for opponent.")
    }
    
    /// Announce turn timeout warning
    func announceTurnTimeoutWarning(secondsRemaining: Int) {
        let message = "Turn expires in \(secondsRemaining) seconds"
        announceAccessibilityUpdate(message)
    }
    
    /// Announce score changes for accessibility
    func announceScoreUpdate(playerScore: Int, opponentScore: Int, scoreGain: Int, isPlayerScore: Bool) {
        guard let gameController = gameController else { return }
        
        let playerName = isPlayerScore ? "You" : gameController.opponentName
        let message = "\(playerName) scored \(scoreGain) points. Your score: \(playerScore). \(gameController.opponentName)'s score: \(opponentScore)"
        
        announceAccessibilityUpdate(message)
        print("MultiplayerAccessibility: Announced score update - \(message)")
    }
    
    /// Announce game end results with detailed information
    func announceGameEndResults(reason: MultiplayerGameController.GameEndReason, 
                               playerScore: Int, 
                               opponentScore: Int) {
        guard let gameController = gameController else { return }
        
        let baseMessage = getGameEndAccessibilityMessage(for: reason)
        let scoreMessage = "Final scores: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        let fullMessage = "\(baseMessage). \(scoreMessage)"
        
        announceAccessibilityUpdate(fullMessage)
        
        // Additional context for screen readers
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let contextMessage: String
            switch reason {
            case .playerWon:
                contextMessage = "You won by \(playerScore - opponentScore) points"
            case .opponentWon:
                contextMessage = "\(gameController.opponentName) won by \(opponentScore - playerScore) points"
            default:
                contextMessage = "Tap to view game options"
            }
            self.announceAccessibilityUpdate(contextMessage)
        }
        
        print("MultiplayerAccessibility: Announced game end results")
    }
    
    /// Announce competitive statistics for accessibility
    func announceStatistics(_ stats: MultiplayerStatistics) {
        let message = "Multiplayer statistics: \(stats.gamesPlayed) games played, \(stats.wins) wins, \(Int(stats.winRate * 100))% win rate, highest score \(stats.highestScore)"
        announceAccessibilityUpdate(message)
        print("MultiplayerAccessibility: Announced statistics - \(message)")
    }
    
    /// Configure VoiceOver support
    private func configureVoiceOverSupport() {
        // Set up custom accessibility actions if needed
        // This would typically be done in the UI layer
    }
    
    /// Setup accessibility notifications
    private func setupAccessibilityNotifications() {
        // Listen for accessibility notifications
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleVoiceOverStatusChange()
        }
    }
    
    /// Handle VoiceOver status changes
    private func handleVoiceOverStatusChange() {
        if UIAccessibility.isVoiceOverRunning {
            announceAccessibilityUpdate("VoiceOver enabled for multiplayer game")
        }
    }
    
    /// Get descriptive text for current game state
    func getCurrentGameStateDescription() -> String {
        guard let gameController = gameController else { return "Game state unknown" }
        
        var description = "Multiplayer game"
        
        if gameController.isGameOver {
            description += " ended"
        } else if gameController.isMyTurn {
            description += " - your turn"
        } else {
            description += " - opponent's turn"
        }
        
        description += ". Your score: \(gameController.score)"
        description += ". \(gameController.opponentName)'s score: \(gameController.opponentScore)"
        
        return description
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
