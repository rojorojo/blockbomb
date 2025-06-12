import SwiftUI

struct PowerupShopView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var currencyManager = PowerupCurrencyManager.shared
    @ObservedObject private var shopManager = PowerupShopManager.shared
    @ObservedObject private var reviveHeartManager = ReviveHeartManager.shared
    @ObservedObject private var adManager = AdManager.shared
    
    @State private var showPurchaseAnimation = false
    @State private var animationScale: CGFloat = 1.0
    @State private var lastPurchasedItem: PowerupType?
    @State private var showShopHelp = false
    @State private var showAdModelHelp = false
    @State private var showCurrencyTooltip = false
    @State private var isLoadingAds = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 32) {
                    // Header with currency display
                    headerView
                    
                    // Shop items
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(PowerupType.allCases, id: \.self) { powerupType in
                                PowerupItemView(
                                    powerupType: powerupType,
                                    onPurchase: { handlePurchase(powerupType) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Close button
                    closeButton
                }
                .padding(.top, 20)
                
                // Purchase animation overlay
                if showPurchaseAnimation {
                    purchaseAnimationView
                }
                
                // Help overlays
                if showShopHelp {
                    HelpOverlayView(isVisible: $showShopHelp, helpContent: .powerupShopHelp)
                        .zIndex(200)
                }
                
                if showAdModelHelp {
                    HelpOverlayView(isVisible: $showAdModelHelp, helpContent: .adSupportedModelHelp)
                        .zIndex(200)
                }
                
                // Currency tooltip
                if showCurrencyTooltip {
                    VStack {
                        HStack {
                            Spacer()
                            TooltipView(
                                text: "Watch ads to earn more coins!",
                                direction: .down,
                                backgroundColor: BlockColors.amber,
                                isVisible: $showCurrencyTooltip
                            )
                            .padding(.trailing, 80)
                            Spacer()
                        }
                        .padding(.top, 60)
                        Spacer()
                    }
                    .zIndex(190)
                }
                
                // Ad loading overlay
                if adManager.isShowingAd || (!adManager.hasRewardedAdLoaded && currencyManager.currentPoints < 20) {
                    VStack {
                        Spacer()
                        if adManager.isShowingAd {
                            AdLoadingIndicator(isLoading: true)
                            Text("Ad in progress...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 8)
                        } else {
                            AdLoadingIndicator(isLoading: false)
                            Text("Need to watch ads for more coins")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 8)
                        }
                        Spacer()
                    }
                    .background(Color.black.opacity(0.3))
                    .zIndex(180)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 32) {
            HStack {
                /*Button(action: { showAdModelHelp = true }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundColor(BlockColors.cyan.opacity(0.7))
                }
                .accessibilityLabel("Learn about free game model")
                
                Spacer()*/
                
                Text("Powerup Shop")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(BlockColors.violet)
                
                /*Spacer()
                
                Button(action: { showShopHelp = true }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(BlockColors.violet.opacity(0.7))
                }
                .accessibilityLabel("Shop help")*/
            }
            
            HStack {
                Button(action: { 
                    showCurrencyTooltip.toggle()
                    if showCurrencyTooltip {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            showCurrencyTooltip = false
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(BlockColors.amber)
                            .font(.title2)
                        
                        Text("\(currencyManager.currentPoints)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(BlockColors.amber)
                            .scaleEffect(animationScale)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currencyManager.points)
                        
                        /*Text("coins")
                            .font(.body)
                            .foregroundColor(BlockColors.amber.opacity(0.8))
                        
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(BlockColors.amber.opacity(0.6))*/
                    }
                }
                .accessibilityCurrencyDisplay(points: currencyManager.currentPoints)
                
                // Show offline indicator if no network
                if !adManager.canShowRewardedAd && !adManager.canShowInterstitialAd {
                    OfflineModeIndicator()
                        .padding(.leading, 10)
                }
            }
        }
    }
    
    // MARK: - Close Button
    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Close")
                .font(.title2.bold())
                .foregroundColor(Color(red: 0.13, green: 0.12, blue: 0.28))
                .frame(width: 200, height: 50)
                .background(BlockColors.violet)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Purchase Animation
    private var purchaseAnimationView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(BlockColors.green)
                    .font(.system(size: 60))
                    .scaleEffect(showPurchaseAnimation ? 1.2 : 0.8)
                
                Text("Purchase Successful!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let item = lastPurchasedItem {
                    Text(item.displayName)
                        .font(.body)
                        .foregroundColor(BlockColors.amber)
                }
            }
            .padding(40)
            .background(Color(red: 0.13, green: 0.12, blue: 0.28))
            .cornerRadius(20)
            .scaleEffect(showPurchaseAnimation ? 1.0 : 0.5)
        }
        .opacity(showPurchaseAnimation ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: showPurchaseAnimation)
    }
    
    // MARK: - Purchase Handler
    private func handlePurchase(_ powerupType: PowerupType) {
        let result = shopManager.purchasePowerup(powerupType)
        
        if result.isSuccess {
            lastPurchasedItem = powerupType
            
            // Trigger animations
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animationScale = 1.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    animationScale = 1.0
                }
            }
            
            // Show success animation
            showPurchaseAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showPurchaseAnimation = false
            }
            
            print("Successfully purchased \(powerupType.displayName)!")
        } else {
            // Handle purchase failure (could add error alerts here)
            print("Purchase failed: \(result)")
        }
    }
}

