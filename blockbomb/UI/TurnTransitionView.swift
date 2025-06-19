import SwiftUI
import SpriteKit

/// Animated view for smooth turn transitions in multiplayer games
/// Provides visual feedback for turn submissions, waiting states, and opponent notifications
struct TurnTransitionView: View {
    
    // MARK: - State Properties
    @State private var isAnimating = false
    @State private var scale = 0.8
    @State private var opacity = 0.0
    @State private var rotationAngle: Double = 0
    @State private var pulseScale = 1.0
    @State private var currentFrame = 0
    @State private var showMessage = false
    
    // MARK: - Configuration
    let transitionType: TransitionType
    let opponentName: String
    let onComplete: () -> Void
    
    // MARK: - Transition Types
    enum TransitionType: Equatable {
        case submittingTurn
        case waitingForOpponent
        case opponentMoved(score: Int)
        case connectionError
        case turnTimeExpired
        
        var title: String {
            switch self {
            case .submittingTurn:
                return "Submitting Turn..."
            case .waitingForOpponent:
                return "Waiting for Opponent"
            case .opponentMoved:
                return "Opponent Moved!"
            case .connectionError:
                return "Connection Issue"
            case .turnTimeExpired:
                return "Turn Time Expired"
            }
        }
        
        var subtitle: String {
            switch self {
            case .submittingTurn:
                return "Sending your move"
            case .waitingForOpponent:
                return "They're thinking..."
            case .opponentMoved(let score):
                return "New score: \(score)"
            case .connectionError:
                return "Reconnecting..."
            case .turnTimeExpired:
                return "Time's up!"
            }
        }
        
        var color: Color {
            switch self {
            case .submittingTurn:
                return BlockColors.blue
            case .waitingForOpponent:
                return BlockColors.amber
            case .opponentMoved:
                return BlockColors.green
            case .connectionError:
                return BlockColors.red
            case .turnTimeExpired:
                return BlockColors.orange
            }
        }
        
        var icon: String {
            switch self {
            case .submittingTurn:
                return "paperplane.fill"
            case .waitingForOpponent:
                return "clock.fill"
            case .opponentMoved:
                return "checkmark.circle.fill"
            case .connectionError:
                return "wifi.exclamationmark"
            case .turnTimeExpired:
                return "timer"
            }
        }
        
        var shouldAutoClose: Bool {
            switch self {
            case .submittingTurn, .opponentMoved, .turnTimeExpired:
                return true
            case .waitingForOpponent, .connectionError:
                return false
            }
        }
        
        var duration: Double {
            switch self {
            case .submittingTurn:
                return 2.0
            case .opponentMoved:
                return 3.0
            case .turnTimeExpired:
                return 2.5
            case .waitingForOpponent, .connectionError:
                return 0 // Don't auto-close
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
            
            // Main transition content
            VStack(spacing: 20) {
                // Animated icon
                iconView
                
                // Title and subtitle
                textContent
                
                // Progress indicator for certain states
                if transitionType == .submittingTurn {
                    progressIndicator
                } else if transitionType == .waitingForOpponent {
                    waitingIndicator
                }
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
            .scaleEffect(scale)
            .opacity(showMessage ? 1 : 0)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - View Components
    
    private var iconView: some View {
        ZStack {
            // Outer pulse ring for waiting states
            if transitionType == .waitingForOpponent {
                Circle()
                    .stroke(transitionType.color.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .opacity(1.0 - (pulseScale - 1.0))
            }
            
            // Main icon
            Image(systemName: transitionType.icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(transitionType.color)
                .rotationEffect(.degrees(rotationAngle))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
        }
        .accessibilityLabel(transitionType.title)
    }
    
    private var textContent: some View {
        VStack(spacing: 8) {
            Text(transitionType.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(transitionType.subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var progressIndicator: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: transitionType.color))
            .scaleEffect(1.2)
    }
    
    private var waitingIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(transitionType.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
    }
    
    // MARK: - Animation Methods
    
    private func startAnimation() {
        // Initial appearance
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 1.0
            scale = 1.0
        }
        
        // Delay for message to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                showMessage = true
            }
        }
        
        // Start specific animations based on type
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startTypeSpecificAnimations()
        }
        
        // Auto-close if needed
        if transitionType.shouldAutoClose {
            DispatchQueue.main.asyncAfter(deadline: .now() + transitionType.duration) {
                closeAnimation()
            }
        }
        
        // Announce for accessibility
        announceTransition()
    }
    
    private func startTypeSpecificAnimations() {
        switch transitionType {
        case .submittingTurn:
            // Rotating plane animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
        case .waitingForOpponent:
            // Pulsing animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
        case .opponentMoved:
            // Success bounce animation
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 10)) {
                isAnimating = true
            }
            
        case .connectionError:
            // Error shake animation
            withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                rotationAngle = 5
            }
            
        case .turnTimeExpired:
            // Urgent pulse animation
            withAnimation(.easeInOut(duration: 0.3).repeatCount(5, autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func closeAnimation() {
        withAnimation(.easeIn(duration: 0.3)) {
            showMessage = false
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onComplete()
        }
    }
    
    private func announceTransition() {
        let announcement: String
        switch transitionType {
        case .submittingTurn:
            announcement = "Submitting your turn to \(opponentName)"
        case .waitingForOpponent:
            announcement = "Waiting for \(opponentName) to make their move"
        case .opponentMoved(let score):
            announcement = "\(opponentName) made their move. Their new score is \(score)"
        case .connectionError:
            announcement = "Connection issue. Attempting to reconnect to match with \(opponentName)"
        case .turnTimeExpired:
            announcement = "Turn time expired. Advancing to next turn"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    // MARK: - Public Methods
    
    /// Manually close the transition view
    func close() {
        closeAnimation()
    }
}

// MARK: - Preview

#if DEBUG
struct TurnTransitionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TurnTransitionView(
                transitionType: .submittingTurn,
                opponentName: "Player",
                onComplete: {}
            )
            .previewDisplayName("Submitting Turn")
            
            TurnTransitionView(
                transitionType: .waitingForOpponent,
                opponentName: "Player",
                onComplete: {}
            )
            .previewDisplayName("Waiting")
            
            TurnTransitionView(
                transitionType: .opponentMoved(score: 1250),
                opponentName: "Player",
                onComplete: {}
            )
            .previewDisplayName("Opponent Moved")
            
            TurnTransitionView(
                transitionType: .connectionError,
                opponentName: "Player",
                onComplete: {}
            )
            .previewDisplayName("Connection Error")
        }
    }
}
#endif
