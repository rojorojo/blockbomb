# Multiplayer Features Documentation

## Overview

The multiplayer system for BlockBomb consists of three main components that handle Game Center integration, turn-based match management, and synchronized game state. All follow the same architectural patterns as other managers in the project (AdManager, ReviveHeartManager).

## Components

### GameCenterManager

The `GameCenterManager` is a singleton class that manages Game Center authentication and basic integration for BlockBomb's multiplayer features.

### TurnBasedMatchManager

The `TurnBasedMatchManager` handles all turn-based match operations for multiplayer gameplay, including match creation, loading, turn management, and Game Center integration.

### MultiplayerGameState

The `MultiplayerGameState` class manages synchronized game state, piece generation, and data serialization for competitive multiplayer matches. It ensures both players have identical pieces and maintains game state consistency.

## Features

### GameCenterManager

- ✅ Game Center authentication with proper error handling
- ✅ Singleton pattern following project conventions
- ✅ Integration with existing app architecture
- ✅ Privacy-compliant user information handling
- ✅ Accessibility support with VoiceOver announcements
- ✅ Automatic authentication on app launch
- ✅ Retry logic for failed authentication attempts (max 3 attempts)
- ✅ User consent handling through Game Center UI
- ✅ Authentication state tracking with published properties
- ✅ Secure player ID retrieval
- ✅ Display name access for authenticated users
- ✅ Privacy-compliant player info for analytics

### TurnBasedMatchManager

- ✅ Turn-based match creation with friend invites
- ✅ Random opponent matching support
- ✅ Active match loading and management
- ✅ Match lifecycle handling (active, ended, expired)
- ✅ Match resignation and quitting support
- ✅ Turn submission with game state serialization
- ✅ Automatic opponent notification via Game Center
- ✅ Turn event handling and push notification support
- ✅ Proper turn participant management
- ✅ Generic game state serialization/deserialization
- ✅ Match data storage and retrieval
- ✅ Error handling for data corruption
- ✅ Privacy-compliant data handling

### MultiplayerGameState

- ✅ Synchronized piece generation using shared random seeds
- ✅ Complete match state serialization for Game Center storage
- ✅ Individual player state tracking (8x8 grids, scores, move history)
- ✅ Turn progression and player identification
- ✅ Game state validation and conflict resolution
- ✅ Integration with existing GameController and GameBoard systems
- ✅ Deterministic piece generation for fair competition
- ✅ Move validation and anti-cheating measures
- ✅ Accessibility considerations for state communication

## Usage

### Basic Integration

All multiplayer components are designed to work together seamlessly:

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

### Creating a Match with Synchronized Game State

```swift
// Create match with friends
turnBasedMatchManager.createMatch(inviteMessage: "Let's play BlockBomb!") { match, error in
    if let match = match {
        // Create initial game state
        let initialState = MultiplayerGameState.createInitialMatchState(
            matchID: match.matchID,
            player1ID: gameCenterManager.getPlayerID()!,
            player2ID: match.participants?.first?.player?.gamePlayerID ?? "",
            player1Name: gameCenterManager.getPlayerDisplayName(),
            player2Name: match.participants?.first?.player?.displayName
        )

        // Encode and submit initial state
        if let matchData = MultiplayerGameState.encodeMatchData(initialState) {
            turnBasedMatchManager.submitTurn(for: match, matchData: matchData) { success, error in
                print("Initial state submitted: \(success)")
            }
        }
    }
}
```

### Synchronized Piece Generation

```swift
// Generate identical pieces for both players
let seed = MultiplayerGameState.generateNewSeed()
let syncedPieces = MultiplayerGameState.generateSyncedPieces(seed: seed)

// Both players will get the same pieces when using the same seed
let player1Pieces = MultiplayerGameState.generateSyncedPieces(seed: seed)
let player2Pieces = MultiplayerGameState.generateSyncedPieces(seed: seed)
// player1Pieces == player2Pieces
```

### Managing Game State

