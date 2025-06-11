import SwiftUI
import SpriteKit

struct GameOverView: View {
    let finalScore: Int
    let highScore: Int
    let isNewHighScore: Bool
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    let gameController: GameController? // Add game controller for revive functionality
    let onRevive: (() -> Void)? // Add revive callback
    
    @State private var isAnimating = false
    @State private var showShop = false
    @State private var showPurchaseSuccess = false
    @State private var showAdSuccess = false
    @State private var showAdRewardAnimation = false
    @State private var adRewardPoints = 10
    @State private var showError = false
    @State private var errorMessage = ""
    @ObservedObject private var reviveHeartManager = ReviveHeartManager.shared
    @ObservedObject private var currencyManager = PowerupCurrencyManager.shared
    @ObservedObject private var shopManager = PowerupShopManager.shared
    @ObservedObject private var adManager = AdManager.shared
    
    var body: some View {
        ZStack {
            
            Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
        .edgesIgnoringSafeArea(.all)
            
            // Game over content
            VStack(spacing: 30) {
                
                
                
                // Display different image based on whether it's a new high score
                if isNewHighScore {
                    
                    Image("BEMUP-high-score-trophy")
                        .resizable()
                        .frame(width: 339, height: 345)
                } else {
                    Spacer()
                    Image("BlockEmUpLogo")
                        .resizable()
                        .frame(width: 144, height: 104)
                    Spacer()
                }
                    
                
                
                // Display different text based on whether it's a new high score
                if isNewHighScore {
                    Text("You did it!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.5)
                } else {
                    Text("So close!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.5)
                    Spacer()
                }
                
                VStack {
                    
                    Text("\(finalScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(BlockColors.cyan)
                    if isNewHighScore {
                        Text("YOUR NEW BEST")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(BlockColors.purple)
                        
                    } else {
                        HStack {
                            Text("BEST")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(BlockColors.purple)  // Use a different color
                            
                            Text("\(highScore)")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(BlockColors.purple)  // Use a different color
                        }
                    }
                }
                
                Spacer()
                VStack(spacing: 15) {
                    // Revive button - only show if hearts available and revive callback exists
                    if let gameController = gameController,
                       let onRevive = onRevive,
                       gameController.canRevive() {
                        Button(action: onRevive) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(BlockColors.red)
                                /*Image(systemName: "xmark")
                                    .foregroundColor(BlockColors.red)*/
                                Text("\(reviveHeartManager.heartCount)")
                                    .font(.title3)
                                    .foregroundColor(BlockColors.red)
                            }
                            .frame(width: 220, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(BlockColors.red, lineWidth: 3)
                            )
                        }
                    }
                    
                    // Buy Revive Heart button - show if player has enough coins but no hearts
                    if !reviveHeartManager.hasHearts() && shopManager.canPurchase(.reviveHeart) {
                        Button(action: {
                            let result = shopManager.purchasePowerup(.reviveHeart)
                            if result.isSuccess {
                                showPurchaseSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    showPurchaseSuccess = false
                                }
                                print("Successfully purchased revive heart!")
                            } else {
                                switch result {
                                case .insufficientFunds:
                                    errorMessage = "Not enough coins"
                                case .itemNotAvailable:
                                    errorMessage = "Item not available"
                                case .purchaseError:
                                    errorMessage = "Purchase failed"
                                default:
                                    errorMessage = "Unknown error"
                                }
                                showError = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    showError = false
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(BlockColors.amber)
                                Text("Buy Heart (20 coins)")
                                    .font(.title3)
                                    .foregroundColor(BlockColors.amber)
                                Image(systemName: "heart.fill")
                                    .foregroundColor(BlockColors.red)
                            }
                            .frame(width: 220, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(BlockColors.amber, lineWidth: 3)
                            )
                        }
                    }
                    
                    // Watch Ad for 10 Coins button - always available for earning coins
                    Button(action: {
                        watchAdForCoins()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(BlockColors.purple)
                            /*Image(systemName: "xmark")
                                .foregroundColor(BlockColors.purple)*/
                            Text("10")
                                .font(.title3.bold())
                                .foregroundColor(BlockColors.purple)
                            Text("Watch Ad")
                                .font(.title3.bold())
                                .foregroundColor(BlockColors.purple)
                            
                        }
                        .frame(width: 220, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(BlockColors.purple, lineWidth: 2)
                        )
                    }
                    .disabled(!adManager.canShowRewardedAd && !adManager.isInitialized)
                    
                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(.title2.bold())
                            .foregroundColor(BlockColors.bg)
                            .frame(width: 220, height: 50)
                            .background(BlockColors.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                    
                    // Shop Access button
                    Button(action: {
                        showShop = true
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .foregroundColor(BlockColors.purple)
                            Text("Powerup Shop")
                                .font(.title2.bold())
                                .foregroundColor(BlockColors.purple)
                        }
                        .frame(width: 220, height: 50)
                        
                    }
                    
                    
                    /*Button(action: onMainMenu) {
                        Text("Main Menu")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 180, height: 40)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }*/
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
            }
            .padding()
            
            // Success feedback overlays
            if showPurchaseSuccess {
                successOverlay(
                    icon: "heart.fill",
                    iconColor: BlockColors.red,
                    title: "Heart Purchased!",
                    subtitle: "You can now revive"
                )
            }
            
            if showAdSuccess {
                successOverlay(
                    icon: "dollarsign.circle.fill",
                    iconColor: BlockColors.amber,
                    title: "+10 Coins!",
                    subtitle: "Thanks for watching"
                )
            }
            
            // Ad reward animation overlay
            if showAdRewardAnimation {
                AdRewardAnimationView(onAnimationComplete: {
                    // Animation completed, hide it
                    withAnimation(.easeOut(duration: 0.3)) {
                        showAdRewardAnimation = false
                    }
                }, pointsEarned: adRewardPoints)
                .transition(.opacity)
                .zIndex(200) // High z-index to ensure it's above all other UI elements
            }
            
            if showError {
                errorOverlay(message: errorMessage)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .interstitialAdRewardEarned)) { notification in
            // Handle interstitial ad rewards that happen while GameOverView is displayed
            if let points = notification.userInfo?["points"] as? Int {
                print("GameOverView: Received interstitial ad reward notification with \(points) points")
                
                // Show animation in GameOverView for better visibility
                adRewardPoints = points
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAdRewardAnimation = true
                }
                print("GameOverView: Showing ad reward animation for interstitial ad")
            }
        }
        .sheet(isPresented: $showShop) {
            PowerupShopView()
        }
    }
    
    // MARK: - Ad Watching Methods
    
    /// Handle watching an ad for coins
    private func watchAdForCoins() {
        // Get the root view controller for presenting the ad
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("GameOverView: Could not find root view controller for ad presentation")
            handleAdFallback()
            return
        }
        
        if adManager.canShowRewardedAd {
            // Show real ad
            adManager.showRewardedAd(from: rootViewController) { [weak currencyManager] success, points in
                DispatchQueue.main.async {
                    // Track ad analytics
                    AdAnalyticsManager.shared.trackRewardedAdCompletion(
                        success: success,
                        pointsEarned: points,
                        adType: "game_over_coins"
                    )
                    
                    if success {
                        currencyManager?.addPoints(points)
                        
                        // Show ad reward animation instead of simple success overlay
                        adRewardPoints = points
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAdRewardAnimation = true
                        }
                        
                        print("GameOverView: Watched ad, earned \(points) points!")
                    } else {
                        handleAdFallback()
                    }
                }
            }
        } else {
            // Use emergency fallback
            adManager.handleAdUnavailable { [weak currencyManager] success, points in
                DispatchQueue.main.async {
                    // Track fallback analytics
                    AdAnalyticsManager.shared.trackRewardedAdCompletion(
                        success: success,
                        pointsEarned: points,
                        adType: "game_over_fallback"
                    )
                    
                    if success {
                        currencyManager?.addPoints(points)
                        
                        // Show ad reward animation for fallback too
                        adRewardPoints = points
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAdRewardAnimation = true
                        }
                        
                        print("GameOverView: Used ad fallback, earned \(points) points!")
                    }
                }
            }
        }
    }
    
    /// Handle ad fallback when ads are unavailable
    private func handleAdFallback() {
        errorMessage = "Ad not available - check network"
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showError = false
        }
    }
    
    // MARK: - Success Overlay
    private func successOverlay(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 50))
                    .scaleEffect(1.2)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color(red: 0.13, green: 0.12, blue: 0.28))
            .cornerRadius(20)
            .scaleEffect(1.0)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: showPurchaseSuccess || showAdSuccess)
    }
    
    // MARK: - Error Overlay
    private func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(BlockColors.red)
                    .font(.system(size: 50))
                
                Text("Oops!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color(red: 0.13, green: 0.12, blue: 0.28))
            .cornerRadius(20)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: showError)
    }
}

struct GameOverView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Regular game over preview
            GameOverView(
                finalScore: 1250,
                highScore: 2500,
                isNewHighScore: false,
                onRestart: {},
                onMainMenu: {},
                gameController: nil,
                onRevive: nil
            )
            .previewDisplayName("Regular Game Over")
            
            // New high score preview
            GameOverView(
                finalScore: 2750,
                highScore: 2750,
                isNewHighScore: true,
                onRestart: {},
                onMainMenu: {},
                gameController: nil,
                onRevive: nil
            )
            .previewDisplayName("New High Score")
        }
    }
}
