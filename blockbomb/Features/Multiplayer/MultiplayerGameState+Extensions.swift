import Foundation
import SpriteKit

/// Extensions to MultiplayerGameState for state management and transitions
extension MultiplayerGameState {
    
    /// Initialize a new multiplayer game with proper setup
    static func initializeNewGame(
        matchState: MatchState,
        gameController: MultiplayerGameController,
        gameScene: GameScene?
    ) {
        // Reset game state
        gameController.score = 0
        gameController.opponentScore = 0
        gameController.isGameOver = false
        gameController.gameEndReason = .none
        
        // Initialize game scene if needed
        if let gameScene = gameScene {
            gameScene.resetGame()
            gameScene.multiplayerMode = true
        }
        
        // Set random seed for synchronized piece generation
        srand48(Int(matchState.randomSeed))
    }
    
    /// Restore game state from an existing match
    static func restoreGameState(
        from matchState: MatchState,
        gameController: MultiplayerGameController,
        gameScene: GameScene?,
        localPlayerID: String
    ) {
        let isPlayer1 = matchState.player1.playerID == localPlayerID
        let localPlayerState = isPlayer1 ? matchState.player1 : matchState.player2
        let opponentState = isPlayer1 ? matchState.player2 : matchState.player1
        
        // Update scores and game state
        gameController.score = localPlayerState.score
        gameController.opponentScore = opponentState.score
        gameController.isGameOver = localPlayerState.isGameOver || opponentState.isGameOver
        
        // Restore board state if needed
        if let gameScene = gameScene {
            gameScene.multiplayerMode = true
            restoreBoardState(localPlayerState.boardState, to: gameScene)
        }
        
        // Set random seed for synchronized piece generation
        srand48(Int(matchState.randomSeed))
    }
    
    /// Restore board state to the game scene
    private static func restoreBoardState(_ boardState: [[String?]], to gameScene: GameScene) {
        // Convert board state data back to game scene format
        if let gameBoard = gameScene.gameBoard {
            gameBoard.restoreBoardState(boardState)
        }
    }
    
    /// Update match state for turn submission
    static func updateStateForTurnSubmission(
        currentState: MatchState,
        turnData: MoveData,
        localPlayerID: String
    ) -> MatchState {
        let isPlayer1 = currentState.player1.playerID == localPlayerID
        
        var updatedPlayer1 = currentState.player1
        var updatedPlayer2 = currentState.player2
        
        // Update the current player's state
        if isPlayer1 {
            updatedPlayer1.score += turnData.scoreGained
            updatedPlayer1.lastMoveTime = Date()
            updatedPlayer1.moveHistory.append(turnData)
        } else {
            updatedPlayer2.score += turnData.scoreGained
            updatedPlayer2.lastMoveTime = Date()
            updatedPlayer2.moveHistory.append(turnData)
        }
        
        // Use the static method to advance to next turn
        let currentPlayerState = isPlayer1 ? updatedPlayer1 : updatedPlayer2
        return advanceToNextTurn(
            currentState: currentState,
            move: turnData,
            updatedPlayerState: currentPlayerState
        )
    }
    
    /// Update match state with opponent's move
    static func updateStateWithOpponentMove(
        currentState: MatchState,
        turnData: MoveData,
        localPlayerID: String
    ) -> MatchState {
        let isPlayer1Local = currentState.player1.playerID == localPlayerID
        
        var updatedOpponentState: PlayerState
        if isPlayer1Local {
            // Opponent is player 2
            updatedOpponentState = currentState.player2
        } else {
            // Opponent is player 1
            updatedOpponentState = currentState.player1
        }
        
        // Update opponent state
        updatedOpponentState.score += turnData.scoreGained
        updatedOpponentState.lastMoveTime = Date()
        updatedOpponentState.moveHistory.append(turnData)
        
        // Use the static method to advance to next turn
        return advanceToNextTurn(
            currentState: currentState,
            move: turnData,
            updatedPlayerState: updatedOpponentState
        )
    }
    
    /// Validate match state consistency
    static func validateMatchState(_ matchState: MatchState) -> Bool {
        // Check basic state validity
        guard !matchState.matchID.isEmpty,
              !matchState.player1.playerID.isEmpty,
              !matchState.player2.playerID.isEmpty else {
            return false
        }
        
        // Check turn number consistency
        guard matchState.turnNumber >= 0 else {
            return false
        }
        
        // Check scores are non-negative
        guard matchState.player1.score >= 0,
              matchState.player2.score >= 0 else {
            return false
        }
        
        return true
    }
    
    /// Create final match state for game end
    static func createFinalMatchState(
        from currentState: MatchState,
        endReason: MultiplayerGameController.GameEndReason
    ) -> MatchState {
        var finalState = currentState
        finalState.isGameEnded = true
        finalState.gameEndTime = Date()
        
        // Set winner based on end reason
        switch endReason {
        case .playerWon:
            finalState.winner = finalState.player1.playerID
        case .opponentWon:
            finalState.winner = finalState.player2.playerID
        case .playerResigned, .opponentResigned, .connectionLost, .gameTimeout:
            // Winner determined by resignation or technical issues
            break
        case .none:
            // No winner determined yet
            break
        }
        
        return finalState
    }
}
