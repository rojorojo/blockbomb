# Bomb Powerup Implementation Plan

## Overview
Implement three types of bomb powerups (small, medium, nuclear) that players can drag and drop onto the game grid to clear blocks strategically. Players can purchase bombs from the shop and hold up to 5 in inventory, with usage limited to twice per game.

## Phase 1: Core Bomb Powerup Infrastructure

### Task 1.1: Powerup Model Extension

**Objective**: Extend the existing powerup system to support three bomb types

**AI Prompt:**
```
Extend the BlockBomb iOS game powerup system to support three new bomb powerups:

Requirements:
- [ ] Add `bombSmall`, `bombMedium`, `bombNuclear` cases to existing PowerupType enum in `/Models/Powerup.swift`
- [ ] Extend PowerupManager to handle bomb powerup logic with inventory limits
- [ ] Add bomb-specific properties (blast radius: 3x3, 5x5, full board)
- [ ] Implement usage limit tracking (max 2 bombs per game)
- [ ] Follow existing powerup architectural patterns (similar to revive hearts)
- [ ] Ensure accessibility labels for bomb powerup UI elements
- [ ] Integration with existing inventory and powerup collection systems

Technical Specifications:
- Small bomb: 3x3 circular blast radius
- Medium bomb: 5x5 circular blast radius  
- Nuclear bomb: clears entire board + bonus points
- Activation: drag-and-drop mechanism (same as blocks)
- Max inventory: 5 bombs total (any combination)
- Usage limit: 2 bombs per game session
- Chain reaction support between bomb types

File Locations:
- `/Models/Powerup.swift` - extend PowerupType enum
- `/Features/Powerups/PowerupManager.swift` - add bomb logic and limits
- `/Features/Powerups/BombPowerup.swift` - new bomb-specific class
- `/Features/Powerups/BombInventoryManager.swift` - inventory and usage tracking

Accessibility:
- VoiceOver support for bomb drag-and-drop
- High contrast visual indicators for blast radius
- Haptic feedback for bomb activation and explosions

Requirements:
- [ ] Add `bombSmall`, `bombMedium`, `bombNuclear` cases to existing PowerupType enum
- [ ] Extend PowerupManager to handle bomb powerup logic with inventory limits
- [ ] Add bomb-specific properties (blast radius: 3x3, 5x5, full board)
- [ ] Implement usage limit tracking (max 2 bombs per game)
- [ ] Follow existing powerup architectural patterns
- [ ] Ensure accessibility labels for bomb powerup UI elements
- [ ] Integration with existing inventory and powerup collection systems
```

**User Intervention**: Review blast radius balance and confirm pricing structure

**Build & Test**: Build and run the app to verify powerup model extensions

### Task 1.2: Bomb Drag and Drop System

**Objective**: Implement drag-and-drop bomb placement using existing block mechanics

**AI Prompt:**
```
Implement bomb drag-and-drop system for the BlockBomb iOS game using existing block drag mechanics:

Requirements:
- [ ] Create bomb UI elements in VStack format (bomb icon on top, count below)
- [ ] Position bomb inventory where current hearts are located
- [ ] Implement drag-and-drop using same offset calculations as blocks
- [ ] Add visual preview of blast radius during drag
- [ ] Implement drop validation for valid grid positions
- [ ] Add cancel drop functionality (drag off grid)
- [ ] Integration with existing game state management

Technical Specifications:
- Use existing block drag-and-drop system as reference
- Apply same position offset calculations for consistent feel
- Circular blast radius preview overlay
- Visual feedback for valid/invalid drop zones
- Smooth animation transitions matching block behavior

File Locations:
- `/Features/UI/GameUI/BombInventoryView.swift` - bomb inventory display
- `/Features/Powerups/BombDragHandler.swift` - drag-and-drop logic
- `/Extensions/GameGrid+BombPlacement.swift` - grid integration
- `/Features/UI/GameUI/BlastRadiusPreview.swift` - preview overlay

Accessibility:
- VoiceOver navigation for bomb inventory
- Audio cues for valid/invalid drop zones
- Alternative placement method for users with motor difficulties

Integration Points:
- GameViewController for drag state management
- PowerupManager for bomb consumption
- GridManager for position validation
- Existing block drag system for consistent UX

Requirements:
- [ ] Create bomb UI elements in VStack format (bomb icon on top, count below)
- [ ] Position bomb inventory where current hearts are located
- [ ] Implement drag-and-drop using same offset calculations as blocks
- [ ] Add visual preview of blast radius during drag
- [ ] Implement drop validation for valid grid positions
- [ ] Add cancel drop functionality
- [ ] Integration with existing game state management
```

**User Intervention**: Test drag-and-drop UX against existing block mechanics

**Build & Test**: Build and run the app to verify bomb placement functionality

