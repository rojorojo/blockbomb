import SwiftUI
import Charts

#if DEBUG
/// Debug dashboard for multiplayer analytics visualization and testing
struct MultiplayerAnalyticsDashboard: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var analytics = MultiplayerAnalyticsManager.shared
    @State private var selectedMetricCategory: AnalyticsCategory = .matches
    @State private var showExportSheet = false
    @State private var exportedData = ""
    @State private var showClearConfirmation = false
    
    enum AnalyticsCategory: String, CaseIterable {
        case matches = "Matches"
        case performance = "Performance"
        case connectivity = "Connectivity"
        case engagement = "Engagement"
        case gameCenter = "Game Center"
        
        var systemImage: String {
            switch self {
            case .matches: return "gamecontroller"
            case .performance: return "speedometer"
            case .connectivity: return "wifi"
            case .engagement: return "heart"
            case .gameCenter: return "person.2.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .matches: return .blue
            case .performance: return .green
            case .connectivity: return .orange
            case .engagement: return .pink
            case .gameCenter: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header with key metrics
                    headerMetricsView
                    
                    // Category selector
                    categorySelector
                    
                    // Analytics content
                    analyticsContent
                    
                    // Action buttons
                    actionButtons
                }
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button("Export") {
                        exportAnalytics()
                        showExportSheet = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear") {
                        showClearConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            )
        }
        .sheet(isPresented: $showExportSheet) {
            AnalyticsExportView(data: exportedData)
        }
        .alert(isPresented: $showClearConfirmation) {
            Alert(
                title: Text("Clear Analytics Data"),
                message: Text("This will permanently delete all multiplayer analytics data. This action cannot be undone."),
                primaryButton: .destructive(Text("Clear")) {
                    analytics.clearAllData()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - View Components
    
    private var headerMetricsView: some View {
        let summary = analytics.getAnalyticsSummary()
        
        return VStack(spacing: 12) {
            // Title
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(BlockColors.violet)
                Text("Multiplayer Analytics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Key metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Matches",
                    value: "\(summary["totalMatchesCompleted"] as? Int ?? 0)",
                    subtitle: "\(String(format: "%.1f", analytics.getMatchCompletionRate()))% completion",
                    color: .blue
                )
                
                MetricCard(
                    title: "Win Rate",
                    value: "\(String(format: "%.1f", analytics.getWinRate()))%",
                    subtitle: "Streak: \(summary["currentWinStreak"] as? Int ?? 0)",
                    color: .green
                )
                
                MetricCard(
                    title: "Network",
                    value: "\(String(format: "%.1f", analytics.getNetworkReliabilityScore()))%",
                    subtitle: "reliability",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnalyticsCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMetricCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.systemImage)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedMetricCategory == category ? category.color : Color.gray.opacity(0.3))
                        )
                        .foregroundColor(selectedMetricCategory == category ? .white : .gray)
                    }
                    .accessibilityLabel("\(category.rawValue) analytics category")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var analyticsContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch selectedMetricCategory {
                case .matches:
                    matchAnalyticsView
                case .performance:
                    performanceAnalyticsView
                case .connectivity:
                    connectivityAnalyticsView
                case .engagement:
                    engagementAnalyticsView
                case .gameCenter:
                    gameCenterAnalyticsView
                }
            }
            .padding()
        }
    }
    
    private var matchAnalyticsView: some View {
        let summary = analytics.getAnalyticsSummary()
        
        return VStack(spacing: 16) {
            // Match completion chart
            AnalyticsCard(title: "Match Statistics", icon: "gamecontroller") {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Started: \(summary["totalMatchesStarted"] as? Int ?? 0)")
                                .foregroundColor(.white)
                            Text("Completed: \(summary["totalMatchesCompleted"] as? Int ?? 0)")
                                .foregroundColor(.green)
                            Text("Completion Rate: \(String(format: "%.1f", analytics.getMatchCompletionRate()))%")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        // Simple completion visualization
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: analytics.getMatchCompletionRate() / 100.0)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 60, height: 60)
                            
                            Text("\(Int(analytics.getMatchCompletionRate()))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // Results breakdown
            AnalyticsCard(title: "Match Results", icon: "chart.bar") {
                VStack(spacing: 8) {
                    let wins = summary["totalMatchesWon"] as? Int ?? 0
                    let losses = summary["totalMatchesLost"] as? Int ?? 0
                    let resigned = summary["totalMatchesResigned"] as? Int ?? 0
                    let disconnected = summary["totalMatchesDisconnected"] as? Int ?? 0
                    
                    ResultRow(label: "Wins", value: wins, color: .green)
                    ResultRow(label: "Losses", value: losses, color: .red)
                    ResultRow(label: "Resigned", value: resigned, color: .orange)
                    ResultRow(label: "Disconnected", value: disconnected, color: .gray)
                }
            }
        }
    }
    
    private var performanceAnalyticsView: some View {
        let summary = analytics.getAnalyticsSummary()
        
        return VStack(spacing: 16) {
            AnalyticsCard(title: "Turn Performance", icon: "timer") {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average: \(String(format: "%.2f", summary["averageTurnTime"] as? Double ?? 0))s")
                                .foregroundColor(.white)
                            Text("Fastest: \(String(format: "%.2f", summary["fastestTurn"] as? Double ?? 0))s")
                                .foregroundColor(.green)
                            Text("Slowest: \(String(format: "%.2f", summary["slowestTurn"] as? Double ?? 0))s")
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Turns")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(summary["totalTurns"] as? Int ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Performance indicator
                    let avgTime = summary["averageTurnTime"] as? Double ?? 0
                    HStack {
                        Text("Performance:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(getPerformanceRating(avgTime))
                            .foregroundColor(getPerformanceColor(avgTime))
                            .fontWeight(.semibold)
                    }
                }
            }
            
            AnalyticsCard(title: "Session Time", icon: "clock") {
                VStack(spacing: 8) {
                    let sessionTime = summary["totalMultiplayerSessionTime"] as? Double ?? 0
                    let hours = Int(sessionTime) / 3600
                    let minutes = (Int(sessionTime) % 3600) / 60
                    
                    HStack {
                        Text("Total Session Time")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(hours)h \(minutes)m")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    
                    if let matches = summary["totalMatchesCompleted"] as? Int, matches > 0 {
                        HStack {
                            Text("Average per Match")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(String(format: "%.1f", sessionTime / Double(matches) / 60))min")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private var connectivityAnalyticsView: some View {
        let summary = analytics.getAnalyticsSummary()
        
        return VStack(spacing: 16) {
            AnalyticsCard(title: "Network Reliability", icon: "wifi") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Reliability Score")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(String(format: "%.1f", analytics.getNetworkReliabilityScore()))%")
                            .foregroundColor(getReliabilityColor(analytics.getNetworkReliabilityScore()))
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Average Latency")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(String(format: "%.0f", summary["averageConnectionLatency"] as? Double ?? 0))ms")
                            .foregroundColor(.white)
                    }
                }
            }
            
            AnalyticsCard(title: "Connection Events", icon: "network") {
                VStack(spacing: 8) {
                    ResultRow(label: "Timeouts", value: summary["connectionTimeouts"] as? Int ?? 0, color: .red)
                    ResultRow(label: "Reconnection Attempts", value: summary["reconnectionAttempts"] as? Int ?? 0, color: .orange)
                    ResultRow(label: "Successful Reconnections", value: summary["reconnectionSuccesses"] as? Int ?? 0, color: .green)
                }
            }
        }
    }
    
    private var engagementAnalyticsView: some View {
        let summary = analytics.getAnalyticsSummary()
        
        return VStack(spacing: 16) {
            AnalyticsCard(title: "Rematch Behavior", icon: "arrow.triangle.2.circlepath") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Acceptance Rate")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(String(format: "%.1f", analytics.getRematchAcceptanceRate()))%")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Offered: \(summary["totalRematchesOffered"] as? Int ?? 0)")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Accepted: \(summary["totalRematchesAccepted"] as? Int ?? 0)")
                            .foregroundColor(.green)
                    }
                }
            }
            
            AnalyticsCard(title: "Win Streaks", icon: "flame") {
                VStack(spacing: 8) {
                    HStack {
                        Text("Current Streak")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(summary["currentWinStreak"] as? Int ?? 0)")
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Best Streak")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(summary["bestWinStreak"] as? Int ?? 0)")
                            .foregroundColor(.yellow)
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
    
    private var gameCenterAnalyticsView: some View {
        let summary = analytics.getAnalyticsSummary()
        
        return VStack(spacing: 16) {
            AnalyticsCard(title: "Game Center Reliability", icon: "person.2.circle") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Reliability Score")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(String(format: "%.1f", analytics.getGameCenterReliabilityScore()))%")
                            .foregroundColor(getReliabilityColor(analytics.getGameCenterReliabilityScore()))
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Average Latency")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(String(format: "%.0f", summary["averageGameCenterLatency"] as? Double ?? 0))ms")
                            .foregroundColor(.white)
                    }
                }
            }
            
            AnalyticsCard(title: "Operations", icon: "gearshape") {
                VStack(spacing: 8) {
                    ResultRow(label: "Successful", value: summary["gameCenterOperationSuccesses"] as? Int ?? 0, color: .green)
                    ResultRow(label: "Failed", value: summary["gameCenterOperationFailures"] as? Int ?? 0, color: .red)
                    ResultRow(label: "Connection Attempts", value: summary["gameCenterConnectionAttempts"] as? Int ?? 0, color: .blue)
                    ResultRow(label: "Connection Failures", value: summary["gameCenterConnectionFailures"] as? Int ?? 0, color: .orange)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("Simulate Data") {
                    analytics.debugSimulateUsage()
                }
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
                
                Button("Upload to Firebase") {
                    analytics.uploadAnalyticsToFirebase()
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
            
            Text("Debug actions for testing analytics system")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Helper Methods
    
    private func exportAnalytics() {
        if let data = analytics.exportAnalyticsData(),
           let jsonString = String(data: data, encoding: .utf8) {
            exportedData = jsonString
        } else {
            exportedData = "Failed to export analytics data"
        }
    }
    
    private func getPerformanceRating(_ avgTime: Double) -> String {
        switch avgTime {
        case 0..<15: return "Excellent"
        case 15..<30: return "Good"
        case 30..<60: return "Fair"
        default: return "Slow"
        }
    }
    
    private func getPerformanceColor(_ avgTime: Double) -> Color {
        switch avgTime {
        case 0..<15: return .green
        case 15..<30: return .blue
        case 30..<60: return .orange
        default: return .red
        }
    }
    
    private func getReliabilityColor(_ score: Double) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct AnalyticsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(BlockColors.violet)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            content()
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ResultRow: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text("\(value)")
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
}

struct AnalyticsExportView: View {
    @Environment(\.presentationMode) var presentationMode
    let data: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(data)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
            }
            .background(Color(red: 0.02, green: 0, blue: 0.22, opacity: 1))
            .navigationTitle("Exported Analytics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#endif
