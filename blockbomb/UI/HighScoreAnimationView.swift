import SwiftUI

struct HighScoreAnimationView: View {
    @State private var currentFrame = 0
    @State private var isAnimating = false
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    let onAnimationComplete: () -> Void
    
    private let frameCount = 24 // high-score-anim has 24 frames (Fx02_00 to Fx02_23)
    private let animationSpeed = 0.06 // 60ms per frame for smooth animation
    
    var body: some View {
        // High score animation frames - positioned over the score display
        Image("Fx02_\(String(format: "%02d", currentFrame))")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120) // Size to cover the score area nicely
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeOut(duration: 0.3), value: scale)
            .animation(.easeOut(duration: 0.3), value: opacity)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Initial appearance animation
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Start frame animation after initial scale-in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateFrames()
        }
    }
    
    private func animateFrames() {
        guard currentFrame < frameCount - 1 else {
            // Animation complete, start exit animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                exitAnimation()
            }
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationSpeed) {
            currentFrame += 1
            animateFrames()
        }
    }
    
    private func exitAnimation() {
        // Scale up and fade out
        withAnimation(.easeOut(duration: 0.4)) {
            scale = 1.3
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onAnimationComplete()
        }
    }
}

#Preview {
    HighScoreAnimationView {
        print("High score animation completed")
    }
    .background(Color.black)
}
