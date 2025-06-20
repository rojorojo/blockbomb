import Foundation
import GameKit
import FirebaseStorage

/// Manages analytics tracking for multiplayer features including match completion, performance, and engagement
/// Extends existing analytics patterns with multiplayer-specific metrics and privacy-compliant data collection
class MultiplayerAnalyticsManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = MultiplayerAnalyticsManager()
    
    // MARK: - Analytics Data Structures
    
    private struct MultiplayerAnalytics: Codable {
        // Match Statistics
        var totalMatchesStarted: Int = 0
        var totalMatchesCompleted: Int = 0
        var totalMatchesWon: Int = 0
        var totalMatchesLost: Int = 0
        var totalMatchesResigned: Int = 0
        var totalMatchesDisconnected: Int = 0
        
        // Performance Metrics
        var totalTurnTime: TimeInterval = 0
        var totalTurns: Int = 0
        var fastestTurn: TimeInterval = 0
        var slowestTurn: TimeInterval = 0
        var averageTurnTime: TimeInterval = 0
        
        // Engagement Metrics
        var totalMultiplayerSessionTime: TimeInterval = 0
        var totalRematchesAccepted: Int = 0
        var totalRematchesOffered: Int = 0
        var consecutiveWins: Int = 0
        var bestWinStreak: Int = 0
        var currentWinStreak: Int = 0
        
        // Game Center Metrics
        var gameCenterConnectionAttempts: Int = 0
        var gameCenterConnectionFailures: Int = 0
        var gameCenterOperationSuccesses: Int = 0
        var gameCenterOperationFailures: Int = 0
        var averageGameCenterLatency: TimeInterval = 0
        
        // Network Connectivity
        var connectionTimeouts: Int = 0
        var reconnectionAttempts: Int = 0
        var reconnectionSuccesses: Int = 0
        var networkErrorsByType: [String: Int] = [:]
        var averageConnectionLatency: TimeInterval = 0
        
        // Session Information
        var lastMultiplayerSession: TimeInterval = 0
        var multiplayerSessionsToday: Int = 0
        var lastAnalyticsUpdate: TimeInterval = 0
    }
    
    private struct MatchSessionData {
        let startTime: TimeInterval
        let matchType: String
        let opponentType: String // "friend", "random", "invited"
        var turnTimes: [TimeInterval] = []
        var connectionEvents: [String] = []
        var performanceMetrics: [String: Double] = [:]
    }
    
    private struct NetworkMetrics {
        var latencyMeasurements: [TimeInterval] = []
        var connectionStartTime: TimeInterval = 0
        var lastHeartbeatTime: TimeInterval = 0
        var activeConnections: Int = 0
    }
    
    // MARK: - Properties
    
    private let userDefaultsKey = "multiplayerAnalyticsData"
    private let firebaseUploadKey = "multiplayerAnalyticsUpload"
    private var analytics: MultiplayerAnalytics
    private var currentMatchSession: MatchSessionData?
    private var networkMetrics = NetworkMetrics()
    private let dateFormatter: DateFormatter
    
    // Configuration
    @Published var analyticsEnabled: Bool = true
    @Published var debugLoggingEnabled: Bool = false
    
    internal let config = MultiplayerConfig.shared
    
    // MARK: - Initialization
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Load existing analytics or create new
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let loadedAnalytics = try? JSONDecoder().decode(MultiplayerAnalytics.self, from: data) {
            analytics = loadedAnalytics
        } else {
            analytics = MultiplayerAnalytics()
        }
        
        // Check if analytics should be enabled based on privacy settings
        analyticsEnabled = config.getBoolValue(for: .shareStatistics)
        
        #if DEBUG
        debugLoggingEnabled = config.getBoolValue(for: .debugModeEnabled)
        #endif
        
        startAnalyticsSession()
    }
    
    // MARK: - Session Management
    
    private func startAnalyticsSession() {
        let today = Date().timeIntervalSince1970
        let dayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        
        // Reset daily counters if it's a new day
        if analytics.lastMultiplayerSession < dayStart {
            analytics.multiplayerSessionsToday = 0
        }
        
        analytics.multiplayerSessionsToday += 1
        analytics.lastMultiplayerSession = today
        analytics.lastAnalyticsUpdate = today
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Session started (Session #\(analytics.multiplayerSessionsToday) today)")
    }
    
    // MARK: - Match Tracking Methods
    
    /// Track the start of a multiplayer match
    /// - Parameters:
    ///   - matchType: Type of match ("competitive", "casual", "ranked")
    ///   - opponentType: Type of opponent ("friend", "random", "invited")
    func trackMultiplayerMatch(matchType: String, opponentType: String) {
        guard analyticsEnabled else { return }
        
        analytics.totalMatchesStarted += 1
        
        // Start new match session tracking
        currentMatchSession = MatchSessionData(
            startTime: Date().timeIntervalSince1970,
            matchType: matchType,
            opponentType: opponentType
        )
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Match started - Type: \(matchType), Opponent: \(opponentType)")
        
        // Track match start event for Firebase
        trackFirebaseEvent("multiplayer_match_started", parameters: [
            "match_type": matchType,
            "opponent_type": opponentType,
            "total_matches": analytics.totalMatchesStarted
        ])
    }
    
    /// Track completion of a multiplayer match
    /// - Parameters:
    ///   - result: Match result ("won", "lost", "resigned", "disconnected", "timeout")
    ///   - finalScore: Player's final score
    ///   - opponentScore: Opponent's final score
    ///   - duration: Match duration in seconds
    func trackMatchCompletion(result: String, finalScore: Int, opponentScore: Int, duration: TimeInterval) {
        guard analyticsEnabled else { return }
        
        analytics.totalMatchesCompleted += 1
        
        // Update specific result counters
        switch result.lowercased() {
        case "won":
            analytics.totalMatchesWon += 1
            analytics.currentWinStreak += 1
            if analytics.currentWinStreak > analytics.bestWinStreak {
                analytics.bestWinStreak = analytics.currentWinStreak
            }
        case "lost":
            analytics.totalMatchesLost += 1
            analytics.currentWinStreak = 0
        case "resigned":
            analytics.totalMatchesResigned += 1
            analytics.currentWinStreak = 0
        case "disconnected":
            analytics.totalMatchesDisconnected += 1
            analytics.currentWinStreak = 0
        default:
            break
        }
        
        // Update session time
        analytics.totalMultiplayerSessionTime += duration
        
        // Finalize current match session
        if var session = currentMatchSession {
            session.performanceMetrics["duration"] = duration
            session.performanceMetrics["final_score"] = Double(finalScore)
            session.performanceMetrics["opponent_score"] = Double(opponentScore)
            session.performanceMetrics["score_difference"] = Double(finalScore - opponentScore)
            
            // Calculate average turn time for this match
            if !session.turnTimes.isEmpty {
                let avgTurnTime = session.turnTimes.reduce(0, +) / Double(session.turnTimes.count)
                session.performanceMetrics["avg_turn_time"] = avgTurnTime
            }
        }
        
        currentMatchSession = nil
        saveAnalytics()
        
        logDebug("MultiplayerAnalytics: Match completed - Result: \(result), Score: \(finalScore)-\(opponentScore), Duration: \(String(format: "%.1f", duration))s")
        
        // Track completion event for Firebase
        trackFirebaseEvent("multiplayer_match_completed", parameters: [
            "result": result,
            "final_score": finalScore,
            "opponent_score": opponentScore,
            "duration": Int(duration),
            "completion_rate": getMatchCompletionRate()
        ])
    }
    
    /// Log turn time for performance tracking
    /// - Parameter turnTime: Time taken for the turn in seconds
    func logTurnTime(_ turnTime: TimeInterval) {
        guard analyticsEnabled else { return }
        
        analytics.totalTurnTime += turnTime
        analytics.totalTurns += 1
        analytics.averageTurnTime = analytics.totalTurnTime / Double(analytics.totalTurns)
        
        // Update fastest/slowest turn records
        if analytics.fastestTurn == 0 || turnTime < analytics.fastestTurn {
            analytics.fastestTurn = turnTime
        }
        if turnTime > analytics.slowestTurn {
            analytics.slowestTurn = turnTime
        }
        
        // Add to current match session if active
        currentMatchSession?.turnTimes.append(turnTime)
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Turn time logged: \(String(format: "%.2f", turnTime))s (Avg: \(String(format: "%.2f", analytics.averageTurnTime))s)")
        
        // Track slow turns for Firebase (only if significantly slow)
        if turnTime > 60 { // More than 1 minute
            trackFirebaseEvent("slow_turn_detected", parameters: [
                "turn_time": Int(turnTime),
                "average_turn_time": Int(analytics.averageTurnTime)
            ])
        }
    }
    
    /// Monitor connectivity status and network performance
    /// - Parameters:
    ///   - event: Connectivity event ("connected", "disconnected", "reconnecting", "timeout", "heartbeat")
    ///   - latency: Network latency in milliseconds (optional)
    func monitorConnectivity(event: String, latency: TimeInterval? = nil) {
        guard analyticsEnabled else { return }
        
        switch event.lowercased() {
        case "connected":
            networkMetrics.activeConnections += 1
            networkMetrics.connectionStartTime = Date().timeIntervalSince1970
            
        case "disconnected":
            if networkMetrics.activeConnections > 0 {
                networkMetrics.activeConnections -= 1
            }
            analytics.connectionTimeouts += 1
            
        case "reconnecting":
            analytics.reconnectionAttempts += 1
            
        case "reconnected":
            analytics.reconnectionSuccesses += 1
            
        case "timeout":
            analytics.connectionTimeouts += 1
            incrementNetworkError("timeout")
            
        case "heartbeat":
            networkMetrics.lastHeartbeatTime = Date().timeIntervalSince1970
            
        default:
            incrementNetworkError(event)
        }
        
        // Track latency if provided
        if let latency = latency {
            networkMetrics.latencyMeasurements.append(latency)
            
            // Calculate rolling average (keep last 100 measurements)
            if networkMetrics.latencyMeasurements.count > 100 {
                networkMetrics.latencyMeasurements.removeFirst()
            }
            
            analytics.averageConnectionLatency = networkMetrics.latencyMeasurements.reduce(0, +) / Double(networkMetrics.latencyMeasurements.count)
        }
        
        // Add to current match session
        currentMatchSession?.connectionEvents.append("\(event):\(Date().timeIntervalSince1970)")
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Connectivity event: \(event)" + (latency != nil ? " (latency: \(latency!)ms)" : ""))
        
        // Track significant connectivity issues for Firebase
        if ["disconnected", "timeout"].contains(event.lowercased()) {
            trackFirebaseEvent("connectivity_issue", parameters: [
                "event_type": event,
                "active_connections": networkMetrics.activeConnections,
                "total_timeouts": analytics.connectionTimeouts
            ])
        }
    }
    
    // MARK: - Game Center Performance Monitoring
    
    /// Track Game Center operation performance
    /// - Parameters:
    ///   - operation: Type of operation ("authentication", "matchmaking", "match_data", "achievement")
    ///   - success: Whether the operation succeeded
    ///   - duration: Operation duration in milliseconds
    ///   - error: Error description if failed
    func trackGameCenterOperation(operation: String, success: Bool, duration: TimeInterval, error: String? = nil) {
        guard analyticsEnabled else { return }
        
        if success {
            analytics.gameCenterOperationSuccesses += 1
        } else {
            analytics.gameCenterOperationFailures += 1
        }
        
        // Update average latency for Game Center operations
        if success {
            let totalOperations = analytics.gameCenterOperationSuccesses + analytics.gameCenterOperationFailures
            analytics.averageGameCenterLatency = ((analytics.averageGameCenterLatency * Double(totalOperations - 1)) + duration) / Double(totalOperations)
        }
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Game Center \(operation) - Success: \(success), Duration: \(String(format: "%.0f", duration))ms" + (error != nil ? ", Error: \(error!)" : ""))
        
        // Track Game Center issues for Firebase
        if !success {
            trackFirebaseEvent("gamekit_operation_failed", parameters: [
                "operation": operation,
                "duration": Int(duration),
                "error": error ?? "unknown",
                "total_failures": analytics.gameCenterOperationFailures
            ])
        }
    }
    
    /// Track Game Center connection attempts
    /// - Parameter success: Whether the connection was successful
    func trackGameCenterConnection(success: Bool) {
        guard analyticsEnabled else { return }
        
        analytics.gameCenterConnectionAttempts += 1
        
        if !success {
            analytics.gameCenterConnectionFailures += 1
        }
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Game Center connection attempt - Success: \(success)")
    }
    
    // MARK: - Engagement Tracking
    
    /// Track rematch behavior
    /// - Parameters:
    ///   - offered: Whether player offered a rematch
    ///   - accepted: Whether player accepted a rematch
    func trackRematchBehavior(offered: Bool, accepted: Bool) {
        guard analyticsEnabled else { return }
        
        if offered {
            analytics.totalRematchesOffered += 1
        }
        
        if accepted {
            analytics.totalRematchesAccepted += 1
        }
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Rematch behavior - Offered: \(offered), Accepted: \(accepted)")
        
        // Track engagement metrics for Firebase
        trackFirebaseEvent("rematch_interaction", parameters: [
            "action": offered ? "offered" : "responded",
            "accepted": accepted,
            "rematch_rate": getRematchAcceptanceRate()
        ])
    }
    
    // MARK: - Data Access Methods
    
    /// Get comprehensive analytics summary
    /// - Returns: Dictionary with all analytics metrics
    func getAnalyticsSummary() -> [String: Any] {
        return [
            // Match Statistics
            "totalMatchesStarted": analytics.totalMatchesStarted,
            "totalMatchesCompleted": analytics.totalMatchesCompleted,
            "totalMatchesWon": analytics.totalMatchesWon,
            "totalMatchesLost": analytics.totalMatchesLost,
            "totalMatchesResigned": analytics.totalMatchesResigned,
            "totalMatchesDisconnected": analytics.totalMatchesDisconnected,
            
            // Performance Metrics
            "averageTurnTime": analytics.averageTurnTime,
            "fastestTurn": analytics.fastestTurn,
            "slowestTurn": analytics.slowestTurn,
            "totalTurns": analytics.totalTurns,
            
            // Engagement Metrics
            "totalMultiplayerSessionTime": analytics.totalMultiplayerSessionTime,
            "totalRematchesAccepted": analytics.totalRematchesAccepted,
            "totalRematchesOffered": analytics.totalRematchesOffered,
            "currentWinStreak": analytics.currentWinStreak,
            "bestWinStreak": analytics.bestWinStreak,
            
            // Game Center Metrics
            "gameCenterConnectionAttempts": analytics.gameCenterConnectionAttempts,
            "gameCenterConnectionFailures": analytics.gameCenterConnectionFailures,
            "gameCenterOperationSuccesses": analytics.gameCenterOperationSuccesses,
            "gameCenterOperationFailures": analytics.gameCenterOperationFailures,
            "averageGameCenterLatency": analytics.averageGameCenterLatency,
            
            // Network Metrics
            "connectionTimeouts": analytics.connectionTimeouts,
            "reconnectionAttempts": analytics.reconnectionAttempts,
            "reconnectionSuccesses": analytics.reconnectionSuccesses,
            "averageConnectionLatency": analytics.averageConnectionLatency,
            
            // Calculated Metrics
            "matchCompletionRate": getMatchCompletionRate(),
            "winRate": getWinRate(),
            "rematchAcceptanceRate": getRematchAcceptanceRate(),
            "networkReliabilityScore": getNetworkReliabilityScore(),
            "gameCenterReliabilityScore": getGameCenterReliabilityScore()
        ]
    }
    
    /// Get match completion rate as percentage
    func getMatchCompletionRate() -> Double {
        guard analytics.totalMatchesStarted > 0 else { return 0.0 }
        return (Double(analytics.totalMatchesCompleted) / Double(analytics.totalMatchesStarted)) * 100.0
    }
    
    /// Get win rate as percentage
    func getWinRate() -> Double {
        guard analytics.totalMatchesCompleted > 0 else { return 0.0 }
        return (Double(analytics.totalMatchesWon) / Double(analytics.totalMatchesCompleted)) * 100.0
    }
    
    /// Get rematch acceptance rate as percentage
    func getRematchAcceptanceRate() -> Double {
        guard analytics.totalRematchesOffered > 0 else { return 0.0 }
        return (Double(analytics.totalRematchesAccepted) / Double(analytics.totalRematchesOffered)) * 100.0
    }
    
    /// Get network reliability score (0-100)
    func getNetworkReliabilityScore() -> Double {
        let totalConnections = analytics.reconnectionAttempts + analytics.connectionTimeouts + 1
        let successfulConnections = analytics.reconnectionSuccesses + 1
        return min((Double(successfulConnections) / Double(totalConnections)) * 100.0, 100.0)
    }
    
    /// Get Game Center reliability score (0-100)
    func getGameCenterReliabilityScore() -> Double {
        let totalOperations = analytics.gameCenterOperationSuccesses + analytics.gameCenterOperationFailures
        guard totalOperations > 0 else { return 100.0 }
        return (Double(analytics.gameCenterOperationSuccesses) / Double(totalOperations)) * 100.0
    }
    
    // MARK: - Privacy and Data Management
    
    /// Enable or disable analytics collection
    /// - Parameter enabled: Whether to enable analytics
    func setAnalyticsEnabled(_ enabled: Bool) {
        analyticsEnabled = enabled
        
        if !enabled {
            logDebug("MultiplayerAnalytics: Analytics disabled by user")
        } else {
            logDebug("MultiplayerAnalytics: Analytics enabled by user")
        }
    }
    
    /// Clear all analytics data (for privacy compliance)
    func clearAllData() {
        analytics = MultiplayerAnalytics()
        currentMatchSession = nil
        networkMetrics = NetworkMetrics()
        
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        logDebug("MultiplayerAnalytics: All data cleared")
    }
    
    /// Export analytics data for user review
    /// - Returns: JSON data containing all analytics
    func exportAnalyticsData() -> Data? {
        let exportData = [
            "analytics": analytics,
            "export_date": Date().timeIntervalSince1970,
            "privacy_compliant": true
        ] as [String: Any]
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            logDebug("MultiplayerAnalytics: Failed to export data: \(error)")
            return nil
        }
    }
    
    // MARK: - Firebase Integration
    
    /// Upload aggregated analytics to Firebase Storage
    func uploadAnalyticsToFirebase() {
        guard analyticsEnabled, config.getBoolValue(for: .shareStatistics) else { return }
        
        // Create anonymized analytics summary
        let anonymizedData = [
            "match_completion_rate": getMatchCompletionRate(),
            "average_turn_time": analytics.averageTurnTime,
            "network_reliability": getNetworkReliabilityScore(),
            "gamekit_reliability": getGameCenterReliabilityScore(),
            "total_matches": analytics.totalMatchesCompleted,
            "timestamp": Date().timeIntervalSince1970,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: anonymizedData, options: .prettyPrinted)
            
            let filename = "multiplayer_analytics_\(UUID().uuidString).json"
            let storageRef = Storage.storage().reference().child("analytics/multiplayer/\(filename)")
            
            storageRef.putData(jsonData, metadata: nil) { [weak self] metadata, error in
                if let error = error {
                    self?.logDebug("MultiplayerAnalytics: Firebase upload failed: \(error)")
                } else {
                    self?.logDebug("MultiplayerAnalytics: Analytics uploaded to Firebase successfully")
                }
            }
        } catch {
            logDebug("MultiplayerAnalytics: Failed to serialize analytics data: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func incrementNetworkError(_ errorType: String) {
        if analytics.networkErrorsByType[errorType] != nil {
            analytics.networkErrorsByType[errorType]! += 1
        } else {
            analytics.networkErrorsByType[errorType] = 1
        }
    }
    
    private func saveAnalytics() {
        do {
            let data = try JSONEncoder().encode(analytics)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            logDebug("MultiplayerAnalytics: Failed to save analytics: \(error)")
        }
    }
    
    private func logDebug(_ message: String) {
        if debugLoggingEnabled {
            print(message)
        }
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// Reset all analytics data for testing
    func debugResetAnalytics() {
        clearAllData()
        startAnalyticsSession()
        logDebug("MultiplayerAnalytics: Debug reset completed")
    }
    
    /// Simulate realistic usage data for testing
    func debugSimulateUsage() {
        analytics.totalMatchesStarted += 10
        analytics.totalMatchesCompleted += 8
        analytics.totalMatchesWon += 5
        analytics.totalMatchesLost += 3
        analytics.totalTurnTime += 240.0 // 4 minutes total
        analytics.totalTurns += 24
        analytics.averageTurnTime = analytics.totalTurnTime / Double(analytics.totalTurns)
        analytics.totalRematchesOffered += 3
        analytics.totalRematchesAccepted += 2
        analytics.currentWinStreak = 2
        analytics.bestWinStreak = 4
        
        saveAnalytics()
        logDebug("MultiplayerAnalytics: Debug simulation completed")
    }
    
    /// Get detailed analytics string for debug display
    func debugGetDetailedAnalytics() -> String {
        let summary = getAnalyticsSummary()
        
        return """
        === MULTIPLAYER ANALYTICS ===
        Matches Started: \(analytics.totalMatchesStarted)
        Matches Completed: \(analytics.totalMatchesCompleted)
        Completion Rate: \(String(format: "%.1f", getMatchCompletionRate()))%
        
        === MATCH RESULTS ===
        Wins: \(analytics.totalMatchesWon)
        Losses: \(analytics.totalMatchesLost)
        Win Rate: \(String(format: "%.1f", getWinRate()))%
        Current Streak: \(analytics.currentWinStreak)
        Best Streak: \(analytics.bestWinStreak)
        
        === PERFORMANCE ===
        Average Turn Time: \(String(format: "%.2f", analytics.averageTurnTime))s
        Fastest Turn: \(String(format: "%.2f", analytics.fastestTurn))s
        Slowest Turn: \(String(format: "%.2f", analytics.slowestTurn))s
        Total Turns: \(analytics.totalTurns)
        
        === CONNECTIVITY ===
        Network Reliability: \(String(format: "%.1f", getNetworkReliabilityScore()))%
        Connection Timeouts: \(analytics.connectionTimeouts)
        Reconnection Success: \(analytics.reconnectionSuccesses)/\(analytics.reconnectionAttempts)
        Average Latency: \(String(format: "%.0f", analytics.averageConnectionLatency))ms
        
        === GAME CENTER ===
        GK Reliability: \(String(format: "%.1f", getGameCenterReliabilityScore()))%
        Operations Success: \(analytics.gameCenterOperationSuccesses)
        Operations Failed: \(analytics.gameCenterOperationFailures)
        Average GK Latency: \(String(format: "%.0f", analytics.averageGameCenterLatency))ms
        
        === ENGAGEMENT ===
        Rematch Acceptance: \(String(format: "%.1f", getRematchAcceptanceRate()))%
        Total Session Time: \(String(format: "%.1f", analytics.totalMultiplayerSessionTime / 60))min
        Sessions Today: \(analytics.multiplayerSessionsToday)
        """
    }
    #endif
}