```swift
// Load and decode match state
if let matchData = match.matchData,
   let gameState = MultiplayerGameState.decodeMatchData(matchData) {

    // Check whose turn it is
    let isMyTurn = gameState.currentTurn == gameCenterManager.getPlayerID()

    // Get current pieces for this turn
    let currentPieces = gameState.currentPieces.compactMap { $0.toGridPiece() }

    // Get opponent's score
    let opponentState = gameState.getOpponentPlayerState()
    let opponentScore = opponentState.score
}
```

### Making a Move

```swift
// Create move data
let move = MultiplayerGameState.MoveData(
    piece: placedPiece,
    placement: placementPosition,
    scoreGained: pointsEarned,
    linesCleared: linesCleared
)

// Validate the move
let isValid = MultiplayerGameState.validateTurn(
    move: move,
    currentState: currentGameState,
    playerID: gameCenterManager.getPlayerID()!
)

if isValid {
    // Update player state
    var updatedPlayerState = currentGameState.getCurrentPlayerState()
    updatedPlayerState.score += pointsEarned
    // ... update board state ...

    // Advance to next turn
    let nextState = MultiplayerGameState.advanceToNextTurn(
        currentState: currentGameState,
        move: move,
        updatedPlayerState: updatedPlayerState
    )

    // Submit turn
    if let matchData = MultiplayerGameState.encodeMatchData(nextState) {
        turnBasedMatchManager.submitTurn(for: match, matchData: matchData) { success, error in
            print("Turn submitted: \(success)")
        }
    }
}
```

### Integration with Single-Player Systems

```swift
// Convert current single-player state to multiplayer
let playerState = MultiplayerGameState.convertSinglePlayerState(
    from: gameController,
    gameScene: gameScene,
    playerID: gameCenterManager.getPlayerID()!
)

// Apply multiplayer state to single-player systems
let success = MultiplayerGameState.applySinglePlayerState(
    playerState,
    to: gameController,
    gameScene: gameScene
)
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

### MultiplayerGameState Tests (`MultiplayerGameStateTests.swift`)

- Match state creation and initialization
- Synchronized piece generation with deterministic seeds
- Game state serialization and deserialization
- Turn validation and anti-cheating measures
- Player state management and board tracking
- Integration with existing game systems
- Accessibility and state communication validation

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

### Phase 1.3 - MultiplayerGameState

- ✅ Create `MultiplayerGameState.swift` in `/Features/Multiplayer/` directory
- ✅ Define Codable structures for match data serialization
- ✅ Track both players' grid states, scores, and current pieces
- ✅ Implement synchronized piece generation using shared random seeds
- ✅ Handle turn progression and player identification
- ✅ Game state validation and conflict resolution
- ✅ Methods: `encodeMatchData()`, `decodeMatchData()`, `generateSyncedPieces()`, `validateTurn()`
- ✅ Integration with existing GameController and grid systems
- ✅ Accessibility considerations for state communication

### User Interface (Phase 2)

- ✅ **MultiplayerLobbyView**: Complete lobby interface for match management
  - Game Center authentication required view
  - Match creation options (friends vs random opponents)
  - Active matches display with status indicators
  - Match details and resignation functionality
  - Loading states and error handling
  - Accessibility support throughout
  - Consistent theming with existing UI patterns
- ✅ **ContentView Integration**: Multiplayer button added to main interface
- ✅ **Navigation**: Proper sheet-based navigation for multiplayer features
- ✅ **MultiplayerGameView**: Complete game interface adaptation (Phase 2.2 - complete)
  - Player and opponent score display with proper positioning
  - Turn indicator with visual status and waiting states
  - End game functionality with confirmation dialogs
  - Real-time opponent score updates and game state synchronization
  - Visual feedback for turn submission with loading overlays
  - Full accessibility support with turn and score announcements
  - Integration with GameScene and piece placement systems
  - Consistent UI patterns and theming throughout

All core multiplayer components are now complete and ready to serve as the foundation for the full multiplayer experience outlined in the Play with Friends implementation plan.
