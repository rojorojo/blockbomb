import SwiftUI
import GameKit

/// Comprehensive multiplayer game result view with winner announcement, statistics, and action options
/// Follows GameOverView patterns with multiplayer-specific features
struct MultiplayerResultView: View {
    
    // MARK: - Properties
    let matchResult: MatchResult
    let onRematch: () -> Void
    let onNewGame: () -> Void
    let onMainMenu: () -> Void
    
    // MARK: - State
    @State private var isAnimating = false
    @State private var showStatistics = false
    @State private var celebrationScale = 0.8
    @State private var showActions = false
    @State private var currentStarFrame = 0
    @State private var showError = false
    @State private var errorMessage = ""
    
    @ObservedObject private var matchManager = TurnBasedMatchManager.shared
    
    // MARK: - Match Result Data
    struct MatchResult {
        let playerScore: Int
        let opponentScore: Int
        let opponentName: String
        let matchDuration: TimeInterval
        let totalTurns: Int
        let playerTurns: Int
        let isWinner: Bool
        let isDraw: Bool
        let match: GKTurnBasedMatch?
        
        var result: GameResult {
            if isDraw {
                return .draw
            } else if isWinner {
                return .victory
            } else {
                return .defeat
            }
        }
        
        var scoreDifference: Int {
            return abs(playerScore - opponentScore)
        }
        
        var averageScorePerTurn: Double {
            return playerTurns > 0 ? Double(playerScore) / Double(playerTurns) : 0
        }
    }
    
    enum GameResult {
        case victory
        case defeat
        case draw
        
        var title: String {
            switch self {
            case .victory:
                return "Victory!"
            case .defeat:
                return "Defeat"
            case .draw:
                return "Draw!"
            }
        }
        
        var subtitle: String {
            switch self {
            case .victory:
                return "Well played!"
            case .defeat:
                return "Better luck next time"
            case .draw:
                return "Close match!"
            }
        }
        
        var color: Color {
            switch self {
            case .victory:
                return BlockColors.green
            case .defeat:
                return BlockColors.red
            case .draw:
                return BlockColors.amber
            }
        }
        
        var icon: String {
            switch self {
            case .victory:
                return "crown.fill"
            case .defeat:
                return "xmark.circle.fill"
            case .draw:
                return "equal.circle.fill"
            }
        }
        
        var shouldShowCelebration: Bool {
            return self == .victory
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header with result
                    resultHeader
                    
                    // Score comparison
                    scoreSection
                    
                    // Match statistics
                    if showStatistics {
                        statisticsSection
                    }
                    
                    // Action buttons
                    if showActions {
                        actionButtons
                    }
                }
                .padding()
            }
            
            // Celebration overlay for victories
            if matchResult.result.shouldShowCelebration && isAnimating {
                celebrationOverlay
            }
            
