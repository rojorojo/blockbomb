import SwiftUI
import SpriteKit
import Combine
import GameKit
import Foundation

/// Multiplayer game controller extending GameController for turn-based gameplay        guard let encodedMatchData = MultiplayerGameState.encodeMatchData(updatedMatchState) else {// Handles multiplayer coordination, turn management, and Game Center integration
class MultiplayerGameController: GameController {
    
    // MARK: - Multiplayer Properties
    @Published var isMultiplayerMode: Bool = false
    @Published var currentMatch: GKTurnBasedMatch? {
        didSet {
            matchManager.currentMatch = currentMatch
        }
    }
    @Published var isMyTurn: Bool = false
    @Published var opponentName: String = ""
    @Published var isWaitingForOpponent: Bool = false
    @Published var isSubmittingTurn: Bool = false
    @Published var isGameActive: Bool = false
    @Published var multiplayerError: String? {
        didSet {
            matchManager.multiplayerError = multiplayerError
        }
    }
    @Published var opponentScore: Int = 0
    @Published var matchState: MultiplayerGameState.MatchState?
    @Published var gameEndReason: GameEndReason = .none {
        didSet {
            matchManager.gameEndReason = gameEndReason
        }
    }
    

    
    // MARK: - Private Properties
    private let turnBasedMatchManager = TurnBasedMatchManager.shared
    private let gameCenterManager = GameCenterManager.shared
    private var multiplayerGameState = MultiplayerGameState()
    private var synchronizedPieces: [TetrominoShape] = []
    private var isProcessingOpponentMove = false
    private var pendingTurnSubmission: MultiplayerGameState.MoveData?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Component Managers
    private lazy var turnManager = MultiplayerTurnManager(gameController: self)
    private lazy var matchManager = MultiplayerMatchManager(gameController: self)
    private lazy var synchronization = MultiplayerSynchronization(gameController: self)
    internal lazy var accessibility = MultiplayerAccessibility(gameController: self)
    private lazy var scoring = MultiplayerScoring(gameController: self)
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupMultiplayerObservers()
        accessibility.setupAccessibilitySupport()
        
        // Load previous statistics
        scoring.loadStatistics()
        
