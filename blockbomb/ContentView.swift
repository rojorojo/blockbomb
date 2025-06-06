import SpriteKit
import SwiftUI

struct ContentView: View {
    // Use a single source of truth with @StateObject
    @StateObject private var gameController = GameController()
    @State private var showSettings = false

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
                        // Attempt to revive using hearts
                        if gameController.attemptRevive() {
                            // Revive successful - game continues
                            print("Revive successful!")
                        } else {
                            // Revive failed - show error (could add alert here)
                            print("Revive failed - insufficient hearts or no saved state")
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
    @State private var heartCount: Int = ReviveHeartManager.shared.getHeartCount()
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
            
            Text("\(heartCount)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
        )
        .onReceive(NotificationCenter.default.publisher(for: .init("HeartCountChanged"))) { _ in
            // Update heart count when it changes
            heartCount = ReviveHeartManager.shared.getHeartCount()
        }
        .onAppear {
            // Refresh heart count when view appears
            heartCount = ReviveHeartManager.shared.getHeartCount()
        }
    }
}

#Preview {
    ContentView()
        
}
