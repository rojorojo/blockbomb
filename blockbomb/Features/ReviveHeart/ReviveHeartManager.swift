import Foundation

/// Manages the revive heart system including persistence and heart count tracking
class ReviveHeartManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ReviveHeartManager()
    
    // MARK: - Published Properties
    @Published var heartCount: Int = 3 {
        didSet {
            saveHeartCount()
        }
    }
    
    // MARK: - Constants
    private let userDefaultsKey = "reviveHeartCount"
    private let defaultHeartCount = 3
    
    // MARK: - Initialization
    private init() {
        loadHeartCount()
    }
    
    // MARK: - Public Methods
    
    /// Get the current number of revive hearts
    /// - Returns: The current heart count
    func getHeartCount() -> Int {
        return heartCount
    }
    
    /// Check if the player has any revive hearts available
    /// - Returns: True if hearts > 0, false otherwise
    func hasHearts() -> Bool {
        return heartCount > 0
    }
    
    /// Use one revive heart (decrements count by 1)
    /// - Returns: True if a heart was successfully used, false if no hearts available
    @discardableResult
    func useHeart() -> Bool {
        guard hasHearts() else {
            print("ReviveHeartManager: Cannot use heart - no hearts available")
            return false
        }
        
        heartCount -= 1
        print("ReviveHeartManager: Used 1 heart. Remaining: \(heartCount)")
        return true
    }
    
    /// Add hearts to the player's inventory
    /// - Parameter count: Number of hearts to add
    func addHearts(count: Int) {
        guard count > 0 else {
            print("ReviveHeartManager: Cannot add negative or zero hearts")
            return
        }
        
        heartCount += count
        print("ReviveHeartManager: Added \(count) hearts. Total: \(heartCount)")
    }
    
    /// Reset hearts to default count (useful for testing or game reset)
    func resetHearts() {
        heartCount = defaultHeartCount
        print("ReviveHeartManager: Reset hearts to default count: \(defaultHeartCount)")
    }
    
    // MARK: - Private Methods
    
    /// Load heart count from UserDefaults
    private func loadHeartCount() {
        if UserDefaults.standard.object(forKey: userDefaultsKey) != nil {
            // Heart count exists in UserDefaults
            heartCount = UserDefaults.standard.integer(forKey: userDefaultsKey)
            print("ReviveHeartManager: Loaded heart count from UserDefaults: \(heartCount)")
        } else {
            // First launch - initialize with default hearts
            heartCount = defaultHeartCount
            saveHeartCount()
            print("ReviveHeartManager: First launch - initialized with \(defaultHeartCount) hearts")
        }
    }
    
    /// Save heart count to UserDefaults
    private func saveHeartCount() {
        UserDefaults.standard.set(heartCount, forKey: userDefaultsKey)
        print("ReviveHeartManager: Saved heart count to UserDefaults: \(heartCount)")
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension ReviveHeartManager {
    /// Debug method to set a specific heart count (only available in debug builds)
    func debugSetHearts(_ count: Int) {
        heartCount = max(0, count) // Ensure non-negative
        print("ReviveHeartManager: Debug set hearts to: \(heartCount)")
    }
    
    /// Debug method to clear UserDefaults (only available in debug builds)
    func debugClearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        loadHeartCount() // Reload from defaults
        print("ReviveHeartManager: Debug cleared UserDefaults and reloaded")
    }
}
#endif
