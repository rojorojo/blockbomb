# Firebase Analytics Integration Implementation Plan

## 🎯 FEATURE OVERVIEW

**Streamlined Firebase Analytics Integration**

Replace existing local analytics with Firebase Analytics throughout the BlockBomb iOS game to track essential gameplay, performance, and monetization metrics. Focus on key performance indicators (KPIs) while maintaining opt-in privacy compliance for US/Europe markets with COPPA considerations for users under 13.

## 📊 ANALYTICS GOALS & KPIs

**Primary KPIs to Track:**

- **Gameplay**: Game start, game over, session length, high score milestones
- **Monetization**: Ad impressions, ad views, power shop purchases, revive hearts usage
- **Engagement**: DAU (Daily Active Users), MAU (Monthly Active Users), onboarding completion
- **Performance**: App performance metrics, offline sync capabilities
- **Retention**: User lifetime value (LTV) tracking
- **Multiplayer**: Separate tracking for multiplayer vs single-player sessions

## Phase 1: Core Firebase Analytics Setup & Migration

### 1.1 Firebase Analytics Manager Setup

**AI Prompt:**

```
Create a centralized Firebase Analytics manager and begin migration from existing analytics:

Requirements:
- Create FirebaseAnalyticsManager.swift in `/Features/Analytics/` directory
- Singleton pattern following existing manager patterns
- Firebase Analytics is already added via Swift Package Manager
- Initialize Firebase Analytics in existing AppDelegate configuration
- Opt-in analytics by default with COPPA compliance (disable for users under 13)
- Methods: `initialize()`, `setAnalyticsEnabled()`, `logEvent()`, `setUserProperty()`
- Integration with existing MultiplayerConfig for user preferences
- Age verification integration for COPPA compliance
- Error handling and offline event queuing
- Privacy-compliant user property tracking
- Remove existing AdAnalyticsManager to reduce app size

Follow existing manager patterns (GameCenterManager, ReviveHeartManager). When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Create FirebaseAnalyticsManager.swift in `/Features/Analytics/`
- [ ] Singleton pattern following existing patterns
- [ ] Initialize Firebase Analytics in AppDelegate
- [ ] Opt-in analytics with COPPA compliance (under 13 disabled)
- [ ] Methods: `initialize()`, `setAnalyticsEnabled()`, `logEvent()`, `setUserProperty()`
- [ ] Integration with MultiplayerConfig for preferences
- [ ] Age verification for COPPA compliance
- [ ] Error handling and offline event queuing
- [ ] Privacy-compliant user property tracking
- [ ] Remove existing AdAnalyticsManager to reduce app size

Build and run the app to verify Firebase Analytics initialization works properly. When complete return to play_friends.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.

### 1.2 Essential Event Schema Definition

**AI Prompt:**

```
Create focused event schema for essential KPIs and gameplay tracking:

Requirements:
- Create AnalyticsEvents.swift in `/Features/Analytics/` directory
- Define enum-based event structures for type safety
- Essential events: game_start, game_end, session_start, session_end
- Monetization events: ad_impression, ad_completion, revive_heart_purchase, power_shop_purchase
- Milestone events: high_score_achieved, onboarding_completed
- Performance events: app_launch_time, offline_sync_completed
- User properties: user_type (new/returning), total_games_played, highest_score
- Multiplayer vs single-player session distinction
- Parameter validation and sanitization
- No PII collection for privacy compliance
- Documentation for each event type

Focus on the specific KPIs mentioned: game start/end, session length, revive hearts, high scores, DAU/MAU, onboarding, ads. When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Create AnalyticsEvents.swift in `/Features/Analytics/`
- [ ] Enum-based event structures for type safety
- [ ] Essential events: game_start, game_end, session_start, session_end
- [ ] Monetization: ad_impression, ad_completion, revive_heart_purchase, power_shop_purchase
- [ ] Milestones: high_score_achieved, onboarding_completed
- [ ] Performance: app_launch_time, offline_sync_completed
- [ ] User properties: user_type, total_games_played, highest_score
- [ ] Multiplayer vs single-player session distinction
- [ ] Parameter validation and sanitization
- [ ] No PII collection for privacy compliance
- [ ] Documentation for each event type

Build and run the app to verify event schema compilation.