            // Error overlay
            if showError {
                errorOverlay
            }
        }
        .onAppear {
            startAnimation()
            announceResult()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var resultHeader: some View {
        VStack(spacing: 20) {
            // Result icon
            Image(systemName: matchResult.result.icon)
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(matchResult.result.color)
                .scaleEffect(celebrationScale)
                .opacity(isAnimating ? 1 : 0)
            
            // Result title
            VStack(spacing: 8) {
                Text(matchResult.result.title)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(matchResult.result.color)
                
                Text(matchResult.result.subtitle)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(matchResult.result.title). \(matchResult.result.subtitle)")
    }
    
    private var scoreSection: some View {
        VStack(spacing: 20) {
            // Final scores
            HStack(spacing: 40) {
                // Player score
                VStack(spacing: 8) {
                    Text("YOU")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(BlockColors.cyan.opacity(0.8))
                    
                    Text("\(matchResult.playerScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
                        .accessibilityLabel("Your final score: \(matchResult.playerScore)")
                }
                
                Text("VS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                
                // Opponent score
                VStack(spacing: 8) {
                    Text(matchResult.opponentName.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(BlockColors.purple.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text("\(matchResult.opponentScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(BlockColors.purple)
                        .accessibilityLabel("\(matchResult.opponentName)'s final score: \(matchResult.opponentScore)")
                }
            }
            
            // Score difference
            if !matchResult.isDraw {
                Text("Difference: \(matchResult.scoreDifference)")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .opacity(showStatistics ? 1 : 0)
        .offset(y: showStatistics ? 0 : 20)
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Match Statistics")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Duration",
                    value: formatDuration(matchResult.matchDuration),
                    icon: "clock.fill",
                    color: BlockColors.blue
                )
                
                StatCard(
                    title: "Total Turns",
                    value: "\(matchResult.totalTurns)",
                    icon: "arrow.triangle.2.circlepath",
                    color: BlockColors.green
                )
                
                StatCard(
                    title: "Your Turns",
                    value: "\(matchResult.playerTurns)",
                    icon: "person.fill",
                    color: BlockColors.cyan
                )
                
                StatCard(
                    title: "Avg Score/Turn",
                    value: String(format: "%.1f", matchResult.averageScorePerTurn),
                    icon: "chart.line.uptrend.xyaxis",
                    color: BlockColors.amber
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Primary actions
            VStack(spacing: 12) {
                // Rematch button (if available)
                if matchResult.match != nil {
                    Button(action: {
                        requestRematch()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                            Text("Request Rematch")
                                .font(.title3.bold())
                        }
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .background(BlockColors.green)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Request a rematch with \(matchResult.opponentName)")
                }
                
                // New game button
                Button(action: onNewGame) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("New Multiplayer Game")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(BlockColors.blue)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Start a new multiplayer game")
            }
            
            // Secondary actions
            VStack(spacing: 8) {
                Button(action: onMainMenu) {
                    Text("Main Menu")
                        .font(.body.bold())
                        .foregroundColor(BlockColors.purple)
                        .frame(width: 250, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(BlockColors.purple, lineWidth: 2)
                        )
                }
                .accessibilityLabel("Return to main menu")
            }
        }
    }
    
    private var celebrationOverlay: some View {
        ZStack {
            // Particle effects for victory
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(Color.random)
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...600)
                    )
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1.5 : 0.5)
                    .animation(
                        .easeOut(duration: 1.5)
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
    }
    
    private var errorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(BlockColors.red)
            
            Text("Unable to Request Rematch")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("OK") {
                showError = false
            }
            .font(.body.bold())
            .foregroundColor(.white)
            .frame(width: 100, height: 40)
            .background(BlockColors.blue)
            .cornerRadius(8)
        }
        .padding(20)
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .frame(maxWidth: 300)
    }
    
    // MARK: - Animation Methods
    
    private func startAnimation() {
        // Initial result animation
        withAnimation(.easeOut(duration: 0.5)) {
            isAnimating = true
        }
        
        // Celebration scale for victories
        if matchResult.result.shouldShowCelebration {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 8).delay(0.3)) {
                celebrationScale = 1.2
            }
        }
        
        // Show statistics after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.6)) {
                showStatistics = true
            }
        }
        
        // Show action buttons after statistics
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                showActions = true
            }
        }
    }
    
    private func announceResult() {
        let announcement: String
        switch matchResult.result {
        case .victory:
            announcement = "Victory! You won with \(matchResult.playerScore) points against \(matchResult.opponentName) who scored \(matchResult.opponentScore) points."
        case .defeat:
            announcement = "Defeat. \(matchResult.opponentName) won with \(matchResult.opponentScore) points. Your score was \(matchResult.playerScore) points."
        case .draw:
            announcement = "Draw! Both you and \(matchResult.opponentName) scored \(matchResult.playerScore) points."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    // MARK: - Action Methods
    
    private func requestRematch() {
        guard let match = matchResult.match else {
            showError(message: "Match is no longer available for rematch")
            return
        }
        
        // Create new match with same opponent
        let participants = match.participants
        guard let opponent = participants.first(where: { $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID }) else {
            showError(message: "Cannot find opponent for rematch")
            return
        }
        
        // For now, just call the new game action
        // In a full implementation, you would create a new match with the specific opponent
        onNewGame()
        
        // Note: Full rematch implementation would involve:
        // 1. Creating a new GKMatchRequest with the specific opponent
        // 2. Presenting match maker with that request
        // 3. Handling the rematch workflow
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        
        UIAccessibility.post(notification: .announcement, argument: "Error: \(message)")
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.4))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Extensions

extension Color {
    static var random: Color {
        let colors = [
            BlockColors.cyan, BlockColors.purple, BlockColors.amber,
            BlockColors.green, BlockColors.blue, BlockColors.red
        ]
        return colors.randomElement() ?? BlockColors.cyan
    }
}

// MARK: - Preview

#if DEBUG
struct MultiplayerResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MultiplayerResultView(
                matchResult: MultiplayerResultView.MatchResult(
                    playerScore: 1250,
                    opponentScore: 980,
                    opponentName: "Player123",
                    matchDuration: 180,
                    totalTurns: 12,
                    playerTurns: 6,
                    isWinner: true,
                    isDraw: false,
                    match: nil
                ),
                onRematch: {},
                onNewGame: {},
                onMainMenu: {}
            )
            .previewDisplayName("Victory")
            
            MultiplayerResultView(
                matchResult: MultiplayerResultView.MatchResult(
                    playerScore: 850,
                    opponentScore: 1100,
                    opponentName: "Champion",
                    matchDuration: 240,
                    totalTurns: 14,
                    playerTurns: 7,
                    isWinner: false,
                    isDraw: false,
                    match: nil
                ),
                onRematch: {},
                onNewGame: {},
                onMainMenu: {}
            )
            .previewDisplayName("Defeat")
            
            MultiplayerResultView(
                matchResult: MultiplayerResultView.MatchResult(
                    playerScore: 1000,
                    opponentScore: 1000,
                    opponentName: "EqualPlayer",
                    matchDuration: 200,
                    totalTurns: 10,
                    playerTurns: 5,
                    isWinner: false,
                    isDraw: true,
                    match: nil
                ),
                onRematch: {},
                onNewGame: {},
                onMainMenu: {}
            )
            .previewDisplayName("Draw")
        }
    }
}
#endif
