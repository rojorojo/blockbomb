import SwiftUI

#if DEBUG
/// Debug panel for testing game mechanics and scenarios
/// Only available in debug builds
struct DebugPanelView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Debug actions to be passed from the parent view
    let onTestBugScenario: () -> Void
    let onTestGameOver: () -> Void
    let onNearlyFullBoard: () -> Void
    let onResetHearts: () -> Void
    let onForceCheck: () -> Void
    let onViewShapes: () -> Void
    let onTestHighScoreAnimation: () -> Void
    let onSetTestHighScore: () -> Void
    let onSimulateHighScoreCrossing: () -> Void
    
    // Currency system debug actions
    let onResetPoints: () -> Void
    let onAddTestPoints: () -> Void
    let onSimulateAds: () -> Void
    
    // Powerup shop debug actions
    let onTestReviveHeartPurchase: () -> Void
    let onMakeAllPowerupsAvailable: () -> Void
    let onResetShopPrices: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    Text("Debug Panel")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(BlockColors.violet)
                        .padding(.top, 40)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            
                            // Game Over Testing Section
                            DebugSection(title: "Game Over Testing") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Test Bug Scenario",
                                        subtitle: "Test the specific game over bug with Elbow + T-Shape pieces",
                                        color: .red,
                                        action: onTestBugScenario
                                    )
                                    
                                    DebugButton(
                                        title: "Test Game Over",
                                        subtitle: "Create a general game over testing scenario",
                                        color: .orange,
                                        action: onTestGameOver
                                    )
                                    
                                    DebugButton(
                                        title: "Nearly Full Board",
                                        subtitle: "Create a nearly full board for manual testing",
                                        color: .yellow,
                                        action: onNearlyFullBoard
                                    )
                                    
                                    DebugButton(
                                        title: "Force Check",
                                        subtitle: "Manually trigger game over detection",
                                        color: .cyan,
                                        action: onForceCheck
                                    )
                                }
                            }
                            
                            // Revive System Testing Section
                            DebugSection(title: "Revive System") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Reset Hearts",
                                        subtitle: "Reset revive heart count to 3 for testing",
                                        color: .red,
                                        action: onResetHearts
                                    )
                                }
                            }
                            
                            // Currency System Testing Section
                            DebugSection(title: "Currency System") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Reset Points",
                                        subtitle: "Reset point balance to 0 for testing",
                                        color: .blue,
                                        action: onResetPoints
                                    )
                                    
                                    DebugButton(
                                        title: "Add Test Points",
                                        subtitle: "Add 100 points for testing purchases",
                                        color: .green,
                                        action: onAddTestPoints
                                    )
                                    
                                    DebugButton(
                                        title: "Simulate 5 Ads",
                                        subtitle: "Simulate watching 5 ads (50 points)",
                                        color: .yellow,
                                        action: onSimulateAds
                                    )
                                }
                            }
                            
                            // Powerup Shop Testing Section
                            DebugSection(title: "Powerup Shop") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Test Revive Heart Purchase",
                                        subtitle: "Test purchasing a revive heart (20 points)",
                                        color: .purple,
                                        action: onTestReviveHeartPurchase
                                    )
                                    
                                    DebugButton(
                                        title: "Make All Powerups Available",
                                        subtitle: "Enable all powerups for testing",
                                        color: .blue,
                                        action: onMakeAllPowerupsAvailable
                                    )
                                    
                                    DebugButton(
                                        title: "Reset Shop Prices",
                                        subtitle: "Reset all powerup prices to defaults",
                                        color: .orange,
                                        action: onResetShopPrices
                                    )
                                }
                            }
                            
                            // High Score Animation Testing Section
                            DebugSection(title: "High Score Animation") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Set Test High Score",
                                        subtitle: "Set high score to 500 for testing animation",
                                        color: .purple,
                                        action: onSetTestHighScore
                                    )
                                    
                                    DebugButton(
                                        title: "Test Animation",
                                        subtitle: "Force trigger high score animation",
                                        color: .green,
                                        action: onTestHighScoreAnimation
                                    )
                                    
                                    DebugButton(
                                        title: "Simulate High Score Crossing",
                                        subtitle: "Test real-time high score detection during gameplay",
                                        color: .orange,
                                        action: onSimulateHighScoreCrossing
                                    )
                                }
                            }
                            
                            // Game Content Section
                            DebugSection(title: "Game Content") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "View All Shapes",
                                        subtitle: "Browse all available tetromino shapes",
                                        color: .blue,
                                        action: onViewShapes
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
                            .font(.title2.bold())
                            .foregroundColor(Color(red: 0.13, green: 0.12, blue: 0.28))
                            .frame(width: 200, height: 50)
                            .background(BlockColors.violet)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, 40)
                }
                .navigationBarHidden(true)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

/// A section container for grouping debug options
struct DebugSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            VStack(spacing: 8) {
                content()
            }
            .padding(20)
            .background(Color(red: 0.13, green: 0.12, blue: 0.28))
            .cornerRadius(16)
        }
    }
}

/// A styled debug button with title and subtitle
struct DebugButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Color indicator circle
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DebugPanelView_Previews: PreviewProvider {
    static var previews: some View {
        DebugPanelView(
            onTestBugScenario: {},
            onTestGameOver: {},
            onNearlyFullBoard: {},
            onResetHearts: {},
            onForceCheck: {},
            onViewShapes: {},
            onTestHighScoreAnimation: {},
            onSetTestHighScore: {},
            onSimulateHighScoreCrossing: {},
            onResetPoints: {},
            onAddTestPoints: {},
            onSimulateAds: {},
            onTestReviveHeartPurchase: {},
            onMakeAllPowerupsAvailable: {},
            onResetShopPrices: {}
        )
    }
}
        
    


#endif
