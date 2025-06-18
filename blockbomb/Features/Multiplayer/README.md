# Multiplayer Features Documentation

## Overview

The multiplayer system for BlockBomb consists of two main managers that handle Game Center integration and turn-based match management. Both follow the same architectural patterns as other managers in the project (AdManager, ReviveHeartManager).

## GameCenterManager

The `GameCenterManager` is a singleton class that manages Game Center authentication and basic integration for BlockBomb's multiplayer features.

### Features

#### Core Functionality

- ✅ Game Center authentication with proper error handling
- ✅ Singleton pattern following project conventions
- ✅ Integration with existing app architecture
- ✅ Privacy-compliant user information handling
- ✅ Accessibility support with VoiceOver announcements

#### Authentication Management

- ✅ Automatic authentication on app launch
- ✅ Retry logic for failed authentication attempts (max 3 attempts)
- ✅ User consent handling through Game Center UI
- ✅ Authentication state tracking with published properties

#### Player Information

- ✅ Secure player ID retrieval
- ✅ Display name access for authenticated users
- ✅ Privacy-compliant player info for analytics

## TurnBasedMatchManager

The `TurnBasedMatchManager` handles all turn-based match operations for multiplayer gameplay, including match creation, loading, turn management, and Game Center integration.

### Features

#### Match Management

- ✅ Turn-based match creation with friend invites
- ✅ Random opponent matching support
- ✅ Active match loading and management
- ✅ Match lifecycle handling (active, ended, expired)
- ✅ Match resignation and quitting support

#### Turn System

- ✅ Turn submission with game state serialization
- ✅ Automatic opponent notification via Game Center
- ✅ Turn event handling and push notification support
- ✅ Proper turn participant management

#### Data Management

- ✅ Generic game state serialization/deserialization
- ✅ Match data storage and retrieval
- ✅ Error handling for data corruption
- ✅ Privacy-compliant data handling

## Usage

### Basic Integration

Both managers are automatically initialized when the app launches and are available as StateObjects in ContentView:

```swift
@StateObject private var gameCenterManager = GameCenterManager.shared
@StateObject private var turnBasedMatchManager = TurnBasedMatchManager.shared
```

### Authentication Check

```swift
if gameCenterManager.isPlayerAuthenticated() {
    // Player is authenticated and ready for multiplayer
    let playerID = gameCenterManager.getPlayerID()
    let displayName = gameCenterManager.getPlayerDisplayName()
}
```

### Creating a Match

```swift
// Create match with friends
turnBasedMatchManager.createMatch(inviteMessage: "Let's play BlockBomb!") { match, error in
    if let match = match {
        print("Match created: \(match.matchID)")
    } else if let error = error {
        print("Failed to create match: \(error.localizedDescription)")
    }
}

// Create match with random opponents
turnBasedMatchManager.createMatchWithRandomOpponents { match, error in
    // Handle result
}
```

### Managing Matches

```swift
// Load active matches
turnBasedMatchManager.loadMatches { matches, error in
    if let matches = matches {
        print("Loaded \(matches.count) matches")
    }
}

// Submit a turn
if let matchData = turnBasedMatchManager.serializeMatchData(gameState) {
    turnBasedMatchManager.submitTurn(for: match, matchData: matchData) { success, error in
        if success {
            print("Turn submitted successfully")
        }
    }
}

// End a match
turnBasedMatchManager.endMatch(match, matchData: finalData) { success, error in
    if success {
        print("Match ended successfully")
    }
}
```

### Match Data Serialization

```swift
struct GameState: Codable {
    let playerScores: [String: Int]
    let currentTurn: String
    let gameBoard: [[Int]]
}

let gameState = GameState(...)

// Serialize for storage
if let data = turnBasedMatchManager.serializeMatchData(gameState) {
    // Use data for turn submission or match ending
}

// Deserialize after loading
if let gameState = turnBasedMatchManager.deserializeMatchData(matchData, as: GameState.self) {
    // Use restored game state
}
```

## Architecture

### GameCenterManager Published Properties

- `isAuthenticated: Bool` - Current authentication status
- `isAuthenticating: Bool` - Whether authentication is in progress
- `authenticationError: String?` - Current authentication error message
- `localPlayer: GKLocalPlayer?` - Game Center local player reference

### TurnBasedMatchManager Published Properties

