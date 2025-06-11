import Foundation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

/// Manages all advertising functionality for the BlockBomb free game
/// Handles both interstitial and rewarded video ads with proper error handling
class AdManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = AdManager()
    
    // MARK: - Published Properties
    @Published var isInitialized = false
    @Published var hasRewardedAdLoaded = false
    @Published var hasInterstitialAdLoaded = false
    @Published var isShowingAd = false
    
    // MARK: - Private Properties
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var loadingRewardedAd = false
    private var loadingInterstitialAd = false
    
    // MARK: - Configuration
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ID
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Test ID
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    // MARK: - Retry Logic
    private var interstitialRetryCount = 0
    private var rewardedRetryCount = 0
    
    // MARK: - Completion Handlers
    private var pendingRewardCompletion: ((Bool, Int) -> Void)?
    private var pendingInterstitialCompletion: ((Bool) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupAdMob()
    }
    
    // MARK: - Setup Methods
    
    /// Initialize AdMob SDK and request tracking authorization
    private func setupAdMob() {
        print("AdManager: Starting AdMob initialization")
        
        // Request tracking authorization first (iOS 14.5+)
        if #available(iOS 14.5, *) {
            requestTrackingAuthorization { [weak self] in
                self?.initializeAdMob()
            }
        } else {
            initializeAdMob()
        }
    }
    
    /// Request App Tracking Transparency permission
    @available(iOS 14.5, *)
    private func requestTrackingAuthorization(completion: @escaping () -> Void) {
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("AdManager: Tracking authorized")
                case .denied:
                    print("AdManager: Tracking denied")
                case .restricted:
                    print("AdManager: Tracking restricted")
                case .notDetermined:
                    print("AdManager: Tracking not determined")
                @unknown default:
                    print("AdManager: Unknown tracking status")
                }
                completion()
            }
        }
    }
    
    /// Initialize the Google Mobile Ads SDK
    private func initializeAdMob() {
        MobileAds.shared.start(completionHandler: { [weak self] (status: InitializationStatus) in
            DispatchQueue.main.async {
                self?.isInitialized = true
                print("AdManager: AdMob initialized successfully")
                
                // Pre-load ads
                self?.loadInterstitialAd()
                self?.loadRewardedAd()
            }
        })
    }
    
    // MARK: - Interstitial Ad Methods
    
    /// Load an interstitial ad
    func loadInterstitialAd() {
        guard isInitialized else {
            print("AdManager: Cannot load interstitial - AdMob not initialized")
            return
        }
        
        guard !loadingInterstitialAd else {
            print("AdManager: Already loading interstitial ad")
            return
        }
        
        loadingInterstitialAd = true
        print("AdManager: Loading interstitial ad")
        
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request, completionHandler: { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.loadingInterstitialAd = false
                
                if let error = error {
                    print("AdManager: Failed to load interstitial ad: \(error.localizedDescription)")
                    self?.hasInterstitialAdLoaded = false
                    self?.retryInterstitialLoad()
                } else {
                    self?.interstitialAd = ad
                    self?.interstitialAd?.fullScreenContentDelegate = self
                    self?.hasInterstitialAdLoaded = true
                    self?.interstitialRetryCount = 0
                    print("AdManager: Interstitial ad loaded successfully")
                }
            }
        })
    }
    
    /// Show interstitial ad
    /// - Parameters:
    ///   - viewController: The presenting view controller
    ///   - completion: Callback with success status and reward amount (interstitials now also give coin rewards)
    func showInterstitialAd(from viewController: UIViewController, completion: @escaping (Bool, Int) -> Void) {
        guard let interstitialAd = interstitialAd else {
            print("AdManager: No interstitial ad available")
            completion(false, 0)
            return
        }
        
        guard !isShowingAd else {
            print("AdManager: Already showing an ad")
            completion(false, 0)
            return
        }
        
        pendingInterstitialCompletion = { success in
            // Interstitial ads now also provide coin rewards when successfully watched
            completion(success, success ? 10 : 0)
        }
        isShowingAd = true
        
        print("AdManager: Presenting interstitial ad")
        interstitialAd.present(from: viewController)
    }
    
    /// Retry loading interstitial ad with exponential backoff
    private func retryInterstitialLoad() {
        guard interstitialRetryCount < maxRetryAttempts else {
            print("AdManager: Max retry attempts reached for interstitial ad")
            return
        }
        
        interstitialRetryCount += 1
        let delay = retryDelay * Double(interstitialRetryCount)
        
        print("AdManager: Retrying interstitial load in \(delay) seconds (attempt \(interstitialRetryCount))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadInterstitialAd()
        }
    }
    
    // MARK: - Rewarded Ad Methods
    
    /// Load a rewarded video ad
    func loadRewardedAd() {
        guard isInitialized else {
            print("AdManager: Cannot load rewarded ad - AdMob not initialized")
            return
        }
        
        guard !loadingRewardedAd else {
            print("AdManager: Already loading rewarded ad")
            return
        }
        
        loadingRewardedAd = true
        print("AdManager: Loading rewarded ad")
        
        let request = Request()
        RewardedAd.load(with: rewardedAdUnitID, request: request, completionHandler: { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.loadingRewardedAd = false
                
                if let error = error {
                    print("AdManager: Failed to load rewarded ad: \(error.localizedDescription)")
                    self?.hasRewardedAdLoaded = false
                    self?.retryRewardedLoad()
                } else {
                    self?.rewardedAd = ad
                    self?.rewardedAd?.fullScreenContentDelegate = self
                    self?.hasRewardedAdLoaded = true
                    self?.rewardedRetryCount = 0
                    print("AdManager: Rewarded ad loaded successfully")
                }
            }
        })
    }
    
    /// Show rewarded video ad
    /// - Parameters:
    ///   - viewController: The presenting view controller
    ///   - onReward: Callback with success status and reward amount
    func showRewardedAd(from viewController: UIViewController, onReward: @escaping (Bool, Int) -> Void) {
        guard let rewardedAd = rewardedAd else {
            print("AdManager: No rewarded ad available")
            onReward(false, 0)
            return
        }
        
        guard !isShowingAd else {
            print("AdManager: Already showing an ad")
            onReward(false, 0)
            return
        }
        
        pendingRewardCompletion = onReward
        isShowingAd = true
        
        print("AdManager: Presenting rewarded ad")
        rewardedAd.present(from: viewController) { [weak self] in
            // Reward granted
            print("AdManager: Rewarded ad completed - granting reward")
            self?.pendingRewardCompletion?(true, 10) // 10 points per ad as configured
        }
    }
    
    /// Retry loading rewarded ad with exponential backoff
    private func retryRewardedLoad() {
        guard rewardedRetryCount < maxRetryAttempts else {
            print("AdManager: Max retry attempts reached for rewarded ad")
            return
        }
        
        rewardedRetryCount += 1
        let delay = retryDelay * Double(rewardedRetryCount)
        
        print("AdManager: Retrying rewarded load in \(delay) seconds (attempt \(rewardedRetryCount))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadRewardedAd()
        }
    }
    
    // MARK: - Utility Methods
    
    /// Check if rewarded ad is available
    var canShowRewardedAd: Bool {
        return hasRewardedAdLoaded && !isShowingAd
    }
    
    /// Check if interstitial ad is available
    var canShowInterstitialAd: Bool {
        return hasInterstitialAdLoaded && !isShowingAd
    }
    
    /// Preload ads for better user experience
    func preloadAds() {
        if !hasInterstitialAdLoaded && !loadingInterstitialAd {
            loadInterstitialAd()
        }
        
        if !hasRewardedAdLoaded && !loadingRewardedAd {
            loadRewardedAd()
        }
    }
    
    /// Emergency fallback for when ads are not available
    /// This ensures the free game model still works
    func handleAdUnavailable(completion: @escaping (Bool, Int) -> Void) {
        print("AdManager: Ad unavailable - using emergency fallback")
        
        // In a real implementation, this might:
        // 1. Show a brief message explaining ads support the free game
        // 2. Provide a small emergency reward
        // 3. Encourage checking network connection
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true, 5) // Emergency fallback: 5 points instead of 10
        }
    }
    
    // MARK: - Debug Methods
    
    /// Reset retry counters (useful for testing)
    func resetRetryCounters() {
        interstitialRetryCount = 0
        rewardedRetryCount = 0
        print("AdManager: Reset retry counters")
    }
    
    /// Force reload all ads (useful for testing)
    func forceReloadAds() {
        interstitialAd = nil
        rewardedAd = nil
        hasInterstitialAdLoaded = false
        hasRewardedAdLoaded = false
        loadingInterstitialAd = false
        loadingRewardedAd = false
        
        resetRetryCounters()
        preloadAds()
        print("AdManager: Force reloaded all ads")
    }
    
    /// Simulate ad success for testing
    func simulateAdReward(completion: @escaping (Bool, Int) -> Void) {
        print("AdManager: Simulating ad reward for testing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(true, 10)
        }
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdManager: Ad will present full screen content")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdManager: Ad did dismiss full screen content")
        
        isShowingAd = false
        
        // Handle completion for different ad types
        if ad is InterstitialAd {
            hasInterstitialAdLoaded = false
            interstitialAd = nil
            pendingInterstitialCompletion?(true)
            pendingInterstitialCompletion = nil
            
            // Post notification for interstitial ad reward
            let userInfo = ["points": 10]
            NotificationCenter.default.post(
                name: .interstitialAdRewardEarned,
                object: nil,
                userInfo: userInfo
            )
            print("AdManager: Posted interstitial ad reward notification with 10 points")
            
            // Preload next interstitial
            loadInterstitialAd()
            
        } else if ad is RewardedAd {
            hasRewardedAdLoaded = false
            rewardedAd = nil
            
            // If reward wasn't granted in the present callback, treat as cancelled
            if let completion = pendingRewardCompletion {
                completion(false, 0)
                pendingRewardCompletion = nil
            }
            
            // Preload next rewarded ad
            loadRewardedAd()
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdManager: Ad failed to present: \(error.localizedDescription)")
        
        isShowingAd = false
        
        if ad is InterstitialAd {
            pendingInterstitialCompletion?(false)
            pendingInterstitialCompletion = nil
        } else if ad is RewardedAd {
            pendingRewardCompletion?(false, 0)
            pendingRewardCompletion = nil
        }
    }
}
