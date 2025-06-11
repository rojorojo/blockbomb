import Foundation

/// Manages analytics tracking for ad impressions, completions, and user engagement
/// Provides privacy-compliant local analytics with future Firebase integration support
class AdAnalyticsManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AdAnalyticsManager()
    
    // MARK: - Analytics Data
    private struct AdAnalytics: Codable {
        var totalRewardedAdsWatched: Int = 0
        var totalInterstitialAdsShown: Int = 0
        var totalBonusAdsWatched: Int = 0
        var totalPointsEarnedFromAds: Int = 0
        var totalGamesPlayed: Int = 0
        var sessionStartTime: TimeInterval = 0
        var lastSessionDate: String = ""
        
        // Conversion metrics
        var rewardedAdToHeartPurchaseConversions: Int = 0
        var averageAdsPerGame: Double = 0.0
        var averagePointsPerSession: Double = 0.0
        
        // Error tracking
        var adLoadFailures: Int = 0
        var adShowFailures: Int = 0
        
        // User engagement
        var consecutiveDaysPlayed: Int = 0
        var totalPlaySessions: Int = 0
    }
    
    // MARK: - Properties
    private let userDefaultsKey = "adAnalyticsData"
    private var analytics: AdAnalytics
    private let dateFormatter: DateFormatter
    
    // MARK: - Initialization
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Load existing analytics or create new
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let loadedAnalytics = try? JSONDecoder().decode(AdAnalytics.self, from: data) {
            analytics = loadedAnalytics
        } else {
            analytics = AdAnalytics()
        }
        
        // Start new session
        startNewSession()
    }
    
    // MARK: - Session Management
    
    private func startNewSession() {
        let today = dateFormatter.string(from: Date())
        
        // Check if this is a new day
        if analytics.lastSessionDate != today {
            if !analytics.lastSessionDate.isEmpty {
                // Check if it's consecutive day
                let calendar = Calendar.current
                if let lastDate = dateFormatter.date(from: analytics.lastSessionDate),
                   let daysBetween = calendar.dateComponents([.day], from: lastDate, to: Date()).day {
                    if daysBetween == 1 {
                        analytics.consecutiveDaysPlayed += 1
                    } else if daysBetween > 1 {
                        analytics.consecutiveDaysPlayed = 1 // Reset streak
                    }
                }
            } else {
                analytics.consecutiveDaysPlayed = 1 // First day
            }
            analytics.lastSessionDate = today
        }
        
        analytics.sessionStartTime = Date().timeIntervalSince1970
        analytics.totalPlaySessions += 1
        
        saveAnalytics()
        print("AdAnalyticsManager: New session started (Day \(analytics.consecutiveDaysPlayed) of streak)")
    }
    
    // MARK: - Ad Tracking Methods
    
    /// Track rewarded ad completion
    /// - Parameter pointsEarned: Points earned from the ad
    func trackRewardedAdWatched(pointsEarned: Int) {
        analytics.totalRewardedAdsWatched += 1
        analytics.totalPointsEarnedFromAds += pointsEarned
        
        updateAverages()
        saveAnalytics()
        
        print("AdAnalyticsManager: Rewarded ad watched - Total: \(analytics.totalRewardedAdsWatched), Points: \(pointsEarned)")
    }
    
    /// Track rewarded ad completion with success status and ad type
    func trackRewardedAdCompletion(success: Bool, pointsEarned: Int, adType: String) {
        if success {
            analytics.totalRewardedAdsWatched += 1
            analytics.totalPointsEarnedFromAds += pointsEarned
            print("AdAnalyticsManager: Rewarded ad completed successfully - Type: \(adType), Points: \(pointsEarned)")
        } else {
            analytics.adShowFailures += 1
            print("AdAnalyticsManager: Rewarded ad failed - Type: \(adType)")
        }
        
        updateAverages()
        saveAnalytics()
    }
    
    /// Track interstitial ad display
    func trackInterstitialAdShown() {
        analytics.totalInterstitialAdsShown += 1
        
        updateAverages()
        saveAnalytics()
        
        print("AdAnalyticsManager: Interstitial ad shown - Total: \(analytics.totalInterstitialAdsShown)")
    }
    
    /// Track bonus ad during gameplay
    /// - Parameter pointsEarned: Points earned from bonus ad
    func trackBonusAdWatched(pointsEarned: Int) {
        analytics.totalBonusAdsWatched += 1
        analytics.totalPointsEarnedFromAds += pointsEarned
        
        updateAverages()
        saveAnalytics()
        
        print("AdAnalyticsManager: Bonus ad watched - Total: \(analytics.totalBonusAdsWatched), Points: \(pointsEarned)")
    }
    
    /// Track when player purchases revive heart after watching ads
    func trackAdToHeartPurchaseConversion() {
        analytics.rewardedAdToHeartPurchaseConversions += 1
        
        saveAnalytics()
        print("AdAnalyticsManager: Ad-to-heart purchase conversion - Total: \(analytics.rewardedAdToHeartPurchaseConversions)")
    }
    
    /// Track game completion
    /// - Parameter gamesPlayed: Number of games played this session
    func trackGameEnd(gamesPlayed: Int) {
        analytics.totalGamesPlayed += 1
        
        updateAverages()
        saveAnalytics()
        
        print("AdAnalyticsManager: Game ended - Total games: \(analytics.totalGamesPlayed)")
    }
    
    /// Track ad loading failure
    /// - Parameter adType: Type of ad that failed to load
    func trackAdLoadFailure(adType: String) {
        analytics.adLoadFailures += 1
        
        saveAnalytics()
        print("AdAnalyticsManager: Ad load failure (\(adType)) - Total failures: \(analytics.adLoadFailures)")
    }
    
    /// Track ad display failure
    /// - Parameter adType: Type of ad that failed to show
    func trackAdShowFailure(adType: String) {
        analytics.adShowFailures += 1
        
        saveAnalytics()
        print("AdAnalyticsManager: Ad show failure (\(adType)) - Total failures: \(analytics.adShowFailures)")
    }
    
    // MARK: - Analytics Computation
    
    private func updateAverages() {
        // Calculate average ads per game
        if analytics.totalGamesPlayed > 0 {
            let totalAds = analytics.totalRewardedAdsWatched + analytics.totalBonusAdsWatched
            analytics.averageAdsPerGame = Double(totalAds) / Double(analytics.totalGamesPlayed)
        }
        
        // Calculate average points per session
        if analytics.totalPlaySessions > 0 {
            analytics.averagePointsPerSession = Double(analytics.totalPointsEarnedFromAds) / Double(analytics.totalPlaySessions)
        }
    }
    
    // MARK: - Data Access Methods
    
    /// Get current analytics summary
    /// - Returns: Dictionary with key analytics metrics
    func getAnalyticsSummary() -> [String: Any] {
        return [
            "totalRewardedAdsWatched": analytics.totalRewardedAdsWatched,
            "totalInterstitialAdsShown": analytics.totalInterstitialAdsShown,
            "totalBonusAdsWatched": analytics.totalBonusAdsWatched,
            "totalPointsEarnedFromAds": analytics.totalPointsEarnedFromAds,
            "totalGamesPlayed": analytics.totalGamesPlayed,
            "rewardedAdToHeartPurchaseConversions": analytics.rewardedAdToHeartPurchaseConversions,
            "averageAdsPerGame": analytics.averageAdsPerGame,
            "averagePointsPerSession": analytics.averagePointsPerSession,
            "consecutiveDaysPlayed": analytics.consecutiveDaysPlayed,
            "totalPlaySessions": analytics.totalPlaySessions,
            "adLoadFailures": analytics.adLoadFailures,
            "adShowFailures": analytics.adShowFailures
        ]
    }
    
    /// Get conversion rate from ads to heart purchases
    /// - Returns: Conversion rate as percentage
    func getAdToHeartConversionRate() -> Double {
        guard analytics.totalRewardedAdsWatched > 0 else { return 0.0 }
        return (Double(analytics.rewardedAdToHeartPurchaseConversions) / Double(analytics.totalRewardedAdsWatched)) * 100.0
    }
    
    /// Get engagement score based on various metrics
    /// - Returns: Engagement score from 0-100
    func getEngagementScore() -> Double {
        var score: Double = 0
        
        // Base score from consecutive days (0-30 points)
        score += min(Double(analytics.consecutiveDaysPlayed) * 2, 30)
        
        // Ads per game score (0-25 points)
        score += min(analytics.averageAdsPerGame * 10, 25)
        
        // Conversion rate score (0-25 points)  
        score += min(getAdToHeartConversionRate() / 4, 25)
        
        // Session frequency score (0-20 points)
        let sessionFrequency = Double(analytics.totalPlaySessions) / max(Double(analytics.consecutiveDaysPlayed), 1)
        score += min(sessionFrequency * 5, 20)
        
        return min(score, 100)
    }
    
    // MARK: - Data Persistence
    
    private func saveAnalytics() {
        do {
            let data = try JSONEncoder().encode(analytics)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("AdAnalyticsManager: Failed to save analytics: \(error)")
        }
    }
    
    // MARK: - Debug Methods
    
    /// Reset all analytics data (for testing)
    func debugResetAnalytics() {
        analytics = AdAnalytics()
        analytics.sessionStartTime = Date().timeIntervalSince1970
        analytics.totalPlaySessions = 1
        analytics.consecutiveDaysPlayed = 1
        analytics.lastSessionDate = dateFormatter.string(from: Date())
        
        saveAnalytics()
        print("AdAnalyticsManager: Debug reset all analytics")
    }
    
    /// Get detailed analytics for debug panel
    /// - Returns: Formatted string with all analytics
    func debugGetDetailedAnalytics() -> String {
        let summary = getAnalyticsSummary()
        let conversionRate = getAdToHeartConversionRate()
        let engagementScore = getEngagementScore()
        
        return """
        === AD ANALYTICS ===
        Rewarded Ads Watched: \(summary["totalRewardedAdsWatched"] ?? 0)
        Interstitial Ads Shown: \(summary["totalInterstitialAdsShown"] ?? 0)
        Bonus Ads Watched: \(summary["totalBonusAdsWatched"] ?? 0)
        Total Points from Ads: \(summary["totalPointsEarnedFromAds"] ?? 0)
        Total Games Played: \(summary["totalGamesPlayed"] ?? 0)
        
        === CONVERSION METRICS ===
        Ad-to-Heart Conversions: \(summary["rewardedAdToHeartPurchaseConversions"] ?? 0)
        Conversion Rate: \(String(format: "%.1f", conversionRate))%
        Avg Ads per Game: \(String(format: "%.2f", summary["averageAdsPerGame"] as? Double ?? 0))
        Avg Points per Session: \(String(format: "%.1f", summary["averagePointsPerSession"] as? Double ?? 0))
        
        === ENGAGEMENT ===
        Consecutive Days: \(summary["consecutiveDaysPlayed"] ?? 0)
        Total Sessions: \(summary["totalPlaySessions"] ?? 0)
        Engagement Score: \(String(format: "%.1f", engagementScore))/100
        
        === ERROR TRACKING ===
        Ad Load Failures: \(summary["adLoadFailures"] ?? 0)
        Ad Show Failures: \(summary["adShowFailures"] ?? 0)
        """
    }
    
    /// Simulate data for testing
    func debugSimulateUsage() {
        // Simulate some realistic usage
        analytics.totalRewardedAdsWatched += 5
        analytics.totalInterstitialAdsShown += 2
        analytics.totalBonusAdsWatched += 1
        analytics.totalPointsEarnedFromAds += 60
        analytics.totalGamesPlayed += 3
        analytics.rewardedAdToHeartPurchaseConversions += 2
        
        updateAverages()
        saveAnalytics()
        
        print("AdAnalyticsManager: Debug simulated usage data")
    }
}
