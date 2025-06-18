import Foundation
import GameKit
import UIKit

/// Manages turn-based match operations for BlockBomb multiplayer gameplay
/// Handles match creation, loading, management, and Game Center turn-based functionality
class TurnBasedMatchManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = TurnBasedMatchManager()
    
    // MARK: - Published Properties
    @Published var activeMatches: [GKTurnBasedMatch] = []
    @Published var isLoadingMatches = false
    @Published var isCreatingMatch = false
    @Published var isSubmittingTurn = false
    @Published var matchError: String?
    @Published var currentMatch: GKTurnBasedMatch?
    
    // MARK: - Private Properties
    private var gameCenterManager: GameCenterManager
    private var matchCreationCompletion: ((GKTurnBasedMatch?, Error?) -> Void)?
    private var turnSubmissionCompletion: ((Bool, Error?) -> Void)?
    private var matchLoadCompletion: (([GKTurnBasedMatch], Error?) -> Void)?
    
    // MARK: - Configuration
    private let maxPlayers = 2
    private let minPlayers = 2
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    private var retryCount = 0
    
    // MARK: - Initialization
    private override init() {
        self.gameCenterManager = GameCenterManager.shared
        super.init()
        setupTurnBasedMatchHandler()
        loadMatches()
    }
    
    // MARK: - Setup Methods
    
    /// Set up turn-based match event handling
    private func setupTurnBasedMatchHandler() {
        print("TurnBasedMatchManager: Setting up turn-based match handler")
        
        guard let localPlayer = gameCenterManager.localPlayer else {
            print("TurnBasedMatchManager: Error - Local player not available")
            return
        }
        
        // Set up turn-based match event handler for push notifications
        localPlayer.register(self)
    }
    
    // MARK: - Match Creation
    
    /// Create a new turn-based match with specified parameters
    /// - Parameters:
    ///   - inviteMessage: Custom message for match invitation
    ///   - completion: Completion handler with created match or error
    func createMatch(inviteMessage: String = "Let's play BlockBomb!", completion: @escaping (GKTurnBasedMatch?, Error?) -> Void) {
        print("TurnBasedMatchManager: Creating new match")
        
        guard gameCenterManager.isPlayerAuthenticated() else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Player not authenticated with Game Center"])
            completion(nil, error)
            return
        }
        
        isCreatingMatch = true
        matchError = nil
        matchCreationCompletion = completion
        
        let matchRequest = GKMatchRequest()
        matchRequest.minPlayers = minPlayers
        matchRequest.maxPlayers = maxPlayers
        matchRequest.inviteMessage = inviteMessage
        
        // Present match maker view controller
        presentMatchMakerViewController(matchRequest: matchRequest)
    }
    
    /// Present the Game Center match maker interface
    /// - Parameter matchRequest: The match request configuration
    private func presentMatchMakerViewController(matchRequest: GKMatchRequest) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -2, 
                              userInfo: [NSLocalizedDescriptionKey: "Cannot find root view controller"])
            handleMatchCreationResult(match: nil, error: error)
            return
        }
        
        let matchMakerViewController = GKTurnBasedMatchmakerViewController(matchRequest: matchRequest)
        matchMakerViewController.turnBasedMatchmakerDelegate = self
        
        // Set accessibility properties
        matchMakerViewController.view.accessibilityLabel = "Game Center Match Maker"
        matchMakerViewController.view.accessibilityHint = "Create or join a multiplayer match"
        
        rootViewController.present(matchMakerViewController, animated: true) {
            print("TurnBasedMatchManager: Match maker presented")
        }
    }
    
    /// Create a match with random opponents
    /// - Parameters:
    ///   - completion: Completion handler with created match or error
    func createMatchWithRandomOpponents(completion: @escaping (GKTurnBasedMatch?, Error?) -> Void) {
        print("TurnBasedMatchManager: Creating match with random opponents")
        
        guard gameCenterManager.isPlayerAuthenticated() else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Player not authenticated with Game Center"])
            completion(nil, error)
            return
        }
        
        isCreatingMatch = true
        matchError = nil
        
        let matchRequest = GKMatchRequest()
        matchRequest.minPlayers = minPlayers
        matchRequest.maxPlayers = maxPlayers
        
        GKTurnBasedMatch.find(for: matchRequest) { [weak self] match, error in
            DispatchQueue.main.async {
                self?.handleMatchCreationResult(match: match, error: error)
                completion(match, error)
            }
        }
    }
    
    /// Handle the result of match creation
    /// - Parameters:
    ///   - match: The created match (if successful)
    ///   - error: Any error that occurred during creation
    private func handleMatchCreationResult(match: GKTurnBasedMatch?, error: Error?) {
        isCreatingMatch = false
        
        if let error = error {
            print("TurnBasedMatchManager: Match creation failed: \(error.localizedDescription)")
            matchError = error.localizedDescription
            matchCreationCompletion?(nil, error)
        } else if let match = match {
            print("TurnBasedMatchManager: Match created successfully: \(match.matchID)")
            currentMatch = match
            matchError = nil
            addMatchToActiveList(match)
            matchCreationCompletion?(match, nil)
        }
        
        matchCreationCompletion = nil
    }
    
    // MARK: - Match Loading
    
    /// Load all active matches for the current player
    /// - Parameter completion: Optional completion handler with matches and error
    func loadMatches(completion: (([GKTurnBasedMatch], Error?) -> Void)? = nil) {
        print("TurnBasedMatchManager: Loading matches")
        
        guard gameCenterManager.isPlayerAuthenticated() else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Player not authenticated with Game Center"])
            completion?([], error)
            return
        }
        
        isLoadingMatches = true
        matchError = nil
        matchLoadCompletion = completion
        
        GKTurnBasedMatch.loadMatches { [weak self] matches, error in
            DispatchQueue.main.async {
                self?.handleMatchLoadResult(matches: matches, error: error)
            }
        }
    }
    
    /// Handle the result of loading matches
    /// - Parameters:
    ///   - matches: The loaded matches (if successful)
    ///   - error: Any error that occurred during loading
    private func handleMatchLoadResult(matches: [GKTurnBasedMatch]?, error: Error?) {
        isLoadingMatches = false
        
        if let error = error {
            print("TurnBasedMatchManager: Match loading failed: \(error.localizedDescription)")
            matchError = error.localizedDescription
            
            // Retry logic for transient errors
            if retryCount < maxRetryAttempts && shouldRetryOperation(error: error) {
                scheduleRetryLoadMatches()
            } else {
                matchLoadCompletion?([], error)
            }
        } else if let matches = matches {
            print("TurnBasedMatchManager: Loaded \(matches.count) matches")
            activeMatches = matches.filter { match in
                match.status == .open || match.status == .matching
            }
            matchError = nil
            retryCount = 0
            matchLoadCompletion?(matches, nil)
        }
        
        matchLoadCompletion = nil
    }
    
    // MARK: - Turn Management
    
    /// Submit a turn with the current game state
    /// - Parameters:
    ///   - match: The match to submit the turn for
    ///   - matchData: Serialized game state data
    ///   - completion: Completion handler with success status and error
    func submitTurn(for match: GKTurnBasedMatch, matchData: Data, completion: @escaping (Bool, Error?) -> Void) {
        print("TurnBasedMatchManager: Submitting turn for match: \(match.matchID)")
        
        guard gameCenterManager.isPlayerAuthenticated() else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Player not authenticated with Game Center"])
            completion(false, error)
            return
        }
        
        isSubmittingTurn = true
        matchError = nil
        turnSubmissionCompletion = completion
        
        // Find next participant (opponent)
        guard let nextParticipant = getNextParticipant(in: match) else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -3, 
                              userInfo: [NSLocalizedDescriptionKey: "Cannot find next participant"])
            handleTurnSubmissionResult(success: false, error: error)
            return
        }
        
        match.endTurn(withNextParticipants: [nextParticipant], 
                      turnTimeout: GKTurnTimeoutDefault, 
                      match: matchData) { [weak self] error in
            DispatchQueue.main.async {
                self?.handleTurnSubmissionResult(success: error == nil, error: error)
            }
        }
    }
    
    /// Get the next participant for turn submission
    /// - Parameter match: The current match
    /// - Returns: The next participant or nil if not found
    private func getNextParticipant(in match: GKTurnBasedMatch) -> GKTurnBasedParticipant? {
        guard let localPlayer = gameCenterManager.localPlayer else { return nil }
        
        // Find opponent (participant who is not the local player)
        return match.participants.first { participant in
            participant.player?.gamePlayerID != localPlayer.gamePlayerID
        }
    }
    
    /// Handle the result of turn submission
    /// - Parameters:
    ///   - success: Whether the turn submission was successful
    ///   - error: Any error that occurred during submission
    private func handleTurnSubmissionResult(success: Bool, error: Error?) {
        isSubmittingTurn = false
        
        if let error = error {
            print("TurnBasedMatchManager: Turn submission failed: \(error.localizedDescription)")
            matchError = error.localizedDescription
        } else {
            print("TurnBasedMatchManager: Turn submitted successfully")
            matchError = nil
        }
        
        turnSubmissionCompletion?(success, error)
        turnSubmissionCompletion = nil
        
        // Reload matches to update status
        loadMatches()
    }
    
    // MARK: - Match Lifecycle
    
    /// End a match with the final game state
    /// - Parameters:
    ///   - match: The match to end
    ///   - matchData: Final game state data  
    ///   - completion: Completion handler with success status and error
    func endMatch(_ match: GKTurnBasedMatch, matchData: Data, completion: @escaping (Bool, Error?) -> Void) {
        print("TurnBasedMatchManager: Ending match: \(match.matchID)")
        
        guard gameCenterManager.isPlayerAuthenticated() else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Player not authenticated with Game Center"])
            completion(false, error)
            return
        }
        
        // Calculate match outcome for each participant
        let _ = calculateMatchOutcomes(for: match, finalData: matchData)
        
        match.endMatchInTurn(withMatch: matchData, completionHandler: { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("TurnBasedMatchManager: Match end failed: \(error.localizedDescription)")
                    self?.matchError = error.localizedDescription
                    completion(false, error)
                } else {
                    print("TurnBasedMatchManager: Match ended successfully")
                    self?.matchError = nil
                    self?.removeMatchFromActiveList(match)
                    completion(true, nil)
                }
                
                // Reload matches to update status
                self?.loadMatches()
            }
        })
    }
    
    /// Calculate match outcomes for participants
    /// - Parameters:
    ///   - match: The match to calculate outcomes for
    ///   - finalData: Final game state data
    /// - Returns: Array of match outcomes for each participant
    private func calculateMatchOutcomes(for match: GKTurnBasedMatch, finalData: Data) -> [GKTurnBasedMatch.Outcome] {
        // For now, return default outcomes - this will be enhanced when game state is implemented
        return match.participants.map { _ in GKTurnBasedMatch.Outcome.none }
    }
    
    /// Quit a match (resign)
    /// - Parameters:
    ///   - match: The match to quit
    ///   - completion: Completion handler with success status and error
    func quitMatch(_ match: GKTurnBasedMatch, completion: @escaping (Bool, Error?) -> Void) {
        print("TurnBasedMatchManager: Quitting match: \(match.matchID)")
        
        guard gameCenterManager.isPlayerAuthenticated() else {
            let error = NSError(domain: "TurnBasedMatchManager", 
                              code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Player not authenticated with Game Center"])
            completion(false, error)
            return
        }
        
        match.participantQuitInTurn(with: .quit, nextParticipants: [], turnTimeout: 0, match: match.matchData ?? Data()) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("TurnBasedMatchManager: Match quit failed: \(error.localizedDescription)")
                    self?.matchError = error.localizedDescription
                    completion(false, error)
                } else {
                    print("TurnBasedMatchManager: Match quit successfully")
                    self?.matchError = nil
                    self?.removeMatchFromActiveList(match)
                    completion(true, nil)
                }
                
                // Reload matches to update status
                self?.loadMatches()
            }
        }
    }
    
    // MARK: - Match Data Serialization
    
    /// Serialize game state data for match storage
    /// - Parameter gameState: The game state to serialize
    /// - Returns: Serialized data or nil if serialization fails
    func serializeMatchData<T: Codable>(_ gameState: T) -> Data? {
        do {
            let data = try JSONEncoder().encode(gameState)
            print("TurnBasedMatchManager: Serialized match data (\(data.count) bytes)")
            return data
        } catch {
            print("TurnBasedMatchManager: Match data serialization failed: \(error.localizedDescription)")
            matchError = "Failed to serialize game state"
            return nil
        }
    }
    
    /// Deserialize game state data from match storage
    /// - Parameters:
    ///   - data: The data to deserialize
    ///   - type: The type to deserialize to
    /// - Returns: Deserialized game state or nil if deserialization fails
    func deserializeMatchData<T: Codable>(_ data: Data, as type: T.Type) -> T? {
        do {
            let gameState = try JSONDecoder().decode(type, from: data)
            print("TurnBasedMatchManager: Deserialized match data")
            return gameState
        } catch {
            print("TurnBasedMatchManager: Match data deserialization failed: \(error.localizedDescription)")
            matchError = "Failed to deserialize game state"
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    /// Add a match to the active matches list
    /// - Parameter match: The match to add
    private func addMatchToActiveList(_ match: GKTurnBasedMatch) {
        if !activeMatches.contains(where: { $0.matchID == match.matchID }) {
            activeMatches.append(match)
        }
    }
    
    /// Remove a match from the active matches list
    /// - Parameter match: The match to remove
    private func removeMatchFromActiveList(_ match: GKTurnBasedMatch) {
        activeMatches.removeAll { $0.matchID == match.matchID }
    }
    
    /// Determine if an operation should be retried for the given error
    /// - Parameter error: The error to evaluate
    /// - Returns: True if retry should be attempted, false otherwise
    private func shouldRetryOperation(error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == GKErrorDomain && 
               nsError.code == GKError.communicationsFailure.rawValue
    }
    
    /// Schedule a retry of match loading after a delay
    private func scheduleRetryLoadMatches() {
        retryCount += 1
        print("TurnBasedMatchManager: Scheduling match load retry \(retryCount)/\(maxRetryAttempts) in \(retryDelay) seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            self?.loadMatches()
        }
    }
    
    /// Reset all state (useful for testing)
    func resetState() {
        print("TurnBasedMatchManager: Resetting state")
        activeMatches = []
        isLoadingMatches = false
        isCreatingMatch = false
        isSubmittingTurn = false
        matchError = nil
        currentMatch = nil
        retryCount = 0
        matchCreationCompletion = nil
        turnSubmissionCompletion = nil
        matchLoadCompletion = nil
    }
}

// MARK: - GKTurnBasedMatchmakerViewControllerDelegate

extension TurnBasedMatchManager: GKTurnBasedMatchmakerViewControllerDelegate {
    
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        print("TurnBasedMatchManager: Match maker cancelled")
        viewController.dismiss(animated: true)
        
        let error = NSError(domain: "TurnBasedMatchManager", 
                          code: -4, 
                          userInfo: [NSLocalizedDescriptionKey: "Match creation cancelled by user"])
        handleMatchCreationResult(match: nil, error: error)
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        print("TurnBasedMatchManager: Match maker failed with error: \(error.localizedDescription)")
        viewController.dismiss(animated: true)
        handleMatchCreationResult(match: nil, error: error)
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFind match: GKTurnBasedMatch) {
        print("TurnBasedMatchManager: Match maker found match: \(match.matchID)")
        viewController.dismiss(animated: true)
        handleMatchCreationResult(match: match, error: nil)
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, playerQuitFor match: GKTurnBasedMatch) {
        print("TurnBasedMatchManager: Player quit match: \(match.matchID)")
        removeMatchFromActiveList(match)
    }
}

// MARK: - GKLocalPlayerListener

extension TurnBasedMatchManager: GKLocalPlayerListener {
    
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        print("TurnBasedMatchManager: Received turn event for match: \(match.matchID), active: \(didBecomeActive)")
        
        DispatchQueue.main.async { [weak self] in
            // Update active matches
            self?.addMatchToActiveList(match)
            
            // Post accessibility notification
            if didBecomeActive {
                UIAccessibility.post(notification: .announcement, 
                                   argument: "It's your turn in BlockBomb multiplayer match")
            }
        }
    }
    
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        print("TurnBasedMatchManager: Match ended: \(match.matchID)")
        
        DispatchQueue.main.async { [weak self] in
            self?.removeMatchFromActiveList(match)
            
            // Post accessibility notification
            UIAccessibility.post(notification: .announcement, 
                               argument: "BlockBomb multiplayer match has ended")
        }
    }
    
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        print("TurnBasedMatchManager: Player wants to quit match: \(match.matchID)")
        
        // Handle quit request - for now just remove from active list
        DispatchQueue.main.async { [weak self] in
            self?.removeMatchFromActiveList(match)
        }
    }
}
