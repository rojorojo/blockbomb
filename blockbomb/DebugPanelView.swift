import SwiftUI

#if DEBUG
/// Debug panel for testing game mechanics and scenarios
/// Only available in debug builds
struct DebugPanelView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showRewardConfigPanel = false
    
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
    
    // Ad Manager debug actions
    let onTestRewardedAd: () -> Void
    let onForceReloadAds: () -> Void
    let onSimulateAdReward: () -> Void
    
    // Ad Timing debug actions
    let onTriggerInterstitialAd: () -> Void
    let onPromptBonusAd: () -> Void
    let onResetAdTimers: () -> Void
    let onSimulateGameCounts: () -> Void
    
    // ML Data Logging debug actions
    let onTestS3Upload: () -> Void
    let onResetSessionCounter: () -> Void
    
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
                            
                            // Ad Manager Testing Section
                            DebugSection(title: "Ad Manager") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Test Rewarded Ad",
                                        subtitle: "Simulate showing a rewarded ad",
                                        color: .green,
                                        action: onTestRewardedAd
                                    )
                                    
                                    DebugButton(
                                        title: "Force Reload Ads",
                                        subtitle: "Reset and reload all ad instances",
                                        color: .blue,
                                        action: onForceReloadAds
                                    )
                                    
                                    DebugButton(
                                        title: "Simulate Ad Reward",
                                        subtitle: "Grant ad reward without showing ad",
                                        color: .orange,
                                        action: onSimulateAdReward
                                    )
                                }
                            }
                            
                            // Ad Timing Testing Section
                            DebugSection(title: "Ad Timing") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Trigger Interstitial Ad",
                                        subtitle: "Force show interstitial ad",
                                        color: .purple,
                                        action: onTriggerInterstitialAd
                                    )
                                    
                                    DebugButton(
                                        title: "Prompt Bonus Ad",
                                        subtitle: "Show bonus ad prompt",
                                        color: .yellow,
                                        action: onPromptBonusAd
                                    )
                                    
                                    DebugButton(
                                        title: "Reset Ad Timers",
                                        subtitle: "Reset game count and cooldown timers",
                                        color: .blue,
                                        action: onResetAdTimers
                                    )
                                    
                                    DebugButton(
                                        title: "Simulate Game Counts",
                                        subtitle: "Add 5 game completions for interstitial testing",
                                        color: .green,
                                        action: onSimulateGameCounts
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
                            
                            // Reward Configuration Section
                            DebugSection(title: "Reward Configuration") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Open Config Panel",
                                        subtitle: "Real-time reward economy tuning",
                                        color: .purple,
                                        action: {
                                            showRewardConfigPanel = true
                                        }
                                    )
                                    
                                    DebugButton(
                                        title: "Apply Test Preset",
                                        subtitle: "Quick test configuration for debugging",
                                        color: .green,
                                        action: {
                                            RewardConfig.shared.debugApplyTestPreset()
                                        }
                                    )
                                    
                                    DebugButton(
                                        title: "Apply Production Preset",
                                        subtitle: "Production-ready configuration values",
                                        color: .blue,
                                        action: {
                                            RewardConfig.shared.debugApplyProductionPreset()
                                        }
                                    )
                                    
                                    DebugButton(
                                        title: "Reset All Config",
                                        subtitle: "Reset all configuration to defaults",
                                        color: .red,
                                        action: {
                                            RewardConfig.shared.resetAllToDefaults()
                                        }
                                    )
                                }
                            }
                            
                            // ML Data Logging Section
                            DebugSection(title: "ML Data Logging") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Test Firebase Upload",
                                        subtitle: "Manually upload current CSV file to Firebase Storage",
                                        color: .green,
                                        action: onTestS3Upload
                                    )
                                    
                                    DebugButton(
                                        title: "Reset Session Counter",
                                        subtitle: "Reset the 20-session counter to restart logging",
                                        color: .orange,
                                        action: onResetSessionCounter
                                    )
                                    
                                    DebugButton(
                                        title: "View Logging Status",
                                        subtitle: "Check current logging and Firebase Storage configuration status",
                                        color: .blue,
                                        action: {
                                            let logger = GameplayDataLogger.shared
                                            let uploader = CSVFirebaseUploader.shared
                                            print("=== ML Data Logging Status ===")
                                            print("Sessions completed: \(logger.getCompletedSessionCount())/\(logger.getMaxSessions())")
                                            print("Logging active: \(logger.isLoggingActive())")
                                            print("CSV file size: \(logger.getCSVFileSize()) bytes")
                                            print("Firebase Status: \(uploader.getConfigurationStatus())")
                                            logger.debugCSVFileStatus()
                                            print("===============================")
                                        }
                                    )
                                    
                                    DebugButton(
                                        title: "Test Firebase Connection",
                                        subtitle: "Test Firebase Storage connection with a simple upload",
                                        color: .purple,
                                        action: {
                                            CSVFirebaseUploader.shared.testFirebaseStorageConnection { success, result in
                                                DispatchQueue.main.async {
                                                    if success {
                                                        print("Debug Firebase Connection: SUCCESS - \(result ?? "unknown")")
                                                    } else {
                                                        print("Debug Firebase Connection: FAILED - \(result ?? "unknown error")")
                                                    }
                                                }
                                            }
                                        }
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
        .sheet(isPresented: $showRewardConfigPanel) {
            RewardConfigDebugView()
        }
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
            onResetShopPrices: {},
            onTestRewardedAd: {},
            onForceReloadAds: {},
            onSimulateAdReward: {},
            onTriggerInterstitialAd: {},
            onPromptBonusAd: {},
            onResetAdTimers: {},
            onSimulateGameCounts: {},
            onTestS3Upload: {},
            onResetSessionCounter: {}
        )
    }
}
        
    


#endif