### 1.3 Privacy and Age Verification

**AI Prompt:**

```
Implement opt-in privacy compliance with age verification for COPPA:

Requirements:
- Extend existing MultiplayerConfig.swift for analytics consent preferences
- Add age verification during onboarding process
- Disable analytics collection for users under 13 (COPPA compliance)
- Opt-in analytics by default for users 13+ with clear consent UI
- Analytics consent options: essential_only, full_analytics, disabled
- Consent persistence and validation
- Methods: `requestAnalyticsConsent()`, `hasAnalyticsConsent()`, `setUserAge()`, `isAnalyticsAllowed()`
- Integration with existing onboarding flow
- Privacy-compliant data handling for EU/US markets
- Clear consent withdrawal mechanism

Build on existing privacy patterns and integrate with current user onboarding. When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Extend MultiplayerConfig.swift for analytics consent
- [ ] Add age verification during onboarding
- [ ] Disable analytics for users under 13 (COPPA)
- [ ] Opt-in analytics for users 13+ with clear consent UI
- [ ] Consent options: essential_only, full_analytics, disabled
- [ ] Consent persistence and validation
- [ ] Methods: `requestAnalyticsConsent()`, `hasAnalyticsConsent()`, `setUserAge()`, `isAnalyticsAllowed()`
- [ ] Integration with existing onboarding flow
- [ ] Privacy-compliant data handling for EU/US
- [ ] Clear consent withdrawal mechanism

Build and run the app to verify privacy and age verification functionality.

Write unit tests for privacy compliance and age verification.

## Phase 2: Core Gameplay Analytics Implementation

### 2.1 Essential Gameplay Event Tracking

**AI Prompt:**

```
Implement core gameplay analytics focusing on primary KPIs:

Requirements:
- Create GameplayAnalytics.swift in `/Features/Analytics/` directory
- Integration with existing GameController and GameScene
- Track session start/end with duration calculation for DAU/MAU
- Game start/end events with outcome tracking
- High score milestone achievements (configurable thresholds)
- Onboarding completion tracking
- Distinguish between single-player and multiplayer sessions
- Methods: `trackSessionStart()`, `trackGameStart()`, `trackGameEnd()`, `trackHighScore()`, `trackOnboardingStep()`
- Offline event queuing with automatic sync when online
- Performance optimized batch processing
- Integration with existing game lifecycle

Focus on the specific KPIs: game start/end, session length, high scores, onboarding completion, DAU/MAU. When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Create GameplayAnalytics.swift in `/Features/Analytics/`
- [ ] Integration with GameController and GameScene
- [ ] Session start/end with duration for DAU/MAU tracking
- [ ] Game start/end events with outcome tracking
- [ ] High score milestone achievements
- [ ] Onboarding completion tracking
- [ ] Single-player vs multiplayer session distinction
- [ ] Methods: `trackSessionStart()`, `trackGameStart()`, `trackGameEnd()`, `trackHighScore()`, `trackOnboardingStep()`
- [ ] Offline event queuing with automatic sync
- [ ] Performance optimized batch processing
- [ ] Integration with existing game lifecycle

Build and run the app to verify gameplay event tracking.

### 2.2 Monetization Analytics Migration

**AI Prompt:**

```
Migrate and enhance ad analytics with Firebase Analytics integration:

Requirements:
- Replace existing AdAnalyticsManager completely with Firebase integration
- Migrate relevant analytics data before removal
- Track ad impression, completion, and failure events
- Revive heart purchase tracking with LTV calculation
- Power shop purchase events and conversion funnels
- Ad source and placement identification
- User journey from ad view to purchase conversion
- Methods: `trackAdImpression()`, `trackAdCompletion()`, `trackReviveHeartPurchase()`, `trackPowerShopPurchase()`, `calculateLTV()`
- Integration with existing ReviveHeartManager and power shop systems
- Revenue attribution and user value tracking
- Remove AdAnalyticsManager.swift to reduce app size

Focus on the monetization KPIs: ad impressions, ad views, revive hearts usage, power shop purchases. When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Replace AdAnalyticsManager completely with Firebase integration
- [ ] Migrate relevant analytics data before removal
- [ ] Track ad impression, completion, and failure events
- [ ] Revive heart purchase tracking with LTV calculation
- [ ] Power shop purchase events and conversion funnels
- [ ] Ad source and placement identification
- [ ] User journey from ad view to purchase conversion
- [ ] Methods: `trackAdImpression()`, `trackAdCompletion()`, `trackReviveHeartPurchase()`, `trackPowerShopPurchase()`, `calculateLTV()`
- [ ] Integration with ReviveHeartManager and power shop systems
- [ ] Revenue attribution and user value tracking
- [ ] Remove AdAnalyticsManager.swift to reduce app size

Build and run the app to verify monetization event tracking.

### 2.3 Multiplayer Analytics Separation

**AI Prompt:**

```
Separate multiplayer analytics from single-player and migrate to Firebase:

