import Foundation
import SpriteKit

/// Handles game synchronization between multiplayer participants
class MultiplayerSynchronization {
    
    private weak var gameController: MultiplayerGameController?
    private weak var gameScene: GameScene?
    
    init(gameController: MultiplayerGameController) {
        self.gameController = gameController
        self.gameScene = gameController.gameScene
    }
    
    /// Generate synchronized pieces for all players using fair piece generation
    func generateSynchronizedPieces(from matchState: MultiplayerGameState.MatchState) -> [TetrominoShape] {
        print("MultiplayerSynchronization: Generating pieces from match state (seed: \(matchState.randomSeed), turn: \(matchState.turnNumber))")
        
        // Create multiplayer context
        let context = TetrominoShape.MultiplayerContext(
            seed: matchState.randomSeed,
            turnNumber: matchState.turnNumber,
            selectionMode: .strategicWeighted, // Use strategic weighted for multiplayer fairness
            gameBoard: gameController?.gameScene?.gameBoard,
            gameController: gameController
        )
        
        // Generate synchronized pieces using the fair piece generation system
        let synchronizedPieces = TetrominoShape.generateSyncedPieces(count: 3, context: context)
        
        // Validate the generated pieces
        let isValid = TetrominoShape.validatePieceSync(pieces: synchronizedPieces, expectedCount: 3)
        if !isValid {
            print("MultiplayerSynchronization: ERROR - Generated pieces failed validation!")
            // Fall back to match state pieces if validation fails
            return matchState.currentPieces.compactMap { $0.toGridPiece()?.shape }
        }
        
        // Update game scene with synchronized pieces
        if let gameScene = gameScene {
            gameScene.setSynchronizedPieces(synchronizedPieces)
        }
        
        // Log accessibility information
        let accessibilityDescription = TetrominoShape.accessibilityDescriptionForSyncedPieces(synchronizedPieces)
        print("MultiplayerSynchronization: \(accessibilityDescription)")
        
        print("MultiplayerSynchronization: Successfully generated \(synchronizedPieces.count) synchronized pieces")
        return synchronizedPieces
    }
    
    /// Generate new synchronized pieces for the next turn
    func generateNewTurnPieces(currentSeed: UInt64, turnNumber: Int, selectionMode: TetrominoShape.SelectionMode = .strategicWeighted) -> [TetrominoShape] {
        print("MultiplayerSynchronization: Generating new turn pieces for turn \(turnNumber)")
        
        // Set the shared seed for synchronization
        TetrominoShape.setSeed(currentSeed)
        
        // Create context for new turn
        let context = TetrominoShape.MultiplayerContext(
            seed: currentSeed,
            turnNumber: turnNumber,
            selectionMode: selectionMode,
            gameBoard: gameController?.gameScene?.gameBoard,
            gameController: gameController
        )
        
        // Generate pieces
        let pieces = TetrominoShape.generateSyncedPieces(count: 3, context: context)
        
        // Voice-over accessibility
        let voiceOverDescription = TetrominoShape.voiceOverDescriptionForPieceGeneration(seed: currentSeed, turnNumber: turnNumber)
        print("MultiplayerSynchronization: \(voiceOverDescription)")
        
        return pieces
    }
    
    /// Create turn data for submission
    func createTurnData() -> MultiplayerGameState.MoveData {
        // Create a dummy GridPiece for now - in real implementation this would come from the game
        let dummyShape = TetrominoShape.allCases.randomElement() ?? TetrominoShape.squareSmall
        let dummyGridPiece = GridPiece(shape: dummyShape, color: dummyShape.color)
        let dummyPlacement = GridCell(column: 0, row: 0)
        
        return MultiplayerGameState.MoveData(
            piece: dummyGridPiece,
            placement: dummyPlacement,
            scoreGained: 10, // This should come from actual game logic
            linesCleared: 0  // This should come from actual game logic
        )
    }
    
