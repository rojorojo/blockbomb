import Foundation
import GameKit

/// Handles competitive scoring and game end logic for multiplayer matches
class MultiplayerScoring {
    
    // MARK: - Properties
    
    private weak var gameController: MultiplayerGameController?
    
    /// Statistics tracking for multiplayer performance
    private var multiplayerStats = MultiplayerStatistics()
    
    // MARK: - Initialization
    
    init(gameController: MultiplayerGameController) {
        self.gameController = gameController
    }
    
    // MARK: - Public Interface
    
    /// Determine the winner based on final scores
    /// - Parameters:
    ///   - playerScore: Local player's final score
    ///   - opponentScore: Opponent's final score
    /// - Returns: GameEndReason indicating the winner
    func determineWinner(playerScore: Int, opponentScore: Int) -> MultiplayerGameController.GameEndReason {
        print("MultiplayerScoring.determineWinner: Player: \(playerScore), Opponent: \(opponentScore)")
        
        if playerScore > opponentScore {
            print("MultiplayerScoring.determineWinner: Player won")
            return .playerWon
        } else if opponentScore > playerScore {
            print("MultiplayerScoring.determineWinner: Opponent won")
            return .opponentWon
        } else {
            // In case of tie, use additional criteria
            print("MultiplayerScoring.determineWinner: Scores tied, using tiebreaker")
            return determineTiebreaker(playerScore: playerScore, opponentScore: opponentScore)
        }
    }
    
    /// Handle game end with comprehensive cleanup and statistics
    /// - Parameters:
    ///   - reason: The reason the game ended
    ///   - playerScore: Final player score
    ///   - opponentScore: Final opponent score
    func handleGameEnd(reason: MultiplayerGameController.GameEndReason, 
                      playerScore: Int, 
                      opponentScore: Int) {
        print("MultiplayerScoring.handleGameEnd: Reason: \(reason), Player: \(playerScore), Opponent: \(opponentScore)")
        
        // Calculate final scores with any bonuses
        let finalScores = calculateFinalScores(
            basePlayerScore: playerScore,
            baseOpponentScore: opponentScore,
            endReason: reason
        )
        
        // Update statistics
        updateMultiplayerStatistics(
            finalPlayerScore: finalScores.playerScore,
            finalOpponentScore: finalScores.opponentScore,
            endReason: reason
        )
        
        // Handle accessibility announcements
        announceGameEndResults(
            reason: reason,
            playerScore: finalScores.playerScore,
            opponentScore: finalScores.opponentScore
        )
        
        // Store game results for Game Center
        submitGameCenterResults(
            playerScore: finalScores.playerScore,
            opponentScore: finalScores.opponentScore,
            won: reason == .playerWon
        )
        
        print("MultiplayerScoring.handleGameEnd: Game end processing complete")
    }
    
    /// Calculate final scores with any end-game bonuses or penalties
    /// - Parameters:
    ///   - basePlayerScore: Base score for player
    ///   - baseOpponentScore: Base score for opponent
    ///   - endReason: How the game ended
    /// - Returns: Tuple with final scores
    func calculateFinalScores(basePlayerScore: Int, 
                             baseOpponentScore: Int, 
                             endReason: MultiplayerGameController.GameEndReason) -> (playerScore: Int, opponentScore: Int) {
        
        var playerScore = basePlayerScore
        var opponentScore = baseOpponentScore
        
        print("MultiplayerScoring.calculateFinalScores: Base scores - Player: \(playerScore), Opponent: \(opponentScore)")
        
        // Apply bonuses/penalties based on end reason
        switch endReason {
        case .playerWon:
            // Winner gets small bonus
            playerScore += calculateWinBonus(score: playerScore)
            
        case .opponentWon:
            // Winner gets small bonus
            opponentScore += calculateWinBonus(score: opponentScore)
            
        case .playerResigned:
            // Player who resigned gets penalty
            playerScore = max(0, playerScore - calculateResignationPenalty(score: playerScore))
            
        case .opponentResigned:
            // Opponent who resigned gets penalty
            opponentScore = max(0, opponentScore - calculateResignationPenalty(score: opponentScore))
            
        case .connectionLost:
            // No bonuses/penalties for connection issues
            break
            
        case .gameTimeout:
            // Small penalty for timeout
            let timeoutPenalty = 50
            playerScore = max(0, playerScore - timeoutPenalty)
            opponentScore = max(0, opponentScore - timeoutPenalty)
            
        case .none:
            break
        }
        
        print("MultiplayerScoring.calculateFinalScores: Final scores - Player: \(playerScore), Opponent: \(opponentScore)")
        return (playerScore: playerScore, opponentScore: opponentScore)
    }
    