Requirements:
- Enhance existing MultiplayerAnalyticsManager.swift with Firebase integration
- Replace placeholder trackFirebaseEvent method with real Firebase Analytics calls
- Separate multiplayer session tracking from single-player analytics
- Track multiplayer-specific KPIs: match start/end, turn duration, completion rates
- Integration with Firebase Analytics for multiplayer events
- Maintain existing multiplayer analytics functionality while adding Firebase
- Methods: `trackMultiplayerSession()`, `trackMatchEvent()`, `logMultiplayerTurn()`
- Remove local analytics storage in favor of Firebase
- Offline sync for multiplayer events
- Performance optimization for multiplayer event batching

Build on existing MultiplayerAnalyticsManager patterns while adding true Firebase integration. When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Enhance MultiplayerAnalyticsManager.swift with Firebase integration
- [ ] Replace trackFirebaseEvent placeholder with real Firebase calls
- [ ] Separate multiplayer from single-player session tracking
- [ ] Track multiplayer KPIs: match start/end, turn duration, completion rates
- [ ] Integration with Firebase Analytics for multiplayer events
- [ ] Maintain existing functionality while adding Firebase
- [ ] Methods: `trackMultiplayerSession()`, `trackMatchEvent()`, `logMultiplayerTurn()`
- [ ] Remove local analytics storage in favor of Firebase
- [ ] Offline sync for multiplayer events
- [ ] Performance optimization for multiplayer event batching

Build and run the app to verify separated multiplayer analytics.

Write unit tests for gameplay and monetization analytics.

## Phase 3: Performance and Lifecycle Analytics

### 3.1 User Lifecycle and LTV Tracking

**AI Prompt:**

```
Implement user lifecycle tracking and lifetime value calculation:

Requirements:
- Create UserLifecycleAnalytics.swift in `/Features/Analytics/` directory
- Track new vs returning users for DAU/MAU calculations
- User lifecycle stages: new, active, at_risk, dormant, churned
- Lifetime value calculation based on ad revenue and purchases
- Session frequency and retention metrics
- First-time user experience tracking
- Methods: `trackUserLifecycleStage()`, `calculateLTV()`, `trackRetention()`, `trackFirstSession()`
- Integration with existing user preferences and game progression
- Privacy-compliant user identification (no PII)
- Long-term user value prediction

Focus on DAU/MAU tracking and LTV calculation as specified in KPIs. When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Create UserLifecycleAnalytics.swift in `/Features/Analytics/`
- [ ] Track new vs returning users for DAU/MAU
- [ ] User lifecycle stages: new, active, at_risk, dormant, churned
- [ ] LTV calculation based on ad revenue and purchases
- [ ] Session frequency and retention metrics
- [ ] First-time user experience tracking
- [ ] Methods: `trackUserLifecycleStage()`, `calculateLTV()`, `trackRetention()`, `trackFirstSession()`
- [ ] Integration with user preferences and game progression
- [ ] Privacy-compliant user identification (no PII)
- [ ] Long-term user value prediction

Build and run the app to verify user lifecycle tracking.

### 3.2 Performance Monitoring

**AI Prompt:**

```
Implement essential performance analytics for app optimization:

Requirements:
- Create PerformanceAnalytics.swift in `/Features/Analytics/` directory
- App launch time tracking for performance KPIs
- Memory usage monitoring and performance correlation
- Network connectivity and offline sync performance
- Game loading time and responsiveness metrics
- Battery usage optimization for analytics operations
- Methods: `trackAppLaunch()`, `trackPerformanceMetric()`, `trackOfflineSync()`, `monitorMemoryUsage()`
- Integration with existing network connectivity monitoring
- Performance regression detection
- Efficient background processing for analytics

