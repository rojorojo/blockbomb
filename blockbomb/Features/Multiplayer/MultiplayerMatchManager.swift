import Foundation
import GameKit
import Combine

/// Manages Game Center match lifecycle and coordination
class MultiplayerMatchManager: ObservableObject {
    
    @Published var currentMatch: GKTurnBasedMatch?
    @Published var multiplayerError: String?
    @Published var gameEndReason: MultiplayerGameController.GameEndReason = .none
    
    private weak var gameController: MultiplayerGameController?
    private let turnBasedMatchManager = TurnBasedMatchManager.shared
    private let gameCenterManager = GameCenterManager.shared
    
    init(gameController: MultiplayerGameController) {
        self.gameController = gameController
    }
    
    /// Handle match update from TurnBasedMatchManager
    func handleMatchUpdate(_ match: GKTurnBasedMatch?) {
        DispatchQueue.main.async {
            self.currentMatch = match
            
            if let match = match, let gameController = self.gameController {
                gameController.updateTurnState()
                gameController.updateOpponentInfo()
                
                // Check if we received a new turn
                if let matchData = match.matchData,
                   let updatedState = MultiplayerGameState.decodeMatchData(matchData),
                   let currentState = gameController.matchState,
                   updatedState.turnNumber > currentState.turnNumber {
                    
                    // Process opponent's move
                    if let lastMove = self.getLastOpponentMove(from: updatedState) {
                        gameController.handleOpponentMove(lastMove)
                    }
                }
            }
        }
    }
    
    /// Resign from the current game
    func resignGame() {
        guard let match = currentMatch else { return }
        
        turnBasedMatchManager.quitMatch(match) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.gameEndReason = .playerResigned
                    self?.gameController?.isGameOver = true
                } else {
                    self?.multiplayerError = error?.localizedDescription ?? "Failed to resign"
                }
            }
        }
    }
    
    /// Handle emergency game ending (connection lost, timeout)
    func handleEmergencyGameEnd(reason: MultiplayerGameController.GameEndReason) {
        guard let match = currentMatch, let gameController = gameController else { return }
        
        // Create final match data
        let currentMatchState = gameController.matchState ?? MultiplayerGameState.createInitialMatchState(
            matchID: match.matchID,
            player1ID: "player1",
            player2ID: "player2"
        )
        
        guard let finalMatchData = MultiplayerGameState.encodeMatchData(currentMatchState) else {
            multiplayerError = "Failed to create final match data"
            return
        }
        
        turnBasedMatchManager.endMatch(match, matchData: finalMatchData) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.gameController?.isGameOver = true
                self?.gameEndReason = reason
                if !success {
                    self?.multiplayerError = "Connection lost. Game ended."
                }
            }
        }
    }
    
    /// Finalize game end
    func finalizeGameEnd() {
        gameController?.isGameOver = true
        gameController?.isMyTurn = false
        gameController?.isWaitingForOpponent = false
    }
    
    /// Check for game end conditions
    func checkForGameEnd() {
        guard let gameController = gameController,
              let currentMatchState = gameController.matchState else { return }
        
        let localPlayerState = currentMatchState.getCurrentPlayerState()
        let opponentState = currentMatchState.getOpponentPlayerState()
        
        if localPlayerState.isGameOver || opponentState.isGameOver {
            // Determine winner
            if localPlayerState.isGameOver && opponentState.isGameOver {
                // Both players finished - higher score wins
                gameEndReason = localPlayerState.score > opponentState.score ? .playerWon : .opponentWon
            } else if localPlayerState.isGameOver {
                // Local player finished first - they lose
                gameEndReason = .opponentWon
            } else {
                // Opponent finished first - they lose
                gameEndReason = .playerWon
            }
            
            finalizeGameEnd()
        }
    }
    
    /// End the match with given reason
    func endMatch(reason: MultiplayerGameController.GameEndReason) {
        guard let match = currentMatch, let gameController = gameController else { return }
        
        gameEndReason = reason
        
        // Create final match state
        var finalMatchState = gameController.matchState ?? MultiplayerGameState.createInitialMatchState(
            matchID: match.matchID,
            player1ID: gameCenterManager.localPlayer?.gamePlayerID ?? "player1",
            player2ID: "player2"
        )
        
        finalMatchState.isGameEnded = true
        finalMatchState.gameEndTime = Date()
        
        // Encode and submit final state
        guard let finalMatchData = MultiplayerGameState.encodeMatchData(finalMatchState) else {
            multiplayerError = "Failed to encode final match data"
            return
        }
        
        turnBasedMatchManager.endMatch(match, matchData: finalMatchData) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.finalizeGameEnd()
                } else {
                    self?.multiplayerError = error?.localizedDescription ?? "Failed to end match"
                }
            }
        }
    }
    
    /// Get the last opponent move from match state
    private func getLastOpponentMove(from matchState: MultiplayerGameState.MatchState) -> MultiplayerGameState.MoveData? {
        guard let gameController = gameController,
              let localPlayer = gameCenterManager.localPlayer else { return nil }
        
        let isPlayer1 = matchState.player1.playerID == localPlayer.gamePlayerID
        let opponentMoves = isPlayer1 ? matchState.player2.moveHistory : matchState.player1.moveHistory
        
        return opponentMoves.last
    }
    
    /// Check match validity and connection status
    func validateMatchStatus() -> Bool {
        guard let match = currentMatch else {
            multiplayerError = "No active match found"
            return false
        }
        
        // Check if match is still active
        if match.status != .open {
            multiplayerError = "Match is no longer active"
            return false
        }
        
        return true
    }
}
