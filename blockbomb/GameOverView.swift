import SwiftUI

struct GameOverView: View {
    let finalScore: Int
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            // Game over content
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                
                VStack {
                    Text("Final Score")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(finalScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
                
                
                VStack(spacing: 15) {
                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 220, height: 50)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button(action: onMainMenu) {
                        Text("Main Menu")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 180, height: 40)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
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
            onRestart: {},
            onMainMenu: {}
        )
    }
}
