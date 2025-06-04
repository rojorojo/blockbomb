import SwiftUI
import SpriteKit

struct GameOverView: View {
    let finalScore: Int
    let highScore: Int
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    
    @State private var isAnimating = false
    @StateObject private var gameController = GameController()
    
    var body: some View {
        ZStack {
            
            Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
        .edgesIgnoringSafeArea(.all)
            
            // Game over content
            VStack(spacing: 30) {
                
                Spacer()
                Image("BlockEmUpLogo")
                    .resizable()
                    .frame(width: 144, height: 104)
                    
                Spacer()
                
                Text("So close!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(BlockColors.cyan)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                Spacer()
                VStack {
                    
                    Text("\(finalScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
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
                
                Spacer()
                VStack(spacing: 15) {
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
        GameOverView(
            finalScore: 1250,
            highScore: 2500,
            onRestart: {},
            onMainMenu: {}
            
        )
    }
}