## Phase 2: Bomb Explosion Mechanics

### Task 2.1: Explosion Logic Implementation

**Objective**: Create explosion mechanics for three bomb types with chain reactions

**AI Prompt:**
```
Implement bomb explosion mechanics for the BlockBomb iOS game:

Requirements:
- [ ] Create BombExplosion class in `/Features/Powerups/BombExplosion/`
- [ ] Implement circular blast radius calculations (3x3, 5x5, full board)
- [ ] Add block destruction logic for all block types equally
- [ ] Implement chain reaction system for nearby bombs
- [ ] Handle nuclear bomb board clearing with bonus calculation
- [ ] No points awarded for bomb-destroyed blocks (only nuclear bonus)
- [ ] Usage tracking to enforce 2-bomb-per-game limit

Technical Specifications:
- Circular blast pattern calculations
- Chain reaction detection and triggering
- Nuclear bomb: clear all blocks + 500 bonus points
- Block destruction without score attribution
- Bomb usage counter integration

File Locations:
- `/Features/Powerups/BombExplosion/BombExplosion.swift`
- `/Features/Powerups/BombExplosion/CircularBlastCalculator.swift`
- `/Features/Powerups/BombExplosion/ChainReactionHandler.swift`
- `/Extensions/Block+BombDestruction.swift`

Accessibility:
- Audio feedback for different explosion types
- Haptic patterns for explosion intensity (small, medium, nuclear)
- Screen reader announcements for cleared areas

Integration Points:
- ScoreManager for nuclear bonus points only
- BlockManager for block removal
- GameState for usage limit tracking
- AnimationManager for explosion effects

Requirements:
- [ ] Create BombExplosion class with circular blast calculations
- [ ] Implement block destruction logic for all block types equally
- [ ] Add chain reaction system for nearby bombs
- [ ] Handle nuclear bomb board clearing with bonus
- [ ] No points for bomb-destroyed blocks (except nuclear bonus)
- [ ] Usage tracking for 2-bomb-per-game limit
```

**User Intervention**: Balance testing for blast radius and nuclear bonus value

**Build & Test**: Build and run the app to verify explosion mechanics

### Task 2.2: Visual Effects and Animation

**Objective**: Implement bomb animations using provided assets

**AI Prompt:**
```
Implement bomb explosion visual effects using provided animation assets:

Requirements:
- [ ] Integrate bomb_small_anim animation for small bomb explosions
- [ ] Integrate bomb_large_anim animation for medium bomb explosions  
- [ ] Integrate bomb_nuclear_anim animation for nuclear bomb explosions
- [ ] Add chain reaction visual effects for multiple bomb triggers
- [ ] Implement screen shake effects (intensity based on bomb type)
- [ ] Add blast radius preview during drag operations
- [ ] Block destruction animations coordinated with bomb effects

Technical Specifications:
- Use provided animation assets: bomb_small_anim, bomb_large_anim, bomb_nuclear_anim
- Coordinate animations with audio timing
- Chain reaction visual cascading effects
- Performance optimized for simultaneous explosions
- Reduced motion accessibility support

File Locations:
- `/Features/Effects/BombExplosion/BombAnimationController.swift`
- `/Features/Effects/BombExplosion/ChainReactionEffects.swift`
- `/Features/Effects/BombExplosion/ScreenShakeEffect.swift`
- `/Resources/Animations/` - provided bomb animation assets

Accessibility:
- Reduced motion support for all bomb animations
- Alternative feedback for motion-sensitive users
- Audio descriptions of visual effects

Integration Points:
- AnimationManager for coordinated effects
- SettingsManager for accessibility preferences
- AudioManager for synchronized sound effects
- Provided assets: bomb_small_anim, bomb_large_anim, bomb_nuclear_anim

Requirements:
- [ ] Integrate bomb_small_anim, bomb_large_anim, bomb_nuclear_anim assets
- [ ] Add chain reaction visual effects
- [ ] Implement screen shake effects by bomb type
- [ ] Add blast radius preview during drag
- [ ] Block destruction animations
- [ ] Reduced motion accessibility support
```

**User Intervention**: Review animation timing and intensity levels

**Build & Test**: Build and run the app to verify visual effects performance

## Phase 3: UI Integration and Audio

### Task 3.1: Bomb Inventory UI Integration

**Objective**: Create bomb inventory UI in current heart location

