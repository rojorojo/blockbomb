import Foundation
import GameKit
import Combine

/// Manages turn-based gameplay logic and state transitions
class MultiplayerTurnManager: ObservableObject {
    
    @Published var isMyTurn: Bool = false
    @Published var isWaitingForOpponent: Bool = false
    @Published var isSubmittingTurn: Bool = false
    
    private weak var gameController: MultiplayerGameController?
    private let gameCenterManager = GameCenterManager.shared
    private let turnBasedMatchManager = TurnBasedMatchManager.shared
    
    init(gameController: MultiplayerGameController) {
        self.gameController = gameController
    }
    
    /// Update turn state based on current match
    func updateTurnState(for match: GKTurnBasedMatch?, isGameOver: Bool) {
        guard let match = match,
              let localPlayer = gameCenterManager.localPlayer else {
            isMyTurn = false
            return
        }
        
        if let currentParticipant = match.currentParticipant {
            isMyTurn = currentParticipant.player?.gamePlayerID == localPlayer.gamePlayerID
        } else {
            isMyTurn = false
        }
        
        isWaitingForOpponent = !isMyTurn && !isGameOver
        print("MultiplayerTurnManager: Turn state updated - isMyTurn: \(isMyTurn)")
    }
    
    /// Handle turn submission result
    func handleTurnSubmissionResult(success: Bool, error: Error?) {
        isSubmittingTurn = false
        
        if success {
            print("MultiplayerTurnManager: Turn submitted successfully")
            gameController?.announceAccessibilityUpdate("Turn submitted. Waiting for opponent.")
        } else {
            print("MultiplayerTurnManager: Turn submission failed: \(error?.localizedDescription ?? "Unknown error")")
            gameController?.multiplayerError = error?.localizedDescription ?? "Failed to submit turn"
        }
    }
    
    /// Get the next participant for turn submission
    func getNextParticipant(in match: GKTurnBasedMatch) -> GKTurnBasedParticipant? {
        guard let localPlayer = gameCenterManager.localPlayer else { return nil }
        
        return match.participants.first { participant in
            participant.player?.gamePlayerID != localPlayer.gamePlayerID
        }
    }
    
    /// Validate if it's the player's turn to make a move
    func canMakeMove(for match: GKTurnBasedMatch?) -> Bool {
        guard let match = match,
              let localPlayer = gameCenterManager.localPlayer,
              let currentParticipant = match.currentParticipant else {
            return false
        }
        
        return currentParticipant.player?.gamePlayerID == localPlayer.gamePlayerID
    }
    
    /// Process turn timeout
    func handleTurnTimeout(for match: GKTurnBasedMatch) {
        print("MultiplayerTurnManager: Turn timeout detected")
        
        // Auto-submit if it's player's turn, or handle opponent timeout
        if isMyTurn {
            autoSubmitTurn()
        } else {
            handleOpponentTimeout()
        }
    }
    
    /// Automatically submit a turn when timeout occurs
    private func autoSubmitTurn() {
        guard let gameController = gameController else { return }
        
        print("MultiplayerTurnManager: Auto-submitting turn due to timeout")
        isSubmittingTurn = true
        gameController.submitTurn()
    }
    
    /// Handle opponent timeout scenario
    private func handleOpponentTimeout() {
        print("MultiplayerTurnManager: Opponent timeout detected")
        gameController?.multiplayerError = "Opponent took too long. Game may end soon."
    }
    
    /// Start turn submission process
    func startTurnSubmission() {
        isSubmittingTurn = true
    }
    
    /// Get turn time remaining (in seconds)
    func getTurnTimeRemaining(for match: GKTurnBasedMatch?) -> TimeInterval? {
        guard let match = match, let currentParticipant = match.currentParticipant else {
            return nil
        }
        
        guard let timeoutDate = currentParticipant.timeoutDate else {
            return nil
        }
        
        return timeoutDate.timeIntervalSinceNow
    }
    
    /// Check if turn is about to expire
    func isTurnExpiringSoon(for match: GKTurnBasedMatch?, threshold: TimeInterval = 60) -> Bool {
        guard let timeRemaining = getTurnTimeRemaining(for: match) else { return false }
        return timeRemaining <= threshold && timeRemaining > 0
    }
}
