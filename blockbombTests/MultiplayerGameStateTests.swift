import XCTest
@testable import blockbomb

/// Test cases for MultiplayerGameState functionality
class MultiplayerGameStateTests: XCTestCase {
    
    // MARK: - Test Data
    
    let testPlayer1ID = "player1-test-id"
    let testPlayer2ID = "player2-test-id"
    let testMatchID = "test-match-12345"
    
    // MARK: - Initial State Tests
    
    func testCreateInitialMatchState() {
        let matchState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID,
            player1Name: "Player One",
            player2Name: "Player Two"
        )
        
        XCTAssertEqual(matchState.matchID, testMatchID, "Match ID should be preserved")
        XCTAssertEqual(matchState.player1.playerID, testPlayer1ID, "Player 1 ID should be set")
        XCTAssertEqual(matchState.player2.playerID, testPlayer2ID, "Player 2 ID should be set")
        XCTAssertEqual(matchState.player1.displayName, "Player One", "Player 1 name should be set")
        XCTAssertEqual(matchState.player2.displayName, "Player Two", "Player 2 name should be set")
        XCTAssertEqual(matchState.currentTurn, testPlayer1ID, "Player 1 should start first")
        XCTAssertEqual(matchState.turnNumber, 1, "Should start at turn 1")
        XCTAssertEqual(matchState.currentPieces.count, 3, "Should have 3 initial pieces")
        XCTAssertTrue(matchState.isValid, "Initial state should be valid")
    }
    
    func testPlayerStateInitialization() {
        let playerState = MultiplayerGameState.PlayerState(playerID: testPlayer1ID, displayName: "Test Player")
        
        XCTAssertEqual(playerState.playerID, testPlayer1ID, "Player ID should be set")
        XCTAssertEqual(playerState.displayName, "Test Player", "Display name should be set")
        XCTAssertEqual(playerState.score, 0, "Score should start at 0")
        XCTAssertEqual(playerState.boardState.count, 8, "Board should have 8 rows")
        XCTAssertEqual(playerState.boardState[0].count, 8, "Each row should have 8 columns")
        XCTAssertFalse(playerState.isGameOver, "Game should not be over initially")
        XCTAssertEqual(playerState.moveHistory.count, 0, "Move history should be empty")
        XCTAssertEqual(playerState.filledCellCount, 0, "Board should be empty initially")
        XCTAssertFalse(playerState.isBoardFull, "Board should not be full")
    }
    
    // MARK: - Piece Generation Tests
    
    func testSyncedPieceGeneration() {
        let seed: UInt64 = 12345
        
        // Generate pieces twice with same seed
        let pieces1 = MultiplayerGameState.generateSyncedPieces(seed: seed)
        let pieces2 = MultiplayerGameState.generateSyncedPieces(seed: seed)
        
        XCTAssertEqual(pieces1.count, 3, "Should generate 3 pieces")
        XCTAssertEqual(pieces2.count, 3, "Should generate 3 pieces")
        
        // Pieces should be identical when using same seed
        for i in 0..<3 {
            XCTAssertEqual(pieces1[i].shape, pieces2[i].shape, "Piece \(i) shapes should match")
            XCTAssertEqual(pieces1[i].colorName, pieces2[i].colorName, "Piece \(i) colors should match")
            XCTAssertEqual(pieces1[i].cells.count, pieces2[i].cells.count, "Piece \(i) cell counts should match")
        }
    }
    
    func testDifferentSeedsProduceDifferentPieces() {
        let seed1: UInt64 = 12345
        let seed2: UInt64 = 54321
        
        let pieces1 = MultiplayerGameState.generateSyncedPieces(seed: seed1)
        let pieces2 = MultiplayerGameState.generateSyncedPieces(seed: seed2)
        
        // At least one piece should be different
        var hasDifference = false
        for i in 0..<3 {
            if pieces1[i].shape != pieces2[i].shape || pieces1[i].colorName != pieces2[i].colorName {
                hasDifference = true
                break
            }
        }
        
        XCTAssertTrue(hasDifference, "Different seeds should produce different pieces")
    }
    
    func testPieceDataConversion() {
        // Create a test GridPiece
        let shape = TetrominoShape.squareSmall
        let color = BlockColors.blue
        let gridPiece = GridPiece(shape: shape, color: color)
        
        // Convert to PieceData and back
        let pieceData = MultiplayerGameState.PieceData(from: gridPiece)
        let convertedPiece = pieceData.toGridPiece()
        
        XCTAssertNotNil(convertedPiece, "Should successfully convert back to GridPiece")
        XCTAssertEqual(convertedPiece?.shape, shape, "Shape should be preserved")
        XCTAssertEqual(pieceData.shape, shape.displayName, "Display name should match")
        XCTAssertEqual(pieceData.colorName, "blue", "Color name should be extracted")
    }
    
    // MARK: - Serialization Tests
    
    func testMatchStateSerialization() {
        let matchState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID
        )
        
        // Test encoding
        guard let encodedData = MultiplayerGameState.encodeMatchData(matchState) else {
            XCTFail("Should successfully encode match state")
            return
        }
        
        XCTAssertGreaterThan(encodedData.count, 0, "Encoded data should not be empty")
        
        // Test decoding
        guard let decodedState = MultiplayerGameState.decodeMatchData(encodedData) else {
            XCTFail("Should successfully decode match state")
            return
        }
        
        XCTAssertEqual(decodedState.matchID, matchState.matchID, "Match ID should be preserved")
        XCTAssertEqual(decodedState.player1.playerID, matchState.player1.playerID, "Player 1 ID should be preserved")
        XCTAssertEqual(decodedState.player2.playerID, matchState.player2.playerID, "Player 2 ID should be preserved")
        XCTAssertEqual(decodedState.currentTurn, matchState.currentTurn, "Current turn should be preserved")
        XCTAssertEqual(decodedState.turnNumber, matchState.turnNumber, "Turn number should be preserved")
        XCTAssertEqual(decodedState.randomSeed, matchState.randomSeed, "Random seed should be preserved")
        XCTAssertEqual(decodedState.currentPieces.count, matchState.currentPieces.count, "Piece count should be preserved")
    }
    
    func testInvalidDataDeserialization() {
        let invalidData = Data([0x00, 0x01, 0x02]) // Invalid JSON data
        
        let result = MultiplayerGameState.decodeMatchData(invalidData)
        XCTAssertNil(result, "Should return nil for invalid data")
    }
    
    // MARK: - Turn Management Tests
    
    func testAdvanceToNextTurn() {
        let initialState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID
        )
        
        // Create a test move
        let testShape = TetrominoShape.squareSmall
        let gridPiece = GridPiece(shape: testShape, color: BlockColors.red)
        let placement = GridCell(row: 2, column: 3)
        let move = MultiplayerGameState.MoveData(
            piece: gridPiece,
            placement: placement,
            scoreGained: 100,
            linesCleared: 1
        )
        
        // Update player state
        var updatedPlayerState = initialState.player1
        updatedPlayerState.score = 100
        
        // Advance turn
        let nextState = MultiplayerGameState.advanceToNextTurn(
            currentState: initialState,
            move: move,
            updatedPlayerState: updatedPlayerState
        )
        
        XCTAssertEqual(nextState.currentTurn, testPlayer2ID, "Should switch to player 2")
        XCTAssertEqual(nextState.turnNumber, 2, "Turn number should increment")
        XCTAssertEqual(nextState.player1.score, 100, "Player 1 score should be updated")
        XCTAssertEqual(nextState.player1.moveHistory.count, 1, "Move should be added to history")
        XCTAssertNotEqual(nextState.randomSeed, initialState.randomSeed, "Should generate new seed")
        XCTAssertNotEqual(nextState.currentPieces[0].shape, initialState.currentPieces[0].shape, "Should generate new pieces")
    }
    
    // MARK: - Validation Tests
    
    func testValidTurnValidation() {
        let matchState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID
        )
        
        // Create valid move using one of the current pieces
        let availablePiece = matchState.currentPieces[0]
        let move = MultiplayerGameState.MoveData(
            piece: GridPiece(shape: TetrominoShape.squareSmall, color: BlockColors.blue),
            placement: GridCell(row: 2, column: 3),
            scoreGained: 50,
            linesCleared: 0
        )
        
        // Modify move to use available piece
        let validMove = MultiplayerGameState.MoveData(
            piece: GridPiece(shape: TetrominoShape.fromDisplayName(availablePiece.shape)!, color: BlockColors.blue),
            placement: GridCell(row: 2, column: 3),
            scoreGained: 50,
            linesCleared: 0
        )
        
        let isValid = MultiplayerGameState.validateTurn(
            move: validMove,
            currentState: matchState,
            playerID: testPlayer1ID
        )
        
        XCTAssertTrue(isValid, "Valid turn should pass validation")
    }
    
    func testInvalidTurnValidation() {
        let matchState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID
        )
        
        let move = MultiplayerGameState.MoveData(
            piece: GridPiece(shape: TetrominoShape.squareSmall, color: BlockColors.blue),
            placement: GridCell(row: 2, column: 3),
            scoreGained: 50,
            linesCleared: 0
        )
        
        // Test wrong player turn
        let wrongPlayerResult = MultiplayerGameState.validateTurn(
            move: move,
            currentState: matchState,
            playerID: testPlayer2ID
        )
        XCTAssertFalse(wrongPlayerResult, "Wrong player turn should fail validation")
        
        // Test out of bounds placement
        let outOfBoundsMove = MultiplayerGameState.MoveData(
            piece: GridPiece(shape: TetrominoShape.squareSmall, color: BlockColors.blue),
            placement: GridCell(row: 10, column: 3), // Out of bounds
            scoreGained: 50,
            linesCleared: 0
        )
        
        let outOfBoundsResult = MultiplayerGameState.validateTurn(
            move: outOfBoundsMove,
            currentState: matchState,
            playerID: testPlayer1ID
        )
        XCTAssertFalse(outOfBoundsResult, "Out of bounds placement should fail validation")
    }
    
    func testMatchStateValidation() {
        let validState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID
        )
        
        let validationResult = MultiplayerGameState.validateMatchState(validState)
        XCTAssertTrue(validationResult.isValid, "Valid state should pass validation")
        XCTAssertEqual(validationResult.issues.count, 0, "Valid state should have no issues")
    }
    
    // MARK: - Integration Tests
    
    func testPlayerStateBoardManagement() {
        var playerState = MultiplayerGameState.PlayerState(playerID: testPlayer1ID)
        
        // Test empty board
        XCTAssertEqual(playerState.filledCellCount, 0, "Empty board should have 0 filled cells")
        XCTAssertFalse(playerState.isBoardFull, "Empty board should not be full")
        
        // Simulate filling some cells
        playerState.boardState[0][0] = "blue"
        playerState.boardState[1][1] = "red"
        playerState.boardState[2][2] = "green"
        
        XCTAssertEqual(playerState.filledCellCount, 3, "Should count filled cells correctly")
        XCTAssertFalse(playerState.isBoardFull, "Partially filled board should not be full")
        
        // Fill entire board
        for row in 0..<8 {
            for col in 0..<8 {
                playerState.boardState[row][col] = "blue"
            }
        }
        
        XCTAssertEqual(playerState.filledCellCount, 64, "Full board should have 64 filled cells")
        XCTAssertTrue(playerState.isBoardFull, "Full board should be detected as full")
    }
    
    func testCurrentAndOpponentPlayerStates() {
        let matchState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID
        )
        
        let currentPlayer = matchState.getCurrentPlayerState()
        let opponentPlayer = matchState.getOpponentPlayerState()
        
        XCTAssertEqual(currentPlayer.playerID, testPlayer1ID, "Current player should be player 1")
        XCTAssertEqual(opponentPlayer.playerID, testPlayer2ID, "Opponent should be player 2")
        
        // Test after turn switch
        let nextState = MultiplayerGameState.advanceToNextTurn(
            currentState: matchState,
            move: MultiplayerGameState.MoveData(
                piece: GridPiece(shape: TetrominoShape.squareSmall, color: BlockColors.blue),
                placement: GridCell(row: 0, column: 0),
                scoreGained: 0,
                linesCleared: 0
            ),
            updatedPlayerState: matchState.player1
        )
        
        let nextCurrentPlayer = nextState.getCurrentPlayerState()
        let nextOpponentPlayer = nextState.getOpponentPlayerState()
        
        XCTAssertEqual(nextCurrentPlayer.playerID, testPlayer2ID, "Current player should switch to player 2")
        XCTAssertEqual(nextOpponentPlayer.playerID, testPlayer1ID, "Opponent should switch to player 1")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityConsiderations() {
        let matchState = MultiplayerGameState.createInitialMatchState(
            matchID: testMatchID,
            player1ID: testPlayer1ID,
            player2ID: testPlayer2ID,
            player1Name: "Alice",
            player2Name: "Bob"
        )
        
        // Test that display names are available for accessibility announcements
        XCTAssertNotNil(matchState.player1.displayName, "Player 1 should have display name for accessibility")
        XCTAssertNotNil(matchState.player2.displayName, "Player 2 should have display name for accessibility")
        
        // Test that current turn information is accessible
        let currentPlayerName = matchState.currentTurn == matchState.player1.playerID ? 
                               matchState.player1.displayName : matchState.player2.displayName
        XCTAssertNotNil(currentPlayerName, "Current player name should be available")
        
        // Test that game state information needed for accessibility is present
        XCTAssertGreaterThanOrEqual(matchState.player1.score, 0, "Score should be accessible")
        XCTAssertGreaterThanOrEqual(matchState.player2.score, 0, "Score should be accessible")
        XCTAssertGreaterThan(matchState.turnNumber, 0, "Turn number should be accessible")
    }
}
