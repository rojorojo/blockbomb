import SpriteKit
import SwiftUI

struct ContentView: View {
    // Use a single source of truth with @StateObject
    @StateObject private var gameController = GameController()
    @State private var showSettings = false
    @State private var showReviveAnimation = false
    #if DEBUG
    @State private var showDebugPanel = false
    #endif

    var body: some View {
        ZStack {
            // Game scene
            GameSceneView(
                gameController: gameController,
                onShapeGalleryRequest: {
                    // Handle shape gallery request
                }
            )
            .ignoresSafeArea()

            // Score overlay
            
            VStack (spacing: 0) {
                HStack {
                    
                    // Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(BlockColors.slate)
                            .frame(width: 44, height: 44)
                            
                    }
                    
                    #if DEBUG
                    // Debug panel button (only in debug builds)
                    Button(action: {
                        showDebugPanel = true
                    }) {
                        Image(systemName: "ant.fill")
                            .font(.title2)
                            .foregroundColor(BlockColors.red)
                            .frame(width: 44, height: 44)
                    }
                    #endif
                    
                    Spacer()
                    
                }
                .padding(.top, -10) // Reduce padding if needed
                    .padding(.horizontal)
                
                VStack(spacing: 20) {
                    ScoreView(
                        score: gameController.score,
                        highScore: gameController.highScore
                    )
                    
                    
                    // Hearts display with revive animation overlay
                    HeartCountView()
                        .overlay(
                            // Revive animation overlay - positioned over HeartCountView
                            Group {
                                if showReviveAnimation {
                                    ReviveAnimationView {
                                        // Animation completed, hide it
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            showReviveAnimation = false
                                        }
                                    }
                                    .transition(.opacity)
                                }
                            }
                        )
                }
                
                
                Spacer()
                
                
            }
            .ignoresSafeArea(.keyboard)

            // Game over overlay
            if gameController.isGameOver {
                GameOverView(
                    finalScore: gameController.finalScore,
                    highScore: gameController.highScore,
                    isNewHighScore: gameController.isNewHighScore,
                    onRestart: {
                        gameController.restartGame()
                    },
                    onMainMenu: {
                        // For now, just restart
                        gameController.restartGame()
                    },
                    gameController: gameController,
                    onRevive: {
                        // New flow: immediately go to gameboard, reduce hearts, then show animation
                        let reviveSuccess = gameController.attemptRevive()
                        
                        if reviveSuccess {
                            // Show revive animation on top of the HeartCountView
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showReviveAnimation = true
                            }
                        } else {
                            // Revive failed - could show error alert here
                            print("Revive failed - insufficient hearts or restoration failed")
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        #if DEBUG
        .sheet(isPresented: $showDebugPanel) {
            DebugPanelView(
                onTestBugScenario: {
                    // Dismiss debug panel first
                    showDebugPanel = false
                    
                    // Test the specific bug scenario with problematic pieces
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        gameController.gameScene?.gameBoard.debugTestGameOverScenario()
                        let problematicPieces = gameController.gameScene?.gameBoard.debugCreateProblematicPieces() ?? []
                        gameController.gameScene?.setupDraggablePieces(withSpecificShapes: problematicPieces)
                        
                        // Force game over check after setup
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            gameController.gameScene?.checkForGameOver()
                        }
                    }
                },
                onTestGameOver: {
                    // Dismiss debug panel first
                    showDebugPanel = false
                    
                    // Create general game over scenario  
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        gameController.gameScene?.gameBoard.debugTestGameOverScenario()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            gameController.gameScene?.checkForGameOver()
                        }
                    }
                },
                onNearlyFullBoard: {
                    // Dismiss debug panel first
                    showDebugPanel = false
                    
                    // Create nearly full board for manual testing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        gameController.gameScene?.gameBoard.debugCreateNearlyFullBoard()
                    }
                },
                onResetHearts: {
                    // Dismiss debug panel first
                    showDebugPanel = false
                    
                    // Reset revive hearts to 3 for testing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        ReviveHeartManager.shared.debugSetHearts(3)
                    }
                },
                onForceCheck: {
                    // Dismiss debug panel first
                    showDebugPanel = false
                    
                    // Force game over check on current state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        gameController.gameScene?.checkForGameOver()
                    }
                },
                onViewShapes: {
                    // Dismiss debug panel first to avoid presentation conflicts
                    showDebugPanel = false
                    
                    // Wait for the sheet to dismiss before presenting the shape gallery
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        gameController.gameScene?.presentSwiftUIShapeGallery()
                    }
                }
            )
        }
        #endif
    }
}

// Score view component remains unchanged
struct ScoreView: View {
    let score: Int
    let highScore: Int

    var body: some View {
        VStack {
            HStack {

                Text("\(score)")
                    .font(.system(size: 60, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(BlockColors.cyan)  // Use a different color
            }
            
            /*.background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.6))
            )*/
            HStack {
                Text("BEST")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(BlockColors.purple)  // Use a different color

                Text("\(highScore)")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(BlockColors.purple)  // Use a different color
            }
        }
    }
}

// Heart count view component for revive hearts display
struct HeartCountView: View {
    @ObservedObject private var reviveHeartManager = ReviveHeartManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundColor(BlockColors.red)
                .font(.system(size: 16))
            
            Text("\(reviveHeartManager.heartCount)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BlockColors.red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        
    }
}

#Preview {
    ContentView()
        
}
