import SwiftUI

struct ReviveAnimationView: View {
    @State private var currentFrame = 0
    @State private var isAnimating = false
    @State private var scale = 0.5
    @State private var opacity = 0.0
    
    let onAnimationComplete: () -> Void
    
    private let frameCount = 20
    private let animationSpeed = 0.05 // 50ms per frame for smooth animation
    
    var body: some View {
        // Heart animation frames - no full screen flash since this is positioned over HeartCountView
        Image("Fx06_\(String(format: "%02d", currentFrame))")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80) // Smaller size for positioning over HeartCountView
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeOut(duration: 0.3), value: scale)
            .animation(.easeOut(duration: 0.3), value: opacity)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Play revive success audio and haptic feedback when animation starts
        AudioManager.shared.playReviveSound()
        AudioManager.shared.triggerHapticFeedback(for: .revive)
        
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
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.3
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onAnimationComplete()
        }
    }
}

#Preview {
    ReviveAnimationView {
        print("Animation completed")
    }
    .background(Color.black)
}
