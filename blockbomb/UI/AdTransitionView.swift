import SwiftUI

/// Smooth transition overlay for ad presentation
struct AdTransitionView: View {
    @Binding var isVisible: Bool
    let progress: Float
    let isOfflineMode: Bool
    let onAnimationComplete: (() -> Void)?
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    
    init(isVisible: Binding<Bool>, progress: Float, isOfflineMode: Bool = false, onAnimationComplete: (() -> Void)? = nil) {
        self._isVisible = isVisible
        self.progress = progress
        self.isOfflineMode = isOfflineMode
        self.onAnimationComplete = onAnimationComplete
    }
    
    var body: some View {
        ZStack {
            // Background dimming
            Color.black
                .opacity(backgroundOpacity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Allow dismissing by tapping background
                    dismissTransition()
                }
            
            VStack(spacing: 20) {
                // Loading indicator
                VStack(spacing: 16) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(BlockColors.amber)
                        .scaleEffect(scale)
                    
                    Text(isOfflineMode ? "Limited Connectivity" : "Preparing Ad")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    Text(isOfflineMode ? "Using emergency fallback" : "Supporting free gameplay")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(opacity)
                    
                    // Animated progress indicator
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(BlockColors.amber)
                                .frame(width: 8, height: 8)
                                .scaleEffect(scale)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: scale
                                )
                        }
                    }
                    .opacity(opacity)
                }
                .padding(40)
                .background(Color(red: 0.13, green: 0.12, blue: 0.28))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                .scaleEffect(scale)
            }
        }
        .onAppear {
            startTransition()
        }
        .onChange(of: isVisible) { visible in
            if !visible {
                dismissTransition()
            }
        }
    }
    
    private func startTransition() {
        // Phase 1: Fade in background
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0.7
        }
        
        // Phase 2: Scale in content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        
        // Auto-dismiss after delay (ads should load quickly)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismissTransition()
        }
    }
    
    private func dismissTransition() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0.0
            backgroundOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onAnimationComplete?()
        }
    }
}

/// Ad preparation indicator that can be used in any view
struct AdPreparationIndicator: View {
    let message: String
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.2.circlepath")
                .font(.title2)
                .foregroundColor(BlockColors.amber)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text(message)
                .font(.body.weight(.medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

/// Enhanced offline mode banner
struct OfflineModeBanner: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.title3)
                .foregroundColor(BlockColors.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Limited Connectivity")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                
                Text("Some features may be unavailable")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.caption)
                .foregroundColor(BlockColors.red)
                .scaleEffect(animate ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animate)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(BlockColors.orange.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(BlockColors.orange, lineWidth: 1)
        )
        .cornerRadius(12)
        .onAppear {
            animate = true
        }
    }
}

struct AdTransitionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AdTransitionView(isVisible: .constant(true), progress: 0.5) {
                print("Transition complete")
            }
            .previewDisplayName("Ad Transition")
            
            AdTransitionView(isVisible: .constant(true), progress: 0.5, isOfflineMode: true) {
                print("Offline transition complete")
            }
            .previewDisplayName("Offline Mode Transition")
            
            VStack(spacing: 20) {
                AdPreparationIndicator(message: "Loading rewarded ad...")
                OfflineModeBanner()
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Indicators")
        }
    }
}
