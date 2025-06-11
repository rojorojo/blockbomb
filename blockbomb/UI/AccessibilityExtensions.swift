import SwiftUI

// MARK: - Accessibility Extensions for Ad-Supported Game

extension View {
    /// Accessibility modifier for currency display
    func accessibilityCurrencyDisplay(points: Int) -> some View {
        self
            .accessibilityLabel("Current balance: \(points) coins")
            .accessibilityHint("Tap for more information about earning coins")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Accessibility modifier for powerup shop items
    func accessibilityPowerupShop() -> some View {
        self
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to purchase this powerup")
    }
    
    /// Accessibility modifier for ad-supported model explanation
    func accessibilityAdModel() -> some View {
        self
            .accessibilityLabel("Learn about free game model")
            .accessibilityHint("This game is supported by ads. Watch ads to earn coins for powerups.")
    }
    
    /// Accessibility modifier for offline mode indicator
    func accessibilityOfflineMode() -> some View {
        self
            .accessibilityLabel("Offline mode")
            .accessibilityHint("Limited ad availability. Some features may be reduced.")
    }
    
    /// Accessibility modifier for loading states
    func accessibilityLoadingState(isLoading: Bool, context: String = "") -> some View {
        self
            .accessibilityLabel(isLoading ? "Loading \(context)" : "Ready")
            .accessibilityHint(isLoading ? "Please wait while content loads" : "")
    }
}

// MARK: - Accessibility Helper Views

struct AccessibleHelpButton: View {
    let action: () -> Void
    let iconName: String
    let helpText: String
    let color: Color
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(color.opacity(0.7))
        }
        .accessibilityLabel(helpText)
        .accessibilityHint("Double tap to show help information")
        .accessibilityAddTraits(.isButton)
    }
}

struct AccessiblePurchaseButton: View {
    let powerupName: String
    let price: Int
    let canPurchase: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(canPurchase ? "Buy" : "Unavailable")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 80, height: 32)
                .background(canPurchase ? BlockColors.amber : Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!canPurchase)
        .accessibilityLabel("Purchase \(powerupName)")
        .accessibilityValue(canPurchase ? "Available for \(price) coins" : "Not available")
        .accessibilityHint(canPurchase ? "Double tap to purchase" : "Not enough coins or item unavailable")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - VoiceOver Content Descriptions

enum AccessibilityContent {
    static let adSupportedModelExplanation = """
        This is a free game supported by advertisements. 
        Watch ads to earn coins, then use coins to purchase helpful powerups like revive hearts. 
        Ads help keep the game free while giving you ways to enhance your gameplay experience.
        """
    
    static let powerupShopExplanation = """
        The powerup shop lets you spend coins earned from watching ads. 
        Currently available: Revive hearts for 20 coins each. 
        Revive hearts let you continue playing when you run out of moves.
        """
    
    static let offlineModeExplanation = """
        Limited connectivity detected. Some ad features may not be available. 
        You can still play the game, but earning new coins may be restricted until connection improves.
        """
}
