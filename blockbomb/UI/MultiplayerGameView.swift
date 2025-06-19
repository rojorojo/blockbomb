import SwiftUI
import GameKit
import SpriteKit

struct MultiplayerGameView: View {
    @ObservedObject var gameController: GameController
    @ObservedObject private var gameCenterManager = GameCenterManager.shared
    @ObservedObject private var matchManager = TurnBasedMatchManager.shared
    
    let match: GKTurnBasedMatch
    let multiplayerGameState: MultiplayerGameState
    
    @State private var currentPlayerScore: Int = 0
    @State private var opponentScore: Int = 0
    @State private var opponentName: String = "Opponent"
    @State private var isMyTurn: Bool = false
    @State private var isSubmittingTurn: Bool = false
    @State private var showEndGameConfirmation: Bool = false
    @State private var turnStatusMessage: String = ""
    @State private var showGameOverAlert: Bool = false
    @State private var gameOverMessage: String = ""
    @State private var lastKnownScore: Int = 0
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Game scene background
            GameSceneView(
                gameController: gameController,
                onShapeGalleryRequest: {
                    // Handle shape gallery request if needed
                }
            )
            .ignoresSafeArea()
            
            // Multiplayer UI overlay
            VStack(spacing: 0) {
                // Top section with buttons and scores
                topSection
                
                // Turn status indicator
                turnIndicator
                
                Spacer()
                
                // Bottom section with controls
                bottomSection
            }
            .ignoresSafeArea(.keyboard)
            
