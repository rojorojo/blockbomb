import SwiftUI

/// Overlay view that prompts players to watch an ad for bonus coins during gameplay
/// Non-intrusive design that doesn't interfere with game flow
struct BonusAdPromptView: View {
    let onWatchAd: () -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // Compact bonus ad prompt
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(BlockColors.cyan)
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Bonus Coins")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 14))
                        }
                    }
                    
                    // Watch ad button
                    Button(action: onWatchAd) {
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(BlockColors.amber)
                                .font(.system(size: 12))
                            
                            Text("+10")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(BlockColors.amber)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(BlockColors.amber.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BlockColors.amber.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding(12)
                .background(Color(red: 0.13, green: 0.12, blue: 0.28).opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(BlockColors.violet.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(scale)
                .opacity(isVisible ? 1.0 : 0.0)
                
                Spacer()
            }
            
            Spacer()
                .frame(height: 120) // Position above bottom UI elements
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
                scale = 1.0
            }
            
            // Auto-dismiss after 5 seconds if not interacted with
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if isVisible {
                    dismissWithAnimation()
                }
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isVisible = false
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview
struct BonusAdPromptView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                .ignoresSafeArea()
            
            BonusAdPromptView(
                onWatchAd: {
                    print("Watch ad tapped")
                },
                onDismiss: {
                    print("Dismiss tapped")
                }
            )
        }
    }
}
