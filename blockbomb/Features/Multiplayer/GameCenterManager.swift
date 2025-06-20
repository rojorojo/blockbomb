import Foundation
import GameKit
import UIKit

/// Manages Game Center authentication and basic integration for BlockBomb multiplayer features
/// Handles authentication states, user consent, and provides core Game Center functionality
class GameCenterManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = GameCenterManager()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var authenticationError: String?
    @Published var localPlayer: GKLocalPlayer?
    
    // MARK: - Private Properties
    private var authenticationCompletionHandler: ((Bool, Error?) -> Void)?
    
    // MARK: - Configuration
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    private var retryCount = 0
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupGameCenter()
    }
    
    // MARK: - Setup Methods
    
    /// Initialize Game Center and set up authentication
    private func setupGameCenter() {
        print("GameCenterManager: Starting Game Center initialization")
        
        // Set up local player
        localPlayer = GKLocalPlayer.local
        
        // Configure authentication handler
        setupAuthenticationHandler()
        
        // Configure accessibility
        configureAccessibility()
        
        // Start authentication process
        authenticatePlayer()
    }
    
    /// Configure the authentication handler for Game Center
    private func setupAuthenticationHandler() {
        guard let localPlayer = localPlayer else {
            print("GameCenterManager: Error - Local player not available")
            return
        }
        
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                self?.handleAuthenticationResult(viewController: viewController, error: error)
            }
        }
    }
    
    /// Handle the result of Game Center authentication
    /// - Parameters:
    ///   - viewController: Optional view controller to present for authentication UI
    ///   - error: Optional error from authentication attempt
    private func handleAuthenticationResult(viewController: UIViewController?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isAuthenticating = false
            
            if let error = error {
                print("GameCenterManager: Authentication failed with error: \(error.localizedDescription)")
                self.authenticationError = error.localizedDescription
                self.isAuthenticated = false
                
                // Retry logic for transient errors
                if self.retryCount < self.maxRetryAttempts && self.shouldRetryAuthentication(error: error) {
                    self.scheduleRetryAuthentication()
                } else {
                    self.authenticationCompletionHandler?(false, error)
                    self.authenticationCompletionHandler = nil
                }
                return
            }
            
            if let viewController = viewController {
                // Present authentication UI
                print("GameCenterManager: Presenting Game Center authentication UI")
                self.presentAuthenticationViewController(viewController)
            } else if self.localPlayer?.isAuthenticated == true {
                // Successfully authenticated
                print("GameCenterManager: Successfully authenticated player: \(self.localPlayer?.displayName ?? "Unknown")")
                self.isAuthenticated = true
                self.authenticationError = nil
                self.retryCount = 0
                
                // Configure accessibility for successful authentication
                DispatchQueue.main.async {
                    UIAccessibility.post(notification: .announcement, 
                                       argument: "Game Center authentication successful. You can now play with friends.")
                }
                
                self.authenticationCompletionHandler?(true, nil)
                self.authenticationCompletionHandler = nil
            } else {
                // Authentication failed without specific error
                print("GameCenterManager: Authentication failed - player not authenticated")
                self.authenticationError = "Game Center authentication failed"
                self.isAuthenticated = false
                self.authenticationCompletionHandler?(false, nil)
                self.authenticationCompletionHandler = nil
            }
        }
    }
    
    /// Present the Game Center authentication view controller
    /// - Parameter viewController: The authentication view controller to present
    private func presentAuthenticationViewController(_ viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("GameCenterManager: Error - Cannot find root view controller to present authentication")
            authenticationError = "Unable to present Game Center authentication"
            isAuthenticated = false
            isAuthenticating = false
            authenticationCompletionHandler?(false, NSError(domain: "GameCenterManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unable to present authentication UI"]))
            authenticationCompletionHandler = nil
            return
        }
        
        // Set accessibility properties for Game Center authentication
        viewController.view.accessibilityLabel = "Game Center Authentication"
        viewController.view.accessibilityHint = "Sign in to Game Center to play with friends"
        
        rootViewController.present(viewController, animated: true) { [weak self] in
            print("GameCenterManager: Game Center authentication UI presented")
            // Keep isAuthenticating true while UI is showing
            self?.isAuthenticating = true
        }
    }
    
    /// Determine if authentication should be retried for the given error
    /// - Parameter error: The authentication error
    /// - Returns: True if retry should be attempted, false otherwise
    private func shouldRetryAuthentication(error: Error) -> Bool {
        // Only retry for network-related errors or temporary failures
        let nsError = error as NSError
        return nsError.domain == GKErrorDomain && 
               (nsError.code == GKError.communicationsFailure.rawValue ||
                nsError.code == GKError.notSupported.rawValue)
    }
    
    /// Schedule a retry of Game Center authentication after a delay
    private func scheduleRetryAuthentication() {
        retryCount += 1
        print("GameCenterManager: Scheduling authentication retry \(retryCount)/\(maxRetryAttempts) in \(retryDelay) seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            self?.authenticatePlayer()
        }
    }
    
    // MARK: - Public Methods
    
    /// Initiate Game Center player authentication
    /// - Parameter completion: Optional completion handler called with success/failure result
    func authenticatePlayer(completion: ((Bool, Error?) -> Void)? = nil) {
        print("GameCenterManager: Starting player authentication")
        
        authenticationCompletionHandler = completion
        isAuthenticating = true
        authenticationError = nil
        
        guard let localPlayer = localPlayer else {
            let error = NSError(domain: "GameCenterManager", 
                              code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Local player not available"])
            handleAuthenticationResult(viewController: nil, error: error)
            return
        }
        
        // Check if already authenticated
        if localPlayer.isAuthenticated {
            print("GameCenterManager: Player already authenticated")
            isAuthenticated = true
            isAuthenticating = false
            completion?(true, nil)
            return
        }
        
        // Force authentication by accessing authenticateHandler property
        // This triggers the authentication flow if not already in progress
        print("GameCenterManager: Triggering authentication process")
        
        // Set a timeout to handle cases where authentication handler doesn't respond
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            
            // If still authenticating after timeout, treat as failure
            if self.isAuthenticating && !self.isAuthenticated {
                let timeoutError = NSError(domain: "GameCenterManager", 
                                         code: -2, 
                                         userInfo: [NSLocalizedDescriptionKey: "Authentication timeout - please try again"])
                self.handleAuthenticationResult(viewController: nil, error: timeoutError)
            }
        }
        
        // Force trigger the authentication handler by accessing the property
        // This is a workaround for cases where the handler wasn't properly triggered
        if localPlayer.authenticateHandler == nil {
            setupAuthenticationHandler()
        }
        
        // Try to force authentication by creating a simple Game Center request
        // This often triggers the authentication flow
        GKLocalPlayer.local.loadDefaultLeaderboardIdentifier { [weak self] _, error in
            // This call will trigger authentication if needed
            // The actual result is handled by the authenticateHandler
            if let error = error {
                print("GameCenterManager: Authentication trigger attempt completed with: \(error.localizedDescription)")
            }
        }
    }
    
    /// Check if the current player is authenticated with Game Center
    /// - Returns: True if authenticated, false otherwise
    func isPlayerAuthenticated() -> Bool {
        return localPlayer?.isAuthenticated == true && isAuthenticated
    }
    
    /// Get the current authenticated player's ID
    /// - Returns: The player ID if authenticated, nil otherwise
    func getPlayerID() -> String? {
        guard isPlayerAuthenticated() else {
            print("GameCenterManager: Cannot get player ID - not authenticated")
            return nil
        }
        
        let playerID = localPlayer?.gamePlayerID
        print("GameCenterManager: Retrieved player ID: \(playerID ?? "nil")")
        return playerID
    }
    
    /// Get the current authenticated player's display name
    /// - Returns: The display name if authenticated, nil otherwise
    func getPlayerDisplayName() -> String? {
        guard isPlayerAuthenticated() else {
            print("GameCenterManager: Cannot get display name - not authenticated")
            return nil
        }
        
        let displayName = localPlayer?.displayName
        print("GameCenterManager: Retrieved display name: \(displayName ?? "nil")")
        return displayName
    }
    
    /// Reset authentication state (useful for testing or logout scenarios)
    func resetAuthenticationState() {
        print("GameCenterManager: Resetting authentication state")
        isAuthenticated = false
        isAuthenticating = false
        authenticationError = nil
        retryCount = 0
        authenticationCompletionHandler = nil
    }
    
    /// Clear authentication error (useful for UI error handling)
    func clearAuthenticationError() {
        authenticationError = nil
    }
}