**AI Prompt:**
```
Create bomb inventory UI to replace current heart display in the BlockBomb iOS game:

Requirements:
- [ ] Replace heart inventory with bomb inventory in same location
- [ ] Create VStack layout: bomb icon on top, count below
- [ ] Support displaying up to 5 bombs in inventory
- [ ] Add bomb type indicators (small, medium, nuclear icons)
- [ ] Implement usage limit indicator (X/2 uses remaining)
- [ ] Integrate with existing UI design system
- [ ] Add purchase integration with PowerupShopView

Technical Specifications:
- Position where current ReviveHeartManager UI is located
- VStack format matching existing powerup display patterns
- Dynamic count display with bomb type icons
- Usage limit counter display
- Consistent styling with existing game UI

File Locations:
- `/Features/UI/GameUI/BombInventoryView.swift`
- `/Features/UI/GameUI/BombTypeIcon.swift`
- `/Features/UI/GameUI/BombUsageLimitDisplay.swift`
- Update `/UI/PowerupShopView.swift` to include bombs

Accessibility:
- VoiceOver labels for all bomb inventory elements
- High contrast mode support
- Dynamic type support for count displays
- Usage limit announcements

Integration Points:
- GameViewController for inventory display
- PowerupShopView for bomb purchases
- BombInventoryManager for count management
- Replace existing heart inventory positioning

Requirements:
- [ ] Replace heart inventory with bomb inventory in same location
- [ ] Create VStack layout: bomb icon on top, count below
- [ ] Support up to 5 bombs with type indicators
- [ ] Add usage limit indicator (X/2 uses remaining)
- [ ] Integrate with PowerupShopView for purchases
- [ ] Match existing UI design patterns
```

**User Intervention**: Review UI placement and confirm visual design

**Build & Test**: Build and run the app to verify UI integration

### Task 3.2: Audio Implementation

**Objective**: Implement bomb audio using provided sound assets

**AI Prompt:**
```
Implement bomb audio system using provided sound assets:

Requirements:
- [ ] Integrate bomb_small audio for small bomb explosions
- [ ] Integrate bomb_large audio for medium bomb explosions
- [ ] Integrate bomb_nuclear audio for nuclear bomb explosions
- [ ] Add bomb placement/drop sound effects
- [ ] Implement chain reaction audio cascading
- [ ] Support for audio mixing with existing game sounds
- [ ] Volume control integration with game settings

Technical Specifications:
- Use provided audio assets: bomb_small, bomb_large, bomb_nuclear
- AVAudioEngine for advanced audio mixing
- Chain reaction audio timing coordination
- Spatial audio support for explosion direction
- Audio ducking for nuclear explosions

File Locations:
- `/Features/Audio/BombAudio/BombAudioManager.swift`
- `/Resources/Audio/bomb_small.wav` - provided asset
- `/Resources/Audio/bomb_large.wav` - provided asset
- `/Resources/Audio/bomb_nuclear.wav` - provided asset
- `/Features/Audio/BombAudio/ChainReactionAudio.swift`

Accessibility:
- Audio description alternatives
- Visual feedback for audio-impaired users
- Customizable audio intensity settings

Integration Points:
- AudioManager for global audio coordination
- SettingsManager for user audio preferences
- HapticManager for combined haptic+audio feedback
- Provided assets: bomb_small, bomb_large, bomb_nuclear

Requirements:
- [ ] Integrate bomb_small, bomb_large, bomb_nuclear audio assets
- [ ] Add bomb placement/drop sound effects
- [ ] Implement chain reaction audio cascading
- [ ] Support audio mixing with existing game sounds
- [ ] Volume control integration
- [ ] Spatial audio support
```

**User Intervention**: Test audio balance and timing with animations

**Build & Test**: Build and run the app to verify audio implementation

## Phase 4: Shop Integration and Testing

### Task 4.1: PowerupShop Integration

**Objective**: Add bomb purchases to existing PowerupShopView

**AI Prompt:**
```
Integrate bomb powerups into existing PowerupShopView in the BlockBomb iOS game:

Requirements:
- [ ] Add bombSmall, bombMedium, bombNuclear to PowerupShopView
- [ ] Implement pricing structure for three bomb types
- [ ] Add inventory limit validation (max 5 bombs total)
- [ ] Create bomb-specific purchase UI elements
- [ ] Add bomb icons and descriptions
- [ ] Integrate with existing purchase flow and currency system

Technical Specifications:
- Small bomb: 15 coins
- Medium bomb: 25 coins  
- Nuclear bomb: 50 coins
- Inventory limit: 5 bombs total (any combination)
- Use existing PowerupShopView architecture

File Locations:
- Update `/UI/PowerupShopView.swift` - add bomb purchase options
- Update `/Features/Powerups/PowerupShopManager.swift` - add bomb logic
- `/Resources/UI/BombIcons/` - bomb type icons for shop

Accessibility:
- VoiceOver labels for all bomb purchase elements
- Clear pricing and inventory limit announcements
- Purchase confirmation feedback

Integration Points:
- Existing PowerupShopView structure
- PowerupCurrencyManager for transactions
- BombInventoryManager for inventory limits
- Existing purchase flow patterns

Requirements:
- [ ] Add bombSmall, bombMedium, bombNuclear to PowerupShopView
- [ ] Implement pricing: small(15), medium(25), nuclear(50) coins
- [ ] Add inventory limit validation (max 5 bombs)
- [ ] Create bomb purchase UI elements
- [ ] Add bomb icons and descriptions
- [ ] Integrate with existing purchase flow
```

