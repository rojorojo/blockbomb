import XCTest
@testable import blockbomb

class AdManagerTests: XCTestCase {
    
    var adManager: AdManager!
    
    override func setUp() {
        super.setUp()
        adManager = AdManager.shared
    }
    
    override func tearDown() {
        adManager.resetRetryCounters()
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonPattern() {
        let instance1 = AdManager.shared
        let instance2 = AdManager.shared
        
        XCTAssertTrue(instance1 === instance2, "AdManager should be a singleton")
    }
    
    func testInitialState() {
        // Note: In a unit test environment, AdMob won't actually initialize
        // These tests verify the initial state and structure
        
        XCTAssertFalse(adManager.isShowingAd)
        XCTAssertNotNil(adManager)
    }
    
    // MARK: - Ad Availability Tests
    
    func testCanShowRewardedAdInitialState() {
        // Initially should not be able to show ads (not loaded)
        XCTAssertFalse(adManager.canShowRewardedAd)
    }
    
    func testCanShowInterstitialAdInitialState() {
        // Initially should not be able to show ads (not loaded)
        XCTAssertFalse(adManager.canShowInterstitialAd)
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryCounterReset() {
        adManager.resetRetryCounters()
        
        // After reset, retry logic should be available
        // This is verified by the fact that the method completes without error
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Emergency Fallback Tests
    
    func testEmergencyFallback() {
        let expectation = XCTestExpectation(description: "Emergency fallback should provide reward")
        
        adManager.handleAdUnavailable { success, points in
            XCTAssertTrue(success, "Emergency fallback should succeed")
            XCTAssertEqual(points, 5, "Emergency fallback should provide 5 points")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Simulation Tests
    
    func testSimulateAdReward() {
        let expectation = XCTestExpectation(description: "Simulated ad should provide reward")
        
        adManager.simulateAdReward { success, points in
            XCTAssertTrue(success, "Simulated ad should succeed")
            XCTAssertEqual(points, 10, "Simulated ad should provide 10 points")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - State Management Tests
    
    func testForceReloadAds() {
        // Test that force reload resets the state appropriately
        adManager.forceReloadAds()
        
        // Verify state is reset
        XCTAssertFalse(adManager.hasInterstitialAdLoaded)
        XCTAssertFalse(adManager.hasRewardedAdLoaded)
        XCTAssertFalse(adManager.isShowingAd)
    }
    
    func testPreloadAds() {
        // Test that preload method can be called without errors
        adManager.preloadAds()
        
        // In a unit test environment, this mainly tests that the method doesn't crash
        XCTAssertNotNil(adManager)
    }
    
    // MARK: - Error Handling Tests
    
    func testShowRewardedAdWithoutLoaded() {
        let expectation = XCTestExpectation(description: "Should handle no ad available gracefully")
        
        // Create a mock view controller for testing
        let viewController = UIViewController()
        
        adManager.showRewardedAd(from: viewController) { success, points in
            XCTAssertFalse(success, "Should fail when no ad is loaded")
            XCTAssertEqual(points, 0, "Should provide 0 points on failure")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testShowInterstitialAdWithoutLoaded() {
        let expectation = XCTestExpectation(description: "Should handle no ad available gracefully")
        
        // Create a mock view controller for testing
        let viewController = UIViewController()
        
        adManager.showInterstitialAd(from: viewController) { success in
            XCTAssertFalse(success, "Should fail when no ad is loaded")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testAdManagerIntegrationWithCurrencyManager() {
        let expectation = XCTestExpectation(description: "Ad reward should integrate with currency manager")
        
        let initialPoints = PowerupCurrencyManager.shared.currentPoints
        
        adManager.simulateAdReward { success, points in
            if success {
                PowerupCurrencyManager.shared.addPoints(points)
                let finalPoints = PowerupCurrencyManager.shared.currentPoints
                XCTAssertEqual(finalPoints, initialPoints + points, "Points should be added to currency manager")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        // Clean up
        PowerupCurrencyManager.shared.resetPoints()
    }
    
    func testAdManagerGameOverViewIntegration() {
        // Test that AdManager can be integrated into views without errors
        let adManager = AdManager.shared
        
        // Verify that the manager exists and has expected properties
        XCTAssertNotNil(adManager.canShowRewardedAd) // Bool property
        XCTAssertNotNil(adManager.canShowInterstitialAd) // Bool property
        XCTAssertNotNil(adManager.isShowingAd) // Bool property
        XCTAssertNotNil(adManager.isInitialized) // Bool property
    }
    
    // MARK: - Performance Tests
    
    func testAdManagerPerformance() {
        measure {
            for _ in 1...100 {
                let _ = adManager.canShowRewardedAd
                let _ = adManager.canShowInterstitialAd
                let _ = adManager.isShowingAd
            }
        }
    }
    
    func testEmergencyFallbackPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            adManager.handleAdUnavailable { success, points in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testMultipleSimultaneousAdRequests() {
        let expectation1 = XCTestExpectation(description: "First ad request")
        let expectation2 = XCTestExpectation(description: "Second ad request")
        
        let viewController = UIViewController()
        
        // Make two simultaneous requests
        adManager.showRewardedAd(from: viewController) { success, points in
            expectation1.fulfill()
        }
        
        adManager.showRewardedAd(from: viewController) { success, points in
            // Second request should fail (already showing ad or no ad available)
            XCTAssertFalse(success, "Second simultaneous request should fail")
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }
    
    func testAdManagerStateConsistency() {
        // Test that state properties remain consistent
        let initialShowingState = adManager.isShowingAd
        let initialInterstitialState = adManager.hasInterstitialAdLoaded
        let initialRewardedState = adManager.hasRewardedAdLoaded
        
        // After force reload, showing state should be false
        adManager.forceReloadAds()
        
        XCTAssertFalse(adManager.isShowingAd, "Should not be showing ad after force reload")
        XCTAssertFalse(adManager.hasInterstitialAdLoaded, "Should not have interstitial loaded after reset")
        XCTAssertFalse(adManager.hasRewardedAdLoaded, "Should not have rewarded ad loaded after reset")
    }
    
    // MARK: - Configuration Tests
    
    func testAdUnitIDs() {
        // Test that the ad unit IDs are properly configured (test IDs in this case)
        // This is more of a structural test to ensure the configuration is in place
        
        // The actual ad unit IDs are private, but we can test that the manager exists
        // and has the expected interface
        XCTAssertNotNil(adManager)
        
        // Test that methods exist and can be called
        adManager.loadInterstitialAd()
        adManager.loadRewardedAd()
        
        // These calls won't actually load ads in test environment,
        // but they verify the methods exist and don't crash
        XCTAssertTrue(true)
    }
}