// MARK: - Accessibility Support

extension GameCenterManager {
    
    /// Configure accessibility settings for Game Center integration
    func configureAccessibility() {
        print("GameCenterManager: Configuring accessibility support")
        
        // Configure accessibility for authentication state changes
        if isPlayerAuthenticated() {
            DispatchQueue.main.async {
                UIAccessibility.post(notification: .announcement, 
                                   argument: "Game Center authentication successful. You can now play with friends.")
            }
        }
    }
}

// MARK: - Privacy Compliance

extension GameCenterManager {
    
    /// Check if Game Center is available and user has consented
    /// - Returns: True if Game Center is available for use, false otherwise
    func isGameCenterAvailable() -> Bool {
        // Check if Game Center is supported on this device
        guard GKLocalPlayer.local.isUnderage == false else {
            print("GameCenterManager: Game Center not available - underage player")
            return false
        }
        
        // Check if player has authenticated (implicit consent)
        guard isPlayerAuthenticated() else {
            print("GameCenterManager: Game Center not available - not authenticated")
            return false
        }
        
        return true
    }
    
    /// Get privacy-compliant player information
    /// - Returns: Dictionary with limited player information safe for analytics
    func getPrivacyCompliantPlayerInfo() -> [String: Any] {
        guard isPlayerAuthenticated() else {
            return ["authenticated": false]
        }
        
        return [
            "authenticated": true,
            "hasDisplayName": localPlayer?.displayName != nil,
            "hasPlayerID": localPlayer?.gamePlayerID != nil
        ]
    }
}
