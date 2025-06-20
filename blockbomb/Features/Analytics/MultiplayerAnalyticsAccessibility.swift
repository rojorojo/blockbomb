import Foundation
import UIKit

/// Provides accessibility support for multiplayer analytics collection and reporting
/// Ensures analytics collection is inclusive and accessible to all users
class MultiplayerAnalyticsAccessibility {
    
    // MARK: - Singleton
    static let shared = MultiplayerAnalyticsAccessibility()
    
    // MARK: - Properties
    private let analytics = MultiplayerAnalyticsManager.shared
    private var accessibilityAnnouncementsEnabled = true
    private var lastAnnouncementTime: TimeInterval = 0
    private let announcementCooldown: TimeInterval = 2.0 // Minimum time between announcements
    
    // MARK: - Initialization
    private init() {
        setupAccessibilityObservers()
    }
    
    // MARK: - Accessibility Announcements
    
    /// Announce match start for accessibility users
    /// - Parameters:
    ///   - matchType: Type of match starting
    ///   - opponentName: Name of opponent (if available)
    func announceMatchStart(matchType: String, opponentName: String?) {
        guard shouldMakeAnnouncement() else { return }
        
        let opponentText = opponentName ?? "another player"
        let announcement = "Starting \(matchType) match against \(opponentText)"
        
        makeAccessibilityAnnouncement(announcement)
        analytics.trackFirebaseEvent("accessibility_match_start_announced", parameters: [
            "match_type": matchType,
            "has_opponent_name": opponentName != nil
        ])
    }
    
    /// Announce match result for accessibility users
    /// - Parameters:
    ///   - result: Match result
    ///   - playerScore: Player's final score
    ///   - opponentScore: Opponent's final score
    ///   - duration: Match duration
    func announceMatchResult(result: String, playerScore: Int, opponentScore: Int, duration: TimeInterval) {
        guard shouldMakeAnnouncement() else { return }
        
        let durationMinutes = Int(duration) / 60
        let durationSeconds = Int(duration) % 60
        
        var announcement = ""
        
        switch result.lowercased() {
        case "won":
            announcement = "Match won! Your score: \(playerScore), opponent: \(opponentScore). Match lasted \(durationMinutes) minutes and \(durationSeconds) seconds."
        case "lost":
            announcement = "Match lost. Your score: \(playerScore), opponent: \(opponentScore). Match lasted \(durationMinutes) minutes and \(durationSeconds) seconds."
        case "resigned":
            announcement = "You resigned from the match. Final scores: You \(playerScore), opponent \(opponentScore)."
        case "disconnected":
            announcement = "Match ended due to connection loss. Scores at disconnect: You \(playerScore), opponent \(opponentScore)."
        default:
            announcement = "Match ended. Final scores: You \(playerScore), opponent \(opponentScore)."
        }
        
        // Add win streak information for wins
        if result.lowercased() == "won" {
            let summary = analytics.getAnalyticsSummary()
            if let streak = summary["currentWinStreak"] as? Int, streak > 1 {
                announcement += " You're on a \(streak) game winning streak!"
            }
        }
        
        makeAccessibilityAnnouncement(announcement)
        analytics.trackFirebaseEvent("accessibility_match_result_announced", parameters: [
            "result": result,
            "duration": Int(duration)
        ])
    }
    
    /// Announce turn time feedback for accessibility users
    /// - Parameter turnTime: Time taken for the turn
    func announceTurnTimeFeedback(turnTime: TimeInterval) {
        guard shouldMakeAnnouncement() else { return }
        
        // Only announce if turn was particularly fast or slow
        let summary = analytics.getAnalyticsSummary()
        let avgTurnTime = summary["averageTurnTime"] as? Double ?? 30.0
        
        var announcement: String?
        
        if turnTime < avgTurnTime * 0.5 && turnTime < 10 {
            announcement = "Quick turn! \(String(format: "%.1f", turnTime)) seconds."
        } else if turnTime > avgTurnTime * 2 && turnTime > 60 {
            let minutes = Int(turnTime) / 60
            let seconds = Int(turnTime) % 60
            announcement = "Turn took \(minutes) minutes and \(seconds) seconds."
        }
        
        if let announcement = announcement {
            makeAccessibilityAnnouncement(announcement)
            analytics.trackFirebaseEvent("accessibility_turn_time_announced", parameters: [
                "turn_time": Int(turnTime),
                "is_fast": turnTime < avgTurnTime * 0.5,
                "is_slow": turnTime > avgTurnTime * 2
            ])
        }
    }
    
    /// Announce connectivity status changes
    /// - Parameters:
    ///   - event: Connectivity event
    ///   - severity: Severity level of the event
    func announceConnectivityChange(event: String, severity: String = "info") {
        guard shouldMakeAnnouncement() else { return }
        
        var announcement: String?
        
        switch event.lowercased() {
        case "connected":
            announcement = "Connected to multiplayer game."
        case "disconnected":
            announcement = "Lost connection to multiplayer game."
        case "reconnecting":
            announcement = "Attempting to reconnect to game."
        case "reconnected":
            announcement = "Reconnected to multiplayer game."
        case "timeout":
            announcement = "Connection timeout. Check your internet connection."
        default:
            if severity == "error" {
                announcement = "Network error occurred: \(event)."
            }
        }
        
        if let announcement = announcement {
            makeAccessibilityAnnouncement(announcement)
            analytics.trackFirebaseEvent("accessibility_connectivity_announced", parameters: [
                "event": event,
                "severity": severity
            ])
        }
    }
    
