import Foundation
import SpriteKit

/// Manages multiplayer game state synchronization and serialization for turn-based matches
/// Handles game state for both players, piece synchronization, and turn management
class MultiplayerGameState {
    
    // MARK: - Game State Structures
    
    /// Complete multiplayer match state that can be serialized and synchronized
    struct MatchState: Codable {
        let gameVersion: String
        let matchID: String
        let player1: PlayerState
        let player2: PlayerState
        let currentTurnPlayerID: String  // Player ID whose turn it is
        let turnNumber: Int
        let randomSeed: UInt64
        let currentPieces: [PieceData]  // Synchronized pieces for current turn
        let matchStartTime: Date
        let lastUpdateTime: Date
        var isGameEnded: Bool = false
        var gameEndTime: Date?
        var winner: String?
        
        /// Check if the match state is valid and not corrupted
        var isValid: Bool {
            return !matchID.isEmpty &&
                   !player1.playerID.isEmpty &&
                   !player2.playerID.isEmpty &&
                   currentPieces.count == 3 &&
                   turnNumber >= 0
        }
        
        /// Get the current player state
        func getCurrentPlayerState() -> PlayerState {
            return currentTurnPlayerID == player1.playerID ? player1 : player2
        }
        
        /// Get the opponent player state
        func getOpponentPlayerState() -> PlayerState {
            return currentTurnPlayerID == player1.playerID ? player2 : player1
        }
    }
    
    /// Individual player state within a match
    struct PlayerState: Codable {
        let playerID: String
        let displayName: String?
        var score: Int
        var boardState: [[String?]]  // 8x8 grid state (color names for filled cells)
        var isGameOver: Bool
        var moveHistory: [MoveData]  // History of moves made
        var lastMoveTime: Date?
        
        /// Initialize with empty 8x8 board
        init(playerID: String, displayName: String? = nil) {
            self.playerID = playerID
            self.displayName = displayName
            self.score = 0
            self.boardState = Array(repeating: Array(repeating: nil, count: 8), count: 8)
            self.isGameOver = false
            self.moveHistory = []
            self.lastMoveTime = nil
        }
        
        /// Count filled cells on the board
        var filledCellCount: Int {
            return boardState.flatMap { $0 }.compactMap { $0 }.count
        }
        
        /// Check if the board is full (game over condition)
        var isBoardFull: Bool {
            return filledCellCount >= 64
        }
    }
    
    /// Data structure for individual pieces in the game
    struct PieceData: Codable {
        let shape: String  // TetrominoShape display name
        let colorName: String
        let cells: [CellPosition]  // Relative cell positions
        
        init(from gridPiece: GridPiece) {
            self.shape = gridPiece.shape.displayName
            self.colorName = extractColorName(from: gridPiece.color)
            self.cells = gridPiece.cells.map { CellPosition(row: $0.row, column: $0.column) }
        }
        
        /// Convert back to GridPiece for game use
        func toGridPiece() -> GridPiece? {
            guard let tetrominoShape = TetrominoShape.fromDisplayName(shape) else {
                print("MultiplayerGameState: Cannot convert piece data - unknown shape: \(shape)")
                return nil
            }
            
            let color = colorFromName(colorName)
            return GridPiece(shape: tetrominoShape, color: color)
        }
    }
    
    /// Individual move data for move history tracking
    struct MoveData: Codable {
        let pieceShape: String
        let placement: CellPosition  // Where the piece was placed (origin cell)
        let scoreGained: Int
        let linesCleared: Int
        let timestamp: Date
        
        init(piece: GridPiece, placement: GridCell, scoreGained: Int, linesCleared: Int) {
            self.pieceShape = piece.shape.displayName
            self.placement = CellPosition(row: placement.row, column: placement.column)
            self.scoreGained = scoreGained
            self.linesCleared = linesCleared
            self.timestamp = Date()
        }
    }
    
    /// Grid cell position for serialization
    struct CellPosition: Codable {
        let row: Int
        let column: Int
        
        /// Convert to GridCell for game use
        func toGridCell() -> GridCell {
            return GridCell(column: column, row: row)
        }
    }
    
    // MARK: - Constants
    private static let gameVersion = "1.0.0"
    private static let maxTurnTime: TimeInterval = 86400 // 24 hours
    
    // MARK: - Synchronized Piece Generation
    
