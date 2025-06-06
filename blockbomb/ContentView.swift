import SpriteKit
import SwiftUI

struct ContentView: View {
    // Use a single source of truth with @StateObject
    @StateObject private var gameController = GameController()
    @State private var showSettings = false
    @State private var showReviveAnimation = false

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
            
            VStack {
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
                    Spacer()
                    
                    // Hearts display
                    HeartCountView()
                }
                    
                    
                    ScoreView(
                        score: gameController.score,
                        highScore: gameController.highScore
                    )
                    
                    
                    
                    
                
                
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity) 

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
                        // Show revive animation first
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showReviveAnimation = true
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
            
            // Revive animation overlay
            if showReviveAnimation {
                ReviveAnimationView {
                    // Animation completed, now attempt the actual revive
                    let reviveSuccess = gameController.attemptRevive()
                    
                    // Hide animation
                    withAnimation(.easeOut(duration: 0.3)) {
                        showReviveAnimation = false
                    }
                    
                    if !reviveSuccess {
                        // Revive failed - could show error alert here
                        print("Revive failed - insufficient hearts or restoration failed")
                    }
                }
                .transition(.opacity)
                .zIndex(200) // Above game over view
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
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
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
            
            Text("\(reviveHeartManager.heartCount)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
        )
    }
}

#Preview {
    ContentView()
        
}