    /// Announce Game Center status changes
    /// - Parameters:
    ///   - operation: Game Center operation
    ///   - success: Whether operation succeeded
    func announceGameCenterStatus(operation: String, success: Bool) {
        guard shouldMakeAnnouncement() else { return }
        
        var announcement: String?
        
        switch operation.lowercased() {
        case "authentication":
            announcement = success ? "Signed in to Game Center." : "Failed to sign in to Game Center."
        case "matchmaking":
            announcement = success ? "Found opponent for multiplayer game." : "Could not find opponent. Retrying matchmaking."
        default:
            if !success {
                announcement = "Game Center operation failed: \(operation)."
            }
        }
        
        if let announcement = announcement {
            makeAccessibilityAnnouncement(announcement)
            analytics.trackFirebaseEvent("accessibility_gamekit_announced", parameters: [
                "operation": operation,
                "success": success
            ])
        }
    }
    
    /// Announce rematch invitation status
    /// - Parameters:
    ///   - offered: Whether player offered rematch
    ///   - accepted: Whether rematch was accepted
    func announceRematchStatus(offered: Bool, accepted: Bool) {
        guard shouldMakeAnnouncement() else { return }
        
        var announcement: String?
        
        if offered {
            announcement = "Rematch invitation sent to opponent."
        } else if accepted {
            announcement = "Rematch accepted. Starting new game."
        } else {
            announcement = "Rematch declined."
        }
        
        if let announcement = announcement {
            makeAccessibilityAnnouncement(announcement)
            analytics.trackFirebaseEvent("accessibility_rematch_announced", parameters: [
                "offered": offered,
                "accepted": accepted
            ])
        }
    }
    
    // MARK: - Analytics Summary for Accessibility
    
    /// Get accessibility-friendly analytics summary
    /// - Returns: Spoken summary of player's multiplayer performance
    func getAccessibleAnalyticsSummary() -> String {
        let summary = analytics.getAnalyticsSummary()
        
        let matchesPlayed = summary["totalMatchesCompleted"] as? Int ?? 0
        let winRate = analytics.getWinRate()
        let currentStreak = summary["currentWinStreak"] as? Int ?? 0
        let avgTurnTime = summary["averageTurnTime"] as? Double ?? 0
        
        var summaryText = "Multiplayer performance summary: "
        
        if matchesPlayed == 0 {
            summaryText += "No completed matches yet."
        } else {
            summaryText += "You've completed \(matchesPlayed) multiplayer match"
            if matchesPlayed != 1 { summaryText += "es" }
            
            summaryText += " with a \(String(format: "%.0f", winRate)) percent win rate."
            
            if currentStreak > 1 {
                summaryText += " You're currently on a \(currentStreak) game winning streak."
            }
            
            if avgTurnTime > 0 {
                summaryText += " Your average turn time is \(String(format: "%.0f", avgTurnTime)) seconds."
            }
            
            // Add connectivity feedback
            let networkReliability = analytics.getNetworkReliabilityScore()
            if networkReliability < 90 {
                summaryText += " Network reliability could be improved."
            }
        }
        
        return summaryText
    }
    
    /// Announce full analytics summary
    func announceAnalyticsSummary() {
        let summary = getAccessibleAnalyticsSummary()
        makeAccessibilityAnnouncement(summary)
        
        analytics.trackFirebaseEvent("accessibility_summary_announced", parameters: [
            "summary_length": summary.count
        ])
    }
    
    // MARK: - Configuration
    
    /// Enable or disable accessibility announcements
    /// - Parameter enabled: Whether to enable announcements
    func setAnnouncementsEnabled(_ enabled: Bool) {
        accessibilityAnnouncementsEnabled = enabled
        
        let message = enabled ? "Multiplayer accessibility announcements enabled." : "Multiplayer accessibility announcements disabled."
        makeAccessibilityAnnouncement(message)
        
        analytics.trackFirebaseEvent("accessibility_announcements_toggled", parameters: [
            "enabled": enabled
        ])
    }
    
    /// Check if accessibility features are needed
    /// - Returns: True if accessibility features should be enhanced
    func needsAccessibilityEnhancements() -> Bool {
        return UIAccessibility.isVoiceOverRunning ||
               UIAccessibility.isSwitchControlRunning ||
               UIAccessibility.isAssistiveTouchRunning
    }
    
    // MARK: - Private Methods
    
    private func setupAccessibilityObservers() {
        // Listen for accessibility changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAccessibilityChange()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.switchControlStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAccessibilityChange()
        }
    }
    
    private func handleAccessibilityChange() {
        let wasEnabled = accessibilityAnnouncementsEnabled
        let shouldEnable = needsAccessibilityEnhancements()
        
        if shouldEnable && !wasEnabled {
            setAnnouncementsEnabled(true)
        }
        
        analytics.trackFirebaseEvent("accessibility_status_changed", parameters: [
            "voice_over": UIAccessibility.isVoiceOverRunning,
            "switch_control": UIAccessibility.isSwitchControlRunning,
            "assistive_touch": UIAccessibility.isAssistiveTouchRunning
        ])
    }
    
    private func shouldMakeAnnouncement() -> Bool {
        guard accessibilityAnnouncementsEnabled else { return false }
        
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastAnnouncementTime < announcementCooldown {
            return false
        }
        
        lastAnnouncementTime = currentTime
        return true
    }
    
    private func makeAccessibilityAnnouncement(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

// MARK: - Integration Extensions

extension MultiplayerAnalyticsManager {
    /// Track accessibility-related events for Firebase
    func trackFirebaseEvent(_ eventName: String, parameters: [String: Any]) {
        guard analyticsEnabled, config.getBoolValue(for: .shareStatistics) else { return }
        
        // This would integrate with Firebase Analytics when available
        // For now, just log for debugging
        if debugLoggingEnabled {
            print("MultiplayerAnalytics: Firebase event: \(eventName) - \(parameters)")
        }
    }
}