    /// Generate synchronized pieces for both players using shared random seed
    /// - Parameters:
    ///   - seed: Random seed for deterministic generation
    ///   - selectionMode: Piece selection mode to use
    /// - Returns: Array of 3 synchronized pieces
    static func generateSyncedPieces(seed: UInt64, selectionMode: TetrominoShape.SelectionMode = .strategicWeighted) -> [PieceData] {
        print("MultiplayerGameState: Generating synced pieces with seed: \(seed)")
        
        // Create deterministic random generator with shared seed
        var generator = MultiplayerGameState.SeededRandomGenerator(seed: seed)
        
        // Generate 3 pieces using the seeded generator
        var pieces: [PieceData] = []
        for _ in 0..<3 {
            let shape = TetrominoShape.generatePiece(using: &generator, mode: selectionMode)
            let color = BlockColors.getRandomColor(using: &generator)
            let gridPiece = GridPiece(shape: shape, color: color)
            pieces.append(PieceData(from: gridPiece))
        }
        
        print("MultiplayerGameState: Generated pieces: \(pieces.map { $0.shape })")
        return pieces
    }
    
    /// Generate a new random seed for piece synchronization
    /// - Returns: Random seed value
    static func generateNewSeed() -> UInt64 {
        return UInt64.random(in: 0...UInt64.max)
    }
    
    // MARK: - Match State Management
    
    /// Create initial match state for a new game
    /// - Parameters:
    ///   - matchID: Game Center match ID
    ///   - player1ID: First player's Game Center ID
    ///   - player2ID: Second player's Game Center ID
    ///   - player1Name: First player's display name
    ///   - player2Name: Second player's display name
    /// - Returns: Initial match state
    static func createInitialMatchState(
        matchID: String,
        player1ID: String,
        player2ID: String,
        player1Name: String? = nil,
        player2Name: String? = nil
    ) -> MatchState {
        let player1 = PlayerState(playerID: player1ID, displayName: player1Name)
        let player2 = PlayerState(playerID: player2ID, displayName: player2Name)
        
        let seed = generateNewSeed()
        let initialPieces = generateSyncedPieces(seed: seed)
        
        return MatchState(
            gameVersion: gameVersion,
            matchID: matchID,
            player1: player1,
            player2: player2,
            currentTurnPlayerID: player1ID, // Player 1 starts
            turnNumber: 1,
            randomSeed: seed,
            currentPieces: initialPieces,
            matchStartTime: Date(),
            lastUpdateTime: Date()
        )
    }
    
    /// Advance to the next turn in the match
    /// - Parameters:
    ///   - currentState: Current match state
    ///   - move: Move data for the completed turn
    ///   - updatedPlayerState: Updated player state after the move
    /// - Returns: New match state for the next turn
    static func advanceToNextTurn(
        currentState: MatchState,
        move: MoveData,
        updatedPlayerState: PlayerState
    ) -> MatchState {
        let nextPlayerID = currentState.currentTurnPlayerID == currentState.player1.playerID ? 
                          currentState.player2.playerID : currentState.player1.playerID
        
        let newSeed = generateNewSeed()
        let newPieces = generateSyncedPieces(seed: newSeed, selectionMode: .strategicWeighted)
        
        // Update the appropriate player state
        var newPlayer1 = currentState.player1
        var newPlayer2 = currentState.player2
        
        if currentState.currentTurnPlayerID == currentState.player1.playerID {
            newPlayer1 = updatedPlayerState
            newPlayer1.moveHistory.append(move)
        } else {
            newPlayer2 = updatedPlayerState
            newPlayer2.moveHistory.append(move)
        }
        
        return MatchState(
            gameVersion: currentState.gameVersion,
            matchID: currentState.matchID,
            player1: newPlayer1,
            player2: newPlayer2,
            currentTurnPlayerID: nextPlayerID,
            turnNumber: currentState.turnNumber + 1,
            randomSeed: newSeed,
            currentPieces: newPieces,
            matchStartTime: currentState.matchStartTime,
            lastUpdateTime: Date()
        )
    }
    
    // MARK: - Serialization Methods
    
