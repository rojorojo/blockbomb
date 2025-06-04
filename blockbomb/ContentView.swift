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

#Preview {
    ContentView()
        
}