Focus on essential performance metrics without over-engineering. When complete return to analytics.md and mark the requirements complete. Do not implement any other parts of the plan without my approval.
```

Requirements:

- [ ] Create PerformanceAnalytics.swift in `/Features/Analytics/`
- [ ] App launch time tracking for performance KPIs
- [ ] Memory usage monitoring and performance correlation
- [ ] Network connectivity and offline sync performance
- [ ] Game loading time and responsiveness metrics
- [ ] Battery usage optimization for analytics operations
- [ ] Methods: `trackAppLaunch()`, `trackPerformanceMetric()`, `trackOfflineSync()`, `monitorMemoryUsage()`
- [ ] Integration with existing network connectivity monitoring
- [ ] Performance regression detection
- [ ] Efficient background processing for analytics

Build and run the app to verify performance analytics tracking.

Write comprehensive unit tests for all analytics components.

Run all unit and UI tests to ensure complete functionality.

## Implementation Order Priority

### High Priority (Essential KPIs)

1. **Phase 1.1** - Firebase Analytics Manager Setup
2. **Phase 1.2** - Essential Event Schema Definition
3. **Phase 1.3** - Privacy and Age Verification
4. **Phase 2.1** - Essential Gameplay Event Tracking

### Medium Priority (Monetization & User Tracking)

5. **Phase 2.2** - Monetization Analytics Migration
6. **Phase 3.1** - User Lifecycle and LTV Tracking
7. **Phase 2.3** - Multiplayer Analytics Separation

### Lower Priority (Performance & Optimization)

8. **Phase 3.2** - Performance Monitoring

## Technical Considerations

### Firebase Integration

- **Existing Setup**: Firebase Analytics already added via Swift Package Manager
- **Migration Strategy**: Replace existing local analytics with Firebase, remove old analytics files
- **Offline Support**: Queue events offline and sync when network available
- **Privacy**: Opt-in by default, COPPA compliance for users under 13

### Key Performance Indicators (KPIs)

- **Gameplay**: Game start, game over, session length, high score milestones
- **Monetization**: Ad impressions, ad views, revive hearts usage, power shop purchases
- **Engagement**: DAU/MAU, onboarding completion, user lifetime value
- **Performance**: App launch time, offline sync efficiency
- **Multiplayer**: Separate tracking from single-player metrics

### Privacy and Compliance

- **Opt-in Analytics**: Default to opt-in with clear user consent
- **Age Verification**: Disable analytics for users under 13 (COPPA)
- **Geographic Compliance**: US/Europe market focus (GDPR considerations)
- **Data Minimization**: Track only essential KPIs, no PII collection

### Performance Optimization

- **Battery Efficiency**: Optimize analytics operations for minimal battery impact
- **Offline Sync**: Store events locally and sync when network available
- **Event Batching**: Process events efficiently to minimize performance impact
- **Memory Management**: Efficient event queuing and processing

## Simplified File Structure

```
blockbomb/
├── Features/
│   └── Analytics/
│       ├── FirebaseAnalyticsManager.swift (new)
│       ├── AnalyticsEvents.swift (new)
│       ├── GameplayAnalytics.swift (new)
│       ├── UserLifecycleAnalytics.swift (new)
│       ├── PerformanceAnalytics.swift (new)
│       └── MultiplayerAnalyticsManager.swift (enhanced, existing)
├── Configuration/
│   └── MultiplayerConfig.swift (enhanced for analytics consent)
└── Tests/
    ├── AnalyticsTests/
    │   ├── FirebaseAnalyticsManagerTests.swift
    │   ├── GameplayAnalyticsTests.swift
    │   └── UserLifecycleAnalyticsTests.swift
    └── Files to Remove:
        └── AdAnalyticsManager.swift (delete to reduce app size)
```

## Success Metrics

- **KPI Coverage**: All specified KPIs tracked and reported in Firebase
- **Privacy Compliance**: 100% COPPA and GDPR compliant data collection
- **Performance Impact**: <2% CPU usage for analytics operations
- **Data Quality**: Offline sync with <1% event loss rate
- **Code Reduction**: Remove existing analytics files to reduce app size
