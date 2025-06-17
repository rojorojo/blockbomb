import SwiftUI

/// Animation view for displaying ad reward completion feedback
/// Shows coin/points earning animation with "+10 Points" text display
struct AdRewardAnimationView: View {
    @State private var currentFrame = 0
    @State private var isAnimating = false
    @State private var scale = 0.5
    @State private var opacity = 0.0
    @State private var textOffset: CGFloat = 0
    @State private var textOpacity = 0.0
    @State private var textScale = 0.8
    @State private var particleOffset: CGFloat = 0
    @State private var particleOpacity = 0.0
    
    let onAnimationComplete: () -> Void
    let pointsEarned: Int
    
    // Animation configuration
    private let frameCount = 20 // Coin animation frames (similar to revive heart)
    private let animationSpeed = 0.06 // 60ms per frame for smooth animation
    private let totalDuration: TimeInterval = 2.5 // Total animation duration
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
            
            VStack(spacing: 16) {
                // Coin animation container
                ZStack {
                    // Main coin animation (using system icon as placeholder for now)
                    // In a real implementation, this would use actual coin animation frames
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(BlockColors.amber)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .shadow(color: BlockColors.amber.opacity(0.5), radius: 8)
                    
                    // Particle effects around the coin
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(BlockColors.yellow)
                            .frame(width: 6, height: 6)
                            .offset(
                                x: cos(Double(index) * .pi / 4) * CGFloat(30 + particleOffset),
                                y: sin(Double(index) * .pi / 4) * CGFloat(30 + particleOffset)
                            )
                            .opacity(particleOpacity)
                            .scaleEffect(0.5 + particleOpacity * 0.5)
                    }
                    
                    // Additional sparkle particles
                    ForEach(0..<12, id: \.self) { index in
                        Circle()
                            .fill(index % 2 == 0 ? BlockColors.amber : BlockColors.orange)
                            .frame(width: 4, height: 4)
                            .offset(
                                x: cos(Double(index) * .pi / 6) * CGFloat(50 + particleOffset * 1.5),
                                y: sin(Double(index) * .pi / 6) * CGFloat(50 + particleOffset * 1.5)
                            )
                            .opacity(particleOpacity * 0.7)
                            .scaleEffect(0.3 + particleOpacity * 0.4)
                    }
                }
                
                // Points earned text with animation
                Text("+\(pointsEarned) coins")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(BlockColors.amber)
                    .scaleEffect(textScale)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                // Secondary celebration text
                Text("Ad Reward Earned!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .opacity(textOpacity * 0.8)
                    .offset(y: textOffset)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Play ad reward sound and haptic feedback when animation starts
        AudioManager.shared.playAdRewardSound()
        AudioManager.shared.triggerHapticFeedback(for: .adReward)
        
        // Phase 1: Initial appearance (0.0 - 0.3s)
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Phase 2: Text and particle entrance (0.2 - 0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                textOpacity = 1.0
                textScale = 1.0
                textOffset = -10
            }
            
            withAnimation(.easeOut(duration: 0.4)) {
                particleOpacity = 1.0
                particleOffset = 20
            }
        }
        
        // Phase 3: Celebration pulse (0.8 - 1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.2
                textScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                    textScale = 1.0
                }
            }
        }
        
        // Phase 4: Particle expansion (1.0 - 1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.8)) {
                particleOffset = 60
                particleOpacity = 0.0
            }
        }
        
        // Phase 5: Exit animation (1.8 - 2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            exitAnimation()
        }
    }
    
    private func exitAnimation() {
        // Fade out everything smoothly
        withAnimation(.easeOut(duration: 0.7)) {
            scale = 1.3
            opacity = 0.0
            textOpacity = 0.0
            textOffset = -30
        }
        
        // Complete animation callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onAnimationComplete()
        }
    }
}

// MARK: - Preview
#Preview {
    AdRewardAnimationView(onAnimationComplete: {
        print("Ad reward animation completed")
    }, pointsEarned: 10)
    .background(Color.black)
}
