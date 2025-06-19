import SwiftUI
import SpriteKit

/// Game over view specifically designed for multiplayer competitive results
struct MultiplayerGameOverView: View {
    let gameController: MultiplayerGameController
    let gameEndReason: MultiplayerGameController.GameEndReason
    let playerScore: Int
    let opponentScore: Int
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    let onRematch: (() -> Void)?
    
    @State private var isAnimating = false
    @State private var showResultAnimation = false
    @State private var showStatistics = false
    @ObservedObject private var currencyManager = PowerupCurrencyManager.shared
    
    private var isPlayerWinner: Bool {
        return gameEndReason == .playerWon || gameEndReason == .opponentResigned
    }
    
    private var resultTitle: String {
        switch gameEndReason {
        case .playerWon:
            return "Victory!"
        case .opponentWon:
            return "Defeat"
        case .playerResigned:
            return "You Resigned"
        case .opponentResigned:
            return "Opponent Resigned"
        case .connectionLost:
            return "Connection Lost"
        case .gameTimeout:
            return "Game Timeout"
        case .none:
            return "Game Over"
        }
    }
    
    private var resultMessage: String {
        switch gameEndReason {
        case .playerWon:
            return "You outscored \(gameController.opponentName)!"
        case .opponentWon:
            return "\(gameController.opponentName) outscored you!"
        case .playerResigned:
            return "Better luck next time!"
        case .opponentResigned:
            return "You win by resignation!"
        case .connectionLost:
            return "The match was interrupted"
        case .gameTimeout:
            return "The match timed out"
        case .none:
            return "Thanks for playing!"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Result header
                resultHeaderView
                
                // Score comparison
                scoreComparisonView
                
                // Statistics summary
                if showStatistics {
                    statisticsView
                }
                
                // Action buttons
                actionButtonsView
            }
            .padding(.horizontal, 20)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
                
                // Delayed result animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showResultAnimation = true
                    }
                }
                
                // Show statistics after animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showStatistics = true
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var resultHeaderView: some View {
        VStack(spacing: 15) {
            // Result icon/image
            if isPlayerWinner {
                Image("BEMUP-high-score-trophy")
                    .resizable()
                    .frame(width: 120, height: 122)
                    .scaleEffect(showResultAnimation ? 1.2 : 1.0)
                    .rotationEffect(.degrees(showResultAnimation ? 5 : 0))
            } else {
                Image("BlockEmUpLogo")
                    .resizable()
                    .frame(width: 100, height: 72)
                    .opacity(showResultAnimation ? 0.8 : 1.0)
            }
            
            // Result title
            Text(resultTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(isPlayerWinner ? .yellow : .white)
                .scaleEffect(showResultAnimation ? 1.1 : 1.0)
            
            // Result message
            Text(resultMessage)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var scoreComparisonView: some View {
        VStack(spacing: 20) {
            Text("Final Scores")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 40) {
                // Player score
                VStack(spacing: 8) {
                    Text("You")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("\(playerScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(playerScore >= opponentScore ? .green : .white)
                        .scaleEffect(showResultAnimation && playerScore >= opponentScore ? 1.2 : 1.0)
                }
                
                Text("VS")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                // Opponent score
                VStack(spacing: 8) {
                    Text(gameController.opponentName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text("\(opponentScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(opponentScore > playerScore ? .red : .white)
                        .scaleEffect(showResultAnimation && opponentScore > playerScore ? 1.2 : 1.0)
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(15)
        }
    }
    
    private var statisticsView: some View {
        VStack(spacing: 15) {
            Text("Match Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                statisticCell(title: "Score Difference", value: "\(abs(playerScore - opponentScore))")
                statisticCell(title: "Match Duration", value: formatGameDuration())
                
                // Additional stats from scoring system
                let stats = gameController.getMultiplayerStatistics()
                statisticCell(title: "Your Win Rate", value: "\(Int(stats.winRate * 100))%")
                statisticCell(title: "Games Played", value: "\(stats.gamesPlayed)")
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .scale))
    }
    
    private func statisticCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 15) {
            // Rematch button (if available)
            if let onRematch = onRematch {
                Button(action: onRematch) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Request Rematch")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Request a rematch with \(gameController.opponentName)")
            }
            
            HStack(spacing: 15) {
                // New game button
                Button(action: onRestart) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("New Game")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Start a new multiplayer game")
                
                // Main menu button
                Button(action: onMainMenu) {
                    HStack {
                        Image(systemName: "house")
                        Text("Main Menu")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Return to main menu")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatGameDuration() -> String {
        // This would need to be tracked during the game
        // For now, return a placeholder
        return "5:23"
    }
}

// MARK: - Preview

struct MultiplayerGameOverView_Previews: PreviewProvider {
    static var previews: some View {
        MultiplayerGameOverView(
            gameController: MultiplayerGameController(),
            gameEndReason: .playerWon,
            playerScore: 1250,
            opponentScore: 980,
            onRestart: {},
            onMainMenu: {},
            onRematch: {}
        )
    }
}
