import SwiftUI
import SpriteKit

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
                HStack {
                    Spacer()
                    
                    ScoreView(score: gameController.score)
                        .padding(.top, 10)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            
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
    
    var body: some View {
        HStack {
            Text("Score:")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
        )
    }
}