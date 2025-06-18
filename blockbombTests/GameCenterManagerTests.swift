import XCTest
@testable import blockbomb

/// Test cases for GameCenterManager functionality
class GameCenterManagerTests: XCTestCase {
    
    var manager: GameCenterManager!
    
    override func setUp() {
        super.setUp()
        manager = GameCenterManager.shared
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    func testSingletonInstance() {
        let manager1 = GameCenterManager.shared
        let manager2 = GameCenterManager.shared
        
        XCTAssertTrue(manager1 === manager2, "GameCenterManager should be singleton")
    }
    
    func testInitialState() {
        // Reset to known state
        manager.resetAuthenticationState()
        
        XCTAssertFalse(manager.isAuthenticated, "Should not be authenticated initially")
        XCTAssertFalse(manager.isAuthenticating, "Should not be authenticating initially")
        XCTAssertNil(manager.authenticationError, "Should have no error initially")
        XCTAssertNotNil(manager.localPlayer, "Local player should be initialized")
    }
    
    func testPlayerIDWhenNotAuthenticated() {
        // Reset to known state
        manager.resetAuthenticationState()
        
        let playerID = manager.getPlayerID()
        XCTAssertNil(playerID, "Player ID should be nil when not authenticated")
    }
    
    func testDisplayNameWhenNotAuthenticated() {
        // Reset to known state
        manager.resetAuthenticationState()
        
        let displayName = manager.getPlayerDisplayName()
        XCTAssertNil(displayName, "Display name should be nil when not authenticated")
    }
    
    func testGameCenterAvailabilityWhenNotAuthenticated() {
        // Reset to known state
        manager.resetAuthenticationState()
        
        let isAvailable = manager.isGameCenterAvailable()
        XCTAssertFalse(isAvailable, "Game Center should not be available when not authenticated")
    }
    
    func testPrivacyCompliantPlayerInfoWhenNotAuthenticated() {
        // Reset to known state
        manager.resetAuthenticationState()
        
        let playerInfo = manager.getPrivacyCompliantPlayerInfo()
        
        XCTAssertEqual(playerInfo["authenticated"] as? Bool, false, "Should indicate not authenticated")
        XCTAssertEqual(playerInfo.count, 1, "Should only contain authentication status when not authenticated")
    }
    
    func testResetAuthenticationState() {
        // Set some state
        manager.isAuthenticated = true
        manager.isAuthenticating = true
        manager.authenticationError = "Test error"
        
        // Reset state
        manager.resetAuthenticationState()
        
        XCTAssertFalse(manager.isAuthenticated, "Should reset authentication status")
        XCTAssertFalse(manager.isAuthenticating, "Should reset authenticating status")
        XCTAssertNil(manager.authenticationError, "Should clear error")
    }
}
