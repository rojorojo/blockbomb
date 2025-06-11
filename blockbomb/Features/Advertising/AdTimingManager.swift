import Foundation
import SwiftUI
import Combine

/// Manages the timing and placement of ads throughout the game flow
/// Handles both rewarded ads (for earning coins) and interstitial ads (between games)
class AdTimingManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AdTimingManager()
    
    // MARK: - Published Properties
    @Published var showInterstitialAd = false
    @Published var showBonusAdPrompt = false
    @Published var isInterstitialReady = false
    
    // MARK: - Configuration
    private let gamesBetweenInterstitials = 3 // Show interstitial every 3 games
    private let bonusAdCooldownSeconds: TimeInterval = 120 // 2 minutes between bonus ad prompts
    private let userDefaultsGameCountKey = "adTimingGameCount"
    private let userDefaultsLastBonusAdKey = "lastBonusAdTime"
    
    // MARK: - Game Tracking
    private var gamesPlayedSinceInterstitial: Int {
        get {
            UserDefaults.standard.integer(forKey: userDefaultsGameCountKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsGameCountKey)
        }
    }
    
    private var lastBonusAdTime: TimeInterval {
        get {
            UserDefaults.standard.double(forKey: userDefaultsLastBonusAdKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsLastBonusAdKey)
        }
    }
    
    // MARK: - Dependencies
    private let adManager = AdManager.shared
    private let analyticsManager = AdAnalyticsManager.shared
    
    // MARK: - Initialization
    private init() {
        // Preload interstitial ads on init
        adManager.preloadAds()
        updateInterstitialReadyState()
        
        // Listen for ad manager updates
        setupAdManagerObserver()
    }
    
    // MARK: - Ad Manager Observer
    private func setupAdManagerObserver() {
        // Monitor when interstitial ads are loaded/unloaded
        adManager.$hasInterstitialAdLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasLoaded in
                self?.isInterstitialReady = hasLoaded
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Game Flow Integration
    
    /// Call this when a game ends to potentially show interstitial ad
    /// - Parameter gameController: The game controller to get root view controller from
    func onGameEnd(gameController: GameController) {
        gamesPlayedSinceInterstitial += 1
        
        print("AdTimingManager: Game ended. Games since last interstitial: \(gamesPlayedSinceInterstitial)")
        
        // Check if it's time for an interstitial ad
        if shouldShowInterstitialAd() {
            showInterstitialAfterDelay(gameController: gameController)
        }
        
        // Track analytics
        analyticsManager.trackGameEnd(gamesPlayed: gamesPlayedSinceInterstitial)
    }
    
    /// Check if bonus ad prompt should be available during gameplay
    /// - Returns: True if bonus ad can be shown
    func canShowBonusAd() -> Bool {
        let timeSinceLastBonus = Date().timeIntervalSince1970 - lastBonusAdTime
        let canShow = timeSinceLastBonus >= bonusAdCooldownSeconds && adManager.canShowRewardedAd
        
        print("AdTimingManager: Can show bonus ad: \(canShow) (cooldown: \(timeSinceLastBonus)s)")
        return canShow
    }
    
    /// Show bonus ad prompt during gameplay
    func promptBonusAd() {
        guard canShowBonusAd() else { return }
        
        showBonusAdPrompt = true
        print("AdTimingManager: Showing bonus ad prompt")
    }
    
    /// Handle bonus ad watch completion
    /// - Parameters:
    ///   - success: Whether the ad was successfully watched
    ///   - points: Points earned from the ad
    func onBonusAdWatched(success: Bool, points: Int) {
        if success {
            lastBonusAdTime = Date().timeIntervalSince1970
            analyticsManager.trackBonusAdWatched(pointsEarned: points)
            print("AdTimingManager: Bonus ad watched successfully, earned \(points) points")
        }
        
        showBonusAdPrompt = false
    }
    
    // MARK: - Private Methods
    
    private func shouldShowInterstitialAd() -> Bool {
        let shouldShow = gamesPlayedSinceInterstitial >= gamesBetweenInterstitials && 
                        adManager.canShowInterstitialAd
        
        print("AdTimingManager: Should show interstitial: \(shouldShow)")
        return shouldShow
    }
    
    private func showInterstitialAfterDelay(gameController: GameController) {
        // Show interstitial after a brief delay to let game over animations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.presentInterstitialAd(gameController: gameController)
        }
    }
    
    private func presentInterstitialAd(gameController: GameController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("AdTimingManager: Could not find root view controller for interstitial")
            return
        }
        
        adManager.showInterstitialAd(from: rootViewController) { [weak self] success, points in
            DispatchQueue.main.async {
                if success {
                    self?.gamesPlayedSinceInterstitial = 0
                    self?.analyticsManager.trackInterstitialAdShown()
                    
                    // Award coins for watching interstitial ad
                    PowerupCurrencyManager.shared.addPoints(points)
                    
                    // Trigger reward animation through ContentView
                    print("AdTimingManager: Posting interstitialAdRewardEarned notification with \(points) points")
                    NotificationCenter.default.post(
                        name: .interstitialAdRewardEarned, 
                        object: nil, 
                        userInfo: ["points": points]
                    )
                    print("AdTimingManager: Notification posted successfully")
                    
                    print("AdTimingManager: Interstitial ad shown successfully, earned \(points) points")
                } else {
                    print("AdTimingManager: Interstitial ad failed to show")
                }
            }
        }
    }
    
    private func updateInterstitialReadyState() {
        isInterstitialReady = adManager.canShowInterstitialAd
    }
    
    // MARK: - Debug Methods
    
    /// Reset game count for testing
    func debugResetGameCount() {
        gamesPlayedSinceInterstitial = 0
        print("AdTimingManager: Debug reset game count")
    }
    
    /// Force interstitial ad for testing
    func debugForceInterstitial(gameController: GameController) {
        presentInterstitialAd(gameController: gameController)
        print("AdTimingManager: Debug force interstitial")
    }
    
    /// Reset bonus ad cooldown for testing
    func debugResetBonusAdCooldown() {
        lastBonusAdTime = 0
        print("AdTimingManager: Debug reset bonus ad cooldown")
    }
    
    /// Get current timing status for debug
    func debugGetStatus() -> String {
        return """
        Games since interstitial: \(gamesPlayedSinceInterstitial)/\(gamesBetweenInterstitials)
        Interstitial ready: \(isInterstitialReady)
        Bonus ad available: \(canShowBonusAd())
        Time since last bonus: \(Int(Date().timeIntervalSince1970 - lastBonusAdTime))s
        """
    }
}

// MARK: - Import for Combine
import Combine
