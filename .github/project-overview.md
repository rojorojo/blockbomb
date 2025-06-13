# Block 'em Up! iOS Game - Project Overview

## Table of Contents

1. [Game Overview](#game-overview)
2. [Technical Architecture](#technical-architecture)
3. [Core Features](#core-features)
4. [Monetization & Ad System](#monetization--ad-system)
5. [Game Mechanics](#game-mechanics)
6. [User Interface](#user-interface)
7. [Development Environment](#development-environment)
8. [Project Structure](#project-structure)
9. [Testing & Debugging](#testing--debugging)
10. [Deployment](#deployment)
11. [Future Features](#future-features)

## Game Overview

**Block 'em Up!** is a modern iOS block puzzle game that combines the strategic thinking of classic Tetris-style puzzles with innovative power-ups, monetization features, and smooth mobile gameplay. The game challenges players to place tetromino-style pieces onto an 8x8 grid to clear lines and achieve high scores.

### Key Highlights

- **Platform**: iOS 15+ (iPhone optimized)
- **Genre**: Puzzle/Strategy
- **Monetization**: Ad-supported free-to-play with optional in-app purchases
- **Architecture**: Hybrid SwiftUI + SpriteKit implementation
- **Target Audience**: Casual puzzle game enthusiasts

## Technical Architecture

### Core Technology Stack

- **Frontend**: SwiftUI (iOS 15+) for UI/UX layers
- **Game Engine**: SpriteKit for game logic and animations
- **Development**: Xcode 15+, Swift 5.8+
- **Deployment**: iOS App Store, TestFlight

### Hybrid Architecture Benefits

The project employs a sophisticated **SwiftUI + SpriteKit hybrid architecture**:

- **SwiftUI Layer**: Handles UI overlays, menus, settings, monetization screens, and state management
- **SpriteKit Layer**: Manages game board, piece interactions, animations, and core gameplay logic
- **Communication Bridge**: Bidirectional data flow between SwiftUI and SpriteKit layers

### Key Architectural Components

```
ContentView (SwiftUI)
├── GameSceneView (UIViewRepresentable)
│   └── GameScene (SpriteKit)
│       ├── GameBoard
│       ├── PieceNodes
│       └── Visual Effects
├── UI Overlays (SwiftUI)
│   ├── Score Display
│   ├── Settings Panel
│   ├── Shop Interface
│   └── Game Over Screen
└── Game Controller (ObservableObject)
    ├── State Management
    ├── Score Tracking
    └── Feature Coordination
```

## Core Features

### 1. **Advanced Ad & Monetization System** ✅ **IMPLEMENTED**

- **Rewarded Video Ads**: Players earn coins by watching advertisements
- **Interstitial Ads**: Strategically timed between gameplay sessions
- **Bonus Ad Prompts**: Optional ad viewing for extra rewards
- **Ad Timing Management**: Intelligent cooldowns and frequency controls
- **Google AdMob Integration**: Production-ready advertisement serving

**Key Files**:

- `Features/Ads/AdManager.swift` - Core ad management
- `Features/Ads/AdTimingManager.swift` - Ad timing and frequency logic
- `ad_powerups.md` - Complete implementation documentation

### 2. **Revive Heart System** ✅ **IMPLEMENTED**

- **Heart-Based Lives**: Players have 3 revive hearts maximum
- **Game State Preservation**: Complete board state saved before game over
- **Precise Restoration**: Board, pieces, and score restored exactly
- **Currency Integration**: Hearts purchasable with earned coins
- **Visual Feedback**: Animated heart consumption and restoration

**Key Files**:

- `Features/ReviveHeart/ReviveHeartManager.swift` - Heart management
- `Features/ReviveHeart/GameStateManager.swift` - State preservation/restoration
- `revive_heart.md` - Complete implementation documentation

### 3. **Machine Learning Integration** ✅ **IMPLEMENTED**

- **Core ML Model**: Trained TensorFlow model for intelligent piece selection
- **Strategic Difficulty**: ML adjusts piece complexity based on board state
- **Adaptive Gameplay**: Maintains engagement without frustration
- **Production Ready**: Integrated with live gameplay systems

**Key Files**:

- `Features/ML/MLPieceSelector.swift` - ML integration
- `ml_plan.md` - Implementation and training documentation

### 4. **Currency & Powerup Economy** ✅ **IMPLEMENTED**

- **Coin System**: Earn coins through ads and gameplay achievements
- **Powerup Shop**: Purchase revive hearts and future power-ups
- **Reward Configuration**: Tunable reward economy for balancing
- **Persistent Storage**: UserDefaults-based currency persistence

### 5. **Sophisticated Piece System** ✅ **IMPLEMENTED**

- **26 Unique Tetromino Shapes**: Organized into 9 strategic categories
- **Weighted Rarity System**: Common, uncommon, rare, and legendary pieces
- **Strategic Selection**: Multiple algorithms for piece generation
- **Visual Variety**: Color-coded categories with harmonious design

**Shape Categories**:

```swift
enum Category: String, CaseIterable {
    case squares, rectangles, sticks, lShapes, corners,
         tShapes, special, elbows, sShapes
}
```

## Monetization & Ad System

### Ad Integration Architecture

The game implements a comprehensive ad system designed for optimal user experience and revenue generation:

#### Ad Types & Timing

- **Rewarded Video Ads**:
  - Triggered by user choice (coin earning)
  - Integrated with powerup purchases
  - 10-30 second standard duration
- **Interstitial Ads**:
  - Shown after every 3-5 completed games
  - Minimum 60-second cooldown between displays
  - Smart timing to avoid gameplay disruption

#### Revenue Optimization Features

- **Bonus Ad Prompts**: Encourage voluntary ad viewing
- **Ad Reward Animations**: Satisfying visual feedback for coin earning
- **Frequency Capping**: Prevents ad fatigue while maximizing views
- **Debug Testing**: Comprehensive testing tools for ad scenarios

## Game Mechanics

### Board System

- **8x8 Grid**: Optimized for mobile gameplay
- **Line Clearing**: Both horizontal and vertical line completion
- **Combo System**: Bonus points for simultaneous row/column clears
- **Ghost Piece Preview**: Shows piece placement before commitment

### Scoring System

```swift
// Points awarded for line clearing
case 1: return 100    // Single line
case 2: return 300    // Double lines
case 3: return 500    // Triple lines
case 4: return 800    // Quadruple lines
case 5+: return 1000 + (lines - 5) * 200  // Bonus scaling
```

### Piece Selection Intelligence

The game uses multiple selection algorithms:

- **Balanced Weighted**: Standard difficulty progression
- **Strategic Weighted**: ML-enhanced difficulty adaptation
- **Uniform Random**: Pure random selection
- **Rescue Mode**: Easier pieces when board is nearly full

### Visual Effects

- **Particle Systems**: Sparkle effects for combos and achievements
- **Animation System**: Smooth piece placement and line clearing
- **Gradient Text**: Premium visual styling for score displays
- **Glow Effects**: Highlight completed lines before clearing

## User Interface

### SwiftUI Components

- **Onboarding Flow**: 4-screen introduction to game mechanics
- **Settings Panel**: Audio, haptics, and game preferences
- **Shop Interface**: Powerup and currency management
- **High Score Animations**: Celebratory effects for achievements

### Accessibility Features

- **VoiceOver Support**: Screen reader compatibility
- **High Contrast**: Colorblind-friendly design choices
- **Large Touch Targets**: Optimized for various hand sizes
- **Haptic Feedback**: Tactile confirmation of actions

### Color System

The game uses a carefully designed color palette:

```swift
// Example color definitions
static let violet = Color(red: 0.53, green: 0.48, blue: 1.0)
static let amber = Color(red: 1.0, green: 0.75, blue: 0.0)
static let teal = Color(red: 0.0, green: 0.8, blue: 0.6)
```

## Development Environment

### Prerequisites

- **macOS**: Latest version recommended
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 15.0+
- **Swift**: 5.8+

### Project Configuration

- **Game Name**: Block 'em Up!
- **Xcode Project**: blockbomb
- **Bundle Identifier**: `com.blockbomb`
- **Architecture**: iPhone-only (no iPad optimization)
- **Orientation**: Portrait only
- **Safe Area**: Full modern iPhone support

### Development Workflow

1. **Local Development**: Xcode simulator testing
2. **Device Testing**: Physical device debugging
3. **TestFlight**: Beta testing distribution
4. **App Store**: Production deployment

## Project Structure

```
blockbomb/
├── blockbomb/                      # Main app target
│   ├── ContentView.swift           # Root SwiftUI view
│   ├── GameController.swift        # Central game state manager
│   ├── GameScene.swift            # Main SpriteKit scene
│   ├── GameBoard.swift            # Game logic and board management
│   ├── TetrominoShape.swift       # Piece definitions and logic
│   │
│   ├── Features/                   # Feature-specific modules
│   │   ├── Ads/                   # Advertisement system
│   │   ├── ReviveHeart/           # Revive heart functionality
│   │   ├── ML/                    # Machine learning integration
│   │   └── Currency/              # Coin and powerup economy
│   │
│   ├── UI/                        # SwiftUI interface components
│   │   ├── OnboardingView.swift   # First-time user experience
│   │   ├── SettingsView.swift     # Game settings interface
│   │   ├── ShopView.swift         # Powerup purchase interface
│   │   └── GameOverView.swift     # End-game screen
│   │
│   └── Extensions/                # Swift extensions and utilities
│
├── blockbombTests/                # Unit tests
├── blockbombUITests/             # UI automation tests
├── docs/                         # Documentation
│   └── features/                 # Feature specifications
└── .github/                      # GitHub configuration
    └── project-overview.md       # This document
```

## Testing & Debugging

### Debug Tools

The project includes comprehensive debugging capabilities:

#### Debug Panel (Debug Builds Only)

- **Game State Testing**: Create specific board scenarios
- **Ad System Testing**: Force ad displays and simulate rewards
- **High Score Testing**: Trigger animations and state changes
- **Currency Testing**: Modify coin balances for testing
- **Heart System Testing**: Reset hearts and test revive functionality

#### Access Debug Panel

- Available only in `DEBUG` builds
- Tap the ant icon (🐜) in the top UI bar
- Provides extensive testing capabilities for all game systems

### Testing Coverage

- **Unit Tests**: Core game logic and piece placement
- **UI Tests**: SwiftUI interface interactions
- **Integration Tests**: Ad system and external service integration
- **Device Testing**: Various iPhone models and iOS versions

### Debug Features

```swift
#if DEBUG
// Debug-only features
struct DebugPanelView: View {
    // Comprehensive testing interface
    // Ad simulation, game state manipulation
    // Currency testing, heart system validation
}
#endif
```

## Deployment

### Build Configuration

- **Debug**: Full debug panel, logging, and testing tools
- **Release**: Optimized performance, minimal logging
- **App Store**: Final production build with analytics

### TestFlight Setup

- **Internal Testing**: Development team validation
- **External Testing**: Beta user feedback collection
- **Crash Reporting**: Integrated crash analytics
- **Performance Monitoring**: Runtime performance tracking

### App Store Preparation

- **Screenshots**: Marketing assets for App Store listing
- **Metadata**: App description, keywords, and categories
- **Age Rating**: Appropriate content rating
- **Privacy Policy**: Data collection and usage transparency

## Future Features

### Planned Developments

#### 1. **Multiplayer System** 📋 **PLANNED**

- **Real-time Competition**: Head-to-head puzzle battles
- **GameCenter Integration**: Leaderboards and achievements
- **Social Features**: Friend challenges and sharing
- **Tournament Mode**: Organized competitive events

**Documentation**: `docs/features/play_friends.md`

#### 2. **Enhanced Powerups** 📋 **PLANNED**

- **Bomb Pieces**: Clear surrounding blocks
- **Line Rockets**: Instantly clear rows/columns
- **Color Bombs**: Remove all blocks of specific color
- **Time Slow**: Extend thinking time for complex placements

#### 3. **Campaign Mode** 📋 **PLANNED**

- **Level Progression**: Structured puzzle challenges
- **Objective Variety**: Clear X lines, reach Y score, etc.
- **Difficulty Scaling**: Progressive challenge increases
- **Reward System**: Unlockable content and achievements

#### 4. **Advanced Analytics** 📋 **PLANNED**

- **Player Behavior Tracking**: Gameplay pattern analysis
- **A/B Testing**: Feature and balance experimentation
- **Retention Metrics**: User engagement optimization
- **Revenue Analytics**: Monetization performance tracking

### Technical Improvements

- **Performance Optimization**: Further animation and rendering improvements
- **Accessibility Enhancement**: Additional accessibility features
- **Localization**: Multi-language support
- **Cloud Save**: Cross-device game state synchronization

---

## Development Notes

### Code Quality Standards

- **Swift Style Guidelines**: Consistent code formatting and conventions
- **Documentation**: Comprehensive inline code documentation
- **Error Handling**: Robust error handling and user feedback
- **Performance**: Optimized for smooth 60fps gameplay

### Architecture Benefits

The hybrid SwiftUI + SpriteKit architecture provides:

- **Separation of Concerns**: Clear division between UI and game logic
- **Maintainability**: Modular, testable code structure
- **Flexibility**: Easy addition of new features and UI components
- **Performance**: Optimized rendering and smooth animations

### Key Design Decisions

1. **8x8 Grid**: Optimal for mobile screen sizes and complexity
2. **Piece Variety**: 26 shapes provide strategic depth without overwhelming players
3. **Ad Integration**: Respectful, optional monetization that enhances rather than disrupts gameplay
4. **ML Integration**: Intelligent difficulty adjustment for sustained engagement

This project represents a production-ready iOS game with comprehensive features, robust architecture, and modern development practices. The codebase is well-structured for continued development and feature expansion.

**Note**: The game is titled "Block 'em Up!" but the Xcode project and internal references use "blockbomb" for technical consistency.
