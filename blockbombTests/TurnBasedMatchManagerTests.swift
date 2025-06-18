import XCTest
@testable import blockbomb

/// Test cases for TurnBasedMatchManager functionality
class TurnBasedMatchManagerTests: XCTestCase {
    
    var manager: TurnBasedMatchManager!
    
    override func setUp() {
        super.setUp()
        manager = TurnBasedMatchManager.shared
    }
    
    override func tearDown() {
        manager.resetState()
        manager = nil
        super.tearDown()
    }
    
    func testSingletonInstance() {
        let manager1 = TurnBasedMatchManager.shared
        let manager2 = TurnBasedMatchManager.shared
        
        XCTAssertTrue(manager1 === manager2, "TurnBasedMatchManager should be singleton")
    }
    
    func testInitialState() {
        manager.resetState()
        
        XCTAssertEqual(manager.activeMatches.count, 0, "Should have no active matches initially")
        XCTAssertFalse(manager.isLoadingMatches, "Should not be loading matches initially")
        XCTAssertFalse(manager.isCreatingMatch, "Should not be creating match initially")
        XCTAssertFalse(manager.isSubmittingTurn, "Should not be submitting turn initially")
        XCTAssertNil(manager.matchError, "Should have no error initially")
        XCTAssertNil(manager.currentMatch, "Should have no current match initially")
    }
    
    func testMatchDataSerialization() {
        struct TestGameState: Codable {
            let score: Int
            let level: Int
            let playerID: String
        }
        
        let gameState = TestGameState(score: 1000, level: 5, playerID: "test-player")
        
        // Test serialization
        guard let serializedData = manager.serializeMatchData(gameState) else {
            XCTFail("Serialization should not fail for valid data")
            return
        }
        
        XCTAssertGreaterThan(serializedData.count, 0, "Serialized data should not be empty")
        
        // Test deserialization
        guard let deserializedState = manager.deserializeMatchData(serializedData, as: TestGameState.self) else {
            XCTFail("Deserialization should not fail for valid data")
            return
        }
        
        XCTAssertEqual(deserializedState.score, gameState.score, "Score should match after serialization")
        XCTAssertEqual(deserializedState.level, gameState.level, "Level should match after serialization")
        XCTAssertEqual(deserializedState.playerID, gameState.playerID, "Player ID should match after serialization")
    }
    
    func testInvalidDataDeserialization() {
        struct TestGameState: Codable {
            let score: Int
        }
        
        let invalidData = Data([0x00, 0x01, 0x02]) // Invalid JSON data
        
        let result = manager.deserializeMatchData(invalidData, as: TestGameState.self)
        XCTAssertNil(result, "Deserialization should fail for invalid data")
        XCTAssertNotNil(manager.matchError, "Should set error for invalid deserialization")
    }
    
    func testResetState() {
        // Set some state
        manager.isLoadingMatches = true
        manager.isCreatingMatch = true
        manager.isSubmittingTurn = true
        manager.matchError = "Test error"
        
        // Reset state
        manager.resetState()
        
        XCTAssertEqual(manager.activeMatches.count, 0, "Should clear active matches")
        XCTAssertFalse(manager.isLoadingMatches, "Should reset loading state")
        XCTAssertFalse(manager.isCreatingMatch, "Should reset creating state")
        XCTAssertFalse(manager.isSubmittingTurn, "Should reset submitting state")
        XCTAssertNil(manager.matchError, "Should clear error")
        XCTAssertNil(manager.currentMatch, "Should clear current match")
    }
    
    func testCreateMatchRequiresAuthentication() {
        // Reset GameCenterManager to unauthenticated state
        let gameCenterManager = GameCenterManager.shared
        gameCenterManager.resetAuthenticationState()
        
        let expectation = XCTestExpectation(description: "Create match completion")
        
        manager.createMatchWithRandomOpponents { match, error in
            XCTAssertNil(match, "Should not create match when not authenticated")
            XCTAssertNotNil(error, "Should return error when not authenticated")
            XCTAssertEqual((error as NSError?)?.domain, "TurnBasedMatchManager", "Should return TurnBasedMatchManager error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSubmitTurnRequiresAuthentication() {
        // Create a mock match
        let mockMatch = createMockMatch()
        let testData = Data([0x01, 0x02, 0x03])
        
        // Reset GameCenterManager to unauthenticated state
        let gameCenterManager = GameCenterManager.shared
        gameCenterManager.resetAuthenticationState()
        
        let expectation = XCTestExpectation(description: "Submit turn completion")
        
        manager.submitTurn(for: mockMatch, matchData: testData) { success, error in
            XCTAssertFalse(success, "Should not succeed when not authenticated")
            XCTAssertNotNil(error, "Should return error when not authenticated")
            XCTAssertEqual((error as NSError?)?.domain, "TurnBasedMatchManager", "Should return TurnBasedMatchManager error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testEndMatchRequiresAuthentication() {
        // Create a mock match
        let mockMatch = createMockMatch()
        let testData = Data([0x01, 0x02, 0x03])
        
        // Reset GameCenterManager to unauthenticated state
        let gameCenterManager = GameCenterManager.shared
        gameCenterManager.resetAuthenticationState()
        
        let expectation = XCTestExpectation(description: "End match completion")
        
        manager.endMatch(mockMatch, matchData: testData) { success, error in
            XCTAssertFalse(success, "Should not succeed when not authenticated")
            XCTAssertNotNil(error, "Should return error when not authenticated")
            XCTAssertEqual((error as NSError?)?.domain, "TurnBasedMatchManager", "Should return TurnBasedMatchManager error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadMatchesRequiresAuthentication() {
        // Reset GameCenterManager to unauthenticated state
        let gameCenterManager = GameCenterManager.shared
        gameCenterManager.resetAuthenticationState()
        
        let expectation = XCTestExpectation(description: "Load matches completion")
        
        manager.loadMatches { matches, error in
            XCTAssertEqual(matches.count, 0, "Should return empty matches when not authenticated")
            XCTAssertNotNil(error, "Should return error when not authenticated")
            XCTAssertEqual((error as NSError?)?.domain, "TurnBasedMatchManager", "Should return TurnBasedMatchManager error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockMatch() -> GKTurnBasedMatch {
        // Note: In a real implementation, this would need to create a proper mock
        // For now, we'll use a basic implementation that satisfies the interface
        // This would be enhanced with a proper mocking framework in production
        return GKTurnBasedMatch()
    }
}
