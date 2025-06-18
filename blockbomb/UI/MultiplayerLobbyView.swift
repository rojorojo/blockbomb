import SwiftUI
import GameKit

struct MultiplayerLobbyView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var gameCenterManager = GameCenterManager.shared
    @ObservedObject private var matchManager = TurnBasedMatchManager.shared
    
    @State private var showCreateMatchOptions = false
    @State private var isCreatingMatch = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showGameCenterMatchmaker = false
    @State private var selectedMatch: GKTurnBasedMatch?
    @State private var showMatchDetails = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                BlockColors.bg
                    .edgesIgnoringSafeArea(.all)
                
                if !gameCenterManager.isAuthenticated {
                    // Authentication required view
                    authenticationRequiredView
                } else {
                    // Main lobby content
                    VStack(spacing: 24) {
                        headerView
                        
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Create new match section
                                createMatchSection
                                
                                // Active matches section
                                if !matchManager.activeMatches.isEmpty {
                                    activeMatchesSection
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                        
                        // Close button
                        closeButton
                    }
                    .padding(.top, 20)
                }
                
                // Loading overlay
                if isCreatingMatch {
                    loadingOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadMatches()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showCreateMatchOptions) {
            createMatchOptionsSheet
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedMatch != nil },
            set: { if !$0 { selectedMatch = nil } }
        )) {
            if let match = selectedMatch {
                MatchDetailsView(match: match)
            }
        }
    }
    
    // MARK: - Authentication Required View
    
    private var authenticationRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(BlockColors.blue)
            
            Text("Game Center Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Sign in to Game Center to play with friends and compete on leaderboards.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                gameCenterManager.authenticatePlayer()
            }) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("Sign In to Game Center")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(BlockColors.blue)
                .cornerRadius(12)
            }
            .accessibilityLabel("Sign in to Game Center")
            .accessibilityHint("Authenticate with Game Center to access multiplayer features")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(BlockColors.blue)
                
                Text("Play with Friends")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Compete in turn-based block puzzle matches!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Create Match Section
    
    private var createMatchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(BlockColors.emerald)
                Text("Start New Match")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Invite friends button
                Button(action: {
                    createMatchWithFriends()
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Friends")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(BlockColors.blue.opacity(0.2))
                    .cornerRadius(12)
                }
                .accessibilityLabel("Invite friends to play")
                .accessibilityHint("Create a new match and invite Game Center friends")
                
                // Random opponent button
                Button(action: {
                    createMatchWithRandomOpponent()
                }) {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Random Opponent")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(BlockColors.purple.opacity(0.2))
                    .cornerRadius(12)
                }
                .accessibilityLabel("Find random opponent")
                .accessibilityHint("Create a new match with a random Game Center player")
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
    
    // MARK: - Active Matches Section
    
    private var activeMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(BlockColors.amber)
                Text("Active Matches (\(matchManager.activeMatches.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            ForEach(matchManager.activeMatches, id: \.matchID) { match in
                MatchRowView(match: match) {
                    selectedMatch = match
                    showMatchDetails = true
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "xmark")
                Text("Close")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(BlockColors.slate.opacity(0.8))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .accessibilityLabel("Close multiplayer lobby")
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Creating match...")
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
        .zIndex(100)
    }
    
    // MARK: - Create Match Options Sheet
    
    private var createMatchOptionsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("How to Play")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 12) {
                    GameRuleView(
                        icon: "arrow.turn.right.up",
                        title: "Turn-Based Play",
                        description: "Players take turns placing pieces on their own 8x8 grid"
                    )
                    
                    GameRuleView(
                        icon: "equal.square",
                        title: "Fair Competition",
                        description: "Both players receive identical piece sets each turn"
                    )
                    
                    GameRuleView(
                        icon: "trophy",
                        title: "Score to Win",
                        description: "Highest score wins when the game ends"
                    )
                    
                    GameRuleView(
                        icon: "clock",
                        title: "No Time Limits",
                        description: "Take your time - matches are asynchronous"
                    )
                }
                
                Spacer()
                
                Button("Got It!") {
                    showCreateMatchOptions = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(20)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Methods
    
    private func loadMatches() {
        matchManager.loadMatches()
    }
    
    private func createMatchWithFriends() {
        isCreatingMatch = true
        
        matchManager.createMatch(inviteMessage: "Let's play BlockBomb!") { match, error in
            DispatchQueue.main.async {
                isCreatingMatch = false
                
                if let error = error {
                    errorMessage = "Failed to create match: \(error.localizedDescription)"
                    showError = true
                } else if match != nil {
                    // Match created successfully - matchManager will handle UI updates
                    print("Match created successfully")
                }
            }
        }
    }
    
    private func createMatchWithRandomOpponent() {
        isCreatingMatch = true
        
        matchManager.createMatchWithRandomOpponents { match, error in
            DispatchQueue.main.async {
                isCreatingMatch = false
                
                if let error = error {
                    errorMessage = "Failed to create match: \(error.localizedDescription)"
                    showError = true
                } else if match != nil {
                    // Match created successfully - matchManager will handle UI updates
                    print("Match created successfully")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MatchRowView: View {
    let match: GKTurnBasedMatch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(opponentName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(matchStatus)
                            .font(.caption)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Text(match.creationDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .accessibilityLabel("Match with \(opponentName)")
        .accessibilityValue(matchStatus)
        .accessibilityHint("Tap to view match details")
    }
    
    private var opponentName: String {
        let participants = match.participants
        let currentPlayerID = gameCenterManager.getPlayerID()
        
        for participant in participants {
            if participant.player?.gamePlayerID != currentPlayerID {
                return participant.player?.displayName ?? "Unknown Player"
            }
        }
        
        return "Unknown Opponent"
    }
    
    private var matchStatus: String {
        switch match.status {
        case .open:
            return "Waiting for opponent"
        case .matching:
            return "Finding opponent"
        case .ended:
            return "Completed"
        default:
            if isMyTurn {
                return "Your turn"
            } else {
                return "Opponent's turn"
            }
        }
    }
    
    private var statusColor: Color {
        switch match.status {
        case .open, .matching:
            return BlockColors.amber
        case .ended:
            return BlockColors.green
        default:
            return isMyTurn ? BlockColors.blue : BlockColors.slate
        }
    }
    
    private var isMyTurn: Bool {
        let currentPlayerID = gameCenterManager.getPlayerID()
        return match.currentParticipant?.player?.gamePlayerID == currentPlayerID
    }
    
    private var gameCenterManager: GameCenterManager {
        GameCenterManager.shared
    }
}

struct GameRuleView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Match Details View

struct MatchDetailsView: View {
    let match: GKTurnBasedMatch
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var matchManager = TurnBasedMatchManager.shared
    
    @State private var showResignConfirmation = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Match info
                VStack(spacing: 12) {
                    Text("Match Details")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("vs \(opponentName)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Match status
                VStack(spacing: 8) {
                    Text(matchStatusText)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    Text("Started \(match.creationDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    if canTakeTurn {
                        Button("Continue Match") {
                            // TODO: Implement match continuation
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    if match.status != .ended {
                        Button("Resign Match") {
                            showResignConfirmation = true
                        }
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(20)
            .navigationBarHidden(true)
        }
        .alert("Resign Match", isPresented: $showResignConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Resign", role: .destructive) {
                resignMatch()
            }
        } message: {
            Text("Are you sure you want to resign this match? This action cannot be undone.")
        }
    }
    
    private var opponentName: String {
        let participants = match.participants
        let currentPlayerID = GameCenterManager.shared.getPlayerID()
        
        for participant in participants {
            if participant.player?.gamePlayerID != currentPlayerID {
                return participant.player?.displayName ?? "Unknown Player"
            }
        }
        
        return "Unknown Opponent"
    }
    
    private var matchStatusText: String {
        switch match.status {
        case .open:
            return "Waiting for opponent to join"
        case .matching:
            return "Finding an opponent"
        case .ended:
            return "Match completed"
        default:
            if canTakeTurn {
                return "It's your turn!"
            } else {
                return "Waiting for opponent's turn"
            }
        }
    }
    
    private var canTakeTurn: Bool {
        let currentPlayerID = GameCenterManager.shared.getPlayerID()
        return match.currentParticipant?.player?.gamePlayerID == currentPlayerID &&
               match.status != .ended
    }
    
    private func resignMatch() {
        isLoading = true
        
        matchManager.quitMatch(match) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    presentationMode.wrappedValue.dismiss()
                } else if let error = error {
                    // Handle error - could show alert
                    print("Failed to resign match: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MultiplayerLobbyView_Previews: PreviewProvider {
    static var previews: some View {
        MultiplayerLobbyView()
    }
}
#endif
