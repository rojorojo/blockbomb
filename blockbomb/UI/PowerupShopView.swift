import SwiftUI

struct PowerupShopView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var currencyManager = PowerupCurrencyManager.shared
    @ObservedObject private var shopManager = PowerupShopManager.shared
    @ObservedObject private var reviveHeartManager = ReviveHeartManager.shared
    
    @State private var showPurchaseAnimation = false
    @State private var animationScale: CGFloat = 1.0
    @State private var lastPurchasedItem: PowerupType?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
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
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Powerup Shop")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(BlockColors.violet)
            
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
                
                Text("coins")
                    .font(.body)
                    .foregroundColor(BlockColors.amber.opacity(0.8))
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
        case .futureBonus1, .futureBonus2, .futureBonus3:
            return "star.fill"
        }
    }
    
    private var itemColor: Color {
        switch powerupType {
        case .reviveHeart:
            return BlockColors.red
        case .futureBonus1, .futureBonus2, .futureBonus3:
            return BlockColors.violet
        }
    }
    
    private var statusText: String {
        switch powerupType {
        case .reviveHeart:
            return "Owned: \(reviveHeartManager.heartCount)"
        case .futureBonus1, .futureBonus2, .futureBonus3:
            return "Coming Soon"
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
                        .foregroundColor(.white)
                    
                    Text(powerupType.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                    
                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(itemColor.opacity(0.8))
                }
                
                Spacer()
                
                // Price and purchase button
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(BlockColors.amber)
                            .font(.caption)
                        
                        Text("\(price)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(BlockColors.amber)
                    }
                    
                    Button(action: onPurchase) {
                        Text("Buy")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(canPurchase ? Color(red: 0.13, green: 0.12, blue: 0.28) : .white.opacity(0.5))
                            .frame(width: 60, height: 30)
                            .background(canPurchase ? BlockColors.amber : Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .disabled(!canPurchase || powerupType != .reviveHeart) // Only revive hearts are purchasable for now
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.13, green: 0.12, blue: 0.28))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(canPurchase && powerupType == .reviveHeart ? BlockColors.amber.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct PowerupShopView_Previews: PreviewProvider {
    static var previews: some View {
        PowerupShopView()
    }
}