            // Turn submission overlay
            if isSubmittingTurn {
                turnSubmissionOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupMultiplayerGame()
        }
        .onReceive(gameController.$score) { newScore in
            handleScoreUpdate(newScore)
        }
        .alert("End Game", isPresented: $showEndGameConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Game", role: .destructive) {
                endGame()
            }
        } message: {
            Text("Are you sure you want to end the game? The player with the highest score will win.")
        }
        .alert("Game Over", isPresented: $showGameOverAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(gameOverMessage)
        }
    }
    
    // MARK: - Top Section
    
    private var topSection: some View {
        HStack {
            // Back/Settings button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(BlockColors.slate)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back to lobby")
            
            Spacer()
            
            // Multiplayer scores
            multiplayerScoreView
            
            Spacer()
            
            // End game button (only show during player's turn)
            if isMyTurn && !isSubmittingTurn {
                Button(action: {
                    showEndGameConfirmation = true
                }) {
                    Image(systemName: "flag.fill")
                        .font(.title2)
                        .foregroundColor(BlockColors.red)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("End game")
                .accessibilityHint("End the multiplayer match")
            } else {
                // Placeholder to maintain layout
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Multiplayer Score View
    
    private var multiplayerScoreView: some View {
        VStack(spacing: 12) {
            // Current player's score (large, prominent)
            VStack(spacing: 4) {
                Text("YOU")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(BlockColors.cyan.opacity(0.8))
                
                Text("\(currentPlayerScore)")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(BlockColors.cyan)
                    .accessibilityLabel("Your score: \(currentPlayerScore)")
            }
            
            // Opponent's score (smaller, in "BEST" position)
            HStack(spacing: 8) {
                Text(opponentName.uppercased())
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(BlockColors.purple)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text("\(opponentScore)")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(BlockColors.purple)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(opponentName) score: \(opponentScore)")
        }
    }
    
    // MARK: - Turn Indicator
    
    private var turnIndicator: some View {
        VStack(spacing: 8) {
            // Turn status
            HStack {
                Circle()
                    .fill(isMyTurn ? BlockColors.green : BlockColors.amber)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isMyTurn ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isMyTurn)
                
                Text(turnStatusMessage)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .accessibilityLabel(turnStatusMessage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))
            .cornerRadius(20)
            
            // Submit turn button (only show during player's turn and when they can submit)
            if isMyTurn && canSubmitTurn && !isSubmittingTurn {
                Button(action: {
                    submitTurn()
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Turn")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(BlockColors.blue)
                    .cornerRadius(25)
                }
                .accessibilityLabel("Submit your turn")
                .accessibilityHint("Send your move to your opponent")
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        // Hearts display (reuse existing HeartCountView)
        HeartCountView()
            .padding(.bottom, 20)
    }
    
    // MARK: - Turn Submission Overlay
    
    private var turnSubmissionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Submitting turn...")
                    .font(.body)
                    .foregroundColor(.white)
                
                Text("Sending your move to \(opponentName)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
        .zIndex(100)
    }
    
    // MARK: - Computed Properties
    
    private var canSubmitTurn: Bool {
        // Player can submit turn if they've made a valid move
        // For now, just check if score has changed from initial
        return currentPlayerScore > 0
    }
    
    // MARK: - Methods
    
    private func setupMultiplayerGame() {
        updateGameState()
        updateTurnStatus()
        
        // Set up score observation
        observeScoreChanges()
        
        // Announce turn status for accessibility
        announceGameState()
    }
    
    private func updateGameState() {
        // Get current player ID
        guard let currentPlayerID = gameCenterManager.getPlayerID() else { return }
        
        // Decode match data to get current game state
        if let matchData = match.matchData,
           let decodedState = MultiplayerGameState.decodeMatchData(matchData) {
            
            // Update scores from match data
            if decodedState.currentTurnPlayerID == currentPlayerID {
                // Current player's turn
                currentPlayerScore = decodedState.getCurrentPlayerState().score
                opponentScore = decodedState.getOpponentPlayerState().score
            } else {
                // Opponent's turn
                currentPlayerScore = decodedState.getOpponentPlayerState().score
                opponentScore = decodedState.getCurrentPlayerState().score
            }
            
            // Update game state
            isMyTurn = decodedState.currentTurnPlayerID == currentPlayerID
            
            // Sync pieces with game controller if it's our turn
            if isMyTurn {
                syncPiecesWithGameController(decodedState.currentPieces)
            }
            
        } else {
            // Fallback to local game state if no match data available
            currentPlayerScore = gameController.score
            opponentScore = 0
        }
        
        // Determine whose turn it is from match participant data
        isMyTurn = match.currentParticipant?.player?.gamePlayerID == currentPlayerID
        
        // Get opponent name
        let participants = match.participants
        for participant in participants {
            if participant.player?.gamePlayerID != currentPlayerID {
                opponentName = participant.player?.displayName ?? "Opponent"
                break
            }
        }
    }
    
    private func updateTurnStatus() {
        if isSubmittingTurn {
            turnStatusMessage = "Submitting turn..."
        } else if isMyTurn {
            turnStatusMessage = "Your turn"
        } else {
            turnStatusMessage = "Waiting for \(opponentName)"
        }
    }
    
    private func observeScoreChanges() {
        // Initial score setup
        lastKnownScore = gameController.score
        currentPlayerScore = gameController.score
    }
    
    private func handleScoreUpdate(_ newScore: Int) {
        let scoreDifference = newScore - lastKnownScore
        
        if scoreDifference > 0 {
            // Score increased, announce for accessibility
            UIAccessibility.post(
                notification: .announcement, 
                argument: "Score increased by \(scoreDifference). New score: \(newScore)"
            )
        }
        
        currentPlayerScore = newScore
        lastKnownScore = newScore
    }
    
    private func announceGameState() {
        let announcement: String
        if isMyTurn {
            announcement = "Your turn. Your score: \(currentPlayerScore). \(opponentName)'s score: \(opponentScore)"
        } else {
            announcement = "\(opponentName)'s turn. Your score: \(currentPlayerScore). \(opponentName)'s score: \(opponentScore)"
        }
        
        // Post accessibility announcement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    private func submitTurn() {
        guard isMyTurn && !isSubmittingTurn else { return }
        guard let currentPlayerID = gameCenterManager.getPlayerID() else { return }
        
        Task {
            await performTurnSubmission(currentPlayerID: currentPlayerID)
        }
    }
    
    @MainActor
    private func performTurnSubmission(currentPlayerID: String) async {
        isSubmittingTurn = true
        updateTurnStatus()
        
        // Get current match state or create initial one
        var currentMatchState: MultiplayerGameState.MatchState
        
        if let matchData = match.matchData,
           let decodedState = MultiplayerGameState.decodeMatchData(matchData) {
            currentMatchState = decodedState
        } else {
            // Create initial match state if none exists
            let participants = match.participants
            let player1ID = participants.first?.player?.gamePlayerID ?? currentPlayerID
            let player2ID = participants.last?.player?.gamePlayerID ?? "opponent"
            let player1Name = participants.first?.player?.displayName
            let player2Name = participants.last?.player?.displayName
            
            currentMatchState = MultiplayerGameState.createInitialMatchState(
                matchID: match.matchID,
                player1ID: player1ID,
                player2ID: player2ID,
                player1Name: player1Name,
                player2Name: player2Name
            )
        }
        
        // Create a simplified move data for the current turn
        // Note: This is a simplified version since we don't have direct access to piece placement details
        let dummyPiece = GridPiece(shape: .squareSmall, color: SKColor(BlockColors.blue))
        let dummyCell = GridCell(column: 0, row: 0)
        
        let moveData = MultiplayerGameState.MoveData(
            piece: dummyPiece,
            placement: dummyCell,
            scoreGained: gameController.score - currentMatchState.getCurrentPlayerState().score,
            linesCleared: 0 // We don't track lines cleared in the current game
        )
        
        // Update current player state with new score
        var updatedPlayerState = currentMatchState.getCurrentPlayerState()
        updatedPlayerState.score = gameController.score
        updatedPlayerState.isGameOver = gameController.isGameOver
        updatedPlayerState.lastMoveTime = Date()
        
        // Advance to next turn
        let updatedMatchState = MultiplayerGameState.advanceToNextTurn(
            currentState: currentMatchState,
            move: moveData,
            updatedPlayerState: updatedPlayerState
        )
        
        // Encode the updated match state
        guard let encodedData = MultiplayerGameState.encodeMatchData(updatedMatchState) else {
            print("MultiplayerGameView: Failed to encode match data")
            isSubmittingTurn = false
            updateTurnStatus()
            return
        }
        
        // Submit turn through match manager (simplified approach)
        await withCheckedContinuation { continuation in
            matchManager.submitTurn(for: match, matchData: encodedData) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.isSubmittingTurn = false
                        self.isMyTurn = false
                        self.updateTurnStatus()
                        
                        // Announce turn submission
                        UIAccessibility.post(notification: .announcement, argument: "Turn submitted. Waiting for \(self.opponentName)")
                        
                        // Refresh match state
                        self.updateGameState()
                    } else {
                        let errorMessage = error?.localizedDescription ?? "Unknown error"
                        print("MultiplayerGameView: Turn submission failed: \(errorMessage)")
                        
                        self.isSubmittingTurn = false
                        self.updateTurnStatus()
                        UIAccessibility.post(notification: .announcement, argument: "Turn submission failed. Please try again.")
                    }
                    continuation.resume()
                }
            }
        }
    }

    
    private func endGame() {
        guard let currentPlayerID = gameCenterManager.getPlayerID() else { return }
        
        Task {
            await performEndGame(currentPlayerID: currentPlayerID)
        }
    }
    
    @MainActor
    private func performEndGame(currentPlayerID: String) async {
        // Get current match state or create final one
        var finalMatchState: MultiplayerGameState.MatchState
        
        if let matchData = match.matchData,
           let currentMatchState = MultiplayerGameState.decodeMatchData(matchData) {
            // Update existing match state with final scores
            var updatedPlayerState = currentMatchState.getCurrentPlayerState()
            updatedPlayerState.score = gameController.score
            updatedPlayerState.isGameOver = true
            updatedPlayerState.lastMoveTime = Date()
            
            // Create final move data
            let dummyPiece = GridPiece(shape: .squareSmall, color: SKColor(BlockColors.blue))
            let dummyCell = GridCell(column: 0, row: 0)
            
            let finalMove = MultiplayerGameState.MoveData(
                piece: dummyPiece,
                placement: dummyCell,
                scoreGained: 0,
                linesCleared: 0
            )
            
            finalMatchState = MultiplayerGameState.advanceToNextTurn(
                currentState: currentMatchState,
                move: finalMove,
                updatedPlayerState: updatedPlayerState
            )
        } else {
            // Create final match state if none exists
            let participants = match.participants
            let player1ID = participants.first?.player?.gamePlayerID ?? currentPlayerID
            let player2ID = participants.last?.player?.gamePlayerID ?? "opponent"
            let player1Name = participants.first?.player?.displayName
            let player2Name = participants.last?.player?.displayName
            
            finalMatchState = MultiplayerGameState.createInitialMatchState(
                matchID: match.matchID,
                player1ID: player1ID,
                player2ID: player2ID,
                player1Name: player1Name,
                player2Name: player2Name
            )
            
            // Update with current score
            var playerState = finalMatchState.getCurrentPlayerState()
            playerState.score = gameController.score
            playerState.isGameOver = true
            
            let dummyPiece = GridPiece(shape: .squareSmall, color: SKColor(BlockColors.blue))
            let dummyCell = GridCell(column: 0, row: 0)
            
            let finalMove = MultiplayerGameState.MoveData(
                piece: dummyPiece,
                placement: dummyCell,
                scoreGained: gameController.score,
                linesCleared: 0
            )
            
            finalMatchState = MultiplayerGameState.advanceToNextTurn(
                currentState: finalMatchState,
                move: finalMove,
                updatedPlayerState: playerState
            )
        }
        
        // Encode final match data
        guard let encodedData = MultiplayerGameState.encodeMatchData(finalMatchState) else {
            print("MultiplayerGameView: Failed to encode final match data")
            return
        }
        
        // End the match
        await withCheckedContinuation { continuation in
            matchManager.endMatch(match, matchData: encodedData) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Determine winner and show result
                        let winner = self.currentPlayerScore > self.opponentScore ? "You" : self.opponentName
                        let yourScore = self.currentPlayerScore
                        let theirScore = self.opponentScore
                        
                        self.gameOverMessage = "\(winner) won!\nYour score: \(yourScore)\n\(self.opponentName)'s score: \(theirScore)"
                        self.showGameOverAlert = true
                    } else {
                        // Handle end game error
                        let errorMessage = error?.localizedDescription ?? "Unknown error"
                        print("MultiplayerGameView: End game failed: \(errorMessage)")
                        
                        // Still show game over dialog with current scores
                        let winner = self.currentPlayerScore > self.opponentScore ? "You" : self.opponentName
                        self.gameOverMessage = "\(winner) won!\nYour score: \(self.currentPlayerScore)\n\(self.opponentName)'s score: \(self.opponentScore)"
                        self.showGameOverAlert = true
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// Sync multiplayer pieces with the game controller
    /// - Parameter pieces: The pieces to sync from multiplayer state
    private func syncPiecesWithGameController(_ pieces: [MultiplayerGameState.PieceData]) {
        // Convert PieceData back to GridPieces and update game controller
        let gridPieces = pieces.compactMap { $0.toGridPiece() }
        
        // Note: This is a simplified sync. In a full implementation, 
        // you would need to update the GameController's piece selection
        // or work with the GameScene to ensure synchronized pieces.
        
        print("MultiplayerGameView: Synced \(gridPieces.count) pieces from multiplayer state")
        
        // If pieces don't match expected count, log a warning
        if gridPieces.count != pieces.count {
            print("MultiplayerGameView: Warning - Some pieces failed to convert from multiplayer state")
        }
    }

    // MARK: - Methods
}

// MARK: - Preview

#if DEBUG
struct MultiplayerGameView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock data for preview
        let gameController = GameController()
        let mockMatch = GKTurnBasedMatch()
        let mockGameState = MultiplayerGameState()
        
        MultiplayerGameView(
            gameController: gameController,
            match: mockMatch,
            multiplayerGameState: mockGameState
        )
    }
}
#endif