    /// Update score tracking during gameplay
    /// - Parameters:
    ///   - playerScore: Current player score
    ///   - opponentScore: Current opponent score
    func updateScores(playerScore: Int, opponentScore: Int) {
        guard let gameController = gameController else { return }
        
        let previousPlayerScore = gameController.score
        let previousOpponentScore = gameController.opponentScore
        
        // Update controller scores
        gameController.score = playerScore
        gameController.opponentScore = opponentScore
        
        // Announce score changes if significant
        let playerDelta = playerScore - previousPlayerScore
        let opponentDelta = opponentScore - previousOpponentScore
        
        if playerDelta > 0 {
            announceScoreChange(player: "You", scoreGain: playerDelta, newTotal: playerScore)
        }
        
        if opponentDelta > 0 {
            announceScoreChange(player: gameController.opponentName, scoreGain: opponentDelta, newTotal: opponentScore)
        }
        
        print("MultiplayerScoring.updateScores: Updated to Player: \(playerScore), Opponent: \(opponentScore)")
    }
    
    /// Check if game should end due to score conditions
    /// - Parameters:
    ///   - playerScore: Current player score
    ///   - opponentScore: Current opponent score
    /// - Returns: GameEndReason if game should end, nil otherwise
    func checkScoreEndConditions(playerScore: Int, opponentScore: Int) -> MultiplayerGameController.GameEndReason? {
        // Check for score-based end conditions
        // For now, games end when no moves are available, but could add score limits
        
        // Example: If one player reaches a massive lead
        let scoreDifference = abs(playerScore - opponentScore)
        if scoreDifference > 5000 { // Configurable threshold
            if playerScore > opponentScore {
                return .playerWon
            } else {
                return .opponentWon
            }
        }
        
        return nil
    }
    
    /// Handle edge cases for simultaneous game over scenarios
    /// - Parameters:
    ///   - playerCanMove: Whether player can make moves
    ///   - opponentCanMove: Whether opponent can make moves
    ///   - playerScore: Current player score
    ///   - opponentScore: Current opponent score
    /// - Returns: GameEndReason for simultaneous scenarios
    func handleSimultaneousGameOver(playerCanMove: Bool, 
                                   opponentCanMove: Bool, 
                                   playerScore: Int, 
                                   opponentScore: Int) -> MultiplayerGameController.GameEndReason {
        
        print("MultiplayerScoring.handleSimultaneousGameOver: Player can move: \(playerCanMove), Opponent can move: \(opponentCanMove)")
        
        // Both players cannot move - determine by score
        if !playerCanMove && !opponentCanMove {
            return determineWinner(playerScore: playerScore, opponentScore: opponentScore)
        }
        
        // Only one player cannot move
        if !playerCanMove && opponentCanMove {
            print("MultiplayerScoring.handleSimultaneousGameOver: Player cannot move, opponent can continue")
            return .opponentWon
        }
        
        if playerCanMove && !opponentCanMove {
            print("MultiplayerScoring.handleSimultaneousGameOver: Opponent cannot move, player can continue")
            return .playerWon
        }
        
        // Both can move - should not reach here
        print("MultiplayerScoring.handleSimultaneousGameOver: Both players can still move")
        return .none
    }
    
