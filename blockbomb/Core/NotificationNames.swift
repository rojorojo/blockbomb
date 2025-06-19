import Foundation

/// Shared notification names used throughout the BlockBomb app
extension Notification.Name {
    /// Posted when an interstitial ad completes and rewards points
    static let interstitialAdRewardEarned = Notification.Name("interstitialAdRewardEarned")
    
    /// Posted when a multiplayer game ends
    static let multiplayerGameEnded = Notification.Name("multiplayerGameEnded")
}
