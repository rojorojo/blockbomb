import SwiftUI
import SpriteKit

struct GameOverView: View {
    let finalScore: Int
    let highScore: Int
    let isNewHighScore: Bool
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    let gameController: GameController? // Add game controller for revive functionality
    let onRevive: (() -> Void)? // Add revive callback
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            
            Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
        .edgesIgnoringSafeArea(.all)
            
            // Game over content
            VStack(spacing: 30) {
                
                
                
                // Display different image based on whether it's a new high score
                if isNewHighScore {
                    
                    Image("BEMUP-high-score-trophy")
                        .resizable()
                        .frame(width: 339, height: 345)
                } else {
                    Spacer()
                    Image("BlockEmUpLogo")
                        .resizable()
                        .frame(width: 144, height: 104)
                    Spacer()
                }
                    
                
                
                // Display different text based on whether it's a new high score
                if isNewHighScore {
                    Text("You did it!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.5)
                } else {
                    Text("So close!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.5)
                    Spacer()
                }
                
                VStack {
                    
                    Text("\(finalScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
                    if isNewHighScore {
                        Text("YOUR NEW BEST")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(BlockColors.purple)
                        
                    } else {
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
                
                Spacer()
                VStack(spacing: 15) {
                    // Revive button - only show if hearts available and revive callback exists
                    if let gameController = gameController,
                       let onRevive = onRevive,
                       gameController.canRevive() {
                        Button(action: onRevive) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("REVIVE")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("(\(ReviveHeartManager.shared.getHeartCount()))")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(width: 220, height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 220, height: 50)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Spacer()
                    /*Button(action: onMainMenu) {
                        Text("Main Menu")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 180, height: 40)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }*/
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

struct GameOverView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Regular game over preview
            GameOverView(
                finalScore: 1250,
                highScore: 2500,
                isNewHighScore: false,
                onRestart: {},
                onMainMenu: {},
                gameController: nil,
                onRevive: nil
            )
            .previewDisplayName("Regular Game Over")
            
            // New high score preview
            GameOverView(
                finalScore: 2750,
                highScore: 2750,
                isNewHighScore: true,
                onRestart: {},
                onMainMenu: {},
                gameController: nil,
                onRevive: nil
            )
            .previewDisplayName("New High Score")
        }
    }
}