- `activeMatches: [GKTurnBasedMatch]` - Currently active matches
- `isLoadingMatches: Bool` - Whether matches are being loaded
- `isCreatingMatch: Bool` - Whether a match is being created
- `isSubmittingTurn: Bool` - Whether a turn is being submitted
- `matchError: String?` - Current match operation error message
- `currentMatch: GKTurnBasedMatch?` - Currently selected match

### Key Methods

#### GameCenterManager

- `authenticatePlayer(completion:)` - Initiate authentication process
- `isPlayerAuthenticated()` - Check current authentication status
- `getPlayerID()` - Get authenticated player's Game Center ID
- `getPlayerDisplayName()` - Get player's display name
- `resetAuthenticationState()` - Reset manager state (useful for testing)

#### TurnBasedMatchManager

- `createMatch(inviteMessage:completion:)` - Create match with custom invite
- `createMatchWithRandomOpponents(completion:)` - Create match with random players
- `loadMatches(completion:)` - Load all active matches
- `submitTurn(for:matchData:completion:)` - Submit turn with game state
- `endMatch(_:matchData:completion:)` - End match with final state
- `quitMatch(_:completion:)` - Quit/resign from match
- `serializeMatchData(_:)` - Serialize game state for storage
- `deserializeMatchData(_:as:)` - Deserialize game state from storage

### Privacy & Accessibility

- Full VoiceOver support with appropriate accessibility labels
- Privacy-compliant data collection
- GDPR-compliant user information handling
- Clear user consent through Game Center's built-in UI
- Push notification support for turn alerts

## Error Handling

Both managers include robust error handling:

- Automatic retry for transient network errors (max 3 attempts)
- Clear error messages for user-facing issues
- Graceful degradation when Game Center is unavailable
- Proper handling of underage users
- Network failure recovery with exponential backoff

## Testing

Unit tests are included covering:

### GameCenterManager Tests (`GameCenterManagerTests.swift`)

- Singleton pattern verification
- Initial state validation
- Authentication state management
- Privacy-compliant data access
- Error condition handling

### TurnBasedMatchManager Tests (`TurnBasedMatchManagerTests.swift`)

- Singleton pattern verification
- Match data serialization/deserialization
- Authentication requirement enforcement
- State management and reset functionality
- Error handling for invalid operations

## Integration Points

### With Existing Systems

- **AppDelegate**: Both managers initialized on app launch
- **ContentView**: Available as StateObjects for UI updates
- **Debug System**: Includes debug logging for troubleshooting
- **Accessibility**: Full VoiceOver integration for all operations

### Future Multiplayer Features

- **MultiplayerGameState**: Will use TurnBasedMatchManager for match data
- **MultiplayerGameController**: Will coordinate with both managers
- **Analytics**: Can use privacy-compliant player info for metrics
- **UI Components**: Will observe published properties for state updates

## Push Notification Support

The TurnBasedMatchManager automatically handles:

- Turn event notifications when it's the player's turn
- Match end notifications when games conclude
- Player quit notifications when opponents leave
- Automatic match state updates via GKLocalPlayerListener

## Requirements Completed

### Phase 1.1 - GameCenterManager

- ✅ Add GameKit framework to the project (via import statements)
- ✅ Create `GameCenterManager.swift` in `/Features/Multiplayer/` directory
- ✅ Singleton pattern with proper Game Center authentication
- ✅ Handle authentication states and user consent
- ✅ Error handling for authentication failures
- ✅ Integration with existing app architecture
- ✅ Methods: `authenticatePlayer()`, `isAuthenticated()`, `getPlayerID()`
- ✅ Accessibility support for Game Center authentication UI
- ✅ Privacy compliance for Game Center features

### Phase 1.2 - TurnBasedMatchManager

- ✅ Create `TurnBasedMatchManager.swift` in `/Features/Multiplayer/` directory
- ✅ Handle GKTurnBasedMatch creation, loading, and management
- ✅ Implement match data serialization for game state
- ✅ Support for inviting friends and finding random opponents
- ✅ Handle match lifecycle (active, ended, expired)
- ✅ Error handling for network issues and match failures
- ✅ Methods: `createMatch()`, `loadMatches()`, `submitTurn()`, `endMatch()`
- ✅ Push notification support for turn alerts
- ✅ Integration with existing game architecture patterns

Both managers are now ready to serve as the foundation for the multiplayer UI and game logic components outlined in the Play with Friends implementation plan.