    /// Handle disconnection scenarios with appropriate scoring
    /// - Parameters:
    ///   - disconnectedPlayer: Which player disconnected
    ///   - gameTimeRemaining: How much time was left in the game
    ///   - playerScore: Current player score
    ///   - opponentScore: Current opponent score
    /// - Returns: GameEndReason and any score adjustments
    func handleDisconnection(disconnectedPlayer: DisconnectedPlayer, 
                           gameTimeRemaining: TimeInterval, 
                           playerScore: Int, 
                           opponentScore: Int) -> (reason: MultiplayerGameController.GameEndReason, playerScore: Int, opponentScore: Int) {
        
        print("MultiplayerScoring.handleDisconnection: \(disconnectedPlayer) disconnected with \(gameTimeRemaining)s remaining")
        
        var adjustedPlayerScore = playerScore
        var adjustedOpponentScore = opponentScore
        var reason: MultiplayerGameController.GameEndReason
        
        switch disconnectedPlayer {
        case .localPlayer:
            reason = .playerResigned
            // Apply disconnection penalty to local player
            adjustedPlayerScore = max(0, playerScore - calculateDisconnectionPenalty(timeRemaining: gameTimeRemaining))
            
        case .opponent:
            reason = .opponentResigned
            // Apply disconnection penalty to opponent
            adjustedOpponentScore = max(0, opponentScore - calculateDisconnectionPenalty(timeRemaining: gameTimeRemaining))
            
        case .unknown:
            reason = .connectionLost
            // No penalties for unknown connection issues
            break
        }
        
        print("MultiplayerScoring.handleDisconnection: Adjusted scores - Player: \(adjustedPlayerScore), Opponent: \(adjustedOpponentScore)")
        return (reason: reason, playerScore: adjustedPlayerScore, opponentScore: adjustedOpponentScore)
    }
    
    /// Get current multiplayer statistics
    /// - Returns: Current statistics object
    func getCurrentStatistics() -> MultiplayerStatistics {
        return multiplayerStats
    }
    
    // MARK: - Private Helper Methods
    
    /// Determine winner in case of tie using additional criteria
    private func determineTiebreaker(playerScore: Int, opponentScore: Int) -> MultiplayerGameController.GameEndReason {
        // In case of exact tie, could use:
        // - Turn completion time
        // - Number of moves made
        // - Game duration
        // For now, we'll consider it a player win if they're the current player
        
        guard let gameController = gameController else { return .playerWon }
        
        if gameController.isMyTurn {
            print("MultiplayerScoring.determineTiebreaker: Tie broken in favor of current player")
            return .playerWon
        } else {
            print("MultiplayerScoring.determineTiebreaker: Tie broken in favor of opponent")
            return .opponentWon
        }
    }
    
    /// Calculate win bonus based on score
    private func calculateWinBonus(score: Int) -> Int {
        // Small percentage bonus for winning
        return max(10, score / 20) // 5% bonus, minimum 10 points
    }
    
    /// Calculate resignation penalty
    private func calculateResignationPenalty(score: Int) -> Int {
        // Small penalty for resigning
        return max(50, score / 10) // 10% penalty, minimum 50 points
    }
    
    /// Calculate disconnection penalty based on time remaining
    private func calculateDisconnectionPenalty(timeRemaining: TimeInterval) -> Int {
        // Larger penalty for early disconnections
        let maxPenalty = 200
        let minPenalty = 50
        
        // If more than 80% of game time remaining, apply larger penalty
        if timeRemaining > 240 { // More than 4 minutes remaining (assuming 5 min max)
            return maxPenalty
        } else if timeRemaining > 60 { // More than 1 minute remaining
            return maxPenalty / 2
        } else {
            return minPenalty
        }
    }
    
    /// Update multiplayer statistics with game results
    private func updateMultiplayerStatistics(finalPlayerScore: Int, 
                                           finalOpponentScore: Int, 
                                           endReason: MultiplayerGameController.GameEndReason) {
        
        multiplayerStats.gamesPlayed += 1
        multiplayerStats.totalScore += finalPlayerScore
        
        switch endReason {
        case .playerWon:
            multiplayerStats.wins += 1
        case .opponentWon:
            multiplayerStats.losses += 1
        case .playerResigned, .opponentResigned, .connectionLost, .gameTimeout:
            multiplayerStats.incompleteGames += 1
        case .none:
            break
        }
        
        // Update highest score
        if finalPlayerScore > multiplayerStats.highestScore {
            multiplayerStats.highestScore = finalPlayerScore
        }
        
        // Calculate win rate
        let completedGames = multiplayerStats.wins + multiplayerStats.losses
        if completedGames > 0 {
            multiplayerStats.winRate = Double(multiplayerStats.wins) / Double(completedGames)
        }
        
        // Save statistics (privacy-compliant)
        saveStatistics()
        
        print("MultiplayerScoring: Statistics updated - Games: \(multiplayerStats.gamesPlayed), Wins: \(multiplayerStats.wins), Win Rate: \(multiplayerStats.winRate)")
    }
    