**User Intervention**: Review pricing balance and shop UI layout

**Build & Test**: Build and run the app to verify shop integration

### Task 4.2: Unit Testing

**Objective**: Create comprehensive unit tests for bomb powerup functionality

**AI Prompt:**
```
Create unit tests for bomb powerup implementation in the BlockBomb iOS game:

Requirements:
- [ ] Test circular blast radius calculations for all bomb types
- [ ] Test chain reaction logic and cascading
- [ ] Test inventory limit enforcement (5 bombs max)
- [ ] Test usage limit tracking (2 bombs per game)
- [ ] Test nuclear bomb board clearing and bonus calculation
- [ ] Test bomb purchase integration and pricing
- [ ] Mock external dependencies

File Locations:
- `/Tests/Unit/Powerups/BombPowerupTests.swift`
- `/Tests/Unit/Powerups/BombExplosionTests.swift`
- `/Tests/Unit/Powerups/BombInventoryTests.swift`
- `/Tests/Unit/Powerups/BombShopTests.swift`

Test Coverage:
- Circular blast radius edge cases
- Chain reaction scenarios
- Inventory and usage limit enforcement
- Nuclear bomb special mechanics
- Purchase flow validation

Requirements:
- [ ] Test circular blast radius calculations
- [ ] Test chain reaction logic
- [ ] Test inventory limits (5 max) and usage limits (2 per game)
- [ ] Test nuclear bomb mechanics and bonus
- [ ] Test purchase integration
- [ ] Mock external dependencies
```

### Task 4.3: UI Testing

**Objective**: Create UI tests for bomb powerup user interactions

**AI Prompt:**
```
Create UI tests for bomb powerup user interactions in the BlockBomb iOS game:

Requirements:
- [ ] Test bomb drag-and-drop workflow
- [ ] Test bomb purchase flow in shop
- [ ] Test inventory display and limits
- [ ] Test usage limit enforcement in UI
- [ ] Test accessibility interactions
- [ ] Test blast radius preview during drag

File Locations:
- `/Tests/UI/Powerups/BombDragDropUITests.swift`
- `/Tests/UI/Powerups/BombShopUITests.swift`
- `/Tests/UI/Accessibility/BombAccessibilityTests.swift`

Test Scenarios:
- Complete bomb purchase and usage workflow
- Inventory limit scenarios
- Usage limit enforcement
- Drag-and-drop cancellation
- Accessibility navigation paths

Requirements:
- [ ] Test bomb drag-and-drop workflow
- [ ] Test bomb purchase flow
- [ ] Test inventory and usage limit displays
- [ ] Test accessibility interactions
- [ ] Test blast radius preview
- [ ] Test error handling scenarios
```

### Task 4.4: Final Testing and Validation

**Objective**: Run comprehensive test suite and validate all functionality

**Build & Test**: Run all unit and UI tests to ensure no regressions

## Implementation Order

1. **Core Foundation** (Phase 1): Powerup model extensions and drag-drop system
2. **Mechanics Implementation** (Phase 2): Explosion logic and visual/audio effects
3. **User Interface** (Phase 3): Inventory UI and audio integration
4. **Shop Integration** (Phase 4): Purchase system and comprehensive testing

## New File Structure Changes

### New Directories:
```
/Features/Powerups/BombExplosion/
/Features/Effects/BombExplosion/
/Features/Audio/BombAudio/
/Features/UI/GameUI/BombInventory/
/Tests/Unit/Powerups/
/Tests/UI/Powerups/
```

### New UI Components:
- `BombInventoryView.swift`
- `BombTypeIcon.swift`
- `BombDragHandler.swift`
- `BlastRadiusPreview.swift`

### Configuration Extensions:
- Bomb pricing in PowerupShopManager
- Inventory limits in BombInventoryManager
- Usage limits in GameStateManager
- Audio settings for bomb effects

### Test Coverage:
- Unit tests: 95% coverage for bomb logic
- UI tests: Complete drag-drop and purchase workflows
- Accessibility tests: VoiceOver navigation for all bomb features
- Performance tests: Chain reaction and multiple bomb scenarios

### Asset Integration:
- Animation assets: bomb_small_anim, bomb_large_anim, bomb_nuclear_anim
- Audio assets: bomb_small, bomb_large, bomb_nuclear
- Icons for small, medium, and nuclear bomb types