        print("MultiplayerGameController: Initialized with scoring system")
    }
    
    // MARK: - Setup Methods
    
    /// Setup multiplayer observers and bindings
    private func setupMultiplayerObservers() {
        // Observe match updates from TurnBasedMatchManager
        turnBasedMatchManager.$currentMatch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] match in
                self?.matchManager.handleMatchUpdate(match)
            }
            .store(in: &cancellables)
        
        // Bind turn manager properties
        turnManager.$isMyTurn
            .assign(to: \.isMyTurn, on: self)
            .store(in: &cancellables)
        
        turnManager.$isWaitingForOpponent
            .assign(to: \.isWaitingForOpponent, on: self)
            .store(in: &cancellables)
        
        turnManager.$isSubmittingTurn
            .assign(to: \.isSubmittingTurn, on: self)
            .store(in: &cancellables)
        
        print("MultiplayerGameController: Observers configured")
    }
    
    // MARK: - Public Interface Methods
    
    /// Start a multiplayer game with the given match
    func startMultiplayerGame(with match: GKTurnBasedMatch) {
        print("MultiplayerGameController: Starting multiplayer game")
        
        currentMatch = match
        isMultiplayerMode = true
        
        // Decode match data or create initial state
        if let matchData = match.matchData,
           let decodedState = MultiplayerGameState.decodeMatchData(matchData) {
            // Restore existing game
            matchState = decodedState
            MultiplayerGameState.restoreGameState(
                from: decodedState,
                gameController: self,
                gameScene: gameScene,
                localPlayerID: gameCenterManager.localPlayer?.gamePlayerID ?? ""
            )
            print("MultiplayerGameController: Restored existing game state")
        } else {
            // Create new game
            let newMatchState = MultiplayerGameState.createInitialMatchState(
                matchID: match.matchID,
                player1ID: gameCenterManager.localPlayer?.gamePlayerID ?? "player1",
                player2ID: getOpponentPlayerID() ?? "player2"
            )
            matchState = newMatchState
            MultiplayerGameState.initializeNewGame(
                matchState: newMatchState,
                gameController: self,
                gameScene: gameScene
            )
            print("MultiplayerGameController: Created new game state")
        }
        
        // Update UI state
        updateTurnState()
        updateOpponentInfo()
        
        // Generate synchronized pieces
        if let currentMatchState = matchState {
            synchronizedPieces = synchronization.generateSynchronizedPieces(from: currentMatchState)
        }
        
        // Announce game start for accessibility
        accessibility.announceGameStart(opponentName: opponentName, isMyTurn: isMyTurn)
    }
    
    /// Submit the current turn
    func submitTurn() {
        guard let match = currentMatch,
              let currentMatchState = matchState,
              turnManager.canMakeMove(for: match) else {
            print("MultiplayerGameController: Cannot submit turn - invalid state")
            return
        }
        
        print("MultiplayerGameController: Submitting turn")
        turnManager.startTurnSubmission()
        
        // Create turn data
        let turnData = synchronization.createTurnData()
        pendingTurnSubmission = turnData
        
        // Update match state
        let updatedMatchState = MultiplayerGameState.updateStateForTurnSubmission(
            currentState: currentMatchState,
            turnData: turnData,
            localPlayerID: gameCenterManager.localPlayer?.gamePlayerID ?? ""
        )
        matchState = updatedMatchState
        
        // Encode and submit
        guard let encodedMatchData = MultiplayerGameState.encodeMatchData(updatedMatchState) else {
            multiplayerError = "Failed to prepare turn data"
            turnManager.handleTurnSubmissionResult(success: false, error: nil)
            return
        }
        
        turnBasedMatchManager.submitTurn(
            for: match,
            matchData: encodedMatchData
        ) { [weak self] success, error in
            self?.turnManager.handleTurnSubmissionResult(success: success, error: error)
        }
        
        accessibility.announceTurnSubmission()
    }
    
    /// Handle an opponent's move
    func handleOpponentMove(_ moveData: MultiplayerGameState.MoveData) {
        guard !isProcessingOpponentMove else { return }
        
        print("MultiplayerGameController: Processing opponent move")
        isProcessingOpponentMove = true
        
        // Update opponent score
        opponentScore += moveData.scoreGained
        
        // Update match state
        if let currentMatchState = matchState {
            let updatedMatchState = MultiplayerGameState.updateStateWithOpponentMove(
                currentState: currentMatchState,
                turnData: moveData,
                localPlayerID: gameCenterManager.localPlayer?.gamePlayerID ?? ""
            )
            matchState = updatedMatchState
        }
        
        // Update turn state
        updateTurnState()
        
        // Announce for accessibility
        accessibility.announceOpponentMove(opponentName: opponentName, scoreGained: moveData.scoreGained)
        
        isProcessingOpponentMove = false
        print("MultiplayerGameController: Opponent move processed")
    }
    
    /// End the multiplayer game
    func endGame(reason: GameEndReason = .none) {
        print("MultiplayerGameController: Ending game with reason: \(reason)")
        
        // Use the new comprehensive game end handling
        handleGameEnd(reason: reason)
        
        // Still notify match manager for Game Center handling
        matchManager.endMatch(reason: reason)
    }
    
    // MARK: - Internal Methods
    
    /// Update turn state
    internal func updateTurnState() {
        turnManager.updateTurnState(for: currentMatch, isGameOver: isGameOver)
    }
    
    /// Update opponent information
    internal func updateOpponentInfo() {
        guard let match = currentMatch,
              let localPlayer = gameCenterManager.localPlayer else {
            return
        }
        
        // Find opponent participant
        if let opponentParticipant = match.participants.first(where: { participant in
            participant.player?.gamePlayerID != localPlayer.gamePlayerID
        }) {
            opponentName = opponentParticipant.player?.displayName ?? "Opponent"
        }
    }
    
    /// Announce accessibility update
    internal func announceAccessibilityUpdate(_ message: String) {
        accessibility.announceAccessibilityUpdate(message)
    }
    
    // MARK: - Helper Methods
    
    /// Get opponent player ID
    private func getOpponentPlayerID() -> String? {
        guard let match = currentMatch,
              let localPlayer = gameCenterManager.localPlayer else {
            return nil
        }
        
        return match.participants.first { participant in
            participant.player?.gamePlayerID != localPlayer.gamePlayerID
        }?.player?.gamePlayerID
    }
    
    /// Get last opponent move from match state
    private func getLastOpponentMove(from matchState: MultiplayerGameState.MatchState) -> MultiplayerGameState.MoveData? {
        guard let localPlayer = gameCenterManager.localPlayer else { return nil }
        
        let isPlayer1 = matchState.player1.playerID == localPlayer.gamePlayerID
        let opponentMoves = isPlayer1 ? matchState.player2.moveHistory : matchState.player1.moveHistory
        
        return opponentMoves.last
    }
    // MARK: - Scoring Methods
    
    /// Determine the winner based on final scores
    func determineWinner() -> GameEndReason {
        return scoring.determineWinner(playerScore: score, opponentScore: opponentScore)
    }
    
    /// Handle game end with comprehensive scoring logic
    func handleGameEnd(reason: GameEndReason) {
        print("MultiplayerGameController.handleGameEnd: Handling game end with reason: \(reason)")
        
        gameEndReason = reason
        isGameOver = true
        
        // Use scoring system to handle the end
        scoring.handleGameEnd(reason: reason, playerScore: score, opponentScore: opponentScore)
        
        // Update game state with final results
        updateFinalGameState(endReason: reason)
        
        print("MultiplayerGameController.handleGameEnd: Game end handling complete")
    }
    
    /// Calculate final scores with bonuses and penalties
    func calculateFinalScores() -> (playerScore: Int, opponentScore: Int) {
        return scoring.calculateFinalScores(
            basePlayerScore: score,
            baseOpponentScore: opponentScore,
            endReason: gameEndReason
        )
    }
    
    /// Update scores during gameplay
    override func updateScore(_ newScore: Int) {
        super.updateScore(newScore)
        
        // Update scoring system with current scores
        scoring.updateScores(playerScore: score, opponentScore: opponentScore)
        
        // Check for score-based end conditions
        if let endReason = scoring.checkScoreEndConditions(playerScore: score, opponentScore: opponentScore) {
            handleGameEnd(reason: endReason)
        }
    }
    
    /// Get current multiplayer statistics
    func getMultiplayerStatistics() -> MultiplayerStatistics {
        return scoring.getCurrentStatistics()
    }
    
    // MARK: - Private Scoring Helpers
    
    /// Update final game state when game ends
    private func updateFinalGameState(endReason: GameEndReason) {
        guard let match = currentMatch else { return }
        
        // Calculate final scores
        let finalScores = calculateFinalScores()
        
        // Update local scores
        finalScore = finalScores.playerScore
        
        // Create final match state
        if var currentState = matchState {
            // Update the match state with final results
            if let localPlayer = gameCenterManager.localPlayer {
                let isPlayer1 = currentState.player1.playerID == localPlayer.gamePlayerID
                
                if isPlayer1 {
                    currentState.player1.score = finalScores.playerScore
                    currentState.player2.score = finalScores.opponentScore
                } else {
                    currentState.player2.score = finalScores.playerScore
                    currentState.player1.score = finalScores.opponentScore
                }
                
                currentState.isGameOver = true
                currentState.winner = determineWinnerPlayerID(endReason: endReason)
                
                matchState = currentState
            }
        }
        
        // End the match in Game Center
        endGameCenterMatch(endReason: endReason, finalScores: finalScores)
    }
    
    /// Determine winner player ID for Game Center
    private func determineWinnerPlayerID(endReason: GameEndReason) -> String? {
        guard let localPlayer = gameCenterManager.localPlayer else { return nil }
        
        switch endReason {
        case .playerWon, .opponentResigned:
            return localPlayer.gamePlayerID
        case .opponentWon, .playerResigned:
            return getOpponentPlayerID()
        case .connectionLost, .gameTimeout, .none:
            return nil // No winner for these cases
        }
    }
    
    /// End the Game Center match with results
    private func endGameCenterMatch(endReason: GameEndReason, finalScores: (playerScore: Int, opponentScore: Int)) {
        guard let match = currentMatch else { return }
        
        var outcome: GKTurnBasedMatch.Outcome
        
        switch endReason {
        case .playerWon, .opponentResigned:
            outcome = .won
        case .opponentWon, .playerResigned:
            outcome = .lost
        case .connectionLost, .gameTimeout:
            outcome = .quit
        case .none:
            outcome = .tied
        }
        
        // Serialize the final match state
        if var currentState = matchState {
            do {
                let matchData = try JSONEncoder().encode(currentState)
                turnBasedMatchManager.endMatch(match, matchData: matchData) { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("MultiplayerGameController: Match ended successfully in Game Center")
                        } else {
                            print("MultiplayerGameController: Failed to end match in Game Center: \(error?.localizedDescription ?? "Unknown error")")
                            self?.multiplayerError = "Failed to submit final results"
                        }
                        self?.notifyGameEnd()
                    }
                }
            } catch {
                print("MultiplayerGameController: Failed to serialize final match state: \(error)")
                multiplayerError = "Failed to prepare final results"
                notifyGameEnd()
            }
        } else {
            print("MultiplayerGameController: No match state available to serialize")
            multiplayerError = "No match state available"
            notifyGameEnd()
        }
    }
    
    // MARK: - Game End Notification
    
    /// Notify that the game has ended
    private func notifyGameEnd() {
        // Post notification about game end
        NotificationCenter.default.post(name: .multiplayerGameEnded, object: self)
        
        // Update game state for UI
        DispatchQueue.main.async { [weak self] in
            self?.isGameActive = false
        }
    }
    
    // MARK: - Override Parent Methods
    
    /// Override pause game to handle multiplayer considerations
    override func pauseGame() {
        super.pauseGame()
        // Note: In multiplayer, pausing only affects local display
        // Turn timer continues on server side
    }
    
    // MARK: - Move Validation Methods
    
    /// Check if current game state allows for valid moves
    func canPlayerMakeMove() -> Bool {
        guard let gameScene = gameScene else { return false }
        return gameScene.hasValidMoves()
    }
    
    /// Handle no moves available scenario
    func handleNoMovesAvailable() {
        print("MultiplayerGameController: No moves available for current player")
        
        // Check if opponent can still move (would need opponent game state)
        // For now, assume if local player can't move, game ends
        let endReason = scoring.determineWinner(playerScore: score, opponentScore: opponentScore)
        handleGameEnd(reason: endReason)
    }
}
