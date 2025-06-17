import SwiftUI

/// Tooltip system for providing contextual help throughout the app
struct TooltipView: View {
    let text: String
    let direction: TooltipDirection
    let backgroundColor: Color
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if direction == .down {
                tooltipArrow
            }
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(backgroundColor)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            if direction == .up {
                tooltipArrow
            }
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
    }
    
    private var tooltipArrow: some View {
        Triangle()
            .fill(backgroundColor)
            .frame(width: 12, height: 6)
            .rotationEffect(.degrees(direction == .up ? 0 : 180))
    }
}

enum TooltipDirection {
    case up, down
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Help overlay system for explaining the ad-supported model
struct HelpOverlayView: View {
    @Binding var isVisible: Bool
    let helpContent: HelpContent
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissHelp()
                }
            
            VStack(spacing: 20) {
                // Help content
                VStack(spacing: 16) {
                    Image(systemName: helpContent.icon)
                        .font(.system(size: 40))
                        .foregroundColor(helpContent.color)
                    
                    Text(helpContent.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(helpContent.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !helpContent.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tips:")
                                .font(.headline)
                                .foregroundColor(helpContent.color)
                            
                            ForEach(helpContent.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(helpContent.color)
                                    Text(tip)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(24)
                .background(Color(red: 0.13, green: 0.12, blue: 0.28))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Dismiss button
                Button(action: dismissHelp) {
                    Text("Got it!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(helpContent.color)
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal, 30)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    private func dismissHelp() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
    }
}

struct HelpContent {
    let icon: String
    let title: String
    let description: String
    let tips: [String]
    let color: Color
    
    static let powerupShopHelp = HelpContent(
        icon: "cart.fill",
        title: "Powerup Shop",
        description: "Use coins earned from watching ads to purchase powerups that help you continue playing.",
        tips: [
            "Watch rewarded video ads to earn coins",
            "Revive hearts let you continue when you run out of moves",
            "Your coin balance is displayed at the top",
            "More powerups will be available in future updates"
        ],
        color: BlockColors.violet
    )
    
    static let adSupportedModelHelp = HelpContent(
        icon: "play.rectangle.fill",
        title: "Free Game Model",
        description: "This game is completely free to play! Ads support the development and let you earn coins for powerups.",
        tips: [
            "Watch ads to earn coins - it's completely optional",
            "Ads help keep the game free for everyone",
            "You can play without watching ads, but coins help a lot",
            "Emergency fallbacks provide some coins when ads aren't available"
        ],
        color: BlockColors.amber
    )
    
    static let currencySystemHelp = HelpContent(
        icon: "dollarsign.circle.fill",
        title: "Coin System",
        description: "Earn coins by watching short video ads, then spend them on useful powerups in the shop.",
        tips: [
            "Each rewarded ad gives you 10 coins",
            "Bonus ads during gameplay give extra coins",
            "Revive hearts cost 20 coins (watch 2 ads)",
            "Your coins are saved automatically"
        ],
        color: BlockColors.amber
    )
}

/// Loading state indicator for ad preparation
struct AdLoadingIndicator: View {
    @State private var animationRotation: Double = 0
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                Image(systemName: "arrow.2.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(BlockColors.amber)
                    .rotationEffect(.degrees(animationRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            animationRotation = 360
                        }
                    }
            }
            
            Text(isLoading ? "Loading ad..." : "Ready")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isLoading ? .white.opacity(0.7) : BlockColors.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

/// Offline mode indicator
struct OfflineModeIndicator: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16))
                .foregroundColor(BlockColors.orange)
            
            Text("Offline Mode")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Image(systemName: "heart.fill")
                .font(.system(size: 12))
                .foregroundColor(BlockColors.red)
                .scaleEffect(animate ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animate)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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

/// Accessibility helper for better navigation
extension View {
    func accessibilityAdSupportedGame() -> some View {
        self
            .accessibilityLabel("Free ad-supported puzzle game")
            .accessibilityHint("Watch ads to earn coins for powerups")
    }
    
    func accessibilityAdButton(isLoading: Bool = false) -> some View {
        self
            .accessibilityLabel(isLoading ? "Loading ad" : "Watch ad for coins")
            .accessibilityHint("Watch a short video to earn 10 coins")
    }
}

struct TooltipView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TooltipView(
                text: "Watch ads to earn coins!",
                direction: .up,
                backgroundColor: BlockColors.amber,
                isVisible: .constant(true)
            )
            .previewDisplayName("Tooltip")
            
            HelpOverlayView(
                isVisible: .constant(true),
                helpContent: .powerupShopHelp
            )
            .previewDisplayName("Help Overlay")
            
            VStack {
                AdLoadingIndicator(isLoading: true)
                AdLoadingIndicator(isLoading: false)
                OfflineModeIndicator()
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Status Indicators")
        }
    }
}