    /// Announce score changes for accessibility
    private func announceScoreChange(player: String, scoreGain: Int, newTotal: Int) {
        guard let gameController = gameController else { return }
        
        let message = "\(player) scored \(scoreGain) points. Total: \(newTotal)"
        
        // Use accessibility manager directly
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Announce game end results for accessibility
    private func announceGameEndResults(reason: MultiplayerGameController.GameEndReason,
                                      playerScore: Int,
                                      opponentScore: Int) {
        guard let gameController = gameController else { return }
        
        var message = ""
        
        switch reason {
        case .playerWon:
            message = "You won! Final score: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        case .opponentWon:
            message = "\(gameController.opponentName) won! Final score: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        case .playerResigned:
            message = "You resigned. Final score: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        case .opponentResigned:
            message = "\(gameController.opponentName) resigned. You won! Final score: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        case .connectionLost:
            message = "Connection lost. Game ended. Final score: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        case .gameTimeout:
            message = "Game timed out. Final score: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        case .none:
            message = "Game ended. Final score: You \(playerScore), \(gameController.opponentName) \(opponentScore)"
        }
        
        // Use accessibility manager if available
        gameController.accessibility.announceAccessibilityUpdate(message)
        
        print("MultiplayerScoring: Announced game end - \(message)")
    }
    
    /// Submit results to Game Center
    private func submitGameCenterResults(playerScore: Int, opponentScore: Int, won: Bool) {
        // Submit to Game Center leaderboards and achievements
        // This would integrate with GameCenterManager
        
        print("MultiplayerScoring: Submitting to Game Center - Score: \(playerScore), Won: \(won)")
        
        // Example Game Center submission (would need actual implementation)
        /*
        GKLeaderboard.submitScore(
            playerScore,
            category: "multiplayer_scores",
            withCompletionHandler: { error in
                if let error = error {
                    print("Game Center submission error: \(error)")
                }
            }
        )
        */
    }
    
    /// Save statistics with privacy compliance
    private func saveStatistics() {
        // Save only aggregated, non-personally identifiable statistics
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(multiplayerStats)
            UserDefaults.standard.set(data, forKey: "multiplayer_statistics")
            print("MultiplayerScoring: Statistics saved successfully")
        } catch {
            print("MultiplayerScoring: Failed to save statistics - \(error)")
        }
    }
    
    /// Load previously saved statistics
    func loadStatistics() {
        guard let data = UserDefaults.standard.data(forKey: "multiplayer_statistics") else {
            print("MultiplayerScoring: No saved statistics found")
            return
        }
        
        let decoder = JSONDecoder()
        
        do {
            multiplayerStats = try decoder.decode(MultiplayerStatistics.self, from: data)
            print("MultiplayerScoring: Statistics loaded - Games: \(multiplayerStats.gamesPlayed), Win Rate: \(multiplayerStats.winRate)")
        } catch {
            print("MultiplayerScoring: Failed to load statistics - \(error)")
            // Keep default stats if loading fails
        }
    }
}

// MARK: - Supporting Types

/// Enum for tracking which player disconnected
enum DisconnectedPlayer {
    case localPlayer
    case opponent
    case unknown
}

/// Privacy-compliant multiplayer statistics
struct MultiplayerStatistics: Codable {
    var gamesPlayed: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var incompleteGames: Int = 0
    var totalScore: Int = 0
    var highestScore: Int = 0
    var winRate: Double = 0.0
    var lastUpdated: Date = Date()
    
    /// Average score per game
    var averageScore: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(totalScore) / Double(gamesPlayed)
    }
    
    /// Total completed games
    var completedGames: Int {
        return wins + losses
    }
}
