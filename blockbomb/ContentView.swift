import SpriteKit
import SwiftUI

struct ContentView: View {
    // Use a single source of truth with @StateObject
    @StateObject private var gameController = GameController()

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
                Spacer().frame(height: 50)
                

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
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.6))
            )
            HStack {
                Text("Best")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))

                Text("\(highScore)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(BlockColors.cyan)  // Use a different color
            }
        }
    }
}
