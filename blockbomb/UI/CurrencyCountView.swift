import SwiftUI

/// Currency count view component for displaying points/coins earned from ads
struct CurrencyCountView: View {
    @ObservedObject private var currencyManager = PowerupCurrencyManager.shared
    @State private var previousPoints: Int = 0
    @State private var animationOffset: CGFloat = 0
    @State private var animationOpacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 4) {
            // Coin icon
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(BlockColors.amber)
                .font(.system(size: 16))
            
            // Points count with animation
            Text("\(currencyManager.points)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BlockColors.amber)
                .offset(y: animationOffset)
                .opacity(animationOpacity)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animationOffset)
                .animation(.easeInOut(duration: 0.3), value: animationOpacity)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onChange(of: currencyManager.points) { oldValue, newValue in
            // Animate when points change
            if newValue != previousPoints {
                animatePointsChange()
                previousPoints = newValue
            }
        }
        .onAppear {
            previousPoints = currencyManager.points
        }
    }
    
    /// Animate the points display when currency changes
    private func animatePointsChange() {
        // Quick bounce animation for points change
        withAnimation(.easeOut(duration: 0.1)) {
            animationOffset = -3
            animationOpacity = 0.7
        }
        
        // Return to normal position
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
            animationOffset = 0
            animationOpacity = 1.0
        }
    }
}