    /// Validate board state consistency between players
    func validateBoardState(localBoard: [[GridCell?]], remoteBoard: [[GridCell?]]) -> Bool {
        guard localBoard.count == remoteBoard.count else { return false }
        
        for (rowIndex, localRow) in localBoard.enumerated() {
            guard localRow.count == remoteBoard[rowIndex].count else { return false }
            
            for (colIndex, localCell) in localRow.enumerated() {
                let remoteCell = remoteBoard[rowIndex][colIndex]
                
                // Compare cell states (simplified comparison)
                if (localCell == nil) != (remoteCell == nil) {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Synchronize piece generation using a shared seed
    func generatePiecesWithSeed(_ seed: UInt32, count: Int) -> [TetrominoShape] {
        var generator = MultiplayerGameState.SeededRandomGenerator(seed: UInt64(seed))
        var pieces: [TetrominoShape] = []
        
        for _ in 0..<count {
            let randomValue = generator.next()
            let randomCase = Int(randomValue % UInt64(TetrominoShape.allCases.count))
            pieces.append(TetrominoShape.allCases[randomCase])
        }
        
        return pieces
    }
    
    // MARK: - Edge Case Handling
    
    /// Handle disconnection and resync scenarios for piece synchronization
    func handleResyncScenario(localPieces: [TetrominoShape], remotePieces: [TetrominoShape], matchState: MultiplayerGameState.MatchState) -> ResyncResult {
        print("MultiplayerSynchronization: Handling resync scenario")
        
        // Check if pieces are already synchronized
        if localPieces.count == remotePieces.count && localPieces == remotePieces {
            print("MultiplayerSynchronization: Pieces already synchronized")
            return .alreadySynced
        }
        
        // Validate piece counts
        guard localPieces.count == 3 && remotePieces.count == 3 else {
            print("MultiplayerSynchronization: Invalid piece counts - local: \(localPieces.count), remote: \(remotePieces.count)")
            return .regenerateRequired(reason: "Invalid piece counts")
        }
        
        // Attempt to regenerate from match state
        let regeneratedPieces = generateSynchronizedPieces(from: matchState)
        
        // Validate regenerated pieces
        if TetrominoShape.validatePieceSync(pieces: regeneratedPieces, expectedCount: 3) {
            print("MultiplayerSynchronization: Successfully regenerated synchronized pieces")
            return .resyncSuccessful(pieces: regeneratedPieces)
        } else {
            print("MultiplayerSynchronization: Regeneration failed, requesting new seed")
            return .newSeedRequired
        }
    }
    
    /// Validate that local and remote piece sets match
    func validatePieceSynchronization(localPieces: [TetrominoShape], remotePieces: [TetrominoShape]) -> Bool {
        guard localPieces.count == remotePieces.count else {
            print("MultiplayerSynchronization: Piece count mismatch - local: \(localPieces.count), remote: \(remotePieces.count)")
            return false
        }
        
        // Check if pieces match exactly
        let localSorted = localPieces.sorted { $0.displayName < $1.displayName }
        let remoteSorted = remotePieces.sorted { $0.displayName < $1.displayName }
        
        let isMatch = localSorted.elementsEqual(remoteSorted) { $0 == $1 }
        
        if isMatch {
            print("MultiplayerSynchronization: Piece synchronization validated successfully")
        } else {
            print("MultiplayerSynchronization: Piece synchronization FAILED")
            print("  Local pieces: \(localPieces.map { $0.displayName })")
            print("  Remote pieces: \(remotePieces.map { $0.displayName })")
        }
        
        return isMatch
    }
    
    /// Handle connection issues and maintain game state
    func handleConnectionIssue(lastKnownMatchState: MultiplayerGameState.MatchState) -> ConnectionRecoveryAction {
        print("MultiplayerSynchronization: Handling connection issue")
        
        // Check if we can continue with last known state
        if lastKnownMatchState.isValid {
            print("MultiplayerSynchronization: Using last known valid match state")
            
            // Generate pieces from last known state
            let pieces = generateSynchronizedPieces(from: lastKnownMatchState)
            
            if TetrominoShape.validatePieceSync(pieces: pieces, expectedCount: 3) {
                return .continueWithLastState(pieces: pieces)
            }
        }
        
        print("MultiplayerSynchronization: Requesting full resync")
        return .requestFullResync
    }
    
    /// Generate emergency fallback pieces when synchronization fails
    func generateFallbackPieces(forPlayer playerID: String) -> [TetrominoShape] {
        print("MultiplayerSynchronization: Generating fallback pieces for player \(playerID)")
        
        // Use a deterministic fallback based on player ID to ensure some consistency
        let playerHash = playerID.hash
        let fallbackSeed = UInt64(abs(playerHash))
        
        // Create emergency context
        let context = TetrominoShape.MultiplayerContext(
            seed: fallbackSeed,
            turnNumber: 1,
            selectionMode: .balanced // Use balanced mode for fallback
        )
        
        let fallbackPieces = TetrominoShape.generateSyncedPieces(count: 3, context: context)
        
        print("MultiplayerSynchronization: Generated fallback pieces: \(fallbackPieces.map { $0.displayName })")
        return fallbackPieces
    }
    
    // MARK: - Resync Result Types
    
    enum ResyncResult {
        case alreadySynced
        case resyncSuccessful(pieces: [TetrominoShape])
        case regenerateRequired(reason: String)
        case newSeedRequired
    }
    
    enum ConnectionRecoveryAction {
        case continueWithLastState(pieces: [TetrominoShape])
        case requestFullResync
    }
}


