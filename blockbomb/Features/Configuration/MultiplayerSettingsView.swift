import SwiftUI
import GameKit

/// Multiplayer settings view for user configuration
struct MultiplayerSettingsView: View {
    @ObservedObject private var config = MultiplayerConfig.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showPrivacyInfo = false
    @State private var gameCenterAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerView
                        
                        // Game Center Status
                        gameCenterStatusView
                        
                        // Match Settings
                        matchSettingsSection
                        
                        // Player Preferences
                        playerPreferencesSection
                        
                        // Privacy Settings
                        privacySettingsSection
                        
                        // Advanced Settings (Debug only)
                        #if DEBUG
                        advancedSettingsSection
                        #endif
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Extra bottom padding for safe area
                }
            }
            .navigationTitle("Multiplayer Settings")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Reset") {
                    resetToRecommended()
                }
                .foregroundColor(.orange)
            )
        }
        .alert(isPresented: $gameCenterAlert) {
            Alert(
                title: Text("Game Center Required"),
                message: Text("Please sign in to Game Center to enable multiplayer features."),
                primaryButton: .default(Text("Settings")) {
                    openGameCenterSettings()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showPrivacyInfo) {
            PrivacyInfoView()
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundColor(BlockColors.violet)
            
            Text("Multiplayer Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Configure your multiplayer experience")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var gameCenterStatusView: some View {
        SettingBox {
            HStack {
                Image(systemName: config.gameCenterAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(config.gameCenterAvailable ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Center")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    
                    Text(config.gameCenterAvailable ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !config.gameCenterAvailable {
                    Button("Connect") {
                        gameCenterAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .accessibilityLabel("Game Center status: \(config.gameCenterAvailable ? "Connected" : "Not Connected")")
    }
    
    private var matchSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Match Settings", icon: "gamecontroller")
            
            SettingBox {
                VStack(spacing: 16) {
                    // Max concurrent matches
                    ConfigSliderRow(
                        title: "Max Active Matches",
                        description: "Maximum number of games you can play at once",
                        value: Binding(
                            get: { config.getValue(for: .maxConcurrentMatches) },
                            set: { config.setValue($0, for: .maxConcurrentMatches) }
                        ),
                        range: 1...5,
                        step: 1
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Turn timeout
                    ConfigSliderRow(
                        title: "Turn Timeout",
                        description: "Time limit for each move (minutes)",
                        value: Binding(
                            get: { config.getValue(for: .turnTimeoutSeconds) / 60 },
                            set: { config.setValue($0 * 60, for: .turnTimeoutSeconds) }
                        ),
                        range: 1...5,
                        step: 1,
                        suffix: "min"
                    )
                }
            }
        }
    }
    
    private var playerPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Player Preferences", icon: "person.2")
            
            SettingBox {
                VStack(spacing: 16) {
                    // Allow random opponents
                    ToggleRow(
                        title: "Random Opponents",
                        description: "Allow matchmaking with unknown players",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .allowRandomOpponents) },
                            set: { config.setValue($0 ? 1 : 0, for: .allowRandomOpponents) }
                        )
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Show opponent score
                    ToggleRow(
                        title: "Show Opponent Score",
                        description: "Display your opponent's score during the game",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .showOpponentScore) },
                            set: { config.setValue($0 ? 1 : 0, for: .showOpponentScore) }
                        )
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Auto accept rematch
                    ToggleRow(
                        title: "Auto Accept Rematch",
                        description: "Automatically accept rematch requests",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .autoAcceptRematch) },
                            set: { config.setValue($0 ? 1 : 0, for: .autoAcceptRematch) }
                        )
                    )
                }
            }
        }
    }
    
    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Privacy & Sharing", icon: "lock.shield")
                
                Spacer()
                
                Button("Info") {
                    showPrivacyInfo = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            SettingBox {
                VStack(spacing: 16) {
                    // Share statistics
                    ToggleRow(
                        title: "Share Statistics",
                        description: "Share your multiplayer stats with Game Center",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .shareStatistics) },
                            set: { config.setValue($0 ? 1 : 0, for: .shareStatistics) }
                        ),
                        disabled: !config.gameCenterAvailable
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Allow leaderboards
                    ToggleRow(
                        title: "Leaderboards",
                        description: "Participate in Game Center leaderboards",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .allowLeaderboards) },
                            set: { config.setValue($0 ? 1 : 0, for: .allowLeaderboards) }
                        ),
                        disabled: !config.gameCenterAvailable
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Enable achievements
                    ToggleRow(
                        title: "Achievements",
                        description: "Enable Game Center achievements",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .enableAchievements) },
                            set: { config.setValue($0 ? 1 : 0, for: .enableAchievements) }
                        ),
                        disabled: !config.gameCenterAvailable
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Anonymous mode
                    ToggleRow(
                        title: "Anonymous Mode",
                        description: "Play without sharing player information",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .anonymousMode) },
                            set: { config.setValue($0 ? 1 : 0, for: .anonymousMode) }
                        )
                    )
                }
            }
        }
    }
    
    #if DEBUG
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Advanced (Debug)", icon: "ladybug")
            
            SettingBox {
                VStack(spacing: 16) {
                    // Debug mode
                    ToggleRow(
                        title: "Debug Mode",
                        description: "Enable debug features and verbose logging",
                        isOn: Binding(
                            get: { config.getBoolValue(for: .debugModeEnabled) },
                            set: { config.setValue($0 ? 1 : 0, for: .debugModeEnabled) }
                        )
                    )
                    
                    if config.getBoolValue(for: .debugModeEnabled) {
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // Simulate network delay
                        ConfigSliderRow(
                            title: "Network Delay",
                            description: "Artificial network delay for testing",
                            value: Binding(
                                get: { config.getValue(for: .simulateNetworkDelay) },
                                set: { config.setValue($0, for: .simulateNetworkDelay) }
                            ),
                            range: 0...2000,
                            step: 100,
                            suffix: "ms"
                        )
                    }
                }
            }
        }
    }
    #endif
    
    // MARK: - Helper Methods
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(BlockColors.violet)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
    
    private func resetToRecommended() {
        // Reset to recommended values for most users
        config.setValue(3, for: .maxConcurrentMatches)
        config.setValue(120, for: .turnTimeoutSeconds) // 2 minutes
        config.setValue(1, for: .allowRandomOpponents)
        config.setValue(1, for: .showOpponentScore)
        config.setValue(0, for: .autoAcceptRematch)
        
        if config.gameCenterAvailable {
            config.setValue(1, for: .shareStatistics)
            config.setValue(1, for: .allowLeaderboards)
            config.setValue(1, for: .enableAchievements)
        }
        
        config.setValue(0, for: .anonymousMode)
    }
    
    private func openGameCenterSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Supporting Views

struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var disabled: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(disabled ? .gray : .white)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: BlockColors.violet))
                .disabled(disabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(isOn ? "On" : "Off"). \(description)")
        .opacity(disabled ? 0.5 : 1.0)
    }
}

struct ConfigSliderRow: View {
    let title: String
    let description: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    var suffix: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text("\(value)\(suffix)")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .frame(minWidth: 40)
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .accentColor(BlockColors.violet)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(suffix). \(description)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
        }
    }
}

struct PrivacyInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Information")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    privacySection(
                        title: "What We Collect",
                        content: """
                        • Game statistics (wins, losses, scores)
                        • Match duration and frequency
                        • Player preferences and settings
                        • Device and performance information
                        """
                    )
                    
                    privacySection(
                        title: "How We Use Your Information",
                        content: """
                        • Improve matchmaking and game balance
                        • Provide Game Center integration
                        • Enhance multiplayer experience
                        • Debug and performance optimization
                        """
                    )
                    
                    privacySection(
                        title: "Your Control",
                        content: """
                        • Anonymous Mode: Play without sharing info
                        • Toggle sharing features individually
                        • Data stays local unless explicitly shared
                        • Delete data anytime through settings
                        """
                    )
                    
                    privacySection(
                        title: "Game Center",
                        content: """
                        When enabled, Apple's Game Center handles:
                        • Player authentication and profiles
                        • Leaderboards and achievements
                        • Friend connections and invites
                        
                        Subject to Apple's Privacy Policy.
                        """
                    )
                }
                .padding()
            }
            .background(Color(red: 0.02, green: 0, blue: 0.22, opacity: 1))
            .navigationTitle("Privacy")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(BlockColors.violet)
            
            Text(content)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

// Reuse SettingBox from existing SettingsView
// (This assumes SettingBox is made available - could be moved to a shared file)
