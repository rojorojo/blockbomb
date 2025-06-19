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
    private lazy var accessibility = MultiplayerAccessibility(gameController: self)
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupMultiplayerObservers()
        accessibility.setupAccessibilitySupport()
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
        
        gameEndReason = reason
        matchManager.endMatch(reason: reason)
        
        // Announce game end for accessibility
        let message = accessibility.getGameEndAccessibilityMessage(for: reason)
        accessibility.announceAccessibilityUpdate(message)
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
    
    // MARK: - Override Parent Methods
    
    /// Override pause game to handle multiplayer considerations
    override func pauseGame() {
        super.pauseGame()
        // Note: In multiplayer, pausing only affects local display
        // Turn timer continues on server side
    }
}