    /// Encode match state to Data for Game Center storage
    /// - Parameter matchState: The match state to encode
    /// - Returns: Encoded data or nil if encoding fails
    static func encodeMatchData(_ matchState: MatchState) -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(matchState)
            print("MultiplayerGameState: Encoded match data (\(data.count) bytes)")
            return data
        } catch {
            print("MultiplayerGameState: Failed to encode match data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Decode match state from Data retrieved from Game Center
    /// - Parameter data: The data to decode
    /// - Returns: Decoded match state or nil if decoding fails
    static func decodeMatchData(_ data: Data) -> MatchState? {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let matchState = try decoder.decode(MatchState.self, from: data)
            
            guard matchState.isValid else {
                print("MultiplayerGameState: Decoded match state is invalid")
                return nil
            }
            
            print("MultiplayerGameState: Decoded match data successfully")
            return matchState
        } catch {
            print("MultiplayerGameState: Failed to decode match data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Game State Validation
    
    /// Validate a player's turn to prevent cheating and ensure consistency
    /// - Parameters:
    ///   - move: The move to validate
    ///   - currentState: Current match state
    ///   - playerID: ID of the player making the move
    /// - Returns: True if the move is valid, false otherwise
    static func validateTurn(move: MoveData, currentState: MatchState, playerID: String) -> Bool {
        // Check if it's the player's turn
        guard currentState.currentTurnPlayerID == playerID else {
            print("MultiplayerGameState: Invalid turn - not player's turn")
            return false
        }
        
        // Check if the piece exists in current pieces
        let pieceExists = currentState.currentPieces.contains { $0.shape == move.pieceShape }
        guard pieceExists else {
            print("MultiplayerGameState: Invalid turn - piece not available")
            return false
        }
        
        // Validate placement position is within bounds
        let placement = move.placement
        guard placement.row >= 0 && placement.row < 8 && 
              placement.column >= 0 && placement.column < 8 else {
            print("MultiplayerGameState: Invalid turn - placement out of bounds")
            return false
        }
        
        // Additional validation could include:
        // - Check if placement doesn't overlap with existing pieces
        // - Validate score calculation
        // - Verify lines cleared count
        
        print("MultiplayerGameState: Turn validation passed")
        return true
    }
    
    /// Validate entire match state for consistency and integrity
    /// - Parameter matchState: The match state to validate
    /// - Returns: Validation result with details
    static func validateMatchState(_ matchState: MatchState) -> ValidationResult {
        var issues: [String] = []
        
        // Check basic validity
        if !matchState.isValid {
            issues.append("Basic match state validation failed")
        }
        
        // Check game version compatibility
        if matchState.gameVersion != gameVersion {
            issues.append("Game version mismatch: \(matchState.gameVersion) vs \(gameVersion)")
        }
        
        // Validate board states
        for (playerNum, playerState) in [(1, matchState.player1), (2, matchState.player2)] {
            if playerState.boardState.count != 8 {
                issues.append("Player \(playerNum) board has invalid row count: \(playerState.boardState.count)")
            }
            
            for (rowIndex, row) in playerState.boardState.enumerated() {
                if row.count != 8 {
                    issues.append("Player \(playerNum) row \(rowIndex) has invalid column count: \(row.count)")
                }
            }
            
            if playerState.score < 0 {
                issues.append("Player \(playerNum) has negative score: \(playerState.score)")
            }
        }
        
        // Validate turn consistency
        if matchState.currentTurnPlayerID != matchState.player1.playerID && 
           matchState.currentTurnPlayerID != matchState.player2.playerID {
            issues.append("Invalid current turn player ID")
        }
        
        // Check piece data
        if matchState.currentPieces.count != 3 {
            issues.append("Invalid piece count: \(matchState.currentPieces.count)")
        }
        
        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    /// Result of match state validation
    struct ValidationResult {
        let isValid: Bool
        let issues: [String]
        
        var description: String {
            if isValid {
                return "Match state is valid"
            } else {
                return "Match state validation failed: \(issues.joined(separator: ", "))"
            }
        }
    }
    
    // MARK: - Integration with Existing Game Systems
    
    /// Convert single-player game state to multiplayer player state
    /// - Parameters:
    ///   - gameController: Current game controller
    ///   - gameScene: Current game scene
    ///   - playerID: Player ID for the converted state
    /// - Returns: PlayerState representing current single-player state
    static func convertSinglePlayerState(
        from gameController: GameController,
        gameScene: GameScene,
        playerID: String
    ) -> PlayerState {
        let boardState = captureBoardState(from: gameScene.gameBoard)
        
        var playerState = PlayerState(playerID: playerID)
        playerState.score = gameController.score
        playerState.boardState = boardState
        playerState.isGameOver = gameController.isGameOver
        playerState.lastMoveTime = Date()
        
        return playerState
    }
    
    /// Apply multiplayer player state to single-player game systems
    /// - Parameters:
    ///   - playerState: The player state to apply
    ///   - gameController: Game controller to update
    ///   - gameScene: Game scene to update
    /// - Returns: True if application was successful
    static func applySinglePlayerState(
        _ playerState: PlayerState,
        to gameController: GameController,
        gameScene: GameScene
    ) -> Bool {
        // Update game controller
        gameController.score = playerState.score
        gameController.isGameOver = playerState.isGameOver
        
        // Restore board state
        return restoreBoardState(playerState.boardState, to: gameScene.gameBoard)
    }
    
    // MARK: - Helper Methods
    
    /// Capture board state from GameBoard (similar to GameStateManager)
    private static func captureBoardState(from gameBoard: GameBoard) -> [[String?]] {
        var boardState: [[String?]] = []
        
        for row in 0..<8 { // Always use 8x8 for multiplayer
            var rowState: [String?] = []
            for col in 0..<8 {
                if let block = gameBoard.getBlockAt(row: row, column: col) {
                    let colorName = extractColorName(from: block.fillColor)
                    rowState.append(colorName)
                } else {
                    rowState.append(nil)
                }
            }
            boardState.append(rowState)
        }
        
        return boardState
    }
    
    /// Restore board state to GameBoard
    private static func restoreBoardState(_ boardState: [[String?]], to gameBoard: GameBoard) -> Bool {
        guard boardState.count == 8 else {
            print("MultiplayerGameState: Invalid board state - wrong row count")
            return false
        }
        
        // Clear existing board
        gameBoard.reset()
        
        // Restore blocks
        for (row, rowData) in boardState.enumerated() {
            guard rowData.count == 8 else {
                print("MultiplayerGameState: Invalid board state - wrong column count at row \(row)")
                return false
            }
            
            for (col, colorName) in rowData.enumerated() {
                if let colorName = colorName {
                    let color = colorFromName(colorName)
                    let cell = GridCell(column: col, row: row)
                    gameBoard.setBlock(at: cell, color: color)
                }
            }
        }
        
        return true
    }
}

// MARK: - Seeded Random Generator

extension MultiplayerGameState {
    /// Deterministic random number generator for synchronized piece generation
    struct SeededRandomGenerator: RandomNumberGenerator {
        private var state: UInt64
        
        init(seed: UInt64) {
            self.state = seed
        }
        
        mutating func next() -> UInt64 {
            // Linear congruential generator
            state = state &* 1103515245 &+ 12345
            return state
        }
    }
}

// MARK: - Extensions for Integration

extension TetrominoShape {
    /// Get TetrominoShape from display name
    static func fromDisplayName(_ displayName: String) -> TetrominoShape? {
        return TetrominoShape.allCases.first { $0.displayName == displayName }
    }
    
    /// Generate piece using custom random generator
    static func generatePiece(using generator: inout MultiplayerGameState.SeededRandomGenerator, mode: SelectionMode) -> TetrominoShape {
        // Use the generator to produce deterministic selection
        let randomValue = generator.next()
        let index = Int(randomValue % UInt64(TetrominoShape.allCases.count))
        return TetrominoShape.allCases[index]
    }
}

extension BlockColors {
    /// Get random color using custom generator
    static func getRandomColor(using generator: inout MultiplayerGameState.SeededRandomGenerator) -> SKColor {
        let colors = [
            SKColor(blue), SKColor(red), SKColor(green), SKColor(orange), 
            SKColor(purple), SKColor(yellow), SKColor(pink), SKColor(teal)
        ]
        let randomValue = generator.next()
        let index = Int(randomValue % UInt64(colors.count))
        return colors[index]
    }
}

// MARK: - Color Helper Functions

/// Extract color name from SKColor for serialization
func extractColorName(from color: SKColor) -> String {
    // Convert colors to comparable format for matching
    let blueColor = SKColor(BlockColors.blue)
    let redColor = SKColor(BlockColors.red)
    let greenColor = SKColor(BlockColors.green)
    let orangeColor = SKColor(BlockColors.orange)
    let purpleColor = SKColor(BlockColors.purple)
    let yellowColor = SKColor(BlockColors.yellow)
    let pinkColor = SKColor(BlockColors.pink)
    let tealColor = SKColor(BlockColors.teal)
    
    if color.isEqual(blueColor) { return "blue" }
    if color.isEqual(redColor) { return "red" }
    if color.isEqual(greenColor) { return "green" }
    if color.isEqual(orangeColor) { return "orange" }
    if color.isEqual(purpleColor) { return "purple" }
    if color.isEqual(yellowColor) { return "yellow" }
    if color.isEqual(pinkColor) { return "pink" }
    if color.isEqual(tealColor) { return "teal" }
    return "blue" // default
}

/// Convert color name back to SKColor
func colorFromName(_ name: String) -> SKColor {
    switch name {
    case "blue": return SKColor(BlockColors.blue)
    case "red": return SKColor(BlockColors.red)
    case "green": return SKColor(BlockColors.green)
    case "orange": return SKColor(BlockColors.orange)
    case "purple": return SKColor(BlockColors.purple)
    case "yellow": return SKColor(BlockColors.yellow)
    case "pink": return SKColor(BlockColors.pink)
    case "teal": return SKColor(BlockColors.teal)
    default: return SKColor(BlockColors.blue)
    }
}