// MARK: - Powerup Item View
struct PowerupItemView: View {
    let powerupType: PowerupType
    let onPurchase: () -> Void
    
    @ObservedObject private var currencyManager = PowerupCurrencyManager.shared
    @ObservedObject private var shopManager = PowerupShopManager.shared
    @ObservedObject private var reviveHeartManager = ReviveHeartManager.shared
    @State private var showTooltip = false
    @State private var isPurchasing = false
    
    private var canPurchase: Bool {
        shopManager.canPurchase(powerupType)
    }
    
    private var price: Int {
        shopManager.getPrice(for: powerupType) ?? 0
    }
    
    private var itemIcon: String {
        switch powerupType {
        case .reviveHeart:
            return "heart.fill"
        // TODO: Temporarily hidden - will be enabled in future update
        // case .futureBonus1, .futureBonus2, .futureBonus3:
        //     return "star.fill"
        }
    }
    
    private var itemColor: Color {
        switch powerupType {
        case .reviveHeart:
            return BlockColors.red
        // TODO: Temporarily hidden - will be enabled in future update
        // case .futureBonus1, .futureBonus2, .futureBonus3:
        //     return BlockColors.violet
        }
    }
    
    private var statusText: String {
        switch powerupType {
        case .reviveHeart:
            return "Owned: \(reviveHeartManager.heartCount)"
        // TODO: Temporarily hidden - will be enabled in future update
        // case .futureBonus1, .futureBonus2, .futureBonus3:
        //     return "Coming Soon"
        }
    }
    
    private var buttonText: String {
        if !canPurchase && currencyManager.currentPoints < price {
            return "Need \(price - currencyManager.currentPoints)"
        } else if !canPurchase {
            return "Unavailable"
        } else {
            return "Buy"
        }
    }
    
    private var buttonBackgroundColor: Color {
        if canPurchase {
            return BlockColors.amber
        } else if currencyManager.currentPoints < price {
            return BlockColors.orange.opacity(0.6)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var tooltipText: String {
        switch powerupType {
        case .reviveHeart:
            if canPurchase {
                return "Tap to buy a revive heart for \(price) coins"
            } else if currencyManager.currentPoints < price {
                return "Watch ads to earn \(price - currencyManager.currentPoints) more coins"
            } else {
                return "Revive hearts let you continue when you run out of moves"
            }
        // TODO: Temporarily hidden - will be enabled in future update
        // case .futureBonus1, .futureBonus2, .futureBonus3:
        //     return "This powerup will be available in a future update"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Item icon
                Image(systemName: itemIcon)
                    .foregroundColor(itemColor)
                    .font(.title)
                    .frame(width: 40, height: 40)
                
                // Item details
                VStack(alignment: .leading, spacing: 4) {
                    Text(powerupType.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1, green: 0.92, blue: 0.8))
                    
                    Text(powerupType.description)
                        .font(.body)
                        .foregroundColor(Color(red: 1, green: 0.92, blue: 0.8))
                        .lineLimit(2)
                    
                    Text(statusText)
                        .font(.body)
                        .foregroundColor(itemColor)
                }
                
                Spacer()
                
                // Price and purchase button
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(BlockColors.amber)
                            .font(.body)
                        
                        Text("\(price)")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(BlockColors.amber)
                    }
                    
                    Button(action: {
                        // Handle purchase action with loading state
                        isPurchasing = true
                        onPurchase()
                        
                        // Simulate brief processing delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isPurchasing = false
                        }
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(buttonText)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 80, height: 32)
                        .background(buttonBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .disabled(!canPurchase || isPurchasing)
                    .accessibilityPowerupShop()
                    .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 10) {
                        // Show tooltip on long press
                        showTooltip = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showTooltip = false
                        }
                    }
                }
                
                // Tooltip overlay
                if showTooltip {
                    VStack {
                        Spacer()
                        TooltipView(
                            text: tooltipText,
                            direction: .up,
                            backgroundColor: itemColor,
                            isVisible: $showTooltip
                        )
                        .offset(y: -10)
                    }
                    .zIndex(100)
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.13, green: 0.12, blue: 0.28))
        .cornerRadius(16)
        
        .onTapGesture {
            // Toggle tooltip visibility on item tap
            showTooltip.toggle()
        }
        .overlay(
            // Tooltip view
            Group {
                if showTooltip {
                    TooltipView(
                        text: "Tap to purchase \(powerupType.displayName)",
                        direction: .up,
                        backgroundColor: BlockColors.violet,
                        isVisible: $showTooltip
                    )
                    .padding(.top, -10)
                }
            },
            alignment: .top
        )
    }
}

// MARK: - Preview
struct PowerupShopView_Previews: PreviewProvider {
    static var previews: some View {
        PowerupShopView()
    }
}
